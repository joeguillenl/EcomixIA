# -*- coding: utf-8 -*-
# ==============================================================================
# ECOMIX IA — RUTINA INDEPENDIENTE DE PROVISIÓN DEL PRIMER ADMINISTRADOR (D-10 / RF-52 / RF-53)
# Provisión controlada y auditable del primer Administrador (Bootstrap inicial)
# - Protegido contra concurrencia multi-proceso mediante sp_getapplock.
# - Bloquea si existe algún administrador (activo o deshabilitado).
# - Protección persistente contra reejecución histórica en AuditEvents.
# - Soporta recuperación administrativa de emergencia autorizada (-AllowRecovery).
# ==============================================================================
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Correo electrónico del usuario que será promovido como primer Administrador.")]
    [string]$TargetEmail,

    [Parameter(Mandatory = $false, HelpMessage = "Cadena de conexión a la base de datos SQL Server.")]
    [string]$ConnectionString,

    [Parameter(Mandatory = $false, HelpMessage = "Confirmación explícita para ejecución no interactiva o en CI/CD.")]
    [switch]$Force,

    [Parameter(Mandatory = $false, HelpMessage = "Habilita la recuperación administrativa de emergencia expresamente autorizada.")]
    [switch]$AllowRecovery
)

$ErrorActionPreference = "Stop"

# Resolver cadena de conexión si no fue provista
if ([string]::IsNullOrWhiteSpace($ConnectionString)) {
    $targetDb = if (![string]::IsNullOrWhiteSpace($env:TARGET_DATABASE)) { $env:TARGET_DATABASE.Trim() } else { "EcomixIA" }
    $ConnectionString = "Server=(LocalDb)\MSSQLLocalDB;Database=$targetDb;Integrated Security=True"
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  ECOMIX IA — PROVISIÓN CONTROLADA DEL PRIMER ADMINISTRADOR (D-10 / RF-52 / RF-53)" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

# 1. Validación de parámetros y autorización explícita
if ([string]::IsNullOrWhiteSpace($TargetEmail)) {
    Write-Error "El correo del usuario destino es obligatorio."
    exit 1
}

$normalizedEmail = $TargetEmail.Trim().ToLowerInvariant()

if (!$Force) {
    $actionType = if ($AllowRecovery) { "RECUPERACIÓN DE EMERGENCIA" } else { "PROVISIÓN INICIAL (BOOTSTRAP)" }
    Write-Host "`nADVERTENCIA: Esta operación ejecutará una $actionType para otorgar privilegios de Administrador al usuario: $normalizedEmail" -ForegroundColor Yellow
    $confirm = Read-Host "¿Confirma que desea proceder con la operación? (Escriba 'CONFIRMAR' para continuar)"
    if ($confirm -ne "CONFIRMAR") {
        Write-Host "Operación cancelada por el operador. No se aplicaron cambios." -ForegroundColor Yellow
        exit 0
    }
}

# 2. Conectar e iniciar transacción protegida con sp_getapplock
$conn = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
$conn.Open()

$tx = $conn.BeginTransaction("AdminBootstrapTx")
$cmd = $conn.CreateCommand()
$cmd.Transaction = $tx

try {
    # 2.1 Adquirir bloqueo exclusivo de aplicación
    $cmd.CommandText = @"
DECLARE @res INT;
EXEC @res = sp_getapplock @Resource = 'EcoMix_Admin_Bootstrap_Lock', @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
SELECT @res;
"@
    $lockRes = [int]$cmd.ExecuteScalar()
    if ($lockRes -lt 0) {
        throw "No se pudo adquirir el bloqueo exclusivo de aplicación (sp_getapplock timeout: $lockRes). Concurrencia excedida."
    }

    # 2.2 Verificar existencia del rol Administrador
    $cmd.CommandText = "SELECT TOP 1 [Id] FROM [dbo].[AspNetRoles] WHERE [Name] = 'Administrador'"
    $roleId = $cmd.ExecuteScalar()

    if ($null -eq $roleId) {
        throw "Precondición fallida: El rol 'Administrador' no existe en AspNetRoles. Aplique primero el esquema base de Identity."
    }

    # 2.3 Verificar si ya existe algún administrador asignado (incluso si está inhabilitado)
    $cmd.CommandText = "SELECT COUNT(1) FROM [dbo].[AspNetUserRoles] WHERE [RoleId] = @adminRoleId"
    $cmd.Parameters.Clear()
    $cmd.Parameters.AddWithValue("@adminRoleId", $roleId) | Out-Null
    $existingAdminAnyCount = [int]$cmd.ExecuteScalar()

    if ($existingAdminAnyCount -gt 0) {
        throw "Precondición fallida (RF-53): Ya existe al menos un usuario con rol Administrador asignado en el sistema ($existingAdminAnyCount encontrado(s)), activo o inhabilitado. La rutina D-10/RF-52 es exclusiva para el bootstrap inicial. Cualquier asignación de rol posterior debe realizarse exclusivamente a través del módulo web de Administración (/Admin/Users) por un administrador autenticado."
    }

    # 2.4 Protección persistente contra reejecución de bootstrap tras retiro de roles
    $cmd.CommandText = "SELECT COUNT(1) FROM [dbo].[AuditEvents] WHERE [Action] IN ('ManualAdminProvisioning', 'AdminEmergencyRecovery') AND [Success] = 1"
    $historicalBootstrapCount = [int]$cmd.ExecuteScalar()

    if ($historicalBootstrapCount -gt 0 -and !$AllowRecovery) {
        throw "Precondición fallida (RF-53): El bootstrap inicial ya fue ejecutado históricamente en esta base ($historicalBootstrapCount registro(s) previo(s)). No está permitido repetir el bootstrap eliminando roles. Para restauraciones administrativas autorizadas utilice el parámetro explícito -AllowRecovery."
    }

    # 2.5 Verificar existencia, estado de confirmación y habilitación del usuario
    $cmd.CommandText = "SELECT TOP 1 [Id], [EmailConfirmed], [IsEnabled] FROM [dbo].[AspNetUsers] WHERE LOWER([Email]) = @email"
    $cmd.Parameters.Clear()
    $cmd.Parameters.AddWithValue("@email", $normalizedEmail) | Out-Null

    $reader = $cmd.ExecuteReader()
    if (!$reader.Read()) {
        $reader.Close()
        throw "Precondición fallida: No se encontró ningún usuario registrado con el correo '$normalizedEmail'."
    }

    $userId = $reader["Id"].ToString()
    $emailConfirmed = [bool]$reader["EmailConfirmed"]
    $isEnabled = [bool]$reader["IsEnabled"]
    $reader.Close()

    if (!$emailConfirmed) {
        throw "Precondición fallida: La cuenta '$normalizedEmail' no ha confirmado su correo electrónico (EmailConfirmed = 0). No se permite aprovisionar administradores no confirmados."
    }

    if (!$isEnabled) {
        throw "Precondición fallida: La cuenta '$normalizedEmail' se encuentra inhabilitada (IsEnabled = 0). No se permite aprovisionar administradores deshabilitados."
    }

    # 2.6 Asignar rol Administrador
    $cmd.CommandText = "INSERT INTO [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES (@uId, @rId)"
    $cmd.Parameters.Clear()
    $cmd.Parameters.AddWithValue("@uId", $userId) | Out-Null
    $cmd.Parameters.AddWithValue("@rId", $roleId) | Out-Null
    $cmd.ExecuteNonQuery() | Out-Null

    # 2.7 Actualizar SecurityStamp para revalidar sesiones
    $newSecurityStamp = [Guid]::NewGuid().ToString()
    $cmd.CommandText = "UPDATE [dbo].[AspNetUsers] SET [SecurityStamp] = @secStamp WHERE [Id] = @uId"
    $cmd.Parameters.Clear()
    $cmd.Parameters.AddWithValue("@secStamp", $newSecurityStamp) | Out-Null
    $cmd.Parameters.AddWithValue("@uId", $userId) | Out-Null
    $cmd.ExecuteNonQuery() | Out-Null

    # 2.8 Registrar evidencia de auditoría estructurada (D-07 / RF-52)
    $actionName = if ($AllowRecovery) { "AdminEmergencyRecovery" } else { "ManualAdminProvisioning" }
    $auditDetails = if ($AllowRecovery) {
        "Recuperación administrativa de emergencia autorizada (-AllowRecovery). Operador: $($env:USERNAME)@$($env:COMPUTERNAME)."
    } else {
        "Provisión controlada del primer Administrador (D-10/RF-52). Operador: $($env:USERNAME)@$($env:COMPUTERNAME)."
    }

    $cmd.CommandText = @"
INSERT INTO [dbo].[AuditEvents] 
([UserId], [ActorEmail], [Category], [Action], [Success], [Details], [IpAddress], [TimestampUtc])
VALUES 
(@uId, @email, 'Admin', @action, 1, @details, '127.0.0.1', SYSUTCDATETIME())
"@
    $cmd.Parameters.Clear()
    $cmd.Parameters.AddWithValue("@uId", $userId) | Out-Null
    $cmd.Parameters.AddWithValue("@email", $normalizedEmail) | Out-Null
    $cmd.Parameters.AddWithValue("@action", $actionName) | Out-Null
    $cmd.Parameters.AddWithValue("@details", $auditDetails) | Out-Null
    $cmd.ExecuteNonQuery() | Out-Null

    $tx.Commit()

    Write-Host "`n [ÉXITO] Usuario '$normalizedEmail' aprovisionado exitosamente como 'Administrador' (Acción: $actionName)." -ForegroundColor Green
    Write-Host "         - Bloqueo exclusivo sp_getapplock adquirido y liberado." -ForegroundColor Gray
    Write-Host "         - Rol asignado en AspNetUserRoles." -ForegroundColor Gray
    Write-Host "         - SecurityStamp actualizado para forzar revalidación de credenciales." -ForegroundColor Gray
    Write-Host "         - Evento estructurado registrado en tabla AuditEvents." -ForegroundColor Gray
}
catch {
    if ($tx -ne $null -and $tx.Connection -ne $null) {
        $tx.Rollback()
    }
    Write-Error "Error durante la transacción de provisión: $_"
    exit 1
}
finally {
    $conn.Close()
}
