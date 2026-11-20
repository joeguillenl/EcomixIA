-- ============================================================================
-- ECOMIX IA — ROLLBACK MIGRACIÓN H02: REVERTIR SNAPSHOTS EN MEZCLACOMPONENTES
-- ============================================================================

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.MezclaComponentes') AND name = 'OrigenSnapshot')
BEGIN
    ALTER TABLE dbo.MezclaComponentes DROP COLUMN OrigenSnapshot;
    PRINT 'Columna [OrigenSnapshot] eliminada de [dbo].[MezclaComponentes].';
END;
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.MezclaComponentes') AND name = 'FechaSnapshotUtc')
BEGIN
    ALTER TABLE dbo.MezclaComponentes DROP COLUMN FechaSnapshotUtc;
    PRINT 'Columna [FechaSnapshotUtc] eliminada de [dbo].[MezclaComponentes].';
END;
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.MezclaComponentes') AND name = 'Co2PorKgGuardado')
BEGIN
    ALTER TABLE dbo.MezclaComponentes DROP COLUMN Co2PorKgGuardado;
    PRINT 'Columna [Co2PorKgGuardado] eliminada de [dbo].[MezclaComponentes].';
END;
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.MezclaComponentes') AND name = 'CostoPorKgGuardado')
BEGIN
    ALTER TABLE dbo.MezclaComponentes DROP COLUMN CostoPorKgGuardado;
    PRINT 'Columna [CostoPorKgGuardado] eliminada de [dbo].[MezclaComponentes].';
END;
GO

PRINT 'Rollback H02 ejecutado exitosamente.';
