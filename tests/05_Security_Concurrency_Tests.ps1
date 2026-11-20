# ==============================================================================
# EcoMix IA — Suite 05: Pruebas de Seguridad, Concurrencia y Provisión D-10
# ==============================================================================

. (Join-Path $PSScriptRoot "Test_Helpers.ps1")

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  SUITE 05: PRUEBAS DE SEGURIDAD, CONCURRENCIA Y PROVISIÓN D-10" -ForegroundColor Cyan
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
# 5.1 Protección Concurrente del Último Administrador (1 Admin Activo)
# ------------------------------------------------------------------------------
Write-Host "`n--- 5.1 Protección Concurrente del Último Administrador (1 Admin) ---" -ForegroundColor DarkCyan

$adminRole = Query-SqlScalar "SELECT Id FROM dbo.AspNetRoles WHERE Name = 'Administrador'"
$mainAdminUser = Query-SqlScalar "SELECT Id FROM dbo.AspNetUsers WHERE Email = 'joamedina@upt.pe'"

# Dejar únicamente a joamedina@upt.pe como admin
Execute-SqlNonQuery "DELETE FROM dbo.AspNetUserRoles WHERE RoleId = '$adminRole' AND UserId <> '$mainAdminUser';" | Out-Null
Execute-SqlNonQuery "UPDATE dbo.AspNetUsers SET IsEnabled = 1 WHERE Id = '$mainAdminUser';" | Out-Null

$initialActiveAdmins = [int](Query-SqlScalar @"
SELECT COUNT(*) 
FROM dbo.AspNetUsers u 
INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId 
WHERE ur.RoleId = '$adminRole' AND u.IsEnabled = 1;
"@)

Check "Concurrencia 5.1.1: Base de prueba inicializada con exactamente 1 administrador activo" `
    ($initialActiveAdmins -eq 1) `
    "Administradores activos iniciales: $initialActiveAdmins"

# Lanzar múltiples procesos concurrentes para degradar o deshabilitar al único administrador
$actionScript = Join-Path $PSScriptRoot "helper_admin_action.ps1"

$p1 = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$actionScript`" -Action Toggle -UserId `"$mainAdminUser`"" -PassThru -WindowStyle Hidden
$p2 = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$actionScript`" -Action Role -UserId `"$mainAdminUser`"" -PassThru -WindowStyle Hidden
$p3 = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$actionScript`" -Action Toggle -UserId `"$mainAdminUser`"" -PassThru -WindowStyle Hidden
$p4 = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$actionScript`" -Action Role -UserId `"$mainAdminUser`"" -PassThru -WindowStyle Hidden

$p1.WaitForExit(10000) | Out-Null
$p2.WaitForExit(10000) | Out-Null
$p3.WaitForExit(10000) | Out-Null
$p4.WaitForExit(10000) | Out-Null

$finalActiveAdmins = [int](Query-SqlScalar @"
SELECT COUNT(*) 
FROM dbo.AspNetUsers u 
INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId 
WHERE ur.RoleId = '$adminRole' AND u.IsEnabled = 1;
"@)

Check "Concurrencia 5.1.2: El único administrador no pudo ser degradado ni deshabilitado concurrentemente" `
    ($finalActiveAdmins -eq 1) `
    "Administradores activos tras ataque concurrente: $finalActiveAdmins"

$lastAdminProtectedEvent = Query-SqlScalar @"
SELECT TOP 1 Details 
FROM dbo.AuditEvents 
WHERE Action IN ('BlockDemoteLastAdmin', 'BlockDisableLastAdmin') 
ORDER BY TimestampUtc DESC;
"@

Check "Concurrencia 5.1.3: Evento de auditoría de rechazo del último administrador registrado" `
    ($lastAdminProtectedEvent -ne $null -and $lastAdminProtectedEvent.Contains("último Administrador")) `
    "Evento registrado: $lastAdminProtectedEvent"

# ------------------------------------------------------------------------------
# 5.2 Operaciones Concurrentes sobre DOS Administradores Activos
# ------------------------------------------------------------------------------
Write-Host "`n--- 5.2 Operaciones Concurrentes sobre DOS Administradores Activos ---" -ForegroundColor DarkCyan

$admin2Id = Query-SqlScalar "SELECT Id FROM dbo.AspNetUsers WHERE Email = 'joamedina2@upt.pe'"

# Asignar rol a segundo administrador para tener exactamente dos
Execute-SqlNonQuery "DELETE FROM dbo.AspNetUserRoles WHERE RoleId = '$adminRole';" | Out-Null
Execute-SqlNonQuery "INSERT INTO dbo.AspNetUserRoles (UserId, RoleId) VALUES ('$mainAdminUser', '$adminRole');" | Out-Null
Execute-SqlNonQuery "INSERT INTO dbo.AspNetUserRoles (UserId, RoleId) VALUES ('$admin2Id', '$adminRole');" | Out-Null
Execute-SqlNonQuery "UPDATE dbo.AspNetUsers SET IsEnabled = 1 WHERE Id IN ('$mainAdminUser', '$admin2Id');" | Out-Null

$twoAdminsCount = [int](Query-SqlScalar @"
SELECT COUNT(*) 
FROM dbo.AspNetUsers u 
INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId 
WHERE ur.RoleId = '$adminRole' AND u.IsEnabled = 1;
"@)

Check "Concurrencia 5.2.1: Base de prueba inicializada con exactamente 2 administradores activos" `
    ($twoAdminsCount -eq 2) `
    "Administradores activos: $twoAdminsCount"

# Ejecutar degradación simultánea de ambos administradores
$pA = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$actionScript`" -Action Role -UserId `"$mainAdminUser`"" -PassThru -WindowStyle Hidden
$pB = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$actionScript`" -Action Role -UserId `"$admin2Id`"" -PassThru -WindowStyle Hidden

$pA.WaitForExit(10000) | Out-Null
$pB.WaitForExit(10000) | Out-Null

$remainingAdminsCount = [int](Query-SqlScalar @"
SELECT COUNT(*) 
FROM dbo.AspNetUsers u 
INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId 
WHERE ur.RoleId = '$adminRole' AND u.IsEnabled = 1;
"@)

Check "Concurrencia 5.2.2: Concurrencia entre 2 administradores arbitra atómicamente dejando exactamente 1 admin activo" `
    ($remainingAdminsCount -eq 1) `
    "Administradores activos resultantes: $remainingAdminsCount"

# Restablecer a joamedina@upt.pe como administrador único para siguientes pruebas
Execute-SqlNonQuery "DELETE FROM dbo.AspNetUserRoles WHERE RoleId = '$adminRole';" | Out-Null
Execute-SqlNonQuery "INSERT INTO dbo.AspNetUserRoles (UserId, RoleId) VALUES ('$mainAdminUser', '$adminRole');" | Out-Null

# ------------------------------------------------------------------------------
# 5.3 Ráfaga Masiva sobre Limitador de Solicitudes (RF-36)
# ------------------------------------------------------------------------------
Write-Host "`n--- 5.3 Ráfaga Masiva de Solicitudes sobre RateLimiter (RF-36) ---" -ForegroundColor DarkCyan

$rateLimiter = New-Object EcomixIA.Services.RequestRateLimiter
$floodIp = "10.0.0.123"
$maxAllowed = 5
$window = [TimeSpan]::FromSeconds(3)
$retry = [TimeSpan]::Zero

$allowedCount = 0
$blockedCount = 0

for ($k = 0; $k -lt 25; $k++) {
    $ok = $rateLimiter.TryAcquire($floodIp, $maxAllowed, $window, [ref]$retry)
    if ($ok) { $allowedCount++ } else { $blockedCount++ }
}

Check "RateLimiter 5.3.1: Ráfaga de 25 solicitudes permite exactamente el umbral (5)" `
    ($allowedCount -eq 5) `
    "Permitidos: $allowedCount"

Check "RateLimiter 5.3.2: Solicitudes excedentes (20) estrictamente bloqueadas" `
    ($blockedCount -eq 20 -and $retry.TotalSeconds -gt 0) `
    "Bloqueados: $blockedCount, RetryAfter: $($retry.TotalSeconds)s"

# ------------------------------------------------------------------------------
# 5.4 Invalidación de Sesión mediante SecurityStamp
# ------------------------------------------------------------------------------
Write-Host "`n--- 5.4 Invalidación de Sesión mediante SecurityStamp ---" -ForegroundColor DarkCyan

$dbStamp = New-Object EcomixIA.Models.ApplicationDbContext ($connStringTrial)
$storeStamp = New-Object Microsoft.AspNet.Identity.EntityFramework.UserStore[EcomixIA.Models.ApplicationUser] ($dbStamp)
$mgrStamp = New-Object EcomixIA.ApplicationUserManager ($storeStamp)

$targetUser = $mgrStamp.FindByEmailAsync("joamedina@upt.pe").GetAwaiter().GetResult()
$oldStamp = $targetUser.SecurityStamp

$stampUpdateRes = $mgrStamp.UpdateSecurityStampAsync($targetUser.Id).GetAwaiter().GetResult()
$newStamp = (Query-SqlScalar "SELECT SecurityStamp FROM dbo.AspNetUsers WHERE Id = '$($targetUser.Id)'")

Check "Seguridad 5.4.1: SecurityStamp regenerado exitosamente en base de datos" `
    ($stampUpdateRes.Succeeded -and $newStamp -ne $oldStamp) `
    "Anterior: $oldStamp -> Nuevo: $newStamp"

# ------------------------------------------------------------------------------
# 5.5 Rutina de Provisión Controlada del Primer Administrador (D-10 / RF-52 / RF-53)
# ------------------------------------------------------------------------------
Write-Host "`n--- 5.5 Rutina de Provisión del Primer Administrador (RF-52 / RF-53) ---" -ForegroundColor DarkCyan

$provisionScript = Join-Path $baseDir "tools\Provision-Administrator.ps1"

# 5.5.1: Cuando ya existe un administrador activo, cualquier intento de provisión debe ser rechazado (RF-53)
$alreadyHasAdminResult = & powershell -ExecutionPolicy Bypass -File $provisionScript -TargetEmail "joamedina2@upt.pe" -ConnectionString $connStringTrial -Force 2>&1
$alreadyHasAdminOutput = $alreadyHasAdminResult -join "`n"

Check "Provisión 5.5.1 (RF-53): Provisión rechazada porque ya existe un administrador activo en el sistema" `
    ($alreadyHasAdminOutput.Contains("RF-53") -or $alreadyHasAdminOutput.Contains("Ya existe al menos un Administrador")) `
    "Bloqueo verificado: $alreadyHasAdminOutput"

# 5.5.2: Simular escenario de bootstrap inicial (0 administradores en el sistema)
Execute-SqlNonQuery "DELETE FROM dbo.AspNetUserRoles WHERE RoleId = '$adminRole';" | Out-Null

$zeroAdmins = [int](Query-SqlScalar @"
SELECT COUNT(*) 
FROM dbo.AspNetUsers u 
INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId 
WHERE ur.RoleId = '$adminRole' AND u.IsEnabled = 1;
"@)

Check "Provisión 5.5.2: Escenario bootstrap inicial preparado con 0 administradores" `
    ($zeroAdmins -eq 0) `
    "Administradores existentes: $zeroAdmins"

# 5.5.3: Ejecutar provisión del PRIMER administrador (RF-52)
$bootstrapResult = & powershell -ExecutionPolicy Bypass -File $provisionScript -TargetEmail "joamedina@upt.pe" -ConnectionString $connStringTrial -Force 2>&1
$bootstrapOutput = $bootstrapResult -join "`n"

$hasAdminNow = [int](Query-SqlScalar @"
SELECT COUNT(*) 
FROM dbo.AspNetUsers u 
INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId 
WHERE ur.RoleId = '$adminRole' AND u.Email = 'joamedina@upt.pe';
"@)

Check "Provisión 5.5.3 (RF-52): Primer Administrador creado exitosamente mediante rutina controlada" `
    ($hasAdminNow -eq 1 -and ($bootstrapOutput.Contains("aprovisionado exitosamente") -or $bootstrapOutput.Contains("ÉXITO") -or $bootstrapOutput.Contains("EXITO"))) `
    "Primer Administrador aprovisionado: joamedina@upt.pe"

# 5.5.4: Intento subsiguiente de usar la rutina debe ser rechazado inmediatamente (RF-53)
$subsequentResult = & powershell -ExecutionPolicy Bypass -File $provisionScript -TargetEmail "joamedina2@upt.pe" -ConnectionString $connStringTrial -Force 2>&1
$subsequentOutput = $subsequentResult -join "`n"

Check "Provisión 5.5.4 (RF-53): Promoción subsiguiente bloqueada; el módulo web /Admin/Users debe usarse para roles ordinarios" `
    ($subsequentOutput.Contains("RF-53") -or $subsequentOutput.Contains("Ya existe al menos un Administrador")) `
    "Rechazo subsiguiente verificado"

# ------------------------------------------------------------------------------
# 5.6 Prueba del Script SQL de Provisión Manual (H05_manual_admin_provisioning.sql)
# ------------------------------------------------------------------------------
Write-Host "`n--- 5.6 Ejecución del Script SQL H05_manual_admin_provisioning.sql en Base Aislada ---" -ForegroundColor DarkCyan

$sqlScriptPath = Join-Path $baseDir "Migrations\Scripts\H05_manual_admin_provisioning.sql"
$sqlContent = [System.IO.File]::ReadAllText($sqlScriptPath)

# Modificar en memoria para probar con target email sobre la base de ensayo
$testSql = $sqlContent.Replace("DECLARE @TargetEmail NVARCHAR(256) = N'';", "DECLARE @TargetEmail NVARCHAR(256) = N'joamedina2@upt.pe';")

# Como ya existe un administrador en EcomixIA_Trial, la ejecución debe capturar el RAISERROR de RF-53 limpiamente
$sqlCmdTest = @"
USE [EcomixIA_Trial];
$testSql
"@

$sqlExecOutput = & sqlcmd -S "(LocalDb)\MSSQLLocalDB" -Q $sqlCmdTest 2>&1
$sqlExecText = $sqlExecOutput -join "`n"

Check "Provisión SQL 5.6.1: Script SQL H05_manual_admin_provisioning.sql valida RF-53 y ejecuta bloque TRY/CATCH sin errores de sintaxis" `
    ($sqlExecText.Contains("RF-53") -or $sqlExecText.Contains("Ya existe al menos un Administrador")) `
    "Respuesta SQL Server: $sqlExecText"

Write-Host "`nRESUMEN SUITE 05: $suitePassed PASS / $suiteFailed FAIL" -ForegroundColor $(if ($suiteFailed -eq 0) { "Green" } else { "Red" })
return ($suiteFailed -eq 0)
