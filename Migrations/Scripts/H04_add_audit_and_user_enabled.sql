-- ==============================================================================
-- ECOMIX IA — MIGRACIÓN ADITIVA H04
-- Incorporación de IsEnabled en AspNetUsers y Creación de Tabla AuditEvents (D-07)
-- ==============================================================================

SET NOCOUNT ON;

-- 1. Agregar columna IsEnabled a AspNetUsers si no existe
IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'AspNetUsers' AND COLUMN_NAME = 'IsEnabled'
)
BEGIN
    PRINT 'Agregando columna IsEnabled a AspNetUsers...';
    ALTER TABLE [dbo].[AspNetUsers] 
    ADD [IsEnabled] BIT NOT NULL CONSTRAINT [DF_AspNetUsers_IsEnabled] DEFAULT 1;
    PRINT 'Columna IsEnabled agregada exitosamente.';
END
ELSE
BEGIN
    PRINT 'La columna IsEnabled ya existe en AspNetUsers.';
END
GO

-- 2. Asegurar existencia del rol 'Administrador' en AspNetRoles
IF NOT EXISTS (
    SELECT 1 
    FROM [dbo].[AspNetRoles] 
    WHERE [Name] = 'Administrador'
)
BEGIN
    PRINT 'Creando rol Administrador en AspNetRoles...';
    INSERT INTO [dbo].[AspNetRoles] ([Id], [Name])
    VALUES (NEWID(), N'Administrador');
    PRINT 'Rol Administrador creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El rol Administrador ya existe en AspNetRoles.';
END
GO

-- NOTA DE SEGURIDAD D-10:
-- La asignación de usuarios al rol 'Administrador' NO se realiza automáticamente
-- en la migración de esquema. Debe utilizarse la rutina de provisión manual
-- independiente (tools/Provision-Administrator.ps1) con autorización explícita.
-- ==============================================================================

-- 3. Crear tabla AuditEvents (D-07) con índices optimizados para retención de 30 días
IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'AuditEvents'
)
BEGIN
    PRINT 'Creando tabla AuditEvents...';
    CREATE TABLE [dbo].[AuditEvents] (
        [Id] BIGINT IDENTITY(1,1) NOT NULL,
        [UserId] NVARCHAR(128) NULL,
        [ActorEmail] NVARCHAR(256) NULL,
        [Category] NVARCHAR(64) NOT NULL,
        [Action] NVARCHAR(64) NOT NULL,
        [Success] BIT NOT NULL,
        [Details] NVARCHAR(MAX) NULL,
        [IpAddress] NVARCHAR(45) NULL,
        [CorrelationId] NVARCHAR(64) NULL,
        [TimestampUtc] DATETIME2 NOT NULL,
        CONSTRAINT [PK_dbo.AuditEvents] PRIMARY KEY CLUSTERED ([Id] ASC)
    );

    CREATE NONCLUSTERED INDEX [IX_AuditEvents_TimestampUtc] 
        ON [dbo].[AuditEvents]([TimestampUtc] ASC);

    CREATE NONCLUSTERED INDEX [IX_AuditEvents_Category_TimestampUtc] 
        ON [dbo].[AuditEvents]([Category] ASC, [TimestampUtc] ASC);

    PRINT 'Tabla AuditEvents e índices creados exitosamente.';
END
ELSE
BEGIN
    PRINT 'La tabla AuditEvents ya existe.';
END
GO
