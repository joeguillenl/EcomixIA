# ==============================================================================
# EcoMix IA — Suite 02: Pruebas de Integración EF6 y SQL Server
# ==============================================================================

. (Join-Path $PSScriptRoot "Test_Helpers.ps1")

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  SUITE 02: PRUEBAS DE INTEGRACIÓN EF6 Y SQL SERVER" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$suitePassed = 0
$suiteFailed = 0

function Check([string]$name, [bool]$cond, [string]$detail) {
    if ($cond) {
        $global:passedTests++
        $script:suitePassed++
        Write-Host " [PASS] $name" -ForegroundColor Green
        if ($detail) { Write-Host "        $detail" -ForegroundColor Gray }
    } else {
        $global:failedTests++
        $script:suiteFailed++
        Write-Host " [FAIL] $name" -ForegroundColor Red
        if ($detail) { Write-Host "        $detail" -ForegroundColor Yellow }
    }
}

# ------------------------------------------------------------------------------
# 2.1 Verificación de Esquema Global en EcomixIA_Trial
# ------------------------------------------------------------------------------
Write-Host "`n--- 2.1 Esquema Global y Tablas en EcomixIA_Trial ---" -ForegroundColor DarkCyan

$tables = Query-SqlList "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';"
$requiredTables = @("Materials", "Mezclas", "MezclaComponentes", "AuditEvents", "AspNetUsers", "AspNetRoles", "AspNetUserRoles")

$allTablesPresent = $true
foreach ($tbl in $requiredTables) {
    if (-not $tables.Contains($tbl)) {
        $allTablesPresent = $false
        Write-Host "    Falta tabla requerida: $tbl" -ForegroundColor Red
    }
}

Check "Esquema 2.1.1: Todas las tablas del modelo existen en EcomixIA_Trial" `
    $allTablesPresent `
    "Tablas encontradas: $($tables.Count)"

# ------------------------------------------------------------------------------
# 2.2 Columnas de Snapshot Histórico en MezclaComponentes (H02 / RF-14 / RF-15)
# ------------------------------------------------------------------------------
Write-Host "`n--- 2.2 Snapshots Históricos en MezclaComponentes (H02) ---" -ForegroundColor DarkCyan

$snapCols = Query-SqlList "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MezclaComponentes';"
$hasCosto = $snapCols.Contains("CostoPorKgGuardado")
$hasCo2 = $snapCols.Contains("Co2PorKgGuardado")
$hasFecha = $snapCols.Contains("FechaSnapshotUtc")
$hasOrigen = $snapCols.Contains("OrigenSnapshot")

Check "Snapshots 2.2.1: Columnas de snapshot persistidas en MezclaComponentes" `
    ($hasCosto -and $hasCo2 -and $hasFecha -and $hasOrigen) `
    "CostoPorKgGuardado, Co2PorKgGuardado, FechaSnapshotUtc, OrigenSnapshot presentes"

# ------------------------------------------------------------------------------
# 2.3 Tabla e Índices de Auditoría (H04 / RF-49)
# ------------------------------------------------------------------------------
Write-Host "`n--- 2.3 Esquema e Índices de AuditEvents ---" -ForegroundColor DarkCyan

$auditCols = Query-SqlList "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'AuditEvents';"
$hasTimestamp = $auditCols.Contains("TimestampUtc")
$hasCategory = $auditCols.Contains("Category")
$hasAction = $auditCols.Contains("Action")
$hasSuccess = $auditCols.Contains("Success")
$hasDetails = $auditCols.Contains("Details")

$indexCount = Query-SqlScalar "SELECT COUNT(*) FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.AuditEvents') AND name = 'IX_AuditEvents_TimestampUtc';"

Check "Auditoría 2.3.1: Columnas requeridas presentes en AuditEvents" `
    ($hasTimestamp -and $hasCategory -and $hasAction -and $hasSuccess -and $hasDetails) `
    "Columnas: TimestampUtc, Category, Action, Success, Details"

Check "Auditoría 2.3.2: Índice IX_AuditEvents_TimestampUtc presente para optimización de retención" `
    ([int]$indexCount -ge 1) `
    "Índice IX_AuditEvents_TimestampUtc activo"

# ------------------------------------------------------------------------------
# 2.4 Política de Retención Estricta de 30 Días (D-07 / RF-49 / H05-A5)
# ------------------------------------------------------------------------------
Write-Host "`n--- 2.4 Filtro de Retención de 30 Días (AuditService.GetActiveEvents) ---" -ForegroundColor DarkCyan

# Insertar dos registros de prueba: uno con 29 días (dentro de retención) y uno con 31 días (fuera)
$idDentro = [Guid]::NewGuid().ToString("N")
$idFuera = [Guid]::NewGuid().ToString("N")

$sqlInsertAudit = @"
INSERT INTO [dbo].[AuditEvents] ([Category], [Action], [Success], [Details], [CorrelationId], [TimestampUtc])
VALUES 
('TestRetencion', 'Dentro30Dias', 1, 'Evento con 29 días de antigüedad', '$idDentro', DATEADD(DAY, -29, GETUTCDATE())),
('TestRetencion', 'Fuera30Dias', 1, 'Evento con 31 días de antigüedad', '$idFuera', DATEADD(DAY, -31, GETUTCDATE()));
"@
Execute-SqlNonQuery $sqlInsertAudit | Out-Null

$auditService = New-Object EcomixIA.Services.AuditService ($connStringTrial)
$activeEventsDb = New-Object EcomixIA.Models.ApplicationDbContext($connStringTrial)

$activeEvents = $auditService.GetActiveEvents($activeEventsDb, $null)

$containsDentro = $false
$containsFuera = $false

foreach ($ev in $activeEvents) {
    if ($ev.CorrelationId -eq $idDentro) { $containsDentro = $true }
    if ($ev.CorrelationId -eq $idFuera) { $containsFuera = $true }
}

Check "Retención 2.4.1: Evento de 29 días incluido en consulta activa (<30 días)" `
    ($containsDentro -eq $true) `
    "CorrelationId: $idDentro presente"

Check "Retención 2.4.2: Evento de 31 días estrictamente excluido de consulta activa (>30 días)" `
    ($containsFuera -eq $false) `
    "CorrelationId: $idFuera filtrado"

$activeEventsDb.Dispose()

# ------------------------------------------------------------------------------
# 2.5 Depuración Física Idempotente (PurgeExpiredEventsAsync)
# ------------------------------------------------------------------------------
Write-Host "`n--- 2.5 Depuración Física Idempotente (PurgeExpiredEventsAsync) ---" -ForegroundColor DarkCyan

# Insertar un evento expirado (>35 días) específico para probar la depuración física manual
$idFueraManual = [Guid]::NewGuid().ToString("N")
Execute-SqlNonQuery "INSERT INTO [dbo].[AuditEvents] ([Category], [Action], [Success], [Details], [CorrelationId], [TimestampUtc]) VALUES ('TestPurge', 'ExpiradoManual', 1, 'Prueba de purga manual', '$idFueraManual', DATEADD(DAY, -35, GETUTCDATE()));" | Out-Null

$initialUserCount = [int](Query-SqlScalar "SELECT COUNT(*) FROM dbo.AspNetUsers")
$initialMixCount = [int](Query-SqlScalar "SELECT COUNT(*) FROM dbo.Mezclas")
$initialMatCount = [int](Query-SqlScalar "SELECT COUNT(*) FROM dbo.Materials")
$initialSnapCount = [int](Query-SqlScalar "SELECT COUNT(*) FROM dbo.MezclaComponentes WHERE CostoPorKgGuardado IS NOT NULL")

# Ejecutar purga física manual
$purgeDb = New-Object EcomixIA.Models.ApplicationDbContext($connStringTrial)
$purgedCount = $auditService.PurgeExpiredEventsAsync($purgeDb, 500, $null).GetAwaiter().GetResult()
$purgeDb.Dispose()

$postUserCount = [int](Query-SqlScalar "SELECT COUNT(*) FROM dbo.AspNetUsers")
$postMixCount = [int](Query-SqlScalar "SELECT COUNT(*) FROM dbo.Mezclas")
$postMatCount = [int](Query-SqlScalar "SELECT COUNT(*) FROM dbo.Materials")
$postSnapCount = [int](Query-SqlScalar "SELECT COUNT(*) FROM dbo.MezclaComponentes WHERE CostoPorKgGuardado IS NOT NULL")

$eventManualStillExists = [int](Query-SqlScalar "SELECT COUNT(*) FROM dbo.AuditEvents WHERE CorrelationId = '$idFueraManual'")
$eventDentroStillExists = [int](Query-SqlScalar "SELECT COUNT(*) FROM dbo.AuditEvents WHERE CorrelationId = '$idDentro'")

Check "Depuración 2.5.1: Registros caducados eliminados físicamente de la base de datos" `
    ($eventManualStillExists -eq 0 -and $purgedCount -ge 1) `
    "Registros depurados: $purgedCount"

Check "Depuración 2.5.2: Registros dentro del plazo de 30 días preservados intactos" `
    ($eventDentroStillExists -eq 1) `
    "Evento de 29 días conservado"

Check "Depuración 2.5.3: Integridad referencial absoluta (usuarios, mezclas, materiales y snapshots inalterados)" `
    ($initialUserCount -eq $postUserCount -and $initialMixCount -eq $postMixCount -and $initialMatCount -eq $postMatCount -and $initialSnapCount -eq $postSnapCount) `
    "Usuarios: $postUserCount, Mezclas: $postMixCount, Materiales: $postMatCount, Snapshots: $postSnapCount"

# Limpieza del evento de prueba dentro
Execute-SqlNonQuery "DELETE FROM dbo.AuditEvents WHERE CorrelationId = '$idDentro';" | Out-Null

Write-Host "`nRESUMEN SUITE 02: $suitePassed PASS / $suiteFailed FAIL" -ForegroundColor $(if ($suiteFailed -eq 0) { "Green" } else { "Red" })
return ($suiteFailed -eq 0)
