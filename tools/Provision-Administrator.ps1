# -*- coding: utf-8 -*-
# ==============================================================================
# ECOMIX IA — RUTINA INDEPENDIENTE DE PROVISIÓN DEL PRIMER ADMINISTRADOR (D-10 / RF-52 / RF-53)
# Provisión controlada y auditable del primer Administrador (Bootstrap inicial)
# Si ya existe al menos un administrador activo, la rutina se aborta (RF-53)
# Las promociones posteriores se efectúan exclusivamente en el módulo web /Admin/Users
# ==============================================================================
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Correo electrónico del usuario que será promovido como primer Administrador.")]
    [string]$TargetEmail,

    [Parameter(Mandatory = $false, HelpMessage = "Cadena de conexión a la base de datos SQL Server.")]
    [string]$ConnectionString = "Server=(LocalDb)\MSSQLLocalDB;Database=EcomixIA;Integrated Security=True",

    [Parameter(Mandatory = $false, HelpMessage = "Confirmación explícita para ejecución no interactiva o en CI/CD.")]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

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
    Write-Host "`nADVERTENCIA: Esta operación otorgará privilegios máximos de Administrador inicial al usuario: $normalizedEmail" -ForegroundColor Yellow
    $confirm = Read-Host "¿Confirma que desea proceder con la provisión del primer administrador? (Escriba 'CONFIRMAR' para continuar)"
    if ($confirm -ne "CONFIRMAR") {
        Write-Host "Operación cancelada por el operador. No se aplicaron cambios." -ForegroundColor Yellow
        exit 0
    }
}

# 2. Conectar y validar precondiciones en base de datos
$conn = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
$conn.Open()

try {
    # 2.1 Verificar existencia del rol Administrador
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT TOP 1 [Id] FROM [dbo].[AspNetRoles] WHERE [Name] = 'Administrador'"
    $roleId = $cmd.ExecuteScalar()

    if ($null -eq $roleId) {
        Write-Error "Precondición fallida: El rol 'Administrador' no existe en AspNetRoles. Aplique primero el esquema base de Identity."
        exit 1
    }

    # 2.2 Verificar existencia de administradores activos previos (RF-52 / RF-53)
    $cmd.CommandText = @"
SELECT COUNT(1) 
FROM [dbo].[AspNetUserRoles] ur
INNER JOIN [dbo].[AspNetUsers] u ON ur.[UserId] = u.[Id]
WHERE ur.[RoleId] = @adminRoleId AND u.[IsEnabled] = 1
"@
    $cmd.Parameters.Clear()
    $cmd.Parameters.AddWithValue("@adminRoleId", $roleId) | Out-Null
    $existingAdminCount = [int]$cmd.ExecuteScalar()

    if ($existingAdminCount -gt 0) {
        Write-Error "Precondición fallida (RF-53): Ya existe al menos un Administrador activo en el sistema ($existingAdminCount encontrado(s)). La rutina D-10/RF-52 es exclusiva para la inicialización del primer Administrador (bootstrap inicial). Cualquier cambio o asignación posterior de roles debe realizarse exclusivamente a través del módulo web de Administración (/Admin/Users) por un administrador autenticado."
        exit 1
    }

    # 2.3 Verificar existencia, estado de confirmación y habilitación del usuario
    $cmd.CommandText = "SELECT TOP 1 [Id], [EmailConfirmed], [IsEnabled] FROM [dbo].[AspNetUsers] WHERE LOWER([Email]) = @email"
    $cmd.Parameters.Clear()
    $cmd.Parameters.AddWithValue("@email", $normalizedEmail) | Out-Null

    $reader = $cmd.ExecuteReader()
    if (!$reader.Read()) {
        $reader.Close()
        Write-Error "Precondición fallida: No se encontró ningún usuario registrado con el correo '$normalizedEmail'."
        exit 1
    }

    $userId = $reader["Id"].ToString()
    $emailConfirmed = [bool]$reader["EmailConfirmed"]
    $isEnabled = [bool]$reader["IsEnabled"]
    $reader.Close()

    if (!$emailConfirmed) {
        Write-Error "Precondición fallida: La cuenta '$normalizedEmail' no ha confirmado su correo electrónico (EmailConfirmed = 0). No se permite aprovisionar administradores no confirmados."
        exit 1
    }

    if (!$isEnabled) {
        Write-Error "Precondición fallida: La cuenta '$normalizedEmail' se encuentra inhabilitada (IsEnabled = 0). No se permite aprovisionar administradores deshabilitados."
        exit 1
    }

    # 2.4 Verificar si ya posee el rol
    $cmd.CommandText = "SELECT COUNT(*) FROM [dbo].[AspNetUserRoles] WHERE [UserId] = @uId AND [RoleId] = @rId"
    $cmd.Parameters.Clear()
    $cmd.Parameters.AddWithValue("@uId", $userId) | Out-Null
    $cmd.Parameters.AddWithValue("@rId", $roleId) | Out-Null
    $alreadyAdmin = [int]$cmd.ExecuteScalar()

    if ($alreadyAdmin -gt 0) {
        Write-Host "`nEl usuario '$normalizedEmail' ya posee el rol 'Administrador'. No se requieren modificaciones." -ForegroundColor Green
        exit 0
    }

    # 3. Transacción atómica de provisión y actualización de SecurityStamp
    $tx = $conn.BeginTransaction("AdminProvisioningTx")
    $cmd.Transaction = $tx

    try {
        # 3.1 Asignar rol Administrador
        $cmd.CommandText = "INSERT INTO [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES (@uId, @rId)"
        $cmd.ExecuteNonQuery() | Out-Null

        # 3.2 Actualizar SecurityStamp para revalidar sesiones
        $newSecurityStamp = [Guid]::NewGuid().ToString()
        $cmd.CommandText = "UPDATE [dbo].[AspNetUsers] SET [SecurityStamp] = @secStamp WHERE [Id] = @uId"
        $cmd.Parameters.Clear()
        $cmd.Parameters.AddWithValue("@secStamp", $newSecurityStamp) | Out-Null
        $cmd.Parameters.AddWithValue("@uId", $userId) | Out-Null
        $cmd.ExecuteNonQuery() | Out-Null

        # 3.3 Registrar evidencia de auditoría no sensible (D-07 / RF-52)
        $auditDetails = "Provisión controlada del primer Administrador (D-10/RF-52). Operador: $($env:USERNAME)@$($env:COMPUTERNAME)."
        $cmd.CommandText = @"
INSERT INTO [dbo].[AuditEvents] 
([UserId], [ActorEmail], [Category], [Action], [Success], [Details], [IpAddress], [TimestampUtc])
VALUES 
(@uId, @email, 'Admin', 'ManualAdminProvisioning', 1, @details, '127.0.0.1', SYSUTCDATETIME())
"@
        $cmd.Parameters.Clear()
        $cmd.Parameters.AddWithValue("@uId", $userId) | Out-Null
        $cmd.Parameters.AddWithValue("@email", $normalizedEmail) | Out-Null
        $cmd.Parameters.AddWithValue("@details", $auditDetails) | Out-Null
        $cmd.ExecuteNonQuery() | Out-Null

        $tx.Commit()

        Write-Host "`n [ÉXITO] Usuario '$normalizedEmail' aprovisionado exitosamente como primer 'Administrador'." -ForegroundColor Green
        Write-Host "         - Rol asignado en AspNetUserRoles." -ForegroundColor Gray
        Write-Host "         - SecurityStamp actualizado para forzar revalidación de credenciales." -ForegroundColor Gray
        Write-Host "         - Evento estructurado registrado en tabla AuditEvents." -ForegroundColor Gray
    }
    catch {
        $tx.Rollback()
        Write-Error "Error durante la transacción de provisión: $_"
        exit 1
    }
}
finally {
    $conn.Close()
}
