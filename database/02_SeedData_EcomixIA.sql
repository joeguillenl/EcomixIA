-- ============================================================================
-- ECOMIX IA — DATOS INICIALES Y SEMILLA (DML IDEMPOTENTE)
-- Contiene: 10 materiales, roles, usuarios demo, mezclas legadas, mezclas privadas,
-- componentes de mezcla e historial de migraciones EF6.
-- ============================================================================

USE [EcomixIA];
GO

SET NOCOUNT ON;
BEGIN TRANSACTION;
BEGIN TRY


    -- 1. Insertar Catálogo de Materiales (10 materiales de referencia)
    SET IDENTITY_INSERT [dbo].[Materials] ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[Materials] WHERE [Id] = 1)
        INSERT INTO [dbo].[Materials] ([Id], [Nombre], [Tipo], [CostoPorKg], [Co2PorKg])
        VALUES (1, N'Cemento Portland Tipo I', N'Cemento', 0.620, 0.900);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Materials] WHERE [Id] = 2)
        INSERT INTO [dbo].[Materials] ([Id], [Nombre], [Tipo], [CostoPorKg], [Co2PorKg])
        VALUES (2, N'Cemento Puzolanico Tipo IP', N'Cemento', 0.580, 0.700);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Materials] WHERE [Id] = 3)
        INSERT INTO [dbo].[Materials] ([Id], [Nombre], [Tipo], [CostoPorKg], [Co2PorKg])
        VALUES (3, N'Agua potable', N'Agua', 0.010, 0.000);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Materials] WHERE [Id] = 4)
        INSERT INTO [dbo].[Materials] ([Id], [Nombre], [Tipo], [CostoPorKg], [Co2PorKg])
        VALUES (4, N'Arena gruesa', N'Agregado', 0.060, 0.010);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Materials] WHERE [Id] = 5)
        INSERT INTO [dbo].[Materials] ([Id], [Nombre], [Tipo], [CostoPorKg], [Co2PorKg])
        VALUES (5, N'Piedra chancada 3/4"', N'Agregado', 0.070, 0.010);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Materials] WHERE [Id] = 6)
        INSERT INTO [dbo].[Materials] ([Id], [Nombre], [Tipo], [CostoPorKg], [Co2PorKg])
        VALUES (6, N'Piedra chancada 1/2"', N'Agregado', 0.080, 0.010);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Materials] WHERE [Id] = 7)
        INSERT INTO [dbo].[Materials] ([Id], [Nombre], [Tipo], [CostoPorKg], [Co2PorKg])
        VALUES (7, N'Aditivo superplastificante', N'Aditivo', 6.500, 0.900);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Materials] WHERE [Id] = 8)
        INSERT INTO [dbo].[Materials] ([Id], [Nombre], [Tipo], [CostoPorKg], [Co2PorKg])
        VALUES (8, N'Ceniza volante', N'Adicion', 0.250, 0.030);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Materials] WHERE [Id] = 9)
        INSERT INTO [dbo].[Materials] ([Id], [Nombre], [Tipo], [CostoPorKg], [Co2PorKg])
        VALUES (9, N'Escoria de alto horno', N'Adicion', 0.300, 0.070);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Materials] WHERE [Id] = 10)
        INSERT INTO [dbo].[Materials] ([Id], [Nombre], [Tipo], [CostoPorKg], [Co2PorKg])
        VALUES (10, N'Humo de silice', N'Adicion', 3.500, 0.030);
    SET IDENTITY_INSERT [dbo].[Materials] OFF;
    PRINT 'Materiales inicializados exitosamente.';


    -- 2. Insertar Roles de Usuario (ASP.NET Identity 2)

    IF NOT EXISTS (SELECT 1 FROM [dbo].[AspNetRoles] WHERE [Id] = '6894EAF8-4D32-42EE-B3F6-F012501FDC00')
        INSERT INTO [dbo].[AspNetRoles] ([Id], [Name]) VALUES ('6894EAF8-4D32-42EE-B3F6-F012501FDC00', N'Registrado');
    IF NOT EXISTS (SELECT 1 FROM [dbo].[AspNetRoles] WHERE [Name] = 'Administrador')
        INSERT INTO [dbo].[AspNetRoles] ([Id], [Name]) VALUES (NEWID(), N'Administrador');
    PRINT 'Roles inicializados exitosamente.';


    -- 3. Insertar Usuarios de Demostración (joamedina@upt.pe y joamedina2@upt.pe)
    -- Contraseña predeterminada: Joe123456! (hash ASP.NET Identity 2 compatible)

    IF NOT EXISTS (SELECT 1 FROM [dbo].[AspNetUsers] WHERE [Id] = 'f64f14c6-aef4-43ae-8b6b-7b99fbb3e39f')
        INSERT INTO [dbo].[AspNetUsers] ([Id], [Email], [EmailConfirmed], [PasswordHash], [SecurityStamp], [PhoneNumber], [PhoneNumberConfirmed], [TwoFactorEnabled], [LockoutEndDateUtc], [LockoutEnabled], [AccessFailedCount], [UserName])
        VALUES ('f64f14c6-aef4-43ae-8b6b-7b99fbb3e39f', N'joamedina@upt.pe', 1, N'AJUooisanABvAjbQh1XfmhvW5w6Ar/T7v7cG1pbaAWZGIhHE0rrNbbdbW36dbvaAEA==', N'53bfd04f-dd6f-476f-bb16-fcc30534afc8', NULL, 0, 0, NULL, 0, 0, N'joamedina@upt.pe');
    IF NOT EXISTS (SELECT 1 FROM [dbo].[AspNetUsers] WHERE [Id] = 'b2e8b715-6692-460e-bef1-4c6a7a356c84')
        INSERT INTO [dbo].[AspNetUsers] ([Id], [Email], [EmailConfirmed], [PasswordHash], [SecurityStamp], [PhoneNumber], [PhoneNumberConfirmed], [TwoFactorEnabled], [LockoutEndDateUtc], [LockoutEnabled], [AccessFailedCount], [UserName])
        VALUES ('b2e8b715-6692-460e-bef1-4c6a7a356c84', N'joamedina2@upt.pe', 1, N'ANj9EInLSYKTwV3AV7IaypiebG/CS+f4TWp4dcY/dpRXAi/Cp4yL7m1PnjwTqZcABA==', N'8c87683a-b052-45e0-bb3a-215da57746f1', NULL, 0, 0, NULL, 0, 0, N'joamedina2@upt.pe');
    PRINT 'Usuarios inicializados exitosamente.';


    -- 4. Asignación de Roles a Usuarios

    IF NOT EXISTS (SELECT 1 FROM [dbo].[AspNetUserRoles] WHERE [UserId] = 'b2e8b715-6692-460e-bef1-4c6a7a356c84' AND [RoleId] = '6894EAF8-4D32-42EE-B3F6-F012501FDC00')
        INSERT INTO [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES ('b2e8b715-6692-460e-bef1-4c6a7a356c84', '6894EAF8-4D32-42EE-B3F6-F012501FDC00');
    IF NOT EXISTS (SELECT 1 FROM [dbo].[AspNetUserRoles] WHERE [UserId] = 'f64f14c6-aef4-43ae-8b6b-7b99fbb3e39f' AND [RoleId] = '6894EAF8-4D32-42EE-B3F6-F012501FDC00')
        INSERT INTO [dbo].[AspNetUserRoles] ([UserId], [RoleId]) VALUES ('f64f14c6-aef4-43ae-8b6b-7b99fbb3e39f', '6894EAF8-4D32-42EE-B3F6-F012501FDC00');
    PRINT 'Roles de usuario asignados exitosamente.';


    -- 5. Insertar Mezclas de Concreto (1..10 legadas públicas/restringidas, 11..13 privadas del usuario)
    SET IDENTITY_INSERT [dbo].[Mezclas] ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[Mezclas] WHERE [Id] = 1)
        INSERT INTO [dbo].[Mezclas] ([Id], [Nombre], [ResistenciaMPa], [EdadDias], [RelacionAguaCemento], [AsentamientoCm], [Notas], [OwnerUserId])
        VALUES (1, N'Concreto f''c 210', 21.00, 28, 0.55, 10.00, N'Uso estructural convencional: losas, columnas, cimentaciones', NULL);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Mezclas] WHERE [Id] = 2)
        INSERT INTO [dbo].[Mezclas] ([Id], [Nombre], [ResistenciaMPa], [EdadDias], [RelacionAguaCemento], [AsentamientoCm], [Notas], [OwnerUserId])
        VALUES (2, N'Concreto f''c 280', 27.50, 28, 0.45, 12.00, N'Estructuras de mayor exigencia, con superplastificante', NULL);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Mezclas] WHERE [Id] = 3)
        INSERT INTO [dbo].[Mezclas] ([Id], [Nombre], [ResistenciaMPa], [EdadDias], [RelacionAguaCemento], [AsentamientoCm], [Notas], [OwnerUserId])
        VALUES (3, N'Concreto f''c 350', 34.50, 28, 0.38, 15.00, N'Alta resistencia, elementos pretensados y columnas esbeltas', NULL);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Mezclas] WHERE [Id] = 4)
        INSERT INTO [dbo].[Mezclas] ([Id], [Nombre], [ResistenciaMPa], [EdadDias], [RelacionAguaCemento], [AsentamientoCm], [Notas], [OwnerUserId])
        VALUES (4, N'Concreto ecologico con ceniza', 25.00, 28, 0.50, 10.00, N'Reemplaza 20% del cemento por ceniza volante', NULL);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Mezclas] WHERE [Id] = 5)
        INSERT INTO [dbo].[Mezclas] ([Id], [Nombre], [ResistenciaMPa], [EdadDias], [RelacionAguaCemento], [AsentamientoCm], [Notas], [OwnerUserId])
        VALUES (5, N'Concreto ecologico con escoria', 30.00, 28, 0.45, 12.00, N'Reemplaza 35% del cemento por escoria de alto horno', NULL);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Mezclas] WHERE [Id] = 6)
        INSERT INTO [dbo].[Mezclas] ([Id], [Nombre], [ResistenciaMPa], [EdadDias], [RelacionAguaCemento], [AsentamientoCm], [Notas], [OwnerUserId])
        VALUES (6, N'Concreto alta resistencia 50 MPa', 50.00, 28, 0.30, 18.00, N'Incluye humo de silice y superplastificante', NULL);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Mezclas] WHERE [Id] = 7)
        INSERT INTO [dbo].[Mezclas] ([Id], [Nombre], [ResistenciaMPa], [EdadDias], [RelacionAguaCemento], [AsentamientoCm], [Notas], [OwnerUserId])
        VALUES (7, N'mezcla test1', 20.00, 7, 1.00, 12.00, N'apuntes test1', NULL);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Mezclas] WHERE [Id] = 8)
        INSERT INTO [dbo].[Mezclas] ([Id], [Nombre], [ResistenciaMPa], [EdadDias], [RelacionAguaCemento], [AsentamientoCm], [Notas], [OwnerUserId])
        VALUES (8, N'mezcla test2', 25.00, 7, 0.80, 12.00, N'prueba test2', NULL);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Mezclas] WHERE [Id] = 9)
        INSERT INTO [dbo].[Mezclas] ([Id], [Nombre], [ResistenciaMPa], [EdadDias], [RelacionAguaCemento], [AsentamientoCm], [Notas], [OwnerUserId])
        VALUES (9, N'mezcla test1', 12.00, 28, 1.00, 12.00, N'test', NULL);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Mezclas] WHERE [Id] = 10)
        INSERT INTO [dbo].[Mezclas] ([Id], [Nombre], [ResistenciaMPa], [EdadDias], [RelacionAguaCemento], [AsentamientoCm], [Notas], [OwnerUserId])
        VALUES (10, N'mezcla test2', 12.00, 7, 1.00, 24.00, N'test 2 comentario', NULL);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Mezclas] WHERE [Id] = 11)
        INSERT INTO [dbo].[Mezclas] ([Id], [Nombre], [ResistenciaMPa], [EdadDias], [RelacionAguaCemento], [AsentamientoCm], [Notas], [OwnerUserId])
        VALUES (11, N'Mezcla ecológica base', 25.00, 28, 0.50, 10.00, N'FÃ³rmula ecolÃ³gica con sustituciÃ³n SCM optimizada para durabilidad.', 'f64f14c6-aef4-43ae-8b6b-7b99fbb3e39f');
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Mezclas] WHERE [Id] = 12)
        INSERT INTO [dbo].[Mezclas] ([Id], [Nombre], [ResistenciaMPa], [EdadDias], [RelacionAguaCemento], [AsentamientoCm], [Notas], [OwnerUserId])
        VALUES (12, N'Concreto f''c 210 ajustado', 21.00, 28, 0.55, 8.00, N'DosificaciÃ³n estÃ¡ndar ajustada para elementos estructurales.', 'f64f14c6-aef4-43ae-8b6b-7b99fbb3e39f');
    IF NOT EXISTS (SELECT 1 FROM [dbo].[Mezclas] WHERE [Id] = 13)
        INSERT INTO [dbo].[Mezclas] ([Id], [Nombre], [ResistenciaMPa], [EdadDias], [RelacionAguaCemento], [AsentamientoCm], [Notas], [OwnerUserId])
        VALUES (13, N'mezcla test3', 1.00, 28, 0.40, 12.00, N'test 3', 'f64f14c6-aef4-43ae-8b6b-7b99fbb3e39f');
    SET IDENTITY_INSERT [dbo].[Mezclas] OFF;
    PRINT 'Mezclas inicializadas exitosamente.';


    -- 6. Insertar Componentes de Mezcla (46 registros con dosificaciones exactas)
    SET IDENTITY_INSERT [dbo].[MezclaComponentes] ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 1)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (1, 1, 1, 350.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 2)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (2, 2, 1, 400.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 3)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (3, 3, 1, 450.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 4)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (4, 4, 1, 280.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 5)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (5, 6, 1, 480.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 6)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (6, 5, 2, 260.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 7)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (7, 1, 3, 193.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 8)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (8, 2, 3, 180.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 9)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (9, 3, 3, 171.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 10)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (10, 4, 3, 175.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 11)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (11, 5, 3, 180.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 12)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (12, 6, 3, 156.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 13)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (13, 1, 4, 800.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 14)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (14, 2, 4, 780.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 15)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (15, 3, 4, 740.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 16)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (16, 4, 4, 800.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 17)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (17, 5, 4, 770.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 18)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (18, 6, 4, 700.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 19)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (19, 1, 5, 1000.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 20)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (20, 2, 5, 1000.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 21)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (21, 4, 5, 1000.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 22)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (22, 5, 5, 1000.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 23)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (23, 3, 6, 1000.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 24)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (24, 6, 6, 1000.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 25)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (25, 2, 7, 2.80);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 26)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (26, 3, 7, 4.50);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 27)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (27, 4, 7, 2.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 28)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (28, 5, 7, 3.20);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 29)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (29, 6, 7, 9.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 30)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (30, 4, 8, 70.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 31)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (31, 5, 9, 140.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 32)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (32, 6, 10, 40.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 33)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (33, 10, 8, 12.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 34)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (34, 11, 1, 200.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 35)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (35, 11, 8, 100.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 36)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (36, 11, 9, 50.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 37)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (37, 11, 3, 150.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 38)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (38, 11, 4, 750.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 39)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (39, 11, 6, 1050.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 40)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (40, 11, 7, 19.30);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 41)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (41, 12, 1, 280.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 42)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (42, 12, 3, 154.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 43)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (43, 12, 4, 750.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 44)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (44, 12, 5, 1050.00);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 45)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (45, 12, 7, 14.80);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[MezclaComponentes] WHERE [Id] = 46)
        INSERT INTO [dbo].[MezclaComponentes] ([Id], [MezclaId], [MaterialId], [Cantidad])
        VALUES (46, 11, 10, 5.01);
    SET IDENTITY_INSERT [dbo].[MezclaComponentes] OFF;
    PRINT 'Componentes de mezcla inicializados exitosamente.';


    -- 7. Historial de Migraciones EF6 (__MigrationHistory)

    IF NOT EXISTS (SELECT 1 FROM [dbo].[__MigrationHistory] WHERE [MigrationId] = '202611082237174_InitialCreate' AND [ContextKey] = 'EcomixIA.Models.EcomixContext')
        INSERT INTO [dbo].[__MigrationHistory] ([MigrationId], [ContextKey], [ProductVersion], [Model])
        VALUES ('202611082237174_InitialCreate', 'EcomixIA.Models.EcomixContext', '6.5.1', 0x1f8b0800000000000400ed5bdb6ee336107d2fd07f10f458642dc78b05b681bd0bd7490a633717c4c9a26f01238d1da112a98a54e0b4e897f5a19fd45fe850574a94642976e2ec629197989733c3e1cc213963fff7cfbfe38f6bdf331e20e42ea313f37030340da036735cba9a989158be796f7efcf0e30fe313c75f1b5fb2716fe5389c49f9c4bc172238b22c6edf834ff8c077ed9071b614039bf9167198351a0e7fb60e0f2d400813b10c637c1551e1fa107fc08f33466d084444bc33e680c7d376ec59c4a8c639f18107c486897982b0ee7a3e1d24434d63eab904d55880b7340d42291344a09247371c16226474b508b08178d78f01e0b825f138a4ca1f15c3bbae633892ebb08a8919941d71c1fc9e80876f53c358d5e94f32af991b0e4d778226168f72d5b1f926e619fc697b64c6fc8051a0028d50157a34f3423941b3f2a03af7c0c8461ce45e81ce23ff0e8c59e489288409854884c43b302ea33bcfb53fc1e335fb1de884469ea7aa8aca625fa9019b2e431640281eaf60992e60ee9886559e675527e6d39439c992e654bc1d99c6390a27771ee49ea02c7f215808bf02859008702e891010528901b12d35e915598991364bdc8082b243f4d76d7166049576488e720cb6eb13cf342e43fc2f8df7f7a6b1b089c4ec20e09c3cb8abd8520d2a9bc61578f1007eef06494c0eb2cedbc27b306a4f43e65f314f99acf6df5e9370050255672d83162c0aed3e6ac6fb53af64dcd5a8a2d6ab2ba80fa9536f6c1561d91eacb9497b04693ae77b70d6c83a67fe5d08993c3c19f084338d33b2fe0c7425ee31168678a69dba6b70b29654871beae2818893441841ef30bc7603d622f5ddb3083d06ca65ec279efe40ba73c0064e61e88b972cfcb4da1dab682246cf2be01c1d8ab7ee48b72de9ca3a254ed9153f66dcd2ca8f19473d8d8052b2ec7b47f84e3eaf887cae80bb5ce085de2567973d58a0a79813a49a63b788aaa75d58646cd8a8cc74159119f86859b62bde9a724423be2b3167feae505f1d93f4bdc4682cd27ccfe9c22153ce197a9ad4aa728b29e9545eed09758c2e44971859254cb435d2891b2081a032b8756695282ee8317820c098dac9936c46b84d1cdde4b820a7975af9f54f514b7b5e95d5fb49938afc05a12410e2e10b982323ba54e864e762f806c4eb60a5cadc8e5429d79f4ba9f61c430054b25c076b7411afbe6e7435726995edd964a9b1a5f8de0697d483a471e75b22a6baef2fe58c2d2f919777c546fbbc8423365aa2931be64ff51770c2842d718ec019106687667c4d92adb01635f7ac1b0ee9558ba70745d52924ea0244dde9501074a34b58ed7059a0d6a3e514bc092516dbac9006a09850d7a57cb42943dbaed2d5fded78e0e42b299b4273978e078502575a4435f6cbebef629b9a43bfc6321b58af2befa956c9b6b6cd24cd74b5b541b25b481e5745d6d84ad2c6597ad96ac82f8fcf4810e0a54dc937a72dc6224936cfde2cfa2762fd04c3b2794d3e36d73697842f0bb2824aaf348a03a76ec8c53111e48ec86be3ccf1b56165166908c64c964e14fad665619acd91ffab84d59c13ae21de14e4145728eff3f16241f3a13688b806403c12d6bcde66cc8b7cda7c9a34cf2ee85fc5683e145a9094fb4c09abe59ed38c56e46c55aca255471a5b151b6bc799b6a5da6da3ec259d7c48a1c4ad5c283b479ee03a8d539fc765b227bc8a90b5754749b2812a46d2d21d414feda9687a6f0fe753927b25f753dafba08d6ab146bd91d26776d9f0a2eee4d95f38a467e1f674fa6412fdbae2a09a9852d1aa7ddd518b3c948a57b4f6d1af26175556b2664077fc6a424a85aef67d8591a2ddcdaa4372e9f91dad72171ba7f7a2cd5f08d02e4ac91099d5630fae232f498b47f4277f20070c167f78334fdab6187046a8bb042e921cb4391a1e8e2a5f2b783d257e8b73c7eb59e77ff184ba2badbb3165deb72e5ea9aec742b457f31c5feeeb89f9573ce9c898ff769bcd3b302e42dcec236368fcbd83a27c67f1f9ccad14a856f39ded72f8fdebd0df8613950b31f48184f63d09f552cc1645de5ad077fd319b6ab87d76beb6beb0b1a6bba56f6daee9ee5c40a912d3b001c376c3f42d8c7e8f87de75c79d6f7bb5ee189b687755c75d475a7d1572d7529e31167654e0db6b354fcb83efaf84f7726592d624ddb750a4db77456ecf0ed5943a7825eeb4ff629b9e4def52b75237ae43452d797822a3dfc9232421d7ea28bdc2d154786b2dbbd58a4a7b3b884803a4b128d7bc121d7c1f15bbdaf25c874a94bea1f56588575c96ab517c2f0bef517ed3533918dfca2f409065b8bb2a20e4ef4128d8a5c8cec7cce992651453d1281ba2250e047130eca7a17097c416d86d03e7f1b7b5be102f921749ff0e9c39bd884410095c32f8775ee94b7d92a8dae4c735c6b2cee38b20fe7ed62e96806ae25350c005fd25723d27d7fbb4e665df002119307d38c8bd14f201b17acc91ced101ba01a5e6cb89fb1afc005fa8c02fe8823cc05374bbe1f01956c47ecc3272cd209b37a26cf631be0f5621f1798a51ccc78fe8c38ebffef03fb2aade3b08350000);
    IF NOT EXISTS (SELECT 1 FROM [dbo].[__MigrationHistory] WHERE [MigrationId] = '202611091550114_IdentityInitialCreate' AND [ContextKey] = 'EcomixIA.Models.ApplicationDbContext')
        INSERT INTO [dbo].[__MigrationHistory] ([MigrationId], [ContextKey], [ProductVersion], [Model])
        VALUES ('202611091550114_IdentityInitialCreate', 'EcomixIA.Models.ApplicationDbContext', '6.5.1', 0x1f8b0800000000000400dd5c6d6fe33612fe7ec0fd07419f7a87d4ca4b77b117d82d5227b90bba79c13a5bf4db82966847588952252a7570e82fbb0ffd49fd0b37942859e28b44d98aed140b2c2c72f8cc70382487c361fefcdf1fe31f5661603de324f52332b14f46c7b685891b793e594eec8c2ebefd60fff0fddfff36bef2c295f5734977c6e8a0254927f613a5f1b9e3a4ee130e513a0a7d3789d26841476e143ac88b9cd3e3e37f3927270e06081bb02c6bfc2923d40f71fe019fd388b838a6190a6e230f07292f879a598e6adda110a73172f1c4be02587f7573312a486deb22f0118831c3c1c2b61021114514843cff9ce2194d22b29cc5508082c7971803dd020529e6c29fafc94dfb717ccafae1ac1b96506e96d228ec097872c615e388cd3752af5d290e5477052aa62facd7b9fa26f68d87f3a24f51000a10199e4f8384114fecdb8ac5451adf613a2a1b8e0ac8eb04e07e8b92afa33ae29165dceea832a4d3d131fb77644db38066099e109cd1040547d643360f7cf727fcf2187dc5647276325f9c7d78f71e7967efbfc367efea3d85be025da3008a1e9228c609c8861755ff6dcb69b673c48655b35a9b422b604b30276ceb16ad3e62b2a44f305b4e3fd8d6b5bfc25e59c28deb33f1610a41239a64f0799705019a07b8aa775a79b2ff5bb89ebe7b3f08d73bf4ec2ff3a117f8c3c449605e7dc2415e9b3ef97131bd1ae3fd85935d2751c8be9bf655d47e994559e2b2ce445a9247942c316d4a3776d6c66b64d20c6a78b32e510fdfb499a4b2792b495987369909258b5dcf8652ded7e56b6c7117710c83979b16d3489bc1093bd548687a6495046ba33931351a029df92baf815721f283011641032ee07c2cfc24c4552f7f8cc0e410e92df3034a535803bcffa0f4a94574f83980e833ec660998e68ca2307e756e0f4f11c17759386716bf3b5e830dcde36fd1357269945c11d66a6bbc8f91fb35cae815f12e11c59fa95b02b2cf473f340718449c0bd7c5697a0dc68cbd6904be75097843e8d9696f38b63aeddb099906c80fd55e88b08e7e2949d79e889a42f24634642a8fa44dd48fd1d22766a296a47a510b8a4e5139595f51199899a49c522f684ed029674135988f978fd0f04e5e0e7bf85ede769bb76e2da8a971062b24fe3726388165cc7b4094e284ac47c064ddd887b3900f1f63faea7b53cee967146443b3da6836e48bc0f0b321873dfcd9908b09c5cfbec7bc1283a34f490cf046f4ea5355f79c1324dbf574687473d7cc77b306e8a6cb459a46ae9fcf0245d08b872c9af2830f6775c72f8ade883110e81818bacfb63c2881bed9a251dd934b1c608aad0bb7080a4e51ea224f562374c8eb2158b9a32a045bc7429ac2fd53e209968e13d608b143500a33d527549e163e71fd18059d5a125a1a6e61acef150fb1e612c79830869d9a3061ae0e7d30012a3ec2a0746968ecd42caedd10355eab6eccbb5cd8f5b84b11899dd86487efacb14beebfbd8a61b66b6c07c6d9ae121301b461bc7d18283fab981a807870393403154e4c1a03e52ed54e0cb4a9b13d186853256fce408b23aae9f80be7d54333cfe64179f7db7aabbaf6609b0d7d1c986916be27b4a1d00227b2795ece59255e51c5e10ce4e4e7b394bbbaa28930f019a6cd90cddadf55faa14e3b8868446d806b43eb00e51780129034a17a0857c6f25aa5e35e440fd832eed60acbd77e01b666033276fd22b446a8bf2e158dd3e8f451f5acb206c9c88d0e0b351c8541888b57b3e3064ad1c56565c598f8c27dbce15ac7f860b428a8c373d528a9eccce05a2a4db35b4b2a87ac8f4bb6959604f749a3a5b233836b89db68b792144e410fb7602b1535b7f081265b19e9a8769baa6eec14c951bc60ec68b2a8c6b7288e7db2ac6555f1126b56a4544dbf9df54f370a0b0cc74d15594795b415271a256889855a600d925efb494a2f114573c4e23c532f94c8947bab66f92f59d6b74f7910cb7da0a466bff9a5b0706ddfd868654f84035c43f742e6cee43174c5e0ab9b5b2cc50d05285184eda751908544ef5de95b179777f5f645898c307604f925ef495295e4e336f56e342af28c1862842acf65f351d243e8745dfa9d756deb7c513d4a199aaaa3e8c2557b1b359d0b633e52a26bd87fa03a115e6746f17c943a002fea89514b6990c06a75e6a8cdac933a66b3c61c51482da9430a553da4ac27903484ac576c84a7d1a89ac29c839c325247976bcd9115c923756845f506d80a99c53a7354457e491d58516d8ebd4e361157d003deb3b40796cd36ade240bbddaea5c1789de570984daf766f5f07aa15f7c4e237f312182f3f4853d29eea3633a52288b19d296930f46b4ee3babbb9e4b4ded1eb311b77d88d65bded0e5f8fd7cf605fd52ca4139d485271af4e76c2096ecc4f53dd8f65a4e35541625ba51a614b7f49290e478c6034fb3598063e660b7849708b88bfc0292df236ecd3e39353e1c9cde13c7f71d2d40b14a751dd1b98e698ed20058b3ca3c47d42899c10b1c5139135a8146bbe211e5e4decffe6adcef3b005fb95171f5937e967e2ff9a41c5639261eb7739c17398947983471a95a0bfbf89d70fe62abff9e54bd1f4c8ba4f603a9d5bc782a23719fee69b885ed2144db79066e397126f77b6351e23285185d9b2f9db83b94f077977504af94d8856ffe82b9af26dc156888af70343e10da242ddfb804db0b46f033cf8a4f9db807e9d55bf15d84434ed3b019ff407135f09982f4365cb3dee438ad3d22e96a45ccf9d59d65ba55cee7b6f9292b1b79ae872c2750fb84193aab77351de58b2f2605ba722177930ec7ddafdab27201f4acef1da69df6faaf12eb38b5bee91fe5249c5079006a748ebd97feaf0ae6d4d17fe3df0fccb7e09c207666c7c9bdf7f1af0ae8d4d17203e7063eb95ec7b60b6b6affd73cf9666bc85ee3d7557ce42d25ce3a8a2c85da9b945c81d8efff3088ca0f0288b1795ea5cb0b63cd60e866b123d537d129ac8589a38125f89a29d6dbfbef20dbfb5b39ca69dad2675b38d375fff5b79739a76de9a84c87d24152b53125589de1deb585bd6d45b4a226ef4a42367bdcb676dbd937f4b39c38328a5317b34b7cb6f27457810950c39757aa404cb17c5b077d6fef622ecdfa9bf5c43b0bfc448b0dbd8352b9a1bb288cacd5b90a824112234b798220fb6d48b84fa0be452a86601e8fc49781ed463d72073ecdd90fb8cc619852ee3701e34025ecc0968e39fe73d37651edfc7ec2b1da20b20a6cf02f7f7e4c7cc0fbc4aee6b454c4803c1bc0b1eee65634959d877f95221dd45c41088abaf728a1e7118070096de93197ac69bc806e6f7112f91fbb28e00ea40ba07a2a9f6f1a58f96090a538eb16e0f9f60c35eb8fafeffe36f952c82540000);
    PRINT 'Historial de migraciones inicializado exitosamente.';


    COMMIT TRANSACTION;
    PRINT '============================================================================';
    PRINT 'DATOS DE SEMILLA INSERTADOS EXITOSAMENTE EN [EcomixIA].';
    PRINT '============================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Err, 16, 1);
END CATCH;
GO
