# ==============================================================================
# EcoMix IA — Suite 03: Pruebas de Integración HTTP y Autorización
# ==============================================================================

. (Join-Path $PSScriptRoot "Test_Helpers.ps1")

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  SUITE 03: PRUEBAS DE INTEGRACIÓN HTTP Y AUTORIZACIÓN" -ForegroundColor Cyan
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
# 3.1 Verificación de Política D-02 en MaterialesController
# ------------------------------------------------------------------------------
Write-Host "`n--- 3.1 Política D-02: Acceso Privado al Catálogo de Materiales ---" -ForegroundColor DarkCyan

$matType = [type]"EcomixIA.Controllers.MaterialesController"
$classAuthorizeAttr = $matType.GetCustomAttributes([System.Web.Mvc.AuthorizeAttribute], $true)
$indexMethod = $matType.GetMethod("Index", [type]::EmptyTypes)
$detailsMethod = $matType.GetMethod("Details", [type[]]@([type][System.Nullable[int]]))

$indexAllowAnon = $indexMethod.GetCustomAttributes([System.Web.Mvc.AllowAnonymousAttribute], $true)
$detailsAllowAnon = $detailsMethod.GetCustomAttributes([System.Web.Mvc.AllowAnonymousAttribute], $true)

Check "D-02 3.1.1: MaterialesController protegido con atributo [Authorize] a nivel de clase" `
    ($classAuthorizeAttr -ne $null -and $classAuthorizeAttr.Length -ge 1) `
    "Atributo Authorize presente en clase"

Check "D-02 3.1.2: Index no permite acceso anónimo (AllowAnonymous removido)" `
    ($indexAllowAnon -eq $null -or $indexAllowAnon.Length -eq 0) `
    "Index estrictamente protegido"

Check "D-02 3.1.3: Details no permite acceso anónimo (AllowAnonymous removido)" `
    ($detailsAllowAnon -eq $null -or $detailsAllowAnon.Length -eq 0) `
    "Details estrictamente protegido"

# ------------------------------------------------------------------------------
# 3.2 RBAC en MaterialesController (Solo Administrador puede mutar)
# ------------------------------------------------------------------------------
Write-Host "`n--- 3.2 RBAC en MaterialesController (Mutación Exclusiva de Admin) ---" -ForegroundColor DarkCyan

$userStore = New-Object Microsoft.AspNet.Identity.EntityFramework.UserStore[EcomixIA.Models.ApplicationUser] (New-Object EcomixIA.Models.ApplicationDbContext ($connStringTrial))
$userManager = New-Object EcomixIA.ApplicationUserManager ($userStore)

# Simular usuario registrado no-admin (joamedina2@upt.pe)
$regUser = $userManager.FindByEmailAsync("joamedina2@upt.pe").GetAwaiter().GetResult()
$claimsIdentity = $userManager.CreateIdentityAsync($regUser, "ApplicationCookie").GetAwaiter().GetResult()
$claimsPrincipal = New-Object System.Security.Claims.ClaimsPrincipal ($claimsIdentity)

$matCtrl = New-Object EcomixIA.Controllers.MaterialesController (New-Object EcomixIA.Models.EcomixContext ($connStringTrial))
Init-Controller $matCtrl
$matCtrl.ControllerContext.HttpContext.User = $claimsPrincipal

$createResultNonAdmin = $matCtrl.Create() -as [System.Web.Mvc.HttpStatusCodeResult]

Check "RBAC 3.2.1: Usuario Registrado rechazado con HTTP 403 al intentar Crear material" `
    ($createResultNonAdmin -ne $null -and $createResultNonAdmin.StatusCode -eq 403) `
    "StatusCode: $($createResultNonAdmin.StatusCode) - $($createResultNonAdmin.StatusDescription)"

# Simular Administrador (joamedina@upt.pe)
$adminUser = $userManager.FindByEmailAsync("joamedina@upt.pe").GetAwaiter().GetResult()
$adminIdentity = $userManager.CreateIdentityAsync($adminUser, "ApplicationCookie").GetAwaiter().GetResult()
$adminPrincipal = New-Object System.Security.Claims.ClaimsPrincipal ($adminIdentity)

$matCtrlAdmin = New-Object EcomixIA.Controllers.MaterialesController (New-Object EcomixIA.Models.EcomixContext ($connStringTrial))
Init-Controller $matCtrlAdmin
$matCtrlAdmin.ControllerContext.HttpContext.User = $adminPrincipal

$createResultAdmin = $matCtrlAdmin.Create() -as [System.Web.Mvc.ViewResult]

Check "RBAC 3.2.2: Administrador autorizado para acceder al formulario Crear material" `
    ($createResultAdmin -ne $null) `
    "ViewResult devuelto correctamente para Administrador"

# ------------------------------------------------------------------------------
# 3.3 RBAC en AdminController
# ------------------------------------------------------------------------------
Write-Host "`n--- 3.3 Control de Acceso en AdminController ---" -ForegroundColor DarkCyan

$adminCtrlType = [type]"EcomixIA.Controllers.AdminController"
$adminAuthorizeAttr = $adminCtrlType.GetCustomAttributes([System.Web.Mvc.AuthorizeAttribute], $true)
$requiredRoles = ""
if ($adminAuthorizeAttr.Length -gt 0) {
    $requiredRoles = ($adminAuthorizeAttr[0] -as [System.Web.Mvc.AuthorizeAttribute]).Roles
}

Check "RBAC 3.3.1: AdminController restringido exclusivamente al rol 'Administrador'" `
    ($requiredRoles -eq "Administrador") `
    "Roles requeridos: $requiredRoles"

# ------------------------------------------------------------------------------
# 3.4 Filtro de Revocación de Cuenta Deshabilitada (H05-A3)
# ------------------------------------------------------------------------------
Write-Host "`n--- 3.4 AuthorizeUserEnabledFilter (Revocación Inmediata de Sesión) ---" -ForegroundColor DarkCyan

$testUserEmail = "auth.test.civil@upt.pe"
# Deshabilitar temporalmente en DB antes de instanciar el contexto
Execute-SqlNonQuery "UPDATE dbo.AspNetUsers SET IsEnabled = 0 WHERE Email = '$testUserEmail';" | Out-Null

$dbFilter = New-Object EcomixIA.Models.ApplicationDbContext ($connStringTrial)
$storeFilter = New-Object Microsoft.AspNet.Identity.EntityFramework.UserStore[EcomixIA.Models.ApplicationUser] ($dbFilter)
$mgrFilter = New-Object EcomixIA.ApplicationUserManager ($storeFilter)

$disabledUser = $mgrFilter.FindByEmailAsync($testUserEmail).GetAwaiter().GetResult()
$disabledIdentity = $mgrFilter.CreateIdentityAsync($disabledUser, "ApplicationCookie").GetAwaiter().GetResult()
$disabledPrincipal = New-Object System.Security.Claims.ClaimsPrincipal ($disabledIdentity)

$filter = New-Object EcomixIA.Services.AuthorizeUserEnabledFilter ([Func[EcomixIA.ApplicationUserManager]]{ return $mgrFilter })

$mezclasCtrl = New-Object EcomixIA.Controllers.MezclasController
Init-Controller $mezclasCtrl
$mezclasCtrl.ControllerContext.HttpContext.User = $disabledPrincipal

$actDesc = New-Object System.Web.Mvc.ReflectedActionDescriptor (
    $mezclasCtrl.GetType().GetMethod("Index", [type]::EmptyTypes),
    "Index",
    (New-Object System.Web.Mvc.ReflectedControllerDescriptor ($mezclasCtrl.GetType()))
)

$authContext = New-Object System.Web.Mvc.AuthorizationContext ($mezclasCtrl.ControllerContext, $actDesc)

$filter.OnAuthorization($authContext)
$redirectResult = $authContext.Result -as [System.Web.Mvc.RedirectResult]

# Restaurar estado habilitado inmediatamente
Execute-SqlNonQuery "UPDATE dbo.AspNetUsers SET IsEnabled = 1 WHERE Email = '$testUserEmail';" | Out-Null
$dbFilter.Dispose()

Check "H05-A3 3.4.1: Cuenta inhabilitada interceptada y redirigida a /Account/Login?disabled=1" `
    ($redirectResult -ne $null -and $redirectResult.Url -like "*Login?disabled=1*") `
    "Redirección efectiva: $($redirectResult.Url)"

# ------------------------------------------------------------------------------
# 3.5 Bloqueo de Cuentas No Confirmadas (D-03 / RF-04)
# ------------------------------------------------------------------------------
Write-Host "`n--- 3.5 Restricción de Acceso para Cuentas No Confirmadas ---" -ForegroundColor DarkCyan

$unconfirmedUser = $userManager.FindByEmailAsync("auth.unconfirmed.test@upt.pe").GetAwaiter().GetResult()

Check "D-03 3.5.1: Cuenta de prueba no confirmada existe en estado EmailConfirmed = 0" `
    ($unconfirmedUser -ne $null -and $unconfirmedUser.EmailConfirmed -eq $false) `
    "auth.unconfirmed.test@upt.pe (EmailConfirmed: $($unconfirmedUser.EmailConfirmed))"

Write-Host "`nRESUMEN SUITE 03: $suitePassed PASS / $suiteFailed FAIL" -ForegroundColor $(if ($suiteFailed -eq 0) { "Green" } else { "Red" })
return ($suiteFailed -eq 0)
