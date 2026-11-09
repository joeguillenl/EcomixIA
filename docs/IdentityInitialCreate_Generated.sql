-- =============================================================================
-- EcoMix IA — Script DDL de Migración: 202611091550114_IdentityInitialCreate
-- ContextKey: EcomixIA.Models.ApplicationDbContext
-- Compatibilidad: Microsoft SQL Server (LocalDB, Standard, Enterprise) y Azure SQL Database
-- =============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- 1. Tabla: dbo.AspNetRoles
IF NOT EXISTS (SELECT * FROM sys.tables WHERE object_id = OBJECT_ID(N'[dbo].[AspNetRoles]'))
BEGIN
    CREATE TABLE [dbo].[AspNetRoles] (
        [Id]   NVARCHAR (128) NOT NULL,
        [Name] NVARCHAR (256) NOT NULL,
        CONSTRAINT [PK_dbo.AspNetRoles] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END;

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[AspNetRoles]') AND name = N'RoleNameIndex')
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [RoleNameIndex]
        ON [dbo].[AspNetRoles]([Name] ASC);
END;

-- 2. Tabla: dbo.AspNetUsers
IF NOT EXISTS (SELECT * FROM sys.tables WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]'))
BEGIN
    CREATE TABLE [dbo].[AspNetUsers] (
        [Id]                   NVARCHAR (128) NOT NULL,
        [Email]                NVARCHAR (256) NULL,
        [EmailConfirmed]       BIT            NOT NULL,
        [PasswordHash]         NVARCHAR (MAX) NULL,
        [SecurityStamp]        NVARCHAR (MAX) NULL,
        [PhoneNumber]          NVARCHAR (MAX) NULL,
        [PhoneNumberConfirmed] BIT            NOT NULL,
        [TwoFactorEnabled]     BIT            NOT NULL,
        [LockoutEndDateUtc]    DATETIME       NULL,
        [LockoutEnabled]       BIT            NOT NULL,
        [AccessFailedCount]    INT            NOT NULL,
        [UserName]             NVARCHAR (256) NOT NULL,
        CONSTRAINT [PK_dbo.AspNetUsers] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END;

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUsers]') AND name = N'UserNameIndex')
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [UserNameIndex]
        ON [dbo].[AspNetUsers]([UserName] ASC);
END;

-- 3. Tabla: dbo.AspNetUserRoles
IF NOT EXISTS (SELECT * FROM sys.tables WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserRoles]'))
BEGIN
    CREATE TABLE [dbo].[AspNetUserRoles] (
        [UserId] NVARCHAR (128) NOT NULL,
        [RoleId] NVARCHAR (128) NOT NULL,
        CONSTRAINT [PK_dbo.AspNetUserRoles] PRIMARY KEY CLUSTERED ([UserId] ASC, [RoleId] ASC),
        CONSTRAINT [FK_dbo.AspNetUserRoles_dbo.AspNetRoles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[AspNetRoles] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_dbo.AspNetUserRoles_dbo.AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserRoles]') AND name = N'IX_RoleId')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_RoleId]
        ON [dbo].[AspNetUserRoles]([RoleId] ASC);
END;

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserRoles]') AND name = N'IX_UserId')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_UserId]
        ON [dbo].[AspNetUserRoles]([UserId] ASC);
END;

-- 4. Tabla: dbo.AspNetUserClaims
IF NOT EXISTS (SELECT * FROM sys.tables WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserClaims]'))
BEGIN
    CREATE TABLE [dbo].[AspNetUserClaims] (
        [Id]         INT            IDENTITY (1, 1) NOT NULL,
        [UserId]     NVARCHAR (128) NOT NULL,
        [ClaimType]  NVARCHAR (MAX) NULL,
        [ClaimValue] NVARCHAR (MAX) NULL,
        CONSTRAINT [PK_dbo.AspNetUserClaims] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_dbo.AspNetUserClaims_dbo.AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserClaims]') AND name = N'IX_UserId')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_UserId]
        ON [dbo].[AspNetUserClaims]([UserId] ASC);
END;

-- 5. Tabla: dbo.AspNetUserLogins
IF NOT EXISTS (SELECT * FROM sys.tables WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserLogins]'))
BEGIN
    CREATE TABLE [dbo].[AspNetUserLogins] (
        [LoginProvider] NVARCHAR (128) NOT NULL,
        [ProviderKey]   NVARCHAR (128) NOT NULL,
        [UserId]        NVARCHAR (128) NOT NULL,
        CONSTRAINT [PK_dbo.AspNetUserLogins] PRIMARY KEY CLUSTERED ([LoginProvider] ASC, [ProviderKey] ASC, [UserId] ASC),
        CONSTRAINT [FK_dbo.AspNetUserLogins_dbo.AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[AspNetUserLogins]') AND name = N'IX_UserId')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_UserId]
        ON [dbo].[AspNetUserLogins]([UserId] ASC);
END;

-- 6. Registro de Migración en __MigrationHistory
IF NOT EXISTS (
    SELECT * FROM [dbo].[__MigrationHistory] 
    WHERE [MigrationId] = N'202611091550114_IdentityInitialCreate' 
      AND [ContextKey] = N'EcomixIA.Models.ApplicationDbContext'
)
BEGIN
    -- El registro en __MigrationHistory se gestiona de forma nativa por Entity Framework
    PRINT 'Registro nativo requerido en dbo.__MigrationHistory para ContextKey EcomixIA.Models.ApplicationDbContext';
END;
