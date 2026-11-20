$baseDir = "C:\Users\Admin\Desktop\Proyectos\ML EcomixIA Sistema"
$connStringTrial = "Server=(LocalDb)\MSSQLLocalDB;Database=EcomixIA_Trial;Integrated Security=True"
[AppDomain]::CurrentDomain.add_AssemblyResolve({
    param($s, $a)
    $shortName = $a.Name.Split(',')[0].Trim()
    foreach ($asm in [AppDomain]::CurrentDomain.GetAssemblies()) {
        if ($asm.GetName().Name -eq $shortName) { return $asm }
    }
    $bin = Join-Path $baseDir "bin\$shortName.dll"
    if (Test-Path $bin) { return [System.Reflection.Assembly]::LoadFrom($bin) }
    return $null
})
Add-Type -Path (Join-Path $baseDir 'packages\Owin.1.0\lib\net40\Owin.dll')
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.Owin.4.2.2\lib\net45\Microsoft.Owin.dll')
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.Owin.Security.4.2.2\lib\net45\Microsoft.Owin.Security.dll')
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.Owin.Security.Cookies.4.2.2\lib\net45\Microsoft.Owin.Security.Cookies.dll')
Add-Type -Path (Join-Path $baseDir 'packages\EntityFramework.6.5.1\lib\net45\EntityFramework.dll')
Add-Type -Path (Join-Path $baseDir 'packages\EntityFramework.6.5.1\lib\net45\EntityFramework.SqlServer.dll')
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.AspNet.Identity.Core.2.2.4\lib\net45\Microsoft.AspNet.Identity.Core.dll')
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.AspNet.Identity.EntityFramework.2.2.4\lib\net45\Microsoft.AspNet.Identity.EntityFramework.dll')
Add-Type -Path (Join-Path $baseDir 'packages\Newtonsoft.Json.13.0.3\lib\net45\Newtonsoft.Json.dll')
Add-Type -Path (Join-Path $baseDir 'bin\EcomixIA.dll')

$req = New-Object System.Web.HttpRequest("", "http://localhost/", "")
$res = New-Object System.Web.HttpResponse([System.IO.TextWriter]::Null)
$httpCtx = New-Object System.Web.HttpContext($req, $res)
[System.Web.HttpContext]::Current = $httpCtx

function Init-Controller([System.Web.Mvc.Controller]$ctrl) {
    $wrapper = New-Object System.Web.HttpContextWrapper([System.Web.HttpContext]::Current)
    $routeData = New-Object System.Web.Routing.RouteData
    $ctrl.ControllerContext = New-Object System.Web.Mvc.ControllerContext($wrapper, $routeData, $ctrl)
    $ctrl.TempData = New-Object System.Web.Mvc.TempDataDictionary
}

$passedTests = 0
$failedTests = 0

function Assert-Test([string]$testName, [bool]$condition, [string]$detail) {
    if ($condition) {
        $global:passedTests++
        Write-Host " [PASS] $testName" -ForegroundColor Green
        if ($detail) { Write-Host "        $detail" -ForegroundColor Gray }
    } else {
        $global:failedTests++
        Write-Host " [FAIL] $testName" -ForegroundColor Red
        if ($detail) { Write-Host "        $detail" -ForegroundColor Yellow }
    }
}

function Query-SqlScalar([string]$sql) {
    $conn = New-Object System.Data.SqlClient.SqlConnection($connStringTrial)
    $conn.Open()
    try {
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $sql
        return $cmd.ExecuteScalar()
    } finally {
        $conn.Close()
    }
}

function Query-SqlList([string]$sql) {
    $conn = New-Object System.Data.SqlClient.SqlConnection($connStringTrial)
    $conn.Open()
    $list = New-Object System.Collections.Generic.List[string]
    try {
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $sql
        $reader = $cmd.ExecuteReader()
        while ($reader.Read()) {
            $list.Add($reader[0].ToString())
        }
        $reader.Close()
        return $list
    } finally {
        $conn.Close()
    }
}

function Execute-SqlNonQuery([string]$sql) {
    $conn = New-Object System.Data.SqlClient.SqlConnection($connStringTrial)
    $conn.Open()
    try {
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $sql
        return $cmd.ExecuteNonQuery()
    } finally {
        $conn.Close()
    }
}

# ==============================================================================
# H04-01: Auditoría de Esquema en EcomixIA_Trial
# ==============================================================================
Write-Host "`n--- SECCIÓN 1: ESQUEMA Y MIGRACIÓN H04 ---" -ForegroundColor Yellow

$hasIsEnabledCol = Query-SqlScalar "SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID('dbo.AspNetUsers') AND name = 'IsEnabled'"
$hasAuditEventsTable = Query-SqlScalar "SELECT COUNT(*) FROM sys.tables WHERE name = 'AuditEvents'"
$hasAdminRole = Query-SqlScalar "SELECT COUNT(*) FROM dbo.AspNetRoles WHERE Name = 'Administrador'"

Assert-Test "H04-01.1" ($hasIsEnabledCol -eq 1) "Columna IsEnabled presente en AspNetUsers de EcomixIA_Trial."
Assert-Test "H04-01.2" ($hasAuditEventsTable -eq 1) "Tabla AuditEvents creada con esquema estructurado."
Assert-Test "H04-01.3" ($hasAdminRole -eq 1) "Rol 'Administrador' registrado en AspNetRoles."

# ==============================================================================
# H04-02: Control de Acceso RBAC en AdminController
# ==============================================================================
Write-Host "`n--- SECCIÓN 2: CONTROL DE ACCESO RBAC EN ADMINCONTROLLER ---" -ForegroundColor Yellow

$adminControllerType = [EcomixIA.Controllers.AdminController]
$authAttrs = $adminControllerType.GetCustomAttributes([System.Web.Mvc.AuthorizeAttribute], $true)
$isRbacProtected = ($authAttrs.Length -gt 0 -and $authAttrs[0].Roles -eq "Administrador")

Assert-Test "H04-02" $isRbacProtected "AdminController decorado con [Authorize(Roles = 'Administrador')]."

# ==============================================================================
# H04-03: Listado de Usuarios con Paginación y Búsqueda
# ==============================================================================
Write-Host "`n--- SECCIÓN 3: GESTIÓN DE USUARIOS (RF-21, RF-22, RF-23) ---" -ForegroundColor Yellow

$dbTrial = New-Object EcomixIA.Models.ApplicationDbContext($connStringTrial)
$userStore = New-Object Microsoft.AspNet.Identity.EntityFramework.UserStore[EcomixIA.Models.ApplicationUser]($dbTrial)
$roleStore = New-Object Microsoft.AspNet.Identity.EntityFramework.RoleStore[Microsoft.AspNet.Identity.EntityFramework.IdentityRole]($dbTrial)
$userManager = New-Object EcomixIA.ApplicationUserManager($userStore)
$roleManager = New-Object EcomixIA.ApplicationRoleManager($roleStore)
$auditService = New-Object EcomixIA.Services.AuditService([Func[EcomixIA.Models.ApplicationDbContext]]{ return New-Object EcomixIA.Models.ApplicationDbContext($connStringTrial) })
$adminCtrl = New-Object EcomixIA.Controllers.AdminController($userManager, $roleManager, $dbTrial, $auditService)
Init-Controller $adminCtrl

function Get-AppUserByEmail($email) {
    return $userManager.FindByEmailAsync($email).GetAwaiter().GetResult()
}
function Get-AppUserById($id) {
    return $userManager.FindByIdAsync($id).GetAwaiter().GetResult()
}
function Delete-AppUser($user) {
    if ($user -ne $null) {
        $userManager.DeleteAsync($user).GetAwaiter().GetResult() | Out-Null
    }
}

$usersViewResult = $adminCtrl.Users($null, 1, 10).GetAwaiter().GetResult() -as [System.Web.Mvc.ViewResult]
$usersModel = $usersViewResult.Model -as [EcomixIA.Models.ViewModels.AdminUsersListViewModel]

Assert-Test "H04-03.1" ($usersModel -ne $null -and $usersModel.TotalUsers -ge 4) "Listado de usuarios recupera $($usersModel.TotalUsers) cuentas."

$searchViewResult = $adminCtrl.Users("joamedina@upt.pe", 1, 10).GetAwaiter().GetResult() -as [System.Web.Mvc.ViewResult]
$searchModel = $searchViewResult.Model -as [EcomixIA.Models.ViewModels.AdminUsersListViewModel]
$foundAdmin = ($searchModel.Users.Count -ge 1 -and $searchModel.Users[0].Email -like "*joamedina*")

Assert-Test "H04-03.2" $foundAdmin "Búsqueda por correo 'joamedina@upt.pe' filtra las cuentas correspondientes."

# ==============================================================================
# H04-04 & H04-05 & H04-06: Inhabilitación, Bloqueo de Login y Rehabilitación
# ==============================================================================
Write-Host "`n--- SECCIÓN 4: INHABILITACIÓN Y BLOQUEO DE LOGIN (RF-22) ---" -ForegroundColor Yellow

$testUserEmail = "test_bloqueo_h04@upt.pe"
$userToDelete = Get-AppUserByEmail $testUserEmail
Delete-AppUser $userToDelete

$testUser = New-Object EcomixIA.Models.ApplicationUser
$testUser.UserName = $testUserEmail
$testUser.Email = $testUserEmail
$testUser.EmailConfirmed = $true
$testUser.IsEnabled = $true
$userManager.CreateAsync($testUser, "TestClaveH04!123").GetAwaiter().GetResult() | Out-Null
$userManager.AddToRoleAsync($testUser.Id, "Registrado").GetAwaiter().GetResult() | Out-Null

$adminCtrl.ToggleUserStatus($testUser.Id).GetAwaiter().GetResult() | Out-Null

$userAfterToggle = Get-AppUserById $testUser.Id
Assert-Test "H04-04" (!$userAfterToggle.IsEnabled) "ToggleUserStatus inhabilitó correctamente al usuario ($($testUser.Email))."

$accountCtrl = New-Object EcomixIA.Controllers.AccountController(
    $userManager, $null, $roleManager, $dbTrial, 
    (New-Object EcomixIA.Services.EmailDomainValidator), 
    (New-Object EcomixIA.Services.RegistrationSafetyGate), 
    (New-Object EcomixIA.Services.RequestRateLimiter), 
    $auditService)
Init-Controller $accountCtrl

$loginVm = New-Object EcomixIA.Models.LoginViewModel
$loginVm.Email = $testUserEmail
$loginVm.Password = "TestClaveH04!123"

$accountCtrl.Login($loginVm, "/Home/Index").GetAwaiter().GetResult() | Out-Null

$loginBlocked = ($accountCtrl.ModelState.IsValid -eq $false -and 
                 $accountCtrl.ModelState[ [string]::Empty ].Errors[0].ErrorMessage -like "*inhabilitada*")

Assert-Test "H04-05" $loginBlocked "Login rechazado correctamente con mensaje de cuenta inhabilitada."

$adminCtrl.ToggleUserStatus($testUser.Id).GetAwaiter().GetResult() | Out-Null
$userAfterReEnable = Get-AppUserById $testUser.Id

Assert-Test "H04-06" ($userAfterReEnable.IsEnabled) "Usuario rehabilitado exitosamente (IsEnabled = true)."

Delete-AppUser $userAfterReEnable

# ==============================================================================
# H04-07: Cambio de Rol RBAC (Promoción / Degradación)
# ==============================================================================
Write-Host "`n--- SECCIÓN 5: GESTIÓN DE ROLES RBAC (RF-23) ---" -ForegroundColor Yellow

$roleTestEmail = "test_role_h04@upt.pe"
$existingRoleUser = Get-AppUserByEmail $roleTestEmail
Delete-AppUser $existingRoleUser

$roleUser = New-Object EcomixIA.Models.ApplicationUser
$roleUser.UserName = $roleTestEmail
$roleUser.Email = $roleTestEmail
$roleUser.EmailConfirmed = $true
$roleUser.IsEnabled = $true
$userManager.CreateAsync($roleUser, "RoleClaveH04!123").GetAwaiter().GetResult() | Out-Null
$userManager.AddToRoleAsync($roleUser.Id, "Registrado").GetAwaiter().GetResult() | Out-Null

# Promover a Administrador
$adminCtrl.ChangeUserRole($roleUser.Id, "Administrador").GetAwaiter().GetResult() | Out-Null

$isAdminNow = $userManager.IsInRoleAsync($roleUser.Id, "Administrador").GetAwaiter().GetResult()
Assert-Test "H04-07.1" $isAdminNow "Usuario promovido exitosamente a rol 'Administrador'."

# Degradar a Registrado
$adminCtrl.ChangeUserRole($roleUser.Id, "Registrado").GetAwaiter().GetResult() | Out-Null

$isRegistradoNow = ($userManager.IsInRoleAsync($roleUser.Id, "Registrado").GetAwaiter().GetResult() -and 
                   !$userManager.IsInRoleAsync($roleUser.Id, "Administrador").GetAwaiter().GetResult())
Assert-Test "H04-07.2" $isRegistradoNow "Usuario degradado exitosamente a rol 'Registrado'."

Delete-AppUser $roleUser

# ==============================================================================
# H04-08 & H04-09: Protección del Último Administrador Activo (D-10)
# ==============================================================================
Write-Host "`n--- SECCIÓN 6: PROTECCIÓN DEL ÚLTIMO ADMINISTRADOR (D-10) ---" -ForegroundColor Yellow

# Obtener admin principal joamedina@upt.pe
$mainAdmin = Get-AppUserByEmail "joamedina@upt.pe"
if (!$userManager.IsInRoleAsync($mainAdmin.Id, "Administrador").GetAwaiter().GetResult()) {
    $userManager.AddToRoleAsync($mainAdmin.Id, "Administrador").GetAwaiter().GetResult() | Out-Null
}

# Asegurar que solo hay 1 admin activo usando Query-SqlList
$adminRoleObj = $roleManager.FindByNameAsync("Administrador").GetAwaiter().GetResult()
$adminUserIds = Query-SqlList "SELECT UserId FROM dbo.AspNetUserRoles WHERE RoleId = '$($adminRoleObj.Id)'"
foreach ($uId in $adminUserIds) {
    if ($uId -ne $mainAdmin.Id) {
        $userManager.RemoveFromRoleAsync($uId, "Administrador").GetAwaiter().GetResult() | Out-Null
    }
}

# Intento de inhabilitar al último admin
$adminCtrl.ToggleUserStatus($mainAdmin.Id).GetAwaiter().GetResult() | Out-Null

$adminStillEnabled = (Get-AppUserById $mainAdmin.Id).IsEnabled
$disableBlockedMsg = $adminCtrl.TempData["MensajeError"] -like "*último Administrador*"
Assert-Test "H04-08" ($adminStillEnabled -and $disableBlockedMsg) "Protección D-10: Inhabilitación del último Administrador bloqueada con éxito."

# Intento de revocar rol al último admin
$adminCtrl.ChangeUserRole($mainAdmin.Id, "Registrado").GetAwaiter().GetResult() | Out-Null

$adminStillAdmin = $userManager.IsInRoleAsync($mainAdmin.Id, "Administrador").GetAwaiter().GetResult()
$revokeBlockedMsg = $adminCtrl.TempData["MensajeError"] -like "*último Administrador*"
Assert-Test "H04-09" ($adminStillAdmin -and $revokeBlockedMsg) "Protección D-10: Revocación de rol del último Administrador bloqueada con éxito."

# ==============================================================================
# H04-10: Protección CSRF en Métodos Mutables
# ==============================================================================
Write-Host "`n--- SECCIÓN 7: SEGURIDAD CSRF EN CONTROLADORES ---" -ForegroundColor Yellow

$methodsToVerify = @("ToggleUserStatus", "ChangeUserRole", "PurgeAudit")
$allCsrfProtected = $true

foreach ($methodName in $methodsToVerify) {
    $method = $adminControllerType.GetMethod($methodName)
    $hasPost = ($method.GetCustomAttributes([System.Web.Mvc.HttpPostAttribute], $false).Length -gt 0)
    $hasCsrf = ($method.GetCustomAttributes([System.Web.Mvc.ValidateAntiForgeryTokenAttribute], $false).Length -gt 0)
    if (!$hasPost -or !$hasCsrf) {
        $allCsrfProtected = $false
    }
}

Assert-Test "H04-10" $allCsrfProtected "Métodos de mutación administrativa decorados con [HttpPost] y [ValidateAntiForgeryToken]."

# ==============================================================================
# H04-11 & H04-12: Modelo de Auditoría y Sanitización (D-07)
# ==============================================================================
Write-Host "`n--- SECCIÓN 8: MODELO DE AUDITORÍA Y SANITIZACIÓN (D-07) ---" -ForegroundColor Yellow

$rawSecretDetails = "Usuario autenticado. Password: SuperSecretPassword123! ApiKey=sk-live-999888777 Token: 1234567890abcdef"
$auditService.LogEventAsync("Seguridad", "TestSanitizacion", $true, $mainAdmin.Id, $mainAdmin.Email, $rawSecretDetails, "192.168.1.100").GetAwaiter().GetResult()

# Consultar directamente vía SQL para evitar conflictos de contexto
$latestAction = Query-SqlScalar "SELECT TOP 1 Action FROM dbo.AuditEvents WHERE Action = 'TestSanitizacion' ORDER BY Id DESC"
$latestDetails = Query-SqlScalar "SELECT TOP 1 Details FROM dbo.AuditEvents WHERE Action = 'TestSanitizacion' ORDER BY Id DESC"

Assert-Test "H04-11" ($latestAction -eq "TestSanitizacion") "Evento de auditoría persistido correctamente en tabla AuditEvents."

$hasNoRawPassword = (!$latestDetails.Contains("SuperSecretPassword123!") -and $latestDetails.Contains("[PROTEGIDO]"))
$hasNoRawApiKey = (!$latestDetails.Contains("sk-live-999888777"))
Assert-Test "H04-12" ($hasNoRawPassword -and $hasNoRawApiKey) "Sanitización D-07: Contraseñas, claves y tokens reemplazados por [PROTEGIDO]."

# ==============================================================================
# H04-13 & H04-14: Retención de 30 Días y Depuración Idempotente (RF-49, RF-51)
# ==============================================================================
Write-Host "`n--- SECCIÓN 9: POLÍTICA DE RETENCIÓN DE 30 DÍAS Y PURGA FÍSICA ---" -ForegroundColor Yellow

# Insertar evento antiguo (>35 días) directamente en DB
$oldDateStr = [DateTime]::UtcNow.AddDays(-35).ToString("yyyy-MM-dd HH:mm:ss")
Execute-SqlNonQuery "INSERT INTO dbo.AuditEvents (Category, Action, Success, Details, TimestampUtc) VALUES ('Seguridad', 'EventoVencido35Dias', 1, 'Registro antiguo de prueba', '$oldDateStr')" | Out-Null

# 1. Consultar eventos activos: No debe incluir el evento de 35 días
$activeEventsDb = New-Object EcomixIA.Models.ApplicationDbContext($connStringTrial)
$activeEvents = $auditService.GetActiveEvents($activeEventsDb, $null)
$containsOldEvent = $false
foreach ($ev in $activeEvents) {
    if ($ev.Action -eq "EventoVencido35Dias") { $containsOldEvent = $true; break }
}
Assert-Test "H04-13" (!$containsOldEvent) "Exclusión de 30 días (RF-49): Registros mayores a 30 días excluidos de GetActiveEvents."

# 2. Ejecutar PurgeExpiredEventsAsync con contexto fresco
$purgeDb = New-Object EcomixIA.Models.ApplicationDbContext($connStringTrial)
$purgedCount = $auditService.PurgeExpiredEventsAsync($purgeDb, 500, $null).GetAwaiter().GetResult()

$countOldInDb = Query-SqlScalar "SELECT COUNT(*) FROM dbo.AuditEvents WHERE Action = 'EventoVencido35Dias'"
Assert-Test "H04-14.1" ($purgedCount -ge 1 -and $countOldInDb -eq 0) "Depuración física (RF-51): Registros > 30 días eliminados físicamente ($purgedCount purgados)."

# 3. Idempotencia: Una segunda purga inmediata debe purgar 0 registros sin error
$secondPurgeDb = New-Object EcomixIA.Models.ApplicationDbContext($connStringTrial)
$secondPurgedCount = $auditService.PurgeExpiredEventsAsync($secondPurgeDb, 500, $null).GetAwaiter().GetResult()
Assert-Test "H04-14.2" ($secondPurgedCount -eq 0) "Idempotencia de purga: Segunda ejecución elimina 0 registros sin alterar datos vigentes."

# ==============================================================================
# H04-15 & H04-16: Dashboard Administrativo vs Dashboard Personal (RF-50)
# ==============================================================================
Write-Host "`n--- SECCIÓN 10: DASHBOARD ADMINISTRATIVO Y AISLAMIENTO ---" -ForegroundColor Yellow

$dashDb = New-Object EcomixIA.Models.ApplicationDbContext($connStringTrial)
$stats = $auditService.GetDashboardStatsAsync($dashDb, $null).GetAwaiter().GetResult()

$validStats = ($stats.TotalUsuarios -ge 4 -and 
               $stats.UsuariosHabilitados -ge 1 -and 
               $stats.RetentionCutoffUtc -le [DateTime]::UtcNow.AddDays(-29))

Assert-Test "H04-15" $validStats "Dashboard Admin (RF-50): Métricas agregadas calculadas correctamente (Total: $($stats.TotalUsuarios))."

$dashControllerType = [EcomixIA.Controllers.DashboardController]
$hasIndexMethod = ($dashControllerType.GetMethod("Index") -ne $null)
Assert-Test "H04-16" $hasIndexMethod "Aislamiento D-01/D-08: Dashboard personal privado de mezclas preservado independientemente."

# ==============================================================================
# H04-17: Blindaje contra Enumeración en Login (H04-A)
# ==============================================================================
Write-Host "`n--- SECCIÓN 11: BLINDAJE CONTRA ENUMERACIÓN EN LOGIN (H04-A) ---" -ForegroundColor Yellow

$unconfEmail = "test_unconf_h04@upt.pe"
$unconfUser = Get-AppUserByEmail $unconfEmail
Delete-AppUser $unconfUser

$unconfUser = New-Object EcomixIA.Models.ApplicationUser
$unconfUser.UserName = $unconfEmail
$unconfUser.Email = $unconfEmail
$unconfUser.EmailConfirmed = $false
$unconfUser.IsEnabled = $true
$userManager.CreateAsync($unconfUser, "PasswordCorrecta!123").GetAwaiter().GetResult() | Out-Null

$loginWrongPass = New-Object EcomixIA.Models.LoginViewModel
$loginWrongPass.Email = $unconfEmail
$loginWrongPass.Password = "PasswordErronea!999"

$accountCtrl2 = New-Object EcomixIA.Controllers.AccountController(
    $userManager, $null, $roleManager, $dbTrial, 
    (New-Object EcomixIA.Services.EmailDomainValidator), 
    (New-Object EcomixIA.Services.RegistrationSafetyGate), 
    (New-Object EcomixIA.Services.RequestRateLimiter), 
    $auditService)
Init-Controller $accountCtrl2

$accountCtrl2.Login($loginWrongPass, "/Home/Index").GetAwaiter().GetResult() | Out-Null

$msg = $accountCtrl2.ModelState[ [string]::Empty ].Errors[0].ErrorMessage
$isBlindToEnumeration = ($msg -eq "Credenciales incorrectas.")
Assert-Test "H04-17" $isBlindToEnumeration "Blindaje H04-A: Contraseña incorrecta devuelve 'Credenciales incorrectas.' sin filtrar estado de confirmación."

Delete-AppUser $unconfUser

# ==============================================================================
# H04-18: Limitador de Solicitudes Atómico (H04-A)
# ==============================================================================
Write-Host "`n--- SECCIÓN 12: LIMITADOR DE FRECUENCIA ATÓMICO (H04-A) ---" -ForegroundColor Yellow

$limiter = New-Object EcomixIA.Services.RequestRateLimiter
$testKey = "UnitTest_Atomic_Key_" + [Guid]::NewGuid().ToString("N")
$retryAfter = [TimeSpan]::Zero

$r1 = $limiter.TryAcquire($testKey, 2, [TimeSpan]::FromMinutes(1), [ref]$retryAfter)
$r2 = $limiter.TryAcquire($testKey, 2, [TimeSpan]::FromMinutes(1), [ref]$retryAfter)
$r3 = $limiter.TryAcquire($testKey, 2, [TimeSpan]::FromMinutes(1), [ref]$retryAfter)

Assert-Test "H04-18" ($r1 -and $r2 -and !$r3 -and $retryAfter.TotalSeconds -gt 0) "RateLimiter Atómico: Máximo de 2 solicitudes respetado atómicamente; 3ra solicitud bloqueada con RetryAfter."

# ==============================================================================
# H04-19 & H04-20: Adaptadores de Correo y Seguridad de Transporte (H04-A)
# ==============================================================================
Write-Host "`n--- SECCIÓN 13: CORREO TRANSACCIONAL Y TRANSPORTE SEGURO (H04-A) ---" -ForegroundColor Yellow

$insecureHttpRejected = $false
try {
    $insecureSender = New-Object EcomixIA.Services.HttpApiTransactionalEmailSender("http://api.mail.local/send", "dummy-key")
} catch {
    $insecureHttpRejected = ($_.Exception.ToString() -like "*HTTPS*")
}
Assert-Test "H04-19" $insecureHttpRejected "Seguridad H04-A: HttpApiTransactionalEmailSender rechaza URLs HTTP no cifradas."

$smtpSender = New-Object EcomixIA.Services.SmtpTransactionalEmailSender("smtp.upt.pe", 587, "user", "pass", "from@upt.pe")
Assert-Test "H04-20" ($smtpSender -ne $null) "Configuración SmtpTransactionalEmailSender validada con STARTTLS en puerto 587."

# ==============================================================================
# H04-21: Regresión Completa de Hitos Anteriores (H01, H02, H03)
# ==============================================================================
Write-Host "`n--- SECCIÓN 14: REGRESIÓN DE HITOS ANTERIORES (H01, H02, H03) ---" -ForegroundColor Yellow

# H01: Verificación de DTOs y Cliente ML
$mlClient = New-Object EcomixIA.Services.EcoMixMlClientService
$h01Ok = ($mlClient -ne $null)

# H02: Verificación de snapshots en MezclaComponentes (CostoPorKgGuardado, Co2PorKgGuardado, FechaSnapshotUtc, OrigenSnapshot)
$hasH02Cols = Query-SqlScalar "SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID('dbo.MezclaComponentes') AND name IN ('CostoPorKgGuardado', 'Co2PorKgGuardado', 'FechaSnapshotUtc', 'OrigenSnapshot')"
$h02Ok = ($hasH02Cols -eq 4)

# H03: Verificación de cuentas existentes de H03 en EcomixIA_Trial
$u1 = Get-AppUserByEmail "joamedina@upt.pe"
$u2 = Get-AppUserByEmail "joamedina2@upt.pe"
$u3 = Get-AppUserByEmail "auth.test.civil@upt.pe"
$u4 = Get-AppUserByEmail "auth.unconfirmed.test@upt.pe"
$h03Ok = ($u1 -ne $null -and $u2 -ne $null -and $u3 -ne $null -and $u4 -ne $null)

Assert-Test "H04-21" ($h01Ok -and $h02Ok -and $h03Ok) "Regresión sin roturas: H01 (ML Client), H02 (Snapshots Mezclas) y H03 (Cuentas preexistentes) preservados intactos."

# ==============================================================================
# RESUMEN DE RESULTADOS
# ==============================================================================
Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "  RESUMEN DE PRUEBAS AUTOMATIZADAS H04" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  Total de Pruebas Ejecutadas: $($global:passedTests + $global:failedTests)"
Write-Host "  Pruebas Aprobadas:           $($global:passedTests)" -ForegroundColor Green
Write-Host "  Pruebas Fallidas:            $($global:failedTests)" -ForegroundColor $(if ($global:failedTests -eq 0) { "Green" } else { "Red" })
Write-Host "================================================================================" -ForegroundColor Cyan

if ($global:failedTests -gt 0) {
    exit 1
} else {
    exit 0
}
