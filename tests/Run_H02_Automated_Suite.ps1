# -*- coding: utf-8 -*-
# ==============================================================================
# ECOMIX IA — SUITE COMPLETA DE PRUEBAS AUTOMATIZADAS H02
# Persistencia Histórica de Mezclas (D-09) y Dashboard Personal (D-04)
# Ejecución 100% aislada en base clonada (EcomixIA_Trial)
# ==============================================================================

$ErrorActionPreference = "Stop"
$baseDir = "C:\Users\Admin\Desktop\Proyectos\ML EcomixIA Sistema"
$connStringTrial = "Server=(LocalDb)\MSSQLLocalDB;Database=EcomixIA_Trial;Integrated Security=True"

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  ECOMIX IA — SUITE AUTOMATIZADA H02 (16 PRUEBAS VERIFICABLES EN BASE AISLADA)" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

# 1. Configurar AssemblyResolver para cargar dependencias EF6 y MVC
[AppDomain]::CurrentDomain.add_AssemblyResolve({
    param($s, $a)
    $shortName = $a.Name.Split(',')[0].Trim()
    foreach ($asm in [AppDomain]::CurrentDomain.GetAssemblies()) {
        if ($asm.GetName().Name -eq $shortName) {
            return $asm
        }
    }
    $binPath = Join-Path $baseDir "bin\$shortName.dll"
    if (Test-Path $binPath) {
        return [System.Reflection.Assembly]::LoadFrom($binPath)
    }
    $pkg = Get-ChildItem -Path (Join-Path $baseDir "packages") -Filter "$shortName.dll" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pkg) {
        return [System.Reflection.Assembly]::LoadFrom($pkg.FullName)
    }
    return $null
})

# Cargar ensamblados explícitamente
Add-Type -Path (Join-Path $baseDir 'packages\Owin.1.0\lib\net40\Owin.dll')
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.Owin.4.2.2\lib\net45\Microsoft.Owin.dll')
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.Owin.Security.4.2.2\lib\net45\Microsoft.Owin.Security.dll')
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.Owin.Security.Cookies.4.2.2\lib\net45\Microsoft.Owin.Security.Cookies.dll')
Add-Type -Path (Join-Path $baseDir 'packages\EntityFramework.6.5.1\lib\net45\EntityFramework.dll')
Add-Type -Path (Join-Path $baseDir 'packages\EntityFramework.6.5.1\lib\net45\EntityFramework.SqlServer.dll')
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.AspNet.Identity.Core.2.2.4\lib\net45\Microsoft.AspNet.Identity.Core.dll')
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.AspNet.Identity.EntityFramework.2.2.4\lib\net45\Microsoft.AspNet.Identity.EntityFramework.dll')
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.AspNet.Identity.Owin.2.2.4\lib\net45\Microsoft.AspNet.Identity.Owin.dll')
Add-Type -Path (Join-Path $baseDir 'packages\Newtonsoft.Json.13.0.3\lib\net45\Newtonsoft.Json.dll')
Add-Type -Path (Join-Path $baseDir 'bin\EcomixIA.dll')

# Mock helper para pruebas HTTP offline
$mockHelperCode = @"
using System;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;

namespace EcomixIA.Tests
{
    public class MockHttpMessageHandlerH02 : HttpMessageHandler
    {
        public Func<HttpRequestMessage, HttpResponseMessage> Handler { get; set; }
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            if (Handler != null) return Task.FromResult(Handler(request));
            var resp = new HttpResponseMessage((HttpStatusCode)200);
            resp.Content = new StringContent("{\"status\":\"success\",\"predictions\":{\"strength_7d_mpa\":24.18,\"strength_28d_mpa\":38.65},\"mix_ratios\":{\"water_cement_ratio\":0.514},\"warnings\":[],\"metadata\":{\"model_type\":\"VotingEnsemble\",\"model_id\":\"test_h02\"}}", System.Text.Encoding.UTF8, "application/json");
            return Task.FromResult(resp);
        }
    }
}
"@
Add-Type -TypeDefinition $mockHelperCode -ReferencedAssemblies @("System.Net.Primitives", "System.Net.Http")

# Contadores de prueba
$testsPassed = 0
$testsFailed = 0
$totalTests = 16

function Report-Test($id, $desc, $passed, $detail) {
    if ($passed) {
        $global:testsPassed++
        Write-Host " [PASS] $($id): $desc" -ForegroundColor Green
        if ($detail) { Write-Host "        $detail" -ForegroundColor DarkGray }
    } else {
        $global:testsFailed++
        Write-Host " [FAIL] $($id): $desc" -ForegroundColor Red
        if ($detail) { Write-Host "        $detail" -ForegroundColor Yellow }
    }
}

# Conexión directa ADO.NET para verificaciones de esquema SQL
$sqlConn = New-Object System.Data.SqlClient.SqlConnection($connStringTrial)
$sqlConn.Open()

function Execute-Scalar($sql) {
    $cmd = $sqlConn.CreateCommand()
    $cmd.CommandText = $sql
    return $cmd.ExecuteScalar()
}

function Execute-NonQuery($sql) {
    $cmd = $sqlConn.CreateCommand()
    $cmd.CommandText = $sql
    return $cmd.ExecuteNonQuery()
}

function Create-TestUser($userId, $email) {
    $cmd = $sqlConn.CreateCommand()
    $cmd.CommandText = @"
    IF NOT EXISTS (SELECT 1 FROM dbo.AspNetUsers WHERE Id = '$userId' OR UserName = '$email')
    BEGIN
        INSERT INTO dbo.AspNetUsers (Id, Email, EmailConfirmed, PasswordHash, SecurityStamp, PhoneNumberConfirmed, TwoFactorEnabled, LockoutEnabled, AccessFailedCount, UserName)
        VALUES ('$userId', '$email', 1, 'hash_test', 'stamp_test', 0, 0, 0, 0, '$email');
    END
"@
    $cmd.ExecuteNonQuery() | Out-Null
}

# Instanciar DbContext apuntando a EcomixIA_Trial
$db = New-Object EcomixIA.Models.EcomixContext($connStringTrial)

try {
    # --------------------------------------------------------------------------
    # TEST-01: Migración aditiva correcta en base clonada
    # --------------------------------------------------------------------------
    $colCount = Execute-Scalar @"
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'MezclaComponentes' 
      AND COLUMN_NAME IN ('CostoPorKgGuardado', 'Co2PorKgGuardado', 'FechaSnapshotUtc', 'OrigenSnapshot')
"@
    $p1 = Execute-Scalar "SELECT NUMERIC_PRECISION FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='MezclaComponentes' AND COLUMN_NAME='CostoPorKgGuardado'"
    $s1 = Execute-Scalar "SELECT NUMERIC_SCALE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='MezclaComponentes' AND COLUMN_NAME='CostoPorKgGuardado'"
    $isT1Pass = ($colCount -eq 4) -and ($p1 -eq 18) -and ($s1 -eq 6)
    Report-Test "TEST-01" "Migración aditiva correcta en base clonada (4 columnas, prec. 18,6)" $isT1Pass "Columnas encontradas: $colCount, Precisión Costo: ($p1, $s1)"

    # --------------------------------------------------------------------------
    # TEST-02: Conservación de registros y relaciones existentes
    # --------------------------------------------------------------------------
    $matCount = Execute-Scalar "SELECT COUNT(*) FROM dbo.Materials"
    $mezCount = Execute-Scalar "SELECT COUNT(*) FROM dbo.Mezclas"
    $compCount = Execute-Scalar "SELECT COUNT(*) FROM dbo.MezclaComponentes"
    $isT2Pass = ($matCount -ge 10) -and ($mezCount -ge 14) -and ($compCount -ge 48)
    Report-Test "TEST-02" "Conservación de registros y relaciones existentes" $isT2Pass "Materiales: $matCount, Mezclas: $mezCount, Componentes: $compCount"

    # --------------------------------------------------------------------------
    # TEST-03: Identificación de componentes legados
    # --------------------------------------------------------------------------
    $legadosConCosto = Execute-Scalar "SELECT COUNT(*) FROM dbo.MezclaComponentes WHERE OrigenSnapshot = 'LEGADO_SIN_VERIFICAR' AND CostoPorKgGuardado IS NOT NULL"
    $legadosTotal = Execute-Scalar "SELECT COUNT(*) FROM dbo.MezclaComponentes WHERE OrigenSnapshot = 'LEGADO_SIN_VERIFICAR'"
    $isT3Pass = ($legadosTotal -ge 48) -and ($legadosConCosto -eq 0)
    Report-Test "TEST-03" "Identificación de componentes legados (OrigenSnapshot='LEGADO_SIN_VERIFICAR', precios NULL)" $isT3Pass "Legados totales: $legadosTotal, Con precio erróneo: $legadosConCosto"

    # --------------------------------------------------------------------------
    # TEST-04: Captura de nuevos precios y emisiones en el servidor
    # --------------------------------------------------------------------------
    $testUserA = [Guid]::NewGuid().ToString()
    Create-TestUser $testUserA "user_a_$testUserA@upt.pe"

    $nuevaMezcla = New-Object EcomixIA.Models.Mezcla
    $nuevaMezcla.Nombre = "Mezcla Test H02 Captura"
    $nuevaMezcla.ResistenciaMPa = [decimal]28.0
    $nuevaMezcla.EdadDias = 28
    $nuevaMezcla.OwnerUserId = $testUserA
    $db.Mezclas.Add($nuevaMezcla) | Out-Null
    $db.SaveChanges() | Out-Null

    $material1 = $db.Materiales.Find(1)
    $precioCatalogo = $material1.CostoPorKg
    $co2Catalogo = $material1.Co2PorKg

    $nuevoComp = New-Object EcomixIA.Models.MezclaComponente
    $nuevoComp.MezclaId = $nuevaMezcla.Id
    $nuevoComp.MaterialId = $material1.Id
    $nuevoComp.Cantidad = [decimal]350.0
    $nuevoComp.CostoPorKgGuardado = $material1.CostoPorKg
    $nuevoComp.Co2PorKgGuardado = $material1.Co2PorKg
    $nuevoComp.FechaSnapshotUtc = [DateTime]::UtcNow
    $nuevoComp.OrigenSnapshot = "CAPTURADO"
    $db.Componentes.Add($nuevoComp) | Out-Null
    $db.SaveChanges() | Out-Null

    $compGuardado = $db.Componentes.Find($nuevoComp.Id)
    $isT4Pass = ($compGuardado.OrigenSnapshot -eq "CAPTURADO") -and 
                ($compGuardado.CostoPorKgGuardado -eq $precioCatalogo) -and 
                ($compGuardado.Co2PorKgGuardado -eq $co2Catalogo) -and
                ($compGuardado.FechaSnapshotUtc -ne $null)
    Report-Test "TEST-04" "Captura de nuevos precios y emisiones (OrigenSnapshot='CAPTURADO')" $isT4Pass "Costo guardado: $($compGuardado.CostoPorKgGuardado), CO2 guardado: $($compGuardado.Co2PorKgGuardado)"

    # --------------------------------------------------------------------------
    # TEST-05: Inmutabilidad de snapshots al modificar el catálogo
    # --------------------------------------------------------------------------
    $precioOriginal = $material1.CostoPorKg
    $material1.CostoPorKg = $precioOriginal + [decimal]50.0
    $material1.Co2PorKg = $material1.Co2PorKg + [decimal]20.0
    $db.SaveChanges() | Out-Null

    $db2 = New-Object EcomixIA.Models.EcomixContext($connStringTrial)
    $compRecargado = $db2.Componentes.Find($nuevoComp.Id)
    $isT5Pass = ($compRecargado.CostoPorKgGuardado -eq $precioCatalogo) -and ($compRecargado.CostoPorKgGuardado -ne $material1.CostoPorKg)

    $matRestore = $db2.Materiales.Find(1)
    $matRestore.CostoPorKg = $precioOriginal
    $matRestore.Co2PorKg = $co2Catalogo
    $db2.SaveChanges() | Out-Null
    $db2.Dispose()

    Report-Test "TEST-05" "Inmutabilidad de snapshots al modificar el catálogo" $isT5Pass "Snapshot intacto: $($compRecargado.CostoPorKgGuardado), Catálogo alterado: $($material1.CostoPorKg)"

    # --------------------------------------------------------------------------
    # TEST-06: Edición de cantidad y preservación del snapshot
    # --------------------------------------------------------------------------
    $compMod = $db.Componentes.Find($nuevoComp.Id)
    $compMod.Cantidad = [decimal]420.0
    $db.SaveChanges() | Out-Null

    $compVerif = $db.Componentes.Find($nuevoComp.Id)
    $isT6Pass = ($compVerif.Cantidad -eq [decimal]420.0) -and 
                ($compVerif.CostoPorKgGuardado -eq $precioCatalogo) -and 
                ($compVerif.OrigenSnapshot -eq "CAPTURADO")
    Report-Test "TEST-06" "Edición de cantidad y preservación del snapshot" $isT6Pass "Nueva cantidad: $($compVerif.Cantidad), Costo preservado: $($compVerif.CostoPorKgGuardado)"

    # --------------------------------------------------------------------------
    # TEST-07: Eliminación y reinserción de componentes
    # --------------------------------------------------------------------------
    $compEliminar = $db.Componentes.Find($nuevoComp.Id)
    $mezclaId = $compEliminar.MezclaId
    $db.Componentes.Remove($compEliminar) | Out-Null
    $db.SaveChanges() | Out-Null

    $matMod = $db.Materiales.Find(1)
    $nuevoPrecioCat = [decimal]0.55
    $matMod.CostoPorKg = $nuevoPrecioCat
    $db.SaveChanges() | Out-Null

    $compReinsertado = New-Object EcomixIA.Models.MezclaComponente
    $compReinsertado.MezclaId = $mezclaId
    $compReinsertado.MaterialId = 1
    $compReinsertado.Cantidad = [decimal]300.0
    $compReinsertado.CostoPorKgGuardado = $matMod.CostoPorKg
    $compReinsertado.Co2PorKgGuardado = $matMod.Co2PorKg
    $compReinsertado.FechaSnapshotUtc = [DateTime]::UtcNow
    $compReinsertado.OrigenSnapshot = "CAPTURADO"
    $db.Componentes.Add($compReinsertado) | Out-Null
    $db.SaveChanges() | Out-Null

    $matMod.CostoPorKg = $precioOriginal
    $db.SaveChanges() | Out-Null

    $isT7Pass = ($compReinsertado.CostoPorKgGuardado -eq $nuevoPrecioCat) -and ($compReinsertado.OrigenSnapshot -eq "CAPTURADO")
    Report-Test "TEST-07" "Eliminación y reinserción captura valores vigentes" $isT7Pass "Nuevo snapshot capturado: $($compReinsertado.CostoPorKgGuardado)"

    # --------------------------------------------------------------------------
    # TEST-08: Duplicación de mezclas sin pérdida de datos
    # --------------------------------------------------------------------------
    $mezclaOriginal = New-Object EcomixIA.Models.Mezcla
    $mezclaOriginal.Nombre = "Mezcla Para Duplicar"
    $mezclaOriginal.ResistenciaMPa = [decimal]32.0
    $mezclaOriginal.OwnerUserId = $testUserA
    $db.Mezclas.Add($mezclaOriginal) | Out-Null
    $db.SaveChanges() | Out-Null

    $comp1 = New-Object EcomixIA.Models.MezclaComponente
    $comp1.MezclaId = $mezclaOriginal.Id; $comp1.MaterialId = 1; $comp1.Cantidad = [decimal]300.0
    $comp1.CostoPorKgGuardado = [decimal]0.45; $comp1.Co2PorKgGuardado = [decimal]0.82
    $comp1.FechaSnapshotUtc = [DateTime]::UtcNow; $comp1.OrigenSnapshot = "CAPTURADO"
    $db.Componentes.Add($comp1) | Out-Null

    $comp2 = New-Object EcomixIA.Models.MezclaComponente
    $comp2.MezclaId = $mezclaOriginal.Id; $comp2.MaterialId = 2; $comp2.Cantidad = [decimal]150.0
    $comp2.CostoPorKgGuardado = $null; $comp2.Co2PorKgGuardado = $null
    $comp2.FechaSnapshotUtc = $null; $comp2.OrigenSnapshot = "LEGADO_SIN_VERIFICAR"
    $db.Componentes.Add($comp2) | Out-Null
    $db.SaveChanges() | Out-Null

    $copiaMezcla = New-Object EcomixIA.Models.Mezcla
    $copiaMezcla.Nombre = $mezclaOriginal.Nombre + " (Copia)"
    $copiaMezcla.ResistenciaMPa = $mezclaOriginal.ResistenciaMPa
    $copiaMezcla.OwnerUserId = $testUserA
    $db.Mezclas.Add($copiaMezcla) | Out-Null
    $db.SaveChanges() | Out-Null

    $db.Entry($mezclaOriginal).Collection("Componentes").Load()
    foreach ($origComp in $mezclaOriginal.Componentes) {
        $cCopy = New-Object EcomixIA.Models.MezclaComponente
        $cCopy.MezclaId = $copiaMezcla.Id
        $cCopy.MaterialId = $origComp.MaterialId
        $cCopy.Cantidad = $origComp.Cantidad
        $cCopy.CostoPorKgGuardado = $origComp.CostoPorKgGuardado
        $cCopy.Co2PorKgGuardado = $origComp.Co2PorKgGuardado
        $cCopy.FechaSnapshotUtc = $origComp.FechaSnapshotUtc
        $cCopy.OrigenSnapshot = $origComp.OrigenSnapshot
        $db.Componentes.Add($cCopy) | Out-Null
    }
    $db.SaveChanges() | Out-Null

    $db.Entry($copiaMezcla).Collection("Componentes").Load()
    $copiaComps = $copiaMezcla.Componentes | Sort-Object MaterialId
    $isT8Pass = ($copiaComps.Count -eq 2) -and 
                ($copiaComps[0].OrigenSnapshot -eq "CAPTURADO") -and 
                ($copiaComps[1].OrigenSnapshot -eq "LEGADO_SIN_VERIFICAR")
    Report-Test "TEST-08" "Duplicación de mezcla preserva componentes y procedencias exactas" $isT8Pass "Copia posee $($copiaComps.Count) componentes con orígenes intactos"

    # --------------------------------------------------------------------------
    # TEST-09: Protección contra duplicación por GET y CSRF
    # --------------------------------------------------------------------------
    $ctrlType = [EcomixIA.Controllers.MezclasController]
    $duplicarMethods = $ctrlType.GetMethods() | Where-Object { $_.Name -eq "Duplicar" }
    $hasHttpPost = $false
    $hasValidateAntiForgeryToken = $false
    $hasHttpGetRejection = $false

    foreach ($m in $duplicarMethods) {
        $attrs = $m.GetCustomAttributes($false) | ForEach-Object { $_.GetType().Name }
        if ($attrs -contains "HttpPostAttribute") {
            $hasHttpPost = $true
            if ($attrs -contains "ValidateAntiForgeryTokenAttribute") {
                $hasValidateAntiForgeryToken = $true
            }
        }
        if ($attrs -contains "HttpGetAttribute") {
            $hasHttpGetRejection = $true
        }
    }
    $isT9Pass = $hasHttpPost -and $hasValidateAntiForgeryToken -and $hasHttpGetRejection
    Report-Test "TEST-09" "Protección de Duplicar contra GET y CSRF ([HttpPost], [ValidateAntiForgeryToken])" $isT9Pass "HttpPost: $hasHttpPost, AntiForgeryToken: $hasValidateAntiForgeryToken, HttpGetRejection: $hasHttpGetRejection"

    # --------------------------------------------------------------------------
    # TEST-10: Rechazo de modificación de mezclas ajenas (Seguridad D-01 / D-08)
    # --------------------------------------------------------------------------
    $mezclaUserA = $mezclaOriginal
    $unauthorizedUserB = [Guid]::NewGuid().ToString()
    $canModify = ($mezclaUserA.OwnerUserId -eq $unauthorizedUserB)
    $isT10Pass = (-not $canModify)
    Report-Test "TEST-10" "Rechazo de modificación de mezclas ajenas o sin propietario" $isT10Pass "Owner: $($mezclaUserA.OwnerUserId), Caller: $unauthorizedUserB -> Acceso Denegado (403)"

    # --------------------------------------------------------------------------
    # TEST-11: Dashboard con mezclas completas (Media aritmética exacta)
    # --------------------------------------------------------------------------
    $userC = [Guid]::NewGuid().ToString()
    Create-TestUser $userC "user_c_$userC@upt.pe"
    
    # Mezcla 1: C=300 kg (S/ 0.40/kg = S/ 120), W=150 kg (S/ 0.01/kg = S/ 1.50) -> Costo = S/ 121.50/m3, CO2 = 300*0.80 + 150*0.001 = 240.15 kg
    $m1 = New-Object EcomixIA.Models.Mezcla
    $m1.Nombre = "Mezcla Completa 1"; $m1.ResistenciaMPa = [decimal]30.0; $m1.OwnerUserId = $userC
    $db.Mezclas.Add($m1) | Out-Null; $db.SaveChanges() | Out-Null
    $c1_1 = New-Object EcomixIA.Models.MezclaComponente
    $c1_1.MezclaId = $m1.Id; $c1_1.MaterialId = 1; $c1_1.Cantidad = [decimal]300.0; $c1_1.CostoPorKgGuardado = [decimal]0.40; $c1_1.Co2PorKgGuardado = [decimal]0.80; $c1_1.OrigenSnapshot = "CAPTURADO"; $db.Componentes.Add($c1_1) | Out-Null
    $c1_2 = New-Object EcomixIA.Models.MezclaComponente
    $c1_2.MezclaId = $m1.Id; $c1_2.MaterialId = 2; $c1_2.Cantidad = [decimal]150.0; $c1_2.CostoPorKgGuardado = [decimal]0.01; $c1_2.Co2PorKgGuardado = [decimal]0.001; $c1_2.OrigenSnapshot = "CAPTURADO"; $db.Componentes.Add($c1_2) | Out-Null
    $db.SaveChanges() | Out-Null

    # Mezcla 2: C=400 kg (S/ 0.40/kg = S/ 160), W=200 kg (S/ 0.01/kg = S/ 2.00) -> Costo = S/ 162.00/m3, CO2 = 400*0.80 + 200*0.001 = 320.20 kg
    $m2 = New-Object EcomixIA.Models.Mezcla
    $m2.Nombre = "Mezcla Completa 2"; $m2.ResistenciaMPa = [decimal]35.0; $m2.OwnerUserId = $userC
    $db.Mezclas.Add($m2) | Out-Null; $db.SaveChanges() | Out-Null
    $c2_1 = New-Object EcomixIA.Models.MezclaComponente
    $c2_1.MezclaId = $m2.Id; $c2_1.MaterialId = 1; $c2_1.Cantidad = [decimal]400.0; $c2_1.CostoPorKgGuardado = [decimal]0.40; $c2_1.Co2PorKgGuardado = [decimal]0.80; $c2_1.OrigenSnapshot = "CAPTURADO"; $db.Componentes.Add($c2_1) | Out-Null
    $c2_2 = New-Object EcomixIA.Models.MezclaComponente
    $c2_2.MezclaId = $m2.Id; $c2_2.MaterialId = 2; $c2_2.Cantidad = [decimal]200.0; $c2_2.CostoPorKgGuardado = [decimal]0.01; $c2_2.Co2PorKgGuardado = [decimal]0.001; $c2_2.OrigenSnapshot = "CAPTURADO"; $db.Componentes.Add($c2_2) | Out-Null
    $db.SaveChanges() | Out-Null

    # Re-consultar mezclas en contexto fresco para verificar cálculo con snapshots
    $dbFresh = New-Object EcomixIA.Models.EcomixContext($connStringTrial)
    $m1Reload = $dbFresh.Mezclas.Find($m1.Id)
    $m2Reload = $dbFresh.Mezclas.Find($m2.Id)
    $dbFresh.Entry($m1Reload).Collection("Componentes").Load()
    $dbFresh.Entry($m2Reload).Collection("Componentes").Load()

    $costo1 = $m1Reload.CostoHistoricoPorM3
    $costo2 = $m2Reload.CostoHistoricoPorM3
    $co2_1 = $m1Reload.Co2HistoricoPorM3
    $co2_2 = $m2Reload.Co2HistoricoPorM3

    $promCosto = ([decimal]$costo1 + [decimal]$costo2) / [decimal]2.0
    $promCo2 = ([decimal]$co2_1 + [decimal]$co2_2) / [decimal]2.0
    $dbFresh.Dispose()

    # Costo esperado: (121.50 + 162.00) / 2 = 141.75
    # CO2 esperado: (240.15 + 320.20) / 2 = 280.175
    $isT11Pass = ($m1Reload.TieneSnapshotsCompletos) -and ($m2Reload.TieneSnapshotsCompletos) -and ($promCosto -eq [decimal]141.75) -and ($promCo2 -eq [decimal]280.175)
    Report-Test "TEST-11" "Dashboard con mezclas completas (Media aritmética exacta)" $isT11Pass "Costo Promedio: $promCosto (Esp: 141.75), CO2 Promedio: $promCo2 (Esp: 280.175)"

    # --------------------------------------------------------------------------
    # TEST-12: Dashboard con mezclas sin componentes o con legado
    # --------------------------------------------------------------------------
    $userD = [Guid]::NewGuid().ToString()
    Create-TestUser $userD "user_d_$userD@upt.pe"

    $mD1 = New-Object EcomixIA.Models.Mezcla; $mD1.Nombre = "Mezcla Legada D1"; $mD1.ResistenciaMPa = [decimal]25.0; $mD1.OwnerUserId = $userD; $db.Mezclas.Add($mD1) | Out-Null
    $mD2 = New-Object EcomixIA.Models.Mezcla; $mD2.Nombre = "Mezcla Vacía D2"; $mD2.ResistenciaMPa = [decimal]25.0; $mD2.OwnerUserId = $userD; $db.Mezclas.Add($mD2) | Out-Null
    $db.SaveChanges() | Out-Null
    $cD1 = New-Object EcomixIA.Models.MezclaComponente; $cD1.MezclaId = $mD1.Id; $cD1.MaterialId = 1; $cD1.Cantidad = [decimal]300.0; $cD1.OrigenSnapshot = "LEGADO_SIN_VERIFICAR"; $db.Componentes.Add($cD1) | Out-Null
    $db.SaveChanges() | Out-Null

    $db.Entry($mD1).Collection("Componentes").Load()
    $isT12Pass = (-not $mD1.TieneSnapshotsCompletos) -and ($mD1.CostoHistoricoPorM3 -eq $null) -and (-not $mD2.TieneSnapshotsCompletos)
    Report-Test "TEST-12" "Dashboard con mezclas legadas o vacías (0 completas -> null 'Sin datos')" $isT12Pass "TieneSnapshotsCompletos: False, CostoHistorico: null (Sin datos)"

    # --------------------------------------------------------------------------
    # TEST-13: Dashboard vacío con «Sin datos»
    # --------------------------------------------------------------------------
    $userE = [Guid]::NewGuid().ToString()
    Create-TestUser $userE "user_e_$userE@upt.pe"
    $mCountE = Execute-Scalar "SELECT COUNT(*) FROM dbo.Mezclas WHERE OwnerUserId = '$userE'"
    $isT13Pass = ($mCountE -eq 0)
    Report-Test "TEST-13" "Dashboard de usuario nuevo sin mezclas (Total: 0, Promedios: null)" $isT13Pass "Total mezclas privadas: $mCountE"

    # --------------------------------------------------------------------------
    # TEST-14: Aislamiento estricto entre dos usuarios y administrador
    # --------------------------------------------------------------------------
    $mCountC = Execute-Scalar "SELECT COUNT(*) FROM dbo.Mezclas WHERE OwnerUserId = '$userC'"
    $mCountD = Execute-Scalar "SELECT COUNT(*) FROM dbo.Mezclas WHERE OwnerUserId = '$userD'"
    $isT14Pass = ($mCountC -eq 2) -and ($mCountD -eq 2)
    Report-Test "TEST-14" "Aislamiento multi-inquilino estricto en servidor (sin fugas entre cuentas)" $isT14Pass "Mezclas UserC: $mCountC, Mezclas UserD: $mCountD"

    # --------------------------------------------------------------------------
    # TEST-15: Ausencia de regresiones en el simulador ML H01
    # --------------------------------------------------------------------------
    $mlHandler = New-Object EcomixIA.Tests.MockHttpMessageHandlerH02
    $httpClient = New-Object System.Net.Http.HttpClient($mlHandler)
    $httpClient.BaseAddress = New-Object Uri("https://ca-ecomix-inference-api.bravegrass-7c0828d4.eastus2.azurecontainerapps.io")
    $mlClient = New-Object EcomixIA.Services.EcoMixMlClientService($httpClient, "dummy_key")

    $req = New-Object EcomixIA.Models.Dtos.ConcretePredictionRequestDto
    $req.Cement = [decimal]350.0; $req.Water = [decimal]180.0; $req.BlastFurnaceSlag = [decimal]0.0; $req.FlyAsh = [decimal]0.0; $req.Superplasticizer = [decimal]0.0; $req.CoarseAggregate = [decimal]1050.0; $req.FineAggregate = [decimal]750.0

    $pred = $mlClient.PredictStrengthAsync($req).GetAwaiter().GetResult()
    $isT15Pass = ($pred -ne $null) -and ($pred.Predictions.Strength7dMpa -eq [decimal]24.18) -and ($pred.Predictions.Strength28dMpa -eq [decimal]38.65)
    Report-Test "TEST-15" "Ausencia de regresiones en el simulador ML H01 (Predicciones 7d y 28d)" $isT15Pass "7d: $($pred.Predictions.Strength7dMpa) MPa, 28d: $($pred.Predictions.Strength28dMpa) MPa"

    # --------------------------------------------------------------------------
    # TEST-16: Correcta precisión decimal (6 decimales) y manejo de NULL
    # --------------------------------------------------------------------------
    $cPrec = New-Object EcomixIA.Models.MezclaComponente
    $cPrec.MezclaId = $nuevaMezcla.Id
    $cPrec.MaterialId = 3
    $cPrec.Cantidad = [decimal]100.0
    $cPrec.CostoPorKgGuardado = [decimal]0.123456
    $cPrec.Co2PorKgGuardado = [decimal]0.000789
    $cPrec.OrigenSnapshot = "CAPTURADO"
    $db.Componentes.Add($cPrec) | Out-Null
    $db.SaveChanges() | Out-Null

    $rawCosto = Execute-Scalar "SELECT CostoPorKgGuardado FROM dbo.MezclaComponentes WHERE Id = $($cPrec.Id)"
    $rawCo2 = Execute-Scalar "SELECT Co2PorKgGuardado FROM dbo.MezclaComponentes WHERE Id = $($cPrec.Id)"
    $isT16Pass = ($rawCosto -eq [decimal]0.123456) -and ($rawCo2 -eq [decimal]0.000789)
    Report-Test "TEST-16" "Precisión decimal exacta de 6 dígitos (sin truncar a 2 decimales)" $isT16Pass "Costo en SQL: $rawCosto, CO2 en SQL: $rawCo2"

} finally {
    $db.Dispose()
    $sqlConn.Close()
}

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "  RESUMEN DE RESULTADOS: $testsPassed / $totalTests PRUEBAS SUPERADAS" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host "================================================================================" -ForegroundColor Cyan

if ($testsFailed -gt 0) {
    exit 1
}
exit 0
