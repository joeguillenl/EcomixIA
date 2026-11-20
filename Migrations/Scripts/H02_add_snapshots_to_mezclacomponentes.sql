-- ============================================================================
-- ECOMIX IA — MIGRACIÓN ADITIVA H02: SNAPSHOTS HISTÓRICOS EN MEZCLACOMPONENTES
-- Requerimientos: RF-14, RF-15, D-09 (Snapshots históricos inmutables)
-- ============================================================================

-- 1. Agregar columnas si no existen
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.MezclaComponentes') AND name = 'CostoPorKgGuardado')
BEGIN
    ALTER TABLE dbo.MezclaComponentes ADD CostoPorKgGuardado DECIMAL(18, 6) NULL;
    PRINT 'Columna [CostoPorKgGuardado] DECIMAL(18,6) agregada a [dbo].[MezclaComponentes].';
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.MezclaComponentes') AND name = 'Co2PorKgGuardado')
BEGIN
    ALTER TABLE dbo.MezclaComponentes ADD Co2PorKgGuardado DECIMAL(18, 6) NULL;
    PRINT 'Columna [Co2PorKgGuardado] DECIMAL(18,6) agregada a [dbo].[MezclaComponentes].';
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.MezclaComponentes') AND name = 'FechaSnapshotUtc')
BEGIN
    ALTER TABLE dbo.MezclaComponentes ADD FechaSnapshotUtc DATETIME2 NULL;
    PRINT 'Columna [FechaSnapshotUtc] DATETIME2 agregada a [dbo].[MezclaComponentes].';
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.MezclaComponentes') AND name = 'OrigenSnapshot')
BEGIN
    ALTER TABLE dbo.MezclaComponentes ADD OrigenSnapshot NVARCHAR(24) NULL;
    PRINT 'Columna [OrigenSnapshot] NVARCHAR(24) agregada a [dbo].[MezclaComponentes].';
END;
GO

-- 2. Clasificar registros preexistentes como LEGADO_SIN_VERIFICAR
-- Precios, emisiones y fechas históricas no verificadas permanecen estrictamente NULL
UPDATE dbo.MezclaComponentes
SET OrigenSnapshot = 'LEGADO_SIN_VERIFICAR'
WHERE OrigenSnapshot IS NULL;
GO

PRINT 'Migración H02 ejecutada exitosamente.';
