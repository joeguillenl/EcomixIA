-- ==============================================================================
-- ECOMIX IA — PROVISIÓN MANUAL AUDITADA DEL PRIMER ADMINISTRADOR (D-10 / RF-52 / RF-53)
-- Este script es para uso EXCLUSIVO de inicialización (bootstrap) del sistema.
-- Cuenta con exclusión mutua mediante sp_getapplock y protección persistente histórica.
-- Si ya existe algún Administrador (activo o deshabilitado), o si el bootstrap ya
-- fue ejecutado históricamente, la operación se aborta atómicamente.
-- Para escenarios de desastre expresamente autorizados, use @IsRecovery = 1.
-- ==============================================================================

SET NOCOUNT ON;

-- 1. Declarar correo objetivo y bandera de recuperación
DECLARE @TargetEmail NVARCHAR(256) = N''; -- Ingrese aquí el correo del usuario autorizado para primer admin
DECLARE @IsRecovery BIT = 0;              -- 0 = Bootstrap inicial estricto; 1 = Recuperación autorizada de emergencia

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

-- 2. Transacción atómica protegida con sp_getapplock contra concurrencia multi-proceso
BEGIN TRY
    BEGIN TRANSACTION;

    -- Adquirir bloqueo exclusivo a nivel de aplicación dentro de la transacción
    DECLARE @LockResult INT;
    EXEC @LockResult = sp_getapplock 
        @Resource = 'EcoMix_Admin_Bootstrap_Lock', 
        @LockMode = 'Exclusive', 
        @LockOwner = 'Transaction', 
        @LockTimeout = 10000;

    IF @LockResult < 0
    BEGIN
        RAISERROR('ERROR D-10: No fue posible adquirir el bloqueo exclusivo de provisión (sp_getapplock timeout).', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- 2.1 Verificar si ya existe algún administrador asignado (incluso si está inhabilitado)
    DECLARE @ExistingAdminAnyCount INT = (
        SELECT COUNT(1)
        FROM [dbo].[AspNetUserRoles] ur
        WHERE ur.[RoleId] = @AdminRoleId
    );

    IF @ExistingAdminAnyCount > 0
    BEGIN
        RAISERROR('ERROR RF-53: Ya existe al menos un usuario con rol Administrador asignado en el sistema (%d encontrado(s)), activo o deshabilitado. La rutina de bootstrap inicial D-10/RF-52 es estrictamente de un solo uso. Cualquier cambio o promoción posterior debe realizarse mediante el módulo web (/Admin/Users).', 16, 1, @ExistingAdminAnyCount);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- 2.2 Protección persistente contra reejecución de bootstrap tras retiro de roles
    DECLARE @HistoricalBootstrapCount INT = (
        SELECT COUNT(1)
        FROM [dbo].[AuditEvents]
        WHERE [Action] IN ('ManualAdminProvisioning', 'AdminEmergencyRecovery') AND [Success] = 1
    );

    IF @HistoricalBootstrapCount > 0 AND @IsRecovery = 0
    BEGIN
        RAISERROR('ERROR RF-53: El bootstrap administrativo inicial ya fue ejecutado históricamente en este sistema (%d registro(s) previo(s)). No está permitido repetir el bootstrap eliminando roles. Para una restauración administrativa autorizada establezca @IsRecovery = 1.', 16, 1, @HistoricalBootstrapCount);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- 2.3 Verificación de precondiciones del usuario objetivo
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
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF @EmailConfirmed = 0
    BEGIN
        RAISERROR('ERROR D-10: El usuario objetivo no ha confirmado su correo electrónico (EmailConfirmed = 0).', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF @IsEnabled = 0
    BEGIN
        RAISERROR('ERROR D-10: El usuario objetivo se encuentra inhabilitado (IsEnabled = 0).', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- 2.4 Asignar rol Administrador y regenerar SecurityStamp
    INSERT INTO [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES (@UserId, @AdminRoleId);

    UPDATE [dbo].[AspNetUsers] 
    SET [SecurityStamp] = NEWID() 
    WHERE [Id] = @UserId;

    -- 2.5 Registrar evidencia estructurada en AuditEvents
    DECLARE @AuditAction NVARCHAR(100) = CASE WHEN @IsRecovery = 1 THEN 'AdminEmergencyRecovery' ELSE 'ManualAdminProvisioning' END;
    DECLARE @AuditDetail NVARCHAR(500) = CASE WHEN @IsRecovery = 1 
        THEN N'Recuperación administrativa de emergencia autorizada ejecutada mediante script D-10.' 
        ELSE N'Provisión manual de primer Administrador ejecutada mediante script auditado D-10/RF-52.' 
    END;

    INSERT INTO [dbo].[AuditEvents] 
    ([UserId], [ActorEmail], [Category], [Action], [Success], [Details], [IpAddress], [TimestampUtc])
    VALUES 
    (@UserId, LOWER(@TargetEmail), 'Admin', @AuditAction, 1, @AuditDetail, '127.0.0.1', SYSUTCDATETIME());

    COMMIT TRANSACTION;
    PRINT 'ÉXITO: Usuario ' + @TargetEmail + ' aprovisionado satisfactoriamente (Acción: ' + @AuditAction + ').';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 
        ROLLBACK TRANSACTION;
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Error durante la provisión: %s', 16, 1, @ErrMsg);
END CATCH;
GO
