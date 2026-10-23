/*
  EcoMix IA - datos de ejemplo (SQL Server)

  Inserta materiales, mezclas y sus componentes.
  Es idempotente: no duplica registros si se ejecuta varias veces.
  Los componentes se enlazan por nombre, asi que no depende de los valores IDENTITY.

  Unidades:
    - CostoPorKg: soles (S/) por kg
    - Co2PorKg: kg de CO2 por kg de material (valores aproximados)
    - MezclaComponentes.Cantidad: kg de material por m3 de concreto
    - ResistenciaMPa: resistencia a compresion objetivo
    - RelacionAguaCemento: agua / material cementante (cemento + adiciones)
*/

USE EcomixIA;
GO

------------------------------------------------------------
-- 1) MATERIALS
------------------------------------------------------------
INSERT INTO dbo.Materials (Nombre, Tipo, DensidadRelativa, CostoPorKg, Co2PorKg, Notas)
SELECT v.Nombre, v.Tipo, v.DensidadRelativa, v.CostoPorKg, v.Co2PorKg, v.Notas
FROM (VALUES
    (N'Cemento Portland Tipo I',     N'Cemento',   3.15, 0.62, 0.90, N'Cemento de uso general'),
    (N'Cemento Puzolanico Tipo IP',  N'Cemento',   3.00, 0.58, 0.70, N'Cemento con adicion de puzolana, menor huella de carbono'),
    (N'Agua potable',                N'Agua',      1.00, 0.01, 0.00, N'Agua de mezclado'),
    (N'Arena gruesa',                N'Agregado',  2.65, 0.06, 0.01, N'Agregado fino, modulo de fineza 2.8'),
    (N'Piedra chancada 3/4"',        N'Agregado',  2.70, 0.07, 0.01, N'Agregado grueso, TMN 3/4"'),
    (N'Piedra chancada 1/2"',        N'Agregado',  2.70, 0.08, 0.01, N'Agregado grueso, TMN 1/2"'),
    (N'Aditivo superplastificante',  N'Aditivo',   1.10, 6.50, 0.90, N'Reductor de agua de alto rango'),
    (N'Ceniza volante',              N'Adicion',   2.20, 0.25, 0.03, N'Subproducto industrial, reemplazo parcial de cemento'),
    (N'Escoria de alto horno',       N'Adicion',   2.90, 0.30, 0.07, N'Escoria granulada molida'),
    (N'Humo de silice',              N'Adicion',   2.20, 3.50, 0.03, N'Para concretos de alta resistencia')
) AS v (Nombre, Tipo, DensidadRelativa, CostoPorKg, Co2PorKg, Notas)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Materials m WHERE m.Nombre = v.Nombre);
GO

------------------------------------------------------------
-- 2) MEZCLAS
------------------------------------------------------------
INSERT INTO dbo.Mezclas (Nombre, ResistenciaMPa, EdadDias, RelacionAguaCemento, AsentamientoCm, Notas)
SELECT v.Nombre, v.ResistenciaMPa, v.EdadDias, v.RelacionAguaCemento, v.AsentamientoCm, v.Notas
FROM (VALUES
    (N'Concreto f''c 210',               21.00, 28, 0.55, 10.00, N'Uso estructural convencional: losas, columnas, cimentaciones'),
    (N'Concreto f''c 280',               27.50, 28, 0.45, 12.00, N'Estructuras de mayor exigencia, con superplastificante'),
    (N'Concreto f''c 350',               34.50, 28, 0.38, 15.00, N'Alta resistencia, elementos pretensados y columnas esbeltas'),
    (N'Concreto ecologico con ceniza',   25.00, 28, 0.50, 10.00, N'Reemplaza 20% del cemento por ceniza volante'),
    (N'Concreto ecologico con escoria',  30.00, 28, 0.45, 12.00, N'Reemplaza 35% del cemento por escoria de alto horno'),
    (N'Concreto alta resistencia 50 MPa',50.00, 28, 0.30, 18.00, N'Incluye humo de silice y superplastificante')
) AS v (Nombre, ResistenciaMPa, EdadDias, RelacionAguaCemento, AsentamientoCm, Notas)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Mezclas z WHERE z.Nombre = v.Nombre);
GO

------------------------------------------------------------
-- 3) MEZCLA COMPONENTES (kg por m3)
------------------------------------------------------------
INSERT INTO dbo.MezclaComponentes (MezclaId, MaterialId, Cantidad)
SELECT z.Id, m.Id, v.Cantidad
FROM (VALUES
    -- f'c 210
    (N'Concreto f''c 210', N'Cemento Portland Tipo I',    350.00),
    (N'Concreto f''c 210', N'Agua potable',               193.00),
    (N'Concreto f''c 210', N'Arena gruesa',               800.00),
    (N'Concreto f''c 210', N'Piedra chancada 3/4"',      1000.00),

    -- f'c 280
    (N'Concreto f''c 280', N'Cemento Portland Tipo I',    400.00),
    (N'Concreto f''c 280', N'Agua potable',               180.00),
    (N'Concreto f''c 280', N'Arena gruesa',               780.00),
    (N'Concreto f''c 280', N'Piedra chancada 3/4"',      1000.00),
    (N'Concreto f''c 280', N'Aditivo superplastificante',   2.80),

    -- f'c 350
    (N'Concreto f''c 350', N'Cemento Portland Tipo I',    450.00),
    (N'Concreto f''c 350', N'Agua potable',               171.00),
    (N'Concreto f''c 350', N'Arena gruesa',               740.00),
    (N'Concreto f''c 350', N'Piedra chancada 1/2"',      1000.00),
    (N'Concreto f''c 350', N'Aditivo superplastificante',   4.50),

    -- Ecologico con ceniza volante (20% reemplazo, ligante total 350 kg)
    (N'Concreto ecologico con ceniza', N'Cemento Portland Tipo I',  280.00),
    (N'Concreto ecologico con ceniza', N'Ceniza volante',            70.00),
    (N'Concreto ecologico con ceniza', N'Agua potable',             175.00),
    (N'Concreto ecologico con ceniza', N'Arena gruesa',             800.00),
    (N'Concreto ecologico con ceniza', N'Piedra chancada 3/4"',    1000.00),
    (N'Concreto ecologico con ceniza', N'Aditivo superplastificante', 2.00),

    -- Ecologico con escoria (35% reemplazo, ligante total 400 kg)
    (N'Concreto ecologico con escoria', N'Cemento Puzolanico Tipo IP', 260.00),
    (N'Concreto ecologico con escoria', N'Escoria de alto horno',      140.00),
    (N'Concreto ecologico con escoria', N'Agua potable',               180.00),
    (N'Concreto ecologico con escoria', N'Arena gruesa',               770.00),
    (N'Concreto ecologico con escoria', N'Piedra chancada 3/4"',      1000.00),
    (N'Concreto ecologico con escoria', N'Aditivo superplastificante',   3.20),

    -- Alta resistencia 50 MPa (ligante total 520 kg)
    (N'Concreto alta resistencia 50 MPa', N'Cemento Portland Tipo I',  480.00),
    (N'Concreto alta resistencia 50 MPa', N'Humo de silice',            40.00),
    (N'Concreto alta resistencia 50 MPa', N'Agua potable',             156.00),
    (N'Concreto alta resistencia 50 MPa', N'Arena gruesa',             700.00),
    (N'Concreto alta resistencia 50 MPa', N'Piedra chancada 1/2"',    1000.00),
    (N'Concreto alta resistencia 50 MPa', N'Aditivo superplastificante', 9.00)
) AS v (MezclaNombre, MaterialNombre, Cantidad)
JOIN dbo.Mezclas   z ON z.Nombre = v.MezclaNombre
JOIN dbo.Materials m ON m.Nombre = v.MaterialNombre
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.MezclaComponentes mc
    WHERE mc.MezclaId = z.Id AND mc.MaterialId = m.Id
);
GO

------------------------------------------------------------
-- 4) VERIFICACION: mezclas con costo y CO2 por m3
------------------------------------------------------------
SELECT
    z.Nombre                                   AS Mezcla,
    z.ResistenciaMPa,
    SUM(mc.Cantidad)                           AS KgPorM3,
    SUM(mc.Cantidad * m.CostoPorKg)            AS CostoPorM3,
    SUM(mc.Cantidad * m.Co2PorKg)              AS Co2KgPorM3
FROM dbo.Mezclas z
JOIN dbo.MezclaComponentes mc ON mc.MezclaId = z.Id
JOIN dbo.Materials m          ON m.Id = mc.MaterialId
GROUP BY z.Nombre, z.ResistenciaMPa
ORDER BY z.ResistenciaMPa;
GO