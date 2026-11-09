-- Rollback: RemoveOwnerUserIdFromMezcla
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_dbo_Mezclas_dbo_AspNetUsers_OwnerUserId')
BEGIN
    ALTER TABLE dbo.Mezclas DROP CONSTRAINT FK_dbo_Mezclas_dbo_AspNetUsers_OwnerUserId;
END;

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Mezclas_OwnerUserId' AND object_id = OBJECT_ID('dbo.Mezclas'))
BEGIN
    DROP INDEX IX_Mezclas_OwnerUserId ON dbo.Mezclas;
END;

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Mezclas') AND name = 'OwnerUserId')
BEGIN
    ALTER TABLE dbo.Mezclas DROP COLUMN OwnerUserId;
END;
PRINT 'Rollback executed successfully.';
