-- ==============================================================================
-- ECOMIX IA — PROVISIÓN MANUAL AUDITADA DEL PRIMER ADMINISTRADOR (D-10 / RF-52 / RF-53)
-- Este script es para uso EXCLUSIVO de inicialización (bootstrap) del sistema.
-- Si ya existe al menos un Administrador activo, la operación se aborta (RF-53).
-- Las promociones posteriores deben realizarse mediante el módulo web (/Admin/Users).
-- Requiere definir la variable @TargetEmail antes de su ejecución.
-- ==============================================================================

SET NOCOUNT ON;

-- 1. Declarar correo objetivo (MODIFICAR SEGÚN EL USUARIO AUTORIZADO)
DECLARE @TargetEmail NVARCHAR(256) = N''; -- Ingrese aquí el correo del usuario autorizado para primer admin

IF @TargetEmail IS NULL OR LTRIM(RTRIM(@TargetEmail)) = N''
BEGIN
    RAISERROR('ERROR D-10: Debe especificar un correo electrónico no vacío en @TargetEmail para proceder con la provisión.', 16, 1);
    RETURN;
END;

DECLARE @AdminRoleId NVARCHAR(128) = (SELECT TOP 1 [Id] FROM [dbo].[AspNetRoles] WHERE [Name] = 'Administrador');
IF @AdminRoleId IS NULL
BEGIN
    RAISERROR('ERROR D-10: El rol Administrador no existe en la base de datos.', 16, 1);
    RETURN;
END;

-- 2. Verificación de existencia de administradores activos previos (RF-52 / RF-53)
DECLARE @ExistingAdminCount INT = (
    SELECT COUNT(1)
    FROM [dbo].[AspNetUserRoles] ur
    INNER JOIN [dbo].[AspNetUsers] u ON ur.[UserId] = u.[Id]
    WHERE ur.[RoleId] = @AdminRoleId AND u.[IsEnabled] = 1
);

IF @ExistingAdminCount > 0
BEGIN
    RAISERROR('ERROR RF-53: Ya existe al menos un Administrador activo en el sistema (%d encontrado(s)). La rutina de provisión D-10 es exclusiva para el primer Administrador (bootstrap inicial). Cualquier asignación de rol posterior debe realizarse exclusivamente a través del módulo web de Administración (/Admin/Users) por un administrador autenticado.', 16, 1, @ExistingAdminCount);
    RETURN;
END;

-- 3. Verificación de precondiciones del usuario objetivo
DECLARE @UserId NVARCHAR(128);
DECLARE @EmailConfirmed BIT;
DECLARE @IsEnabled BIT;

SELECT TOP 1 
    @UserId = [Id], 
    @EmailConfirmed = [EmailConfirmed], 
    @IsEnabled = [IsEnabled]
FROM [dbo].[AspNetUsers]
WHERE LOWER([Email]) = LOWER(LTRIM(RTRIM(@TargetEmail)));

IF @UserId IS NULL
BEGIN
    RAISERROR('ERROR D-10: No se encontró ningún usuario con el correo especificado.', 16, 1);
    RETURN;
END;

IF @EmailConfirmed = 0
BEGIN
    RAISERROR('ERROR D-10: El usuario objetivo no ha confirmado su correo electrónico (EmailConfirmed = 0).', 16, 1);
    RETURN;
END;

IF @IsEnabled = 0
BEGIN
    RAISERROR('ERROR D-10: El usuario objetivo se encuentra inhabilitado (IsEnabled = 0).', 16, 1);
    RETURN;
END;

IF EXISTS (SELECT 1 FROM [dbo].[AspNetUserRoles] WHERE [UserId] = @UserId AND [RoleId] = @AdminRoleId)
BEGIN
    PRINT 'AVISO: El usuario ya posee el rol Administrador. No se realizaron cambios.';
    RETURN;
END;

-- 4. Ejecución transaccional atómica con manejo robusto de errores
BEGIN TRY
    BEGIN TRANSACTION;

    -- Asignar rol Administrador
    INSERT INTO [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES (@UserId, @AdminRoleId);

    -- Actualizar SecurityStamp para revalidar sesiones
    UPDATE [dbo].[AspNetUsers] 
    SET [SecurityStamp] = NEWID() 
    WHERE [Id] = @UserId;

    -- Registrar evento de auditoría no sensible
    INSERT INTO [dbo].[AuditEvents] 
    ([UserId], [ActorEmail], [Category], [Action], [Success], [Details], [IpAddress], [TimestampUtc])
    VALUES 
    (@UserId, LOWER(@TargetEmail), 'Admin', 'ManualAdminProvisioning', 1, 
     N'Provisión manual de primer Administrador ejecutada mediante script auditado D-10/RF-52.', '127.0.0.1', SYSUTCDATETIME());

    COMMIT TRANSACTION;
    PRINT 'ÉXITO: Usuario ' + @TargetEmail + ' aprovisionado satisfactoriamente como primer Administrador.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 
        ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Error durante la provisión: %s', 16, 1, @ErrMsg);
END CATCH;
GO
