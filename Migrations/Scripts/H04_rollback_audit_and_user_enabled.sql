-- ==============================================================================
-- ECOMIX IA — REVERSIÓN DE MIGRACIÓN H04 (ROLLBACK)
-- Eliminación segura de AuditEvents y de columna IsEnabled en AspNetUsers
-- NOTA DE IMPACTO: La reversión elimina físicamente el historial de auditoría.
-- ==============================================================================

SET NOCOUNT ON;

-- 1. Eliminar tabla AuditEvents e índices asociados
IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'AuditEvents'
)
BEGIN
    PRINT 'Eliminando tabla AuditEvents...';
    DROP TABLE [dbo].[AuditEvents];
    PRINT 'Tabla AuditEvents eliminada exitosamente.';
END
GO

-- 2. Eliminar columna IsEnabled y su restricción por defecto en AspNetUsers
IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'AspNetUsers' AND COLUMN_NAME = 'IsEnabled'
)
BEGIN
    PRINT 'Eliminando restricción y columna IsEnabled de AspNetUsers...';
    
    DECLARE @defConstraint NVARCHAR(256);
    SELECT @defConstraint = d.name
    FROM sys.default_constraints d
    INNER JOIN sys.columns c ON d.parent_column_id = c.column_id AND d.parent_object_id = c.object_id
    WHERE c.name = 'IsEnabled' AND d.parent_object_id = OBJECT_ID('dbo.AspNetUsers');

    IF @defConstraint IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE [dbo].[AspNetUsers] DROP CONSTRAINT [' + @defConstraint + ']');
        PRINT 'Restricción por defecto ' + @defConstraint + ' eliminada.';
    END

    ALTER TABLE [dbo].[AspNetUsers] DROP COLUMN [IsEnabled];
    PRINT 'Columna IsEnabled eliminada de AspNetUsers exitosamente.';
END
GO
