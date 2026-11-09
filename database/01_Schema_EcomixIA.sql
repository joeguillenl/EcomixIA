-- ============================================================================
-- ECOMIX IA — ESQUEMA COMPLETO DE BASE DE DATOS (DDL IDEMPOTENTE)
-- Proyecto: EcoMix IA (ASP.NET MVC 5 + EF6 + ASP.NET Identity 2 + SQL Server)
-- ============================================================================

-- 1. Crear Base de Datos si no existe
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'EcomixIA')
BEGIN
    CREATE DATABASE [EcomixIA];
    PRINT 'Base de datos [EcomixIA] creada exitosamente.';
END
ELSE
BEGIN
    PRINT 'Base de datos [EcomixIA] ya existe.';
END
GO

USE [EcomixIA];
GO

-- 2. Tabla de Historial de Migraciones EF6 (__MigrationHistory)
IF OBJECT_ID(N'[dbo].[__MigrationHistory]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[__MigrationHistory] (
        [MigrationId] NVARCHAR(150) NOT NULL,
        [ContextKey] NVARCHAR(300) NOT NULL,
        [Model] VARBINARY(MAX) NOT NULL,
        [ProductVersion] NVARCHAR(32) NOT NULL,
        CONSTRAINT [PK_dbo.__MigrationHistory] PRIMARY KEY CLUSTERED ([MigrationId] ASC, [ContextKey] ASC)
    );
    PRINT 'Tabla [dbo].[__MigrationHistory] creada.';
END
GO

-- 3. Tabla de Catálogo de Materiales (dbo.Materials)
IF OBJECT_ID(N'[dbo].[Materials]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Materials] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Nombre] NVARCHAR(100) NOT NULL,
        [Tipo] NVARCHAR(50) NOT NULL,
        [CostoPorKg] DECIMAL(18, 2) NOT NULL,
        [Co2PorKg] DECIMAL(18, 2) NOT NULL,
        CONSTRAINT [PK_dbo.Materials] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    PRINT 'Tabla [dbo].[Materials] creada.';
END
GO

-- 4. Tablas de Seguridad y Autenticación ASP.NET Identity 2
IF OBJECT_ID(N'[dbo].[AspNetRoles]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[AspNetRoles] (
        [Id] NVARCHAR(128) NOT NULL,
        [Name] NVARCHAR(256) NOT NULL,
        CONSTRAINT [PK_dbo.AspNetRoles] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE UNIQUE NONCLUSTERED INDEX [RoleNameIndex] ON [dbo].[AspNetRoles]([Name] ASC);
    PRINT 'Tabla [dbo].[AspNetRoles] creada con índice [RoleNameIndex].';
END
GO

IF OBJECT_ID(N'[dbo].[AspNetUsers]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[AspNetUsers] (
        [Id] NVARCHAR(128) NOT NULL,
        [Email] NVARCHAR(256) NULL,
        [EmailConfirmed] BIT NOT NULL CONSTRAINT [DF_AspNetUsers_EmailConfirmed] DEFAULT (0),
        [PasswordHash] NVARCHAR(MAX) NULL,
        [SecurityStamp] NVARCHAR(MAX) NULL,
        [PhoneNumber] NVARCHAR(MAX) NULL,
        [PhoneNumberConfirmed] BIT NOT NULL CONSTRAINT [DF_AspNetUsers_PhoneNumberConfirmed] DEFAULT (0),
        [TwoFactorEnabled] BIT NOT NULL CONSTRAINT [DF_AspNetUsers_TwoFactorEnabled] DEFAULT (0),
        [LockoutEndDateUtc] DATETIME NULL,
        [LockoutEnabled] BIT NOT NULL CONSTRAINT [DF_AspNetUsers_LockoutEnabled] DEFAULT (0),
        [AccessFailedCount] INT NOT NULL CONSTRAINT [DF_AspNetUsers_AccessFailedCount] DEFAULT (0),
        [UserName] NVARCHAR(256) NOT NULL,
        CONSTRAINT [PK_dbo.AspNetUsers] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    CREATE UNIQUE NONCLUSTERED INDEX [UserNameIndex] ON [dbo].[AspNetUsers]([UserName] ASC);
    PRINT 'Tabla [dbo].[AspNetUsers] creada con índice [UserNameIndex].';
END
GO

IF OBJECT_ID(N'[dbo].[AspNetUserRoles]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[AspNetUserRoles] (
        [UserId] NVARCHAR(128) NOT NULL,
        [RoleId] NVARCHAR(128) NOT NULL,
        CONSTRAINT [PK_dbo.AspNetUserRoles] PRIMARY KEY CLUSTERED ([UserId] ASC, [RoleId] ASC),
        CONSTRAINT [FK_dbo.AspNetUserRoles_dbo.AspNetRoles_RoleId] FOREIGN KEY ([RoleId]) 
            REFERENCES [dbo].[AspNetRoles] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_dbo.AspNetUserRoles_dbo.AspNetUsers_UserId] FOREIGN KEY ([UserId]) 
            REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
    CREATE NONCLUSTERED INDEX [IX_RoleId] ON [dbo].[AspNetUserRoles]([RoleId] ASC);
    CREATE NONCLUSTERED INDEX [IX_UserId] ON [dbo].[AspNetUserRoles]([UserId] ASC);
    PRINT 'Tabla [dbo].[AspNetUserRoles] creada.';
END
GO

IF OBJECT_ID(N'[dbo].[AspNetUserClaims]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[AspNetUserClaims] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [UserId] NVARCHAR(128) NOT NULL,
        [ClaimType] NVARCHAR(MAX) NULL,
        [ClaimValue] NVARCHAR(MAX) NULL,
        CONSTRAINT [PK_dbo.AspNetUserClaims] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_dbo.AspNetUserClaims_dbo.AspNetUsers_UserId] FOREIGN KEY ([UserId]) 
            REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
    CREATE NONCLUSTERED INDEX [IX_UserId] ON [dbo].[AspNetUserClaims]([UserId] ASC);
    PRINT 'Tabla [dbo].[AspNetUserClaims] creada.';
END
GO

IF OBJECT_ID(N'[dbo].[AspNetUserLogins]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[AspNetUserLogins] (
        [LoginProvider] NVARCHAR(128) NOT NULL,
        [ProviderKey] NVARCHAR(128) NOT NULL,
        [UserId] NVARCHAR(128) NOT NULL,
        CONSTRAINT [PK_dbo.AspNetUserLogins] PRIMARY KEY CLUSTERED ([LoginProvider] ASC, [ProviderKey] ASC, [UserId] ASC),
        CONSTRAINT [FK_dbo.AspNetUserLogins_dbo.AspNetUsers_UserId] FOREIGN KEY ([UserId]) 
            REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
    CREATE NONCLUSTERED INDEX [IX_UserId] ON [dbo].[AspNetUserLogins]([UserId] ASC);
    PRINT 'Tabla [dbo].[AspNetUserLogins] creada.';
END
GO

-- 5. Tabla de Mezclas de Concreto (dbo.Mezclas) con soporte de Usuario Propietario (Fase 3)
IF OBJECT_ID(N'[dbo].[Mezclas]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Mezclas] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Nombre] NVARCHAR(100) NOT NULL,
        [ResistenciaMPa] DECIMAL(18, 2) NOT NULL,
        [EdadDias] INT NOT NULL,
        [RelacionAguaCemento] DECIMAL(18, 2) NULL,
        [AsentamientoCm] DECIMAL(18, 2) NULL,
        [Notas] NVARCHAR(500) NULL,
        [OwnerUserId] NVARCHAR(128) NULL,
        CONSTRAINT [PK_dbo.Mezclas] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_dbo.Mezclas_dbo.AspNetUsers_OwnerUserId] FOREIGN KEY ([OwnerUserId]) 
            REFERENCES [dbo].[AspNetUsers] ([Id])
    );
    CREATE NONCLUSTERED INDEX [IX_Mezclas_OwnerUserId] ON [dbo].[Mezclas]([OwnerUserId] ASC);
    PRINT 'Tabla [dbo].[Mezclas] creada con columna [OwnerUserId] e índice.';
END
ELSE
BEGIN
    -- Asegurar columna OwnerUserId si la tabla existía previamente sin ella
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Mezclas]') AND name = 'OwnerUserId')
    BEGIN
        ALTER TABLE [dbo].[Mezclas] ADD [OwnerUserId] NVARCHAR(128) NULL;
        ALTER TABLE [dbo].[Mezclas] ADD CONSTRAINT [FK_dbo.Mezclas_dbo.AspNetUsers_OwnerUserId] 
            FOREIGN KEY ([OwnerUserId]) REFERENCES [dbo].[AspNetUsers] ([Id]);
        CREATE NONCLUSTERED INDEX [IX_Mezclas_OwnerUserId] ON [dbo].[Mezclas]([OwnerUserId] ASC);
        PRINT 'Columna [OwnerUserId], FK e índice agregados a [dbo].[Mezclas].';
    END
END
GO

-- 6. Tabla de Componentes de Mezcla (dbo.MezclaComponentes)
IF OBJECT_ID(N'[dbo].[MezclaComponentes]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[MezclaComponentes] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [MezclaId] INT NOT NULL,
        [MaterialId] INT NOT NULL,
        [Cantidad] DECIMAL(18, 2) NOT NULL,
        CONSTRAINT [PK_dbo.MezclaComponentes] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_dbo.MezclaComponentes_dbo.Materials_MaterialId] FOREIGN KEY ([MaterialId]) 
            REFERENCES [dbo].[Materials] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_dbo.MezclaComponentes_dbo.Mezclas_MezclaId] FOREIGN KEY ([MezclaId]) 
            REFERENCES [dbo].[Mezclas] ([Id]) ON DELETE CASCADE
    );
    CREATE NONCLUSTERED INDEX [IX_MezclaId] ON [dbo].[MezclaComponentes]([MezclaId] ASC);
    CREATE NONCLUSTERED INDEX [IX_MaterialId] ON [dbo].[MezclaComponentes]([MaterialId] ASC);
    PRINT 'Tabla [dbo].[MezclaComponentes] creada.';
END
GO

PRINT '============================================================================';
PRINT 'ESQUEMA DE BASE DE DATOS [EcomixIA] CONFIGURADO CORRECTAMENTE.';
PRINT '============================================================================';
GO
