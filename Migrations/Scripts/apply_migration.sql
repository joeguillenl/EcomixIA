-- Migration: AddOwnerUserIdToMezcla
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Mezclas') AND name = 'OwnerUserId')
BEGIN
    ALTER TABLE dbo.Mezclas ADD OwnerUserId NVARCHAR(128) NULL;
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Mezclas_OwnerUserId' AND object_id = OBJECT_ID('dbo.Mezclas'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Mezclas_OwnerUserId ON dbo.Mezclas(OwnerUserId);
END;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_dbo_Mezclas_dbo_AspNetUsers_OwnerUserId')
BEGIN
    ALTER TABLE dbo.Mezclas ADD CONSTRAINT FK_dbo_Mezclas_dbo_AspNetUsers_OwnerUserId FOREIGN KEY (OwnerUserId) REFERENCES dbo.AspNetUsers(Id);
END;
PRINT 'DDL Migration AddOwnerUserIdToMezcla executed successfully.';
