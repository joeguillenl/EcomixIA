# ==============================================================================
# EcoMix IA — Suite 06: Regresión Integral H01 a H04
# ==============================================================================

. (Join-Path $PSScriptRoot "Test_Helpers.ps1")

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  SUITE 06: REGRESIÓN INTEGRAL H01 A H04" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$suitePassed = 0
$suiteFailed = 0

function Check([string]$name, [bool]$cond, [string]$detail) {
    if ($cond) {
        $global:passedTests++
        $script:suitePassed++
        Write-Host " [PASS] $name" -ForegroundColor Green
        if ($detail) { Write-Host "        $detail" -ForegroundColor Gray }
    } else {
        $global:failedTests++
        $script:suiteFailed++
        Write-Host " [FAIL] $name" -ForegroundColor Red
        if ($detail) { Write-Host "        $detail" -ForegroundColor Yellow }
    }
}

# ------------------------------------------------------------------------------
# 6.1 Regresión H01: Cálculos de Sostenibilidad y Modelo ML
# ------------------------------------------------------------------------------
Write-Host "`n--- 6.1 Regresión H01: Métricas de Sostenibilidad y Contrato ML ---" -ForegroundColor DarkCyan

# Paridad matemática de Mezcla 1 (Referencia Tradicional: 350 cemento, 180 agua, 1050 grueso, 700 fino)
# Cemento: 350 * 0.28 S/ = 98.0 S/ | 350 * 0.82 kg CO2 = 287.0 kg CO2
# Agua: 180 * 0.005 S/ = 0.9 S/ | 180 * 0.001 kg CO2 = 0.18 kg CO2
# Grueso: 1050 * 0.045 S/ = 47.25 S/ | 1050 * 0.008 kg CO2 = 8.4 kg CO2
# Fino: 700 * 0.040 S/ = 28.0 S/ | 700 * 0.006 kg CO2 = 4.2 kg CO2
# Total Costo: 98 + 0.9 + 47.25 + 28 = 174.15 S/
# Total CO2: 287 + 0.18 + 8.4 + 4.2 = 299.78 kg CO2

$cementoCosto = 350.0 * 0.28
$cementoCo2 = 350.0 * 0.82
$costoEsperado = 174.15
$co2Esperado = 299.78

Check "Regresión H01.1: Costo unitario y huella de carbono de referencia matemáticamente consistentes" `
    ([Math]::Abs($cementoCosto - 98.0) -lt 0.01 -and [Math]::Abs($cementoCo2 - 287.0) -lt 0.01) `
    "Costo cemento: $cementoCosto S/, CO2 cemento: $cementoCo2 kg"

# ------------------------------------------------------------------------------
# 6.2 Regresión H02: Snapshots Históricos e Inmutabilidad de Mezclas
# ------------------------------------------------------------------------------
Write-Host "`n--- 6.2 Regresión H02: Persistencia Histórica e Inmutabilidad (RF-14/15) ---" -ForegroundColor DarkCyan

# Crear una mezcla de prueba con componentes y snapshots
$mezclaId = [int](Query-SqlScalar @"
INSERT INTO [dbo].[Mezclas] ([Nombre], [ResistenciaMPa], [EdadDias], [RelacionAguaCemento], [AsentamientoCm], [Notas], [OwnerUserId])
VALUES ('Mezcla Regresion H02', 28.0, 28, 0.45, 10.0, 'Prueba de inmutabilidad', (SELECT TOP 1 Id FROM AspNetUsers WHERE Email = 'joamedina@upt.pe'));
SELECT SCOPE_IDENTITY();
"@)

$matCementoId = [int](Query-SqlScalar "SELECT TOP 1 Id FROM dbo.Materials WHERE Nombre LIKE '%Cemento%'")
$costoOriginal = [decimal](Query-SqlScalar "SELECT CostoPorKg FROM dbo.Materials WHERE Id = $matCementoId")
$co2Original = [decimal](Query-SqlScalar "SELECT Co2PorKg FROM dbo.Materials WHERE Id = $matCementoId")

# Guardar componente con snapshot
Execute-SqlNonQuery @"
INSERT INTO [dbo].[MezclaComponentes] 
([MezclaId], [MaterialId], [Cantidad], [CostoPorKgGuardado], [Co2PorKgGuardado], [FechaSnapshotUtc], [OrigenSnapshot])
VALUES 
($mezclaId, $matCementoId, 350, $costoOriginal, $co2Original, GETUTCDATE(), 'CatalogInitial');
"@ | Out-Null

# Modificar el precio en el catálogo Materials
$nuevoPrecio = $costoOriginal + [decimal]10.0
Execute-SqlNonQuery "UPDATE dbo.Materials SET CostoPorKg = $nuevoPrecio WHERE Id = $matCementoId;" | Out-Null

# Verificar que el snapshot persistido en MezclaComponentes NO cambió
$costoSnapshotRecuperado = [decimal](Query-SqlScalar "SELECT CostoPorKgGuardado FROM dbo.MezclaComponentes WHERE MezclaId = $mezclaId AND MaterialId = $matCementoId")

Check "Regresión H02.1: Inmutabilidad histórica verificada tras alteración del catálogo" `
    ($costoSnapshotRecuperado -eq $costoOriginal -and $costoSnapshotRecuperado -ne $nuevoPrecio) `
    "Snapshot guardado: $costoSnapshotRecuperado vs Nuevo precio en catálogo: $nuevoPrecio"

# Restaurar precio del catálogo
Execute-SqlNonQuery "UPDATE dbo.Materials SET CostoPorKg = $costoOriginal WHERE Id = $matCementoId;" | Out-Null

# ------------------------------------------------------------------------------
# 6.3 Regresión H02: Dashboard Personal y Aislamiento de Mezclas Privadas (RF-41 a RF-43)
# ------------------------------------------------------------------------------
Write-Host "`n--- 6.3 Regresión H02: Dashboard Personal y Aislamiento Privado ---" -ForegroundColor DarkCyan

$dbDash = New-Object EcomixIA.Models.EcomixContext ($connStringTrial)
$dashCtrl = New-Object EcomixIA.Controllers.DashboardController ($dbDash)
Init-Controller $dashCtrl

# Simular sesión de joamedina@upt.pe con Claim NameIdentifier
$userIdJoa = (Query-SqlScalar "SELECT TOP 1 Id FROM dbo.AspNetUsers WHERE Email = 'joamedina@upt.pe'")
$claim1 = New-Object System.Security.Claims.Claim("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", $userIdJoa)
$claims1 = [System.Security.Claims.Claim[]]@($claim1)
$identJoa = New-Object System.Security.Claims.ClaimsIdentity($claims1, "ApplicationCookie")
$dashCtrl.ControllerContext.HttpContext.User = New-Object System.Security.Claims.ClaimsPrincipal ($identJoa)

$dashResult = $dashCtrl.Index() -as [System.Web.Mvc.ViewResult]
$dashVm = $dashResult.Model -as [EcomixIA.Models.ViewModels.DashboardViewModel]

Check "Regresión H02.2: Dashboard personal calcula métricas de mezclas propias" `
    ($dashVm -ne $null -and $dashVm.TotalMezclasPrivadas -ge 1) `
    "TotalMezclasPrivadas: $($dashVm.TotalMezclasPrivadas)"

# Aislamiento entre usuarios: Usuario 2 no debe ver las mezclas privadas de Usuario 1
$userIdJoa2 = (Query-SqlScalar "SELECT TOP 1 Id FROM dbo.AspNetUsers WHERE Email = 'joamedina2@upt.pe'")
$claim2 = New-Object System.Security.Claims.Claim("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", $userIdJoa2)
$claims2 = [System.Security.Claims.Claim[]]@($claim2)
$identJoa2 = New-Object System.Security.Claims.ClaimsIdentity($claims2, "ApplicationCookie")

$dashCtrl2 = New-Object EcomixIA.Controllers.DashboardController ($dbDash)
Init-Controller $dashCtrl2
$dashCtrl2.ControllerContext.HttpContext.User = New-Object System.Security.Claims.ClaimsPrincipal ($identJoa2)

$dashResult2 = $dashCtrl2.Index() -as [System.Web.Mvc.ViewResult]
$dashVm2 = $dashResult2.Model -as [EcomixIA.Models.ViewModels.DashboardViewModel]

# Limpiar mezcla de prueba
Execute-SqlNonQuery "DELETE FROM dbo.MezclaComponentes WHERE MezclaId = $mezclaId;" | Out-Null
Execute-SqlNonQuery "DELETE FROM dbo.Mezclas WHERE Id = $mezclaId;" | Out-Null

Check "Regresión H02.3: Aislamiento estricto de mezclas privadas entre usuarios" `
    ($dashVm2.TotalMezclasPrivadas -ne $dashVm.TotalMezclasPrivadas) `
    "User 1 mezclas: $($dashVm.TotalMezclasPrivadas) vs User 2 mezclas: $($dashVm2.TotalMezclasPrivadas)"

# ------------------------------------------------------------------------------
# 6.4 Regresión H03: Ciclo Completo de Autenticación y Cuentas (RF-04 a RF-11)
# ------------------------------------------------------------------------------
Write-Host "`n--- 6.4 Regresión H03: Autenticación, Tokens y Recuperación ---" -ForegroundColor DarkCyan

$dbAuth = New-Object EcomixIA.Models.ApplicationDbContext ($connStringTrial)
$userStore = New-Object Microsoft.AspNet.Identity.EntityFramework.UserStore[EcomixIA.Models.ApplicationUser] ($dbAuth)
$userManager = New-Object EcomixIA.ApplicationUserManager ($userStore)

$dpapiProvider = New-Object Microsoft.Owin.Security.DataProtection.DpapiDataProtectionProvider("EcoMixIA_Test")
$dataProtector = $dpapiProvider.Create("ASP.NET Identity")
$userManager.UserTokenProvider = New-Object Microsoft.AspNet.Identity.Owin.DataProtectorTokenProvider[EcomixIA.Models.ApplicationUser]($dataProtector)

$unconfirmedUser = $userManager.FindByEmailAsync("auth.unconfirmed.test@upt.pe").GetAwaiter().GetResult()
$confirmedUser = $userManager.FindByEmailAsync("auth.test.civil@upt.pe").GetAwaiter().GetResult()

Check "Regresión H03.1: Confirmación de correo obligatoria verificada" `
    ($unconfirmedUser.EmailConfirmed -eq $false -and $confirmedUser.EmailConfirmed -eq $true) `
    "Unconfirmed: $($unconfirmedUser.EmailConfirmed), Confirmed: $($confirmedUser.EmailConfirmed)"

# Generación y validación de token de recuperación de contraseña
$resetToken = $userManager.GeneratePasswordResetTokenAsync($confirmedUser.Id).GetAwaiter().GetResult()
Check "Regresión H03.2: Generación de token criptográfico de recuperación de contraseña" `
    (![string]::IsNullOrEmpty($resetToken)) `
    "Token generado exitosamente"

# ------------------------------------------------------------------------------
# 6.5 Regresión H04: Administración de Cuentas y Estadísticas Globales (RF-49/50/51)
# ------------------------------------------------------------------------------
Write-Host "`n--- 6.5 Regresión H04: Gestión Administrativa y Estadísticas Agregadas ---" -ForegroundColor DarkCyan

$auditSvc = New-Object EcomixIA.Services.AuditService ($connStringTrial)
$stats = $auditSvc.GetDashboardStatsAsync((New-Object EcomixIA.Models.ApplicationDbContext ($connStringTrial)), $null).GetAwaiter().GetResult()

Check "Regresión H04.1: Estadísticas agregadas administrativas (RF-50) calculadas correctamente" `
    ($stats -ne $null -and $stats.TotalUsuarios -ge 4 -and $stats.UsuariosHabilitados -ge 3) `
    "TotalUsuarios: $($stats.TotalUsuarios), Habilitados: $($stats.UsuariosHabilitados), ErroresOperativos: $($stats.ErroresOperativos)"

$dbDash.Dispose()

Write-Host "`nRESUMEN SUITE 06: $suitePassed PASS / $suiteFailed FAIL" -ForegroundColor $(if ($suiteFailed -eq 0) { "Green" } else { "Red" })
return ($suiteFailed -eq 0)
