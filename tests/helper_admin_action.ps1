param(
    [Parameter(Mandatory=$true)][string]$Action,
    [Parameter(Mandatory=$true)][string]$UserId
)

. (Join-Path $PSScriptRoot "Test_Helpers.ps1")

$db = New-Object EcomixIA.Models.ApplicationDbContext ($connStringTrial)
$store = New-Object Microsoft.AspNet.Identity.EntityFramework.UserStore[EcomixIA.Models.ApplicationUser] ($db)
$mgr = New-Object EcomixIA.ApplicationUserManager ($store)
$roleStore = New-Object Microsoft.AspNet.Identity.EntityFramework.RoleStore[Microsoft.AspNet.Identity.EntityFramework.IdentityRole] ($db)
$roleMgr = New-Object EcomixIA.ApplicationRoleManager ($roleStore)
$aud = New-Object EcomixIA.Services.AuditService ($connStringTrial)

$ctrl = New-Object EcomixIA.Controllers.AdminController ($mgr, $roleMgr, $db, $aud)
Init-Controller $ctrl

try {
    if ($Action -eq "Toggle") {
        $res = $ctrl.ToggleUserStatus($UserId).GetAwaiter().GetResult()
    } elseif ($Action -eq "Role") {
        $res = $ctrl.ChangeUserRole($UserId, "Registrado").GetAwaiter().GetResult()
    }
} catch {
    # Errores controlados de concurrencia esperados
} finally {
    $db.Dispose()
}
