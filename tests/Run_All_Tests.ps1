# ==============================================================================
# EcoMix IA — H05 Master Test Suite Orchestrator (Hardened Pre-Merge Version)
# ==============================================================================
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TargetDatabase = "EcomixIA_Trial",

    [Parameter(Mandatory = $false)]
    [switch]$SkipRestore
)

$ErrorActionPreference = "Stop"

$baseDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$backupPath = Join-Path $baseDir "database\backups\EcomixIA_pre_h05_20261120.bak"

Write-Host "================================================================================" -ForegroundColor Magenta
Write-Host "  ECOMIX IA — MASTER AUTOMATED TEST SUITE (H05-R: VERIFICACIÓN PRE-MERGE)" -ForegroundColor Magenta
Write-Host "================================================================================" -ForegroundColor Magenta

# 1. Validación de seguridad de la base de datos de ensayo
$allowedDatabases = @("EcomixIA_Trial", "EcomixIA_Test")
if ($TargetDatabase -notin $allowedDatabases) {
    Write-Error "[SEGURIDAD CRÍTICA] La base de datos objetivo '$TargetDatabase' no está en la lista blanca de bases de ensayo autorizadas ($($allowedDatabases -join ', ')). Abortando para prevenir sobreescritura destructiva."
    exit 1
}

if ($TargetDatabase -eq "EcomixIA") {
    Write-Error "[SEGURIDAD CRÍTICA] Se prohíbe explícitamente ejecutar restauraciones destructivas sobre la base principal 'EcomixIA'."
    exit 1
}

# Propagar explícitamente la base de datos de ensayo en el entorno del orquestador
$env:TARGET_DATABASE = $TargetDatabase

# 2. Verificación de existencia del respaldo base
if (!(Test-Path $backupPath)) {
    Write-Error "El archivo de respaldo '$backupPath' no existe. No se puede proceder con la restauración de la base de ensayo."
    exit 1
}

# Resolución dinámica de rutas de archivos de datos (sin rutas absolutas fijas)
$tempDir = [System.IO.Path]::GetTempPath()
$mdfPath = Join-Path $tempDir "$($TargetDatabase).mdf"
$ldfPath = Join-Path $tempDir "$($TargetDatabase)_log.ldf"

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

function Restore-TrialDatabase {
    Write-Host "`n[FLIGHT] Restaurando base de datos de ensayo '$TargetDatabase'..." -ForegroundColor Yellow
    $sqlRestore = @"
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'$TargetDatabase')
BEGIN
    ALTER DATABASE [$TargetDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
END
RESTORE DATABASE [$TargetDatabase] 
FROM DISK = N'$backupPath' 
WITH REPLACE, 
MOVE 'EcomixIA' TO N'$mdfPath', 
MOVE 'EcomixIA_log' TO N'$ldfPath';
ALTER DATABASE [$TargetDatabase] SET MULTI_USER;
"@
    $restoreOutput = & sqlcmd -S "(LocalDb)\MSSQLLocalDB" -b -Q $sqlRestore 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Fallo crítico en sqlcmd durante la restauración de ${TargetDatabase}: $restoreOutput"
        exit 1
    }
    Write-Host "[FLIGHT] '$TargetDatabase' restaurada exitosamente a estado base limpio." -ForegroundColor Green
}

# 3. Pre-flight restore
if (!$SkipRestore) {
    Restore-TrialDatabase
}

# 4. Definición de suites modulares
$testSuites = @(
    @{ Name = "Suite 01: Unit & Domain"; Script = "01_Unit_Domain_Tests.ps1" },
    @{ Name = "Suite 02: Integration EF6 & SQL"; Script = "02_Integration_EF6_Sql_Tests.ps1" },
    @{ Name = "Suite 03: HTTP & Authorization Pipeline"; Script = "03_Http_Authorization_Tests.ps1" },
    @{ Name = "Suite 04: FastAPI Contract Mocks"; Script = "04_FastApi_Contract_Mock_Tests.ps1" },
    @{ Name = "Suite 05: Security & Concurrency"; Script = "05_Security_Concurrency_Tests.ps1" },
    @{ Name = "Suite 06: Full Regression H01-H04"; Script = "06_Full_Regression_H01_H04.ps1" },
    @{ Name = "Suite 07: Real HTTP Pipeline (IIS Express)"; Script = "07_Real_Http_IisExpress_Tests.ps1" }
)

$suiteResults = @()
$allPass = $true

foreach ($suite in $testSuites) {
    Write-Host "`n--------------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ">> EJECUTANDO: $($suite.Name)" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Gray
    
    $suiteWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $scriptPath = Join-Path $PSScriptRoot $suite.Script
    
    # Propagar TargetDatabase al entorno del subproceso de prueba
    $cmd = "`$env:TARGET_DATABASE = '$TargetDatabase'; & '$scriptPath'"
    $output = & powershell -ExecutionPolicy Bypass -Command $cmd 2>&1
    $suiteWatch.Stop()
    
    $exitCode = $LASTEXITCODE
    $outputText = $output -join "`n"
    Write-Host $outputText
    
    # Extraer conteos de resumen
    $passMatches = [regex]::Match($outputText, "RESUMEN.*:\s*(\d+)\s*PASS\s*/\s*(\d+)\s*FAIL")
    $passed = 0
    $failed = 0
    $hasValidSummary = $false
    if ($passMatches.Success) {
        $passed = [int]$passMatches.Groups[1].Value
        $failed = [int]$passMatches.Groups[2].Value
        $hasValidSummary = $true
    } elseif ($exitCode -ne 0) {
        $failed = 1
    }
    
    # Validación estricta: código 0, resumen válido presente, al menos 1 prueba pasada y 0 fallidas
    $suiteSuccess = ($exitCode -eq 0 -and $hasValidSummary -and $passed -gt 0 -and $failed -eq 0)
    if (!$suiteSuccess) { $allPass = $false }
    
    $suiteResults += [PSCustomObject]@{
        Suite = $suite.Name
        Script = $suite.Script
        Passed = $passed
        Failed = $failed
        DurationSec = [Math]::Round($suiteWatch.Elapsed.TotalSeconds, 2)
        Success = $suiteSuccess
    }
}

# 5. Post-flight restore para dejar base de ensayo limpia
if (!$SkipRestore) {
    Restore-TrialDatabase
}

$stopwatch.Stop()

# 6. Generar reporte consolidado
Write-Host "`n================================================================================" -ForegroundColor Magenta
Write-Host "  RESUMEN EJECUTIVO CONSOLIDADO DE PRUEBAS H05-R" -ForegroundColor Magenta
Write-Host "================================================================================" -ForegroundColor Magenta

$totalPassed = 0
$totalFailed = 0

foreach ($sr in $suiteResults) {
    $totalPassed += $sr.Passed
    $totalFailed += $sr.Failed
    $statusColor = if ($sr.Success) { "Green" } else { "Red" }
    $statusText = if ($sr.Success) { "PASS" } else { "FAIL" }
    Write-Host ("  [{0}] {1,-38} | {2,3} PASS | {3,2} FAIL | {4,5} s" -f $statusText, $sr.Suite, $sr.Passed, $sr.Failed, $sr.DurationSec) -ForegroundColor $statusColor
}

Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Gray
$overallStatusColor = if ($allPass) { "Green" } else { "Red" }
Write-Host ("  TOTAL: {0} PASS / {1} FAIL | Tiempo Total: {2:N2} s" -f $totalPassed, $totalFailed, $stopwatch.Elapsed.TotalSeconds) -ForegroundColor $overallStatusColor
Write-Host "================================================================================" -ForegroundColor Magenta

# 7. Exportar JSON de evidencia
$summaryJson = [PSCustomObject]@{
    TimestampUtc = [DateTime]::UtcNow.ToString("o")
    Environment = "LocalDB ($TargetDatabase)"
    TotalPassed = $totalPassed
    TotalFailed = $totalFailed
    DurationSeconds = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
    AllSuitesPassed = $allPass
    Suites = $suiteResults
} | ConvertTo-Json -Depth 4

$summaryPath = Join-Path $PSScriptRoot "Test_Results_H05_Summary.json"
[System.IO.File]::WriteAllText($summaryPath, $summaryJson, [System.Text.Encoding]::UTF8)
Write-Host "`n[OK] Resumen estructurado exportado a: $summaryPath" -ForegroundColor Cyan

if (!$allPass) {
    exit 1
} else {
    exit 0
}
