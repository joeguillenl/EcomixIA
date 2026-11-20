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

$sqlInitial = "SELECT COUNT(*) FROM dbo.AspNetUsers u INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId WHERE ur.RoleId = '$adminRole' AND u.IsEnabled = 1;"
$initialActiveAdmins = [int](Query-SqlScalar $sqlInitial)

Check "Concurrencia 5.1.1: Base de prueba inicializada con exactamente 1 administrador activo" ($initialActiveAdmins -eq 1) "Administradores activos iniciales: $initialActiveAdmins"

# Lanzar múltiples procesos concurrentes para degradar o deshabilitar al único administrador
$actionScript = Join-Path $PSScriptRoot "helper_admin_action.ps1"

$p1 = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$actionScript`" -Action Toggle -UserId `"$mainAdminUser`" -TargetDatabase `"$targetDbName`"" -PassThru -WindowStyle Hidden
$p2 = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$actionScript`" -Action Role -UserId `"$mainAdminUser`" -TargetDatabase `"$targetDbName`"" -PassThru -WindowStyle Hidden
$p3 = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$actionScript`" -Action Toggle -UserId `"$mainAdminUser`" -TargetDatabase `"$targetDbName`"" -PassThru -WindowStyle Hidden
$p4 = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$actionScript`" -Action Role -UserId `"$mainAdminUser`" -TargetDatabase `"$targetDbName`"" -PassThru -WindowStyle Hidden

$p1.WaitForExit(10000) | Out-Null
$p2.WaitForExit(10000) | Out-Null
$p3.WaitForExit(10000) | Out-Null
$p4.WaitForExit(10000) | Out-Null

$sqlFinal = "SELECT COUNT(*) FROM dbo.AspNetUsers u INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId WHERE ur.RoleId = '$adminRole' AND u.IsEnabled = 1;"
$finalActiveAdmins = [int](Query-SqlScalar $sqlFinal)

Check "Concurrencia 5.1.2: El único administrador no pudo ser degradado ni deshabilitado concurrentemente" ($finalActiveAdmins -eq 1) "Administradores activos tras ataque concurrente: $finalActiveAdmins"

$sqlLastAdminAudit = "SELECT TOP 1 Details FROM dbo.AuditEvents WHERE Action IN ('BlockDemoteLastAdmin', 'BlockDisableLastAdmin') ORDER BY TimestampUtc DESC;"
$lastAdminProtectedEvent = Query-SqlScalar $sqlLastAdminAudit

Check "Concurrencia 5.1.3: Evento de auditoría de rechazo del último administrador registrado" ($lastAdminProtectedEvent -ne $null -and $lastAdminProtectedEvent.Contains("último Administrador")) "Evento registrado: $lastAdminProtectedEvent"

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

$sqlTwo = "SELECT COUNT(*) FROM dbo.AspNetUsers u INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId WHERE ur.RoleId = '$adminRole' AND u.IsEnabled = 1;"
$twoAdminsCount = [int](Query-SqlScalar $sqlTwo)

Check "Concurrencia 5.2.1: Base de prueba inicializada con exactamente 2 administradores activos" ($twoAdminsCount -eq 2) "Administradores activos: $twoAdminsCount"

# Ejecutar degradación simultánea de ambos administradores
$pA = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$actionScript`" -Action Role -UserId `"$mainAdminUser`" -TargetDatabase `"$targetDbName`"" -PassThru -WindowStyle Hidden
$pB = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$actionScript`" -Action Role -UserId `"$admin2Id`" -TargetDatabase `"$targetDbName`"" -PassThru -WindowStyle Hidden

$pA.WaitForExit(10000) | Out-Null
$pB.WaitForExit(10000) | Out-Null

$sqlRem = "SELECT COUNT(*) FROM dbo.AspNetUsers u INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId WHERE ur.RoleId = '$adminRole' AND u.IsEnabled = 1;"
$remainingAdminsCount = [int](Query-SqlScalar $sqlRem)

Check "Concurrencia 5.2.2: Concurrencia entre 2 administradores arbitra atómicamente dejando exactamente 1 admin activo" ($remainingAdminsCount -eq 1) "Administradores activos resultantes: $remainingAdminsCount"

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

Check "RateLimiter 5.3.1: Ráfaga de 25 solicitudes permite exactamente el umbral (5)" ($allowedCount -eq 5) "Permitidos: $allowedCount"
Check "RateLimiter 5.3.2: Solicitudes excedentes (20) estrictamente bloqueadas" ($blockedCount -eq 20 -and $retry.TotalSeconds -gt 0) "Bloqueados: $blockedCount, RetryAfter: $($retry.TotalSeconds)s"

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

Check "Seguridad 5.4.1: SecurityStamp regenerado exitosamente en base de datos" ($stampUpdateRes.Succeeded -and $newStamp -ne $oldStamp) "Anterior: $oldStamp -> Nuevo: $newStamp"

# ------------------------------------------------------------------------------
# 5.5 Provisión Robusta con Exclusión Mutua sp_getapplock y Protección Persistente
# ------------------------------------------------------------------------------
Write-Host "`n--- 5.5 Provisión Controlada (sp_getapplock, Admin Deshabilitado y Concurrencia) ---" -ForegroundColor DarkCyan

$provisionScript = Join-Path $baseDir "tools\Provision-Administrator.ps1"

# 5.5.1: Rechazo si el administrador existente se encuentra DESHABILITADO
Execute-SqlNonQuery "UPDATE dbo.AspNetUsers SET IsEnabled = 0 WHERE Email = 'joamedina@upt.pe';" | Out-Null
$disabledAdminResult = & powershell -ExecutionPolicy Bypass -File $provisionScript -TargetEmail "joamedina2@upt.pe" -ConnectionString $connStringTrial -Force 2>&1
$disabledAdminOutput = $disabledAdminResult -join "`n"
Execute-SqlNonQuery "UPDATE dbo.AspNetUsers SET IsEnabled = 1 WHERE Email = 'joamedina@upt.pe';" | Out-Null

Check "Provisión 5.5.1 (RF-53): Provisión rechazada aunque el administrador existente esté deshabilitado" ($disabledAdminOutput.Contains("activo o inhabilitado") -or $disabledAdminOutput.Contains("RF-53")) "Bloqueo verificado: Administrador asignado inhabilitado impide bootstrap"

# 5.5.2: Limpiar administradores e historial previo para simular sistema completamente nuevo (bootstrap puro)
Execute-SqlNonQuery "DELETE FROM dbo.AspNetUserRoles WHERE RoleId = '$adminRole';" | Out-Null
Execute-SqlNonQuery "DELETE FROM dbo.AuditEvents WHERE Action IN ('ManualAdminProvisioning', 'AdminEmergencyRecovery');" | Out-Null

$zeroAdmins = [int](Query-SqlScalar "SELECT COUNT(1) FROM dbo.AspNetUserRoles WHERE RoleId = '$adminRole';")
Check "Provisión 5.5.2: Escenario limpio de bootstrap preparado (0 admins asignados, 0 registros históricos)" ($zeroAdmins -eq 0) "Administradores: $zeroAdmins"

# 5.5.3: Dos ejecuciones concurrentes desde cero con sp_getapplock: exactamente una debe tener éxito
$outP1 = Join-Path $PSScriptRoot "prov_concurr_1.log"
$outP2 = Join-Path $PSScriptRoot "prov_concurr_2.log"

$cmdP1 = "powershell -ExecutionPolicy Bypass -File `"$provisionScript`" -TargetEmail `"joamedina@upt.pe`" -ConnectionString `"$connStringTrial`" -Force > `"$outP1`" 2>&1"
$cmdP2 = "powershell -ExecutionPolicy Bypass -File `"$provisionScript`" -TargetEmail `"joamedina2@upt.pe`" -ConnectionString `"$connStringTrial`" -Force > `"$outP2`" 2>&1"

$proc1 = Start-Process cmd.exe -ArgumentList "/c $cmdP1" -PassThru -WindowStyle Hidden
$proc2 = Start-Process cmd.exe -ArgumentList "/c $cmdP2" -PassThru -WindowStyle Hidden

$proc1.WaitForExit(15000) | Out-Null
$proc2.WaitForExit(15000) | Out-Null

$txt1 = if (Test-Path $outP1) { Get-Content $outP1 -Raw } else { "" }
$txt2 = if (Test-Path $outP2) { Get-Content $outP2 -Raw } else { "" }
Remove-Item $outP1, $outP2 -Force -ErrorAction SilentlyContinue

$adminsAfterConcurrent = [int](Query-SqlScalar "SELECT COUNT(1) FROM dbo.AspNetUserRoles WHERE RoleId = '$adminRole';")
$oneSucceeded = ($txt1.Contains("aprovisionado exitosamente") -or $txt1.Contains("ÉXITO")) -xor ($txt2.Contains("aprovisionado exitosamente") -or $txt2.Contains("ÉXITO"))

Check "Provisión 5.5.3 (sp_getapplock): Exactamente una ejecución concurrente aprovisionó al primer Administrador" ($adminsAfterConcurrent -eq 1 -and $oneSucceeded) "Admins resultantes en DB: $adminsAfterConcurrent. Exclusión mutua sp_getapplock verificada"

# 5.5.4: Protección persistente: si se retiran los roles pero existe historial, repetir bootstrap falla sin -AllowRecovery
Execute-SqlNonQuery "DELETE FROM dbo.AspNetUserRoles WHERE RoleId = '$adminRole';" | Out-Null

$blockedReplayResult = & powershell -ExecutionPolicy Bypass -File $provisionScript -TargetEmail "joamedina@upt.pe" -ConnectionString $connStringTrial -Force 2>&1
$blockedReplayOutput = $blockedReplayResult -join "`n"

Check "Provisión 5.5.4 (RF-53 Persistente): Repetición de bootstrap rechazada por historial previo tras retiro de roles" ($blockedReplayOutput.Contains("históricamente") -or $blockedReplayOutput.Contains("AllowRecovery")) "Bloqueo persistente confirmado: $blockedReplayOutput"

# 5.5.5: Procedimiento de recuperación administrativa de emergencia (-AllowRecovery)
$recoveryResult = & powershell -ExecutionPolicy Bypass -File $provisionScript -TargetEmail "joamedina@upt.pe" -ConnectionString $connStringTrial -Force -AllowRecovery 2>&1
$recoveryOutput = $recoveryResult -join "`n"

$sqlRecEvent = "SELECT TOP 1 Action FROM dbo.AuditEvents WHERE Action = 'AdminEmergencyRecovery' ORDER BY TimestampUtc DESC;"
$recoveryEvent = Query-SqlScalar $sqlRecEvent
$adminsAfterRecovery = [int](Query-SqlScalar "SELECT COUNT(1) FROM dbo.AspNetUserRoles WHERE RoleId = '$adminRole';")

Check "Provisión 5.5.5: Procedimiento de recuperación administrativa (-AllowRecovery) exitoso y auditado" ($adminsAfterRecovery -eq 1 -and $recoveryEvent -eq "AdminEmergencyRecovery") "Administrador recuperado y auditado como AdminEmergencyRecovery"

# ------------------------------------------------------------------------------
# 5.6 Prueba del Script SQL de Provisión Manual (H05_manual_admin_provisioning.sql)
# ------------------------------------------------------------------------------
Write-Host "`n--- 5.6 Ejecución del Script SQL H05_manual_admin_provisioning.sql en Base Aislada ---" -ForegroundColor DarkCyan

$sqlScriptPath = Join-Path $baseDir "Migrations\Scripts\H05_manual_admin_provisioning.sql"
$sqlContent = [System.IO.File]::ReadAllText($sqlScriptPath)

# Modificar en memoria para probar con target email sobre la base de ensayo
$testSql = $sqlContent.Replace("DECLARE @TargetEmail NVARCHAR(256) = N'';", "DECLARE @TargetEmail NVARCHAR(256) = N'joamedina2@upt.pe';")

# Como ya existe un administrador en la base aislada, la ejecución debe capturar el RAISERROR de RF-53 limpiamente
$sqlCmdTest = "USE [$targetDbName]; $testSql"

$sqlExecOutput = & sqlcmd -S "(LocalDb)\MSSQLLocalDB" -Q $sqlCmdTest 2>&1
$sqlExecText = $sqlExecOutput -join "`n"

Check "Provisión SQL 5.6.1: Script SQL valida RF-53, adquiere sp_getapplock y ejecuta bloque TRY/CATCH sin errores de sintaxis" ($sqlExecText.Contains("RF-53") -or $sqlExecText.Contains("Ya existe al menos un usuario con rol Administrador")) "Respuesta SQL Server: $sqlExecText"

Write-Host "`nRESUMEN SUITE 05: $suitePassed PASS / $suiteFailed FAIL" -ForegroundColor $(if ($suiteFailed -eq 0) { "Green" } else { "Red" })
return ($suiteFailed -eq 0)
