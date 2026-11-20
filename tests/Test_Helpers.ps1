# ==============================================================================
# EcoMix IA — H05 Test Helpers (Modular Suite & TargetDatabase Propagation)
# ==============================================================================

$baseDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

# 1. Resolución y validación estricta de base de datos de ensayo autorizada
$targetDb = if (![string]::IsNullOrWhiteSpace($env:TARGET_DATABASE)) { $env:TARGET_DATABASE.Trim() } else { "EcomixIA_Trial" }
$allowedDatabases = @("EcomixIA_Trial", "EcomixIA_Test")

if ($targetDb -notin $allowedDatabases) {
    throw "[SEGURIDAD CRÍTICA] La base de datos '$targetDb' no está en la lista blanca de pruebas autorizadas ($($allowedDatabases -join ', ')). Abortando para proteger bases de datos productivas o principales."
}

$connStringTrial = "Server=(LocalDb)\MSSQLLocalDB;Database=$targetDb;Integrated Security=True"
$targetDbName = $targetDb

# 2. Resolver dinámico de ensamblados
[AppDomain]::CurrentDomain.add_AssemblyResolve({
    param($s, $a)
    $shortName = $a.Name.Split(',')[0].Trim()
    foreach ($asm in [AppDomain]::CurrentDomain.GetAssemblies()) {
        if ($asm.GetName().Name -eq $shortName) { return $asm }
    }
    $bin = Join-Path $baseDir "bin\$shortName.dll"
    if (Test-Path $bin) { return [System.Reflection.Assembly]::LoadFrom($bin) }
    return $null
})

# 3. Cargar dependencias esenciales
Add-Type -Path (Join-Path $baseDir 'packages\Owin.1.0\lib\net40\Owin.dll') -ErrorAction SilentlyContinue
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.Owin.4.2.2\lib\net45\Microsoft.Owin.dll') -ErrorAction SilentlyContinue
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.Owin.Security.4.2.2\lib\net45\Microsoft.Owin.Security.dll') -ErrorAction SilentlyContinue
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.Owin.Security.Cookies.4.2.2\lib\net45\Microsoft.Owin.Security.Cookies.dll') -ErrorAction SilentlyContinue
Add-Type -Path (Join-Path $baseDir 'packages\EntityFramework.6.5.1\lib\net45\EntityFramework.dll') -ErrorAction SilentlyContinue
Add-Type -Path (Join-Path $baseDir 'packages\EntityFramework.6.5.1\lib\net45\EntityFramework.SqlServer.dll') -ErrorAction SilentlyContinue
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.AspNet.Identity.Core.2.2.4\lib\net45\Microsoft.AspNet.Identity.Core.dll') -ErrorAction SilentlyContinue
Add-Type -Path (Join-Path $baseDir 'packages\Microsoft.AspNet.Identity.EntityFramework.2.2.4\lib\net45\Microsoft.AspNet.Identity.EntityFramework.dll') -ErrorAction SilentlyContinue
Add-Type -Path (Join-Path $baseDir 'packages\Newtonsoft.Json.13.0.3\lib\net45\Newtonsoft.Json.dll') -ErrorAction SilentlyContinue
Add-Type -Path (Join-Path $baseDir 'bin\EcomixIA.dll') -ErrorAction SilentlyContinue

# 4. Inicializar contexto HTTP simulado si no existe
if ([System.Web.HttpContext]::Current -eq $null) {
    $req = New-Object System.Web.HttpRequest("", "http://localhost/", "")
    $res = New-Object System.Web.HttpResponse([System.IO.TextWriter]::Null)
    $httpCtx = New-Object System.Web.HttpContext($req, $res)
    [System.Web.HttpContext]::Current = $httpCtx
}

# 5. Inicializador de controladores MVC
function Init-Controller([System.Web.Mvc.Controller]$ctrl) {
    $wrapper = New-Object System.Web.HttpContextWrapper([System.Web.HttpContext]::Current)
    $routeData = New-Object System.Web.Routing.RouteData
    $ctrl.ControllerContext = New-Object System.Web.Mvc.ControllerContext($wrapper, $routeData, $ctrl)
    $ctrl.TempData = New-Object System.Web.Mvc.TempDataDictionary
}

# 6. Funciones de aserción y conteo
$global:passedTests = 0
$global:failedTests = 0

function Assert-Test([string]$testName, [bool]$condition, [string]$detail) {
    if ($condition) {
        $global:passedTests++
        Write-Host " [PASS] $testName" -ForegroundColor Green
        if ($detail) { Write-Host "        $detail" -ForegroundColor Gray }
    } else {
        $global:failedTests++
        Write-Host " [FAIL] $testName" -ForegroundColor Red
        if ($detail) { Write-Host "        $detail" -ForegroundColor Yellow }
    }
}

# 7. Utilidades SQL Server vinculadas estrictamente a TargetDatabase
function Query-SqlScalar([string]$sql) {
    $conn = New-Object System.Data.SqlClient.SqlConnection($connStringTrial)
    $conn.Open()
    try {
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $sql
        return $cmd.ExecuteScalar()
    } finally {
        $conn.Close()
    }
}

function Query-SqlList([string]$sql) {
    $conn = New-Object System.Data.SqlClient.SqlConnection($connStringTrial)
    $conn.Open()
    $list = New-Object System.Collections.Generic.List[string]
    try {
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $sql
        $reader = $cmd.ExecuteReader()
        while ($reader.Read()) {
            $list.Add($reader[0].ToString())
        }
        $reader.Close()
        return $list
    } finally {
        $conn.Close()
    }
}

function Execute-SqlNonQuery([string]$sql) {
    $conn = New-Object System.Data.SqlClient.SqlConnection($connStringTrial)
    $conn.Open()
    try {
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = $sql
        return $cmd.ExecuteNonQuery()
    } finally {
        $conn.Close()
    }
}
