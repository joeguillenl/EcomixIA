# ==============================================================================
# EcoMix IA — H05 Master Test Suite Orchestrator
# ==============================================================================

$baseDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$backupPath = Join-Path $baseDir "database\backups\EcomixIA_pre_h05_20261120.bak"

Write-Host "================================================================================" -ForegroundColor Magenta
Write-Host "  ECOMIX IA — MASTER AUTOMATED TEST SUITE (H05: AUDITORÍA Y REMEDIACIÓN)" -ForegroundColor Magenta
Write-Host "================================================================================" -ForegroundColor Magenta

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

function Restore-TrialDatabase {
    Write-Host "`n[PRE-FLIGHT] Restaurando base de datos de ensayo 'EcomixIA_Trial'..." -ForegroundColor Yellow
    $sqlRestore = @"
ALTER DATABASE [EcomixIA_Trial] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [EcomixIA_Trial] 
FROM DISK = N'$backupPath' 
WITH REPLACE, 
MOVE 'EcomixIA' TO 'C:\Users\Admin\EcomixIA_Trial.mdf', 
MOVE 'EcomixIA_log' TO 'C:\Users\Admin\EcomixIA_Trial_log.ldf';
ALTER DATABASE [EcomixIA_Trial] SET MULTI_USER;
"@
    sqlcmd -S "(LocalDb)\MSSQLLocalDB" -Q $sqlRestore | Out-Null
    Write-Host "[PRE-FLIGHT] 'EcomixIA_Trial' restaurada exitosamente a estado base limpio." -ForegroundColor Green
}

# 1. Pre-flight restore
Restore-TrialDatabase

# 2. Definición de suites modulares
$testSuites = @(
    @{ Name = "Suite 01: Unit & Domain"; Script = "01_Unit_Domain_Tests.ps1" },
    @{ Name = "Suite 02: Integration EF6 & SQL"; Script = "02_Integration_EF6_Sql_Tests.ps1" },
    @{ Name = "Suite 03: HTTP & Authorization"; Script = "03_Http_Authorization_Tests.ps1" },
    @{ Name = "Suite 04: FastAPI Contract Mocks"; Script = "04_FastApi_Contract_Mock_Tests.ps1" },
    @{ Name = "Suite 05: Security & Concurrency"; Script = "05_Security_Concurrency_Tests.ps1" },
    @{ Name = "Suite 06: Full Regression H01-H04"; Script = "06_Full_Regression_H01_H04.ps1" }
)

$suiteResults = @()
$allPass = $true

foreach ($suite in $testSuites) {
    Write-Host "`n--------------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ">> EJECUTANDO: $($suite.Name)" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Gray
    
    $suiteWatch = [System.Diagnostics.Stopwatch]::StartNew()
    $scriptPath = Join-Path $PSScriptRoot $suite.Script
    
    $output = & powershell -ExecutionPolicy Bypass -File $scriptPath 2>&1
    $suiteWatch.Stop()
    
    $exitCode = $LASTEXITCODE
    $outputText = $output -join "`n"
    Write-Host $outputText
    
    # Extraer conteos de resumen
    $passMatches = [regex]::Match($outputText, "RESUMEN.*:\s*(\d+)\s*PASS\s*/\s*(\d+)\s*FAIL")
    $passed = 0
    $failed = 0
    if ($passMatches.Success) {
        $passed = [int]$passMatches.Groups[1].Value
        $failed = [int]$passMatches.Groups[2].Value
    } elseif ($exitCode -ne 0) {
        $failed = 1
    }
    
    $suiteSuccess = ($exitCode -eq 0 -and $failed -eq 0)
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

# 3. Post-flight restore para dejar EcomixIA_Trial limpia
Restore-TrialDatabase

$stopwatch.Stop()

# 4. Generar reporte consolidado
Write-Host "`n================================================================================" -ForegroundColor Magenta
Write-Host "  RESUMEN EJECUTIVO CONSOLIDADO DE PRUEBAS H05" -ForegroundColor Magenta
Write-Host "================================================================================" -ForegroundColor Magenta

$totalPassed = 0
$totalFailed = 0

foreach ($sr in $suiteResults) {
    $totalPassed += $sr.Passed
    $totalFailed += $sr.Failed
    $statusColor = if ($sr.Success) { "Green" } else { "Red" }
    $statusText = if ($sr.Success) { "PASS" } else { "FAIL" }
    Write-Host ("  [{0}] {1,-35} | {2,3} PASS | {3,2} FAIL | {4,5} s" -f $statusText, $sr.Suite, $sr.Passed, $sr.Failed, $sr.DurationSec) -ForegroundColor $statusColor
}

Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Gray
$overallStatusColor = if ($allPass) { "Green" } else { "Red" }
Write-Host ("  TOTAL: {0} PASS / {1} FAIL | Tiempo Total: {2:N2} s" -f $totalPassed, $totalFailed, $stopwatch.Elapsed.TotalSeconds) -ForegroundColor $overallStatusColor
Write-Host "================================================================================" -ForegroundColor Magenta

# 5. Exportar JSON de evidencia
$summaryJson = [PSCustomObject]@{
    TimestampUtc = [DateTime]::UtcNow.ToString("o")
    Environment = "LocalDB (EcomixIA_Trial)"
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
