# ==============================================================================
# EcoMix IA — Suite 05: Pruebas de Seguridad y Concurrencia
# ==============================================================================

. (Join-Path $PSScriptRoot "Test_Helpers.ps1")

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  SUITE 05: PRUEBAS DE SEGURIDAD Y CONCURRENCIA" -ForegroundColor Cyan
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
# 5.1 Protección Concurrente del Último Administrador (H05-A2 / D-10)
# ------------------------------------------------------------------------------
Write-Host "`n--- 5.1 Protección Concurrente del Último Administrador (H05-A2) ---" -ForegroundColor DarkCyan

# Asegurar que solo hay exactamente UN administrador activo en EcomixIA_Trial
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

Check "Concurrencia 5.1.2: El último administrador no pudo ser degradado ni deshabilitado concurrentemente" `
    ($finalActiveAdmins -eq 1) `
    "Administradores activos tras ataque concurrente: $finalActiveAdmins"

# Verificar que los mensajes de advertencia de AdminController protegieron la integridad
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
# 5.2 Ráfaga Masiva sobre Limitador de Solicitudes (RF-36)
# ------------------------------------------------------------------------------
Write-Host "`n--- 5.2 Ráfaga Masiva de Solicitudes sobre RateLimiter (RF-36) ---" -ForegroundColor DarkCyan

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

Check "RateLimiter 5.2.1: Ráfaga de 25 solicitudes permite exactamente el umbral (5)" `
    ($allowedCount -eq 5) `
    "Permitidos: $allowedCount"

Check "RateLimiter 5.2.2: Solicitudes excedentes (20) estrictamente bloqueadas" `
    ($blockedCount -eq 20 -and $retry.TotalSeconds -gt 0) `
    "Bloqueados: $blockedCount, RetryAfter: $($retry.TotalSeconds)s"

# ------------------------------------------------------------------------------
# 5.3 Invalidación de Sesión mediante SecurityStamp
# ------------------------------------------------------------------------------
Write-Host "`n--- 5.3 Invalidación de Sesión mediante SecurityStamp ---" -ForegroundColor DarkCyan

$dbStamp = New-Object EcomixIA.Models.ApplicationDbContext ($connStringTrial)
$storeStamp = New-Object Microsoft.AspNet.Identity.EntityFramework.UserStore[EcomixIA.Models.ApplicationUser] ($dbStamp)
$mgrStamp = New-Object EcomixIA.ApplicationUserManager ($storeStamp)

$targetUser = $mgrStamp.FindByEmailAsync("joamedina@upt.pe").GetAwaiter().GetResult()
$oldStamp = $targetUser.SecurityStamp

$stampUpdateRes = $mgrStamp.UpdateSecurityStampAsync($targetUser.Id).GetAwaiter().GetResult()
$newStamp = (Query-SqlScalar "SELECT SecurityStamp FROM dbo.AspNetUsers WHERE Id = '$($targetUser.Id)'")

Check "Seguridad 5.3.1: SecurityStamp regenerado exitosamente en base de datos" `
    ($stampUpdateRes.Succeeded -and $newStamp -ne $oldStamp) `
    "Anterior: $oldStamp -> Nuevo: $newStamp"

# ------------------------------------------------------------------------------
# 5.4 Rutina de Provisión Manual de Administrador (H05-A1 / D-10)
# ------------------------------------------------------------------------------
Write-Host "`n--- 5.4 Script Independiente de Provisión Manual (tools/Provision-Administrator.ps1) ---" -ForegroundColor DarkCyan

$provisionScript = Join-Path $baseDir "tools\Provision-Administrator.ps1"

# Probar precondición: correo inexistente debe ser rechazado
$fakeResult = & powershell -ExecutionPolicy Bypass -File $provisionScript -TargetEmail "noexiste@upt.pe" -ConnectionString $connStringTrial -Force 2>&1
$fakeOutput = $fakeResult -join "`n"

Check "Provisión 5.4.1: Correo inexistente rechazado por precondiciones" `
    ($fakeOutput.Contains("Precondición fallida") -or $fakeOutput.Contains("no se encontró") -or $fakeOutput.Contains("WriteError")) `
    "Resultado: Usuario inexistente bloqueado"

# Probar provisión exitosa sobre usuario confirmado existente (joamedina2@upt.pe)
$provSuccessResult = & powershell -ExecutionPolicy Bypass -File $provisionScript -TargetEmail "joamedina2@upt.pe" -ConnectionString $connStringTrial -Force 2>&1
$provSuccessOutput = $provSuccessResult -join "`n"

$hasAdminRoleNow = [int](Query-SqlScalar @"
SELECT COUNT(*) 
FROM dbo.AspNetUsers u 
INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId 
WHERE ur.RoleId = '$adminRole' AND u.Email = 'joamedina2@upt.pe';
"@)

Check "Provisión 5.4.2: joamedina2@upt.pe promovido exitosamente a Administrador con evidencia" `
    ($hasAdminRoleNow -eq 1 -and ($provSuccessOutput.Contains("promovido exitosamente") -or $provSuccessOutput.Contains("EXITO"))) `
    "Rol Administrador asignado"

# Revertir a joamedina2@upt.pe al estado original (Registrado) para mantener el estado de la base
Execute-SqlNonQuery @"
DELETE FROM dbo.AspNetUserRoles 
WHERE RoleId = '$adminRole' AND UserId = (SELECT Id FROM dbo.AspNetUsers WHERE Email = 'joamedina2@upt.pe');
"@ | Out-Null

$hasAdminRoleReverted = [int](Query-SqlScalar @"
SELECT COUNT(*) 
FROM dbo.AspNetUsers u 
INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId 
WHERE ur.RoleId = '$adminRole' AND u.Email = 'joamedina2@upt.pe';
"@)

Check "Provisión 5.4.3: Reversión y aislamiento de prueba completados" `
    ($hasAdminRoleReverted -eq 0) `
    "joamedina2@upt.pe restablecido a estado base"

Write-Host "`nRESUMEN SUITE 05: $suitePassed PASS / $suiteFailed FAIL" -ForegroundColor $(if ($suiteFailed -eq 0) { "Green" } else { "Red" })
return ($suiteFailed -eq 0)
