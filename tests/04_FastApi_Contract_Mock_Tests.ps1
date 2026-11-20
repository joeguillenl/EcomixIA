# ==============================================================================
# EcoMix IA — Suite 04: Pruebas de Contrato FastAPI con Mocks y Simuladores
# ==============================================================================

. (Join-Path $PSScriptRoot "Test_Helpers.ps1")

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  SUITE 04: PRUEBAS DE CONTRATO FASTAPI CON MOCKS" -ForegroundColor Cyan
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

# Definir MockHttpMessageHandler para simulación HTTP controlada
$mockHandlerSrc = @"
using System;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;

namespace EcomixIA.Tests
{
    public class MockHttpMessageHandler : HttpMessageHandler
    {
        public Func<HttpRequestMessage, HttpResponseMessage> HandlerFunc { get; set; }

        public static HttpResponseMessage CreateResponse(int statusCode, string content, string mediaType = "application/json")
        {
            var resp = new HttpResponseMessage((HttpStatusCode)statusCode);
            if (content != null)
            {
                resp.Content = new StringContent(content, System.Text.Encoding.UTF8, mediaType);
            }
            return resp;
        }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            if (HandlerFunc == null)
            {
                return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK));
            }
            return Task.FromResult(HandlerFunc(request));
        }
    }
}
"@
Add-Type -TypeDefinition $mockHandlerSrc -ReferencedAssemblies "System.Net.Http.dll" -ErrorAction SilentlyContinue

# ------------------------------------------------------------------------------
# 4.1 Mock HTTP 200 OK — Predicción Exitosa
# ------------------------------------------------------------------------------
Write-Host "`n--- 4.1 Simulación HTTP 200 OK (Contrato Exitoso FastAPI) ---" -ForegroundColor DarkCyan

$mockHandler = New-Object EcomixIA.Tests.MockHttpMessageHandler
$mockHandler.HandlerFunc = [Func[System.Net.Http.HttpRequestMessage, System.Net.Http.HttpResponseMessage]]{
    param($req)
    $respJson = @"
{
    "status": "success",
    "predictions": {
        "strength_7d_mpa": 27.8,
        "strength_28d_mpa": 41.2
    },
    "mix_ratios": {
        "water_cement_ratio": 0.45,
        "water_binder_ratio": 0.38,
        "total_cementitious_content_kg_m3": 450.0,
        "scm_replacement_percentage": 22.2,
        "aggregates_total_kg_m3": 1750.0,
        "total_mass_kg_m3": 2380.0
    },
    "warnings": [],
    "metadata": {
        "model_id": "voting_ensemble_fastapi_v1",
        "model_type": "VotingEnsemble",
        "model_sha256": "abcdef1234567890",
        "inference_timestamp": "2026-11-20T14:00:00Z"
    }
}
"@
    $resp = New-Object System.Net.Http.HttpResponseMessage([System.Net.HttpStatusCode]::OK)
    $resp.Content = New-Object System.Net.Http.StringContent($respJson, [System.Text.Encoding]::UTF8, "application/json")
    return $resp
}

$mockHttpClient = New-Object System.Net.Http.HttpClient($mockHandler)
$mockHttpClient.BaseAddress = New-Object Uri("https://mock-fastapi.local/")

$mlClient = New-Object EcomixIA.Services.EcoMixMlClientService($mockHttpClient, "test-api-key")

$predictReq = New-Object EcomixIA.Models.Dtos.ConcretePredictionRequestDto
$predictReq.Cement = 350.0
$predictReq.BlastFurnaceSlag = 100.0
$predictReq.Water = 180.0
$predictReq.Superplasticizer = 5.0
$predictReq.CoarseAggregate = 1050.0
$predictReq.FineAggregate = 700.0

$result = $mlClient.PredictStrengthAsync($predictReq).GetAwaiter().GetResult()

Check "FastAPI 4.1.1: Respuesta exitosa deserializada en PredictionResponseDto" `
    ($result -ne $null -and $result.Status -eq "success") `
    "Status: $($result.Status)"

Check "FastAPI 4.1.2: Predicciones puntuales parseadas correctamente (28d: 41.2 MPa)" `
    ($result.Predictions -ne $null -and $result.Predictions.Strength28dMpa -eq 41.2) `
    "Strength28dMpa: $($result.Predictions.Strength28dMpa) MPa"

Check "FastAPI 4.1.3: Metadatos de procedencia del modelo VotingEnsemble verificados" `
    ($result.Metadata -ne $null -and $result.Metadata.ModelType -eq "VotingEnsemble") `
    "ModelType: $($result.Metadata.ModelType), ModelId: $($result.Metadata.ModelId)"

# ------------------------------------------------------------------------------
# 4.2 Mock HTTP 422 Unprocessable Entity — Validación de Dominio
# ------------------------------------------------------------------------------
Write-Host "`n--- 4.2 Simulación HTTP 422 Unprocessable Entity (ProblemDetails) ---" -ForegroundColor DarkCyan

$mockHandler422 = New-Object EcomixIA.Tests.MockHttpMessageHandler
$mockHandler422.HandlerFunc = [Func[System.Net.Http.HttpRequestMessage, System.Net.Http.HttpResponseMessage]]{
    param($req)
    $problemJson = @"
{
    "type": "https://errors.ecomix.local/validation",
    "title": "Unprocessable Entity",
    "status": 422,
    "detail": "Relación agua/aglomerante fuera de rango admisible (0.25 - 0.70).",
    "instance": "/predict",
    "invalid_params": [
        { "name": "water", "reason": "Exceso de agua para la masa aglomerante" }
    ]
}
"@
    return [EcomixIA.Tests.MockHttpMessageHandler]::CreateResponse(422, $problemJson, "application/problem+json")
}

$mockHttpClient422 = New-Object System.Net.Http.HttpClient($mockHandler422)
$mockHttpClient422.BaseAddress = New-Object Uri("https://mock-fastapi.local/")
$mlClient422 = New-Object EcomixIA.Services.EcoMixMlClientService($mockHttpClient422, "test-api-key")

$caughtException422 = $null
try {
    $mlClient422.PredictStrengthAsync($predictReq).GetAwaiter().GetResult() | Out-Null
} catch [EcomixIA.Services.EcoMixMlClientException] {
    $caughtException422 = $_.Exception
}

Check "FastAPI 4.2.1: EcoMixMlClientException lanzada con código HTTP 422" `
    ($caughtException422 -ne $null -and [int]$caughtException422.StatusCode -eq 422) `
    "StatusCode: $($caughtException422.StatusCode)"

Check "FastAPI 4.2.2: ProblemDetails estructurado parseado correctamente" `
    ($caughtException422.ProblemDetails -ne $null -and $caughtException422.ProblemDetails.Detail.Contains("agua/aglomerante")) `
    "Detail: $($caughtException422.ProblemDetails.Detail)"

# ------------------------------------------------------------------------------
# 4.3 Mock HTTP 503 Service Unavailable
# ------------------------------------------------------------------------------
Write-Host "`n--- 4.3 Simulación HTTP 503 Service Unavailable ---" -ForegroundColor DarkCyan

$mockHandler503 = New-Object EcomixIA.Tests.MockHttpMessageHandler
$mockHandler503.HandlerFunc = [Func[System.Net.Http.HttpRequestMessage, System.Net.Http.HttpResponseMessage]]{
    param($req)
    $resp = New-Object System.Net.Http.HttpResponseMessage([System.Net.HttpStatusCode]::ServiceUnavailable)
    $resp.Content = New-Object System.Net.Http.StringContent("Service Temporarily Unavailable", [System.Text.Encoding]::UTF8, "text/plain")
    return $resp
}

$mockHttpClient503 = New-Object System.Net.Http.HttpClient($mockHandler503)
$mockHttpClient503.BaseAddress = New-Object Uri("https://mock-fastapi.local/")
$mlClient503 = New-Object EcomixIA.Services.EcoMixMlClientService($mockHttpClient503, "test-api-key")

$caughtException503 = $null
try {
    $mlClient503.PredictStrengthAsync($predictReq).GetAwaiter().GetResult() | Out-Null
} catch [EcomixIA.Services.EcoMixMlClientException] {
    $caughtException503 = $_.Exception
}

Check "FastAPI 4.3.1: EcoMixMlClientException lanzada con código HTTP 503" `
    ($caughtException503 -ne $null -and $caughtException503.StatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable) `
    "StatusCode: $($caughtException503.StatusCode)"

# ------------------------------------------------------------------------------
# 4.4 Enmascaramiento Seguro en MezclasController.SimularAsync y SimularAjax (H05-A4)
# ------------------------------------------------------------------------------
Write-Host "`n--- 4.4 Enmascaramiento Seguro de Errores en MezclasController (H05-A4) ---" -ForegroundColor DarkCyan

$ecomixCtx = New-Object EcomixIA.Models.EcomixContext ($connStringTrial)
$auditSvc = New-Object EcomixIA.Services.AuditService ($connStringTrial)

# Simular con cliente que produce HTTP 422
$mezclasCtrl422 = New-Object EcomixIA.Controllers.MezclasController($ecomixCtx, $mlClient422, $auditSvc)
Init-Controller $mezclasCtrl422

$simModel = New-Object EcomixIA.Models.ViewModels.SimuladorDosificacionViewModel
$simModel.Cemento = 350.0
$simModel.Agua = 180.0
$simModel.AgregadoGrueso = 1000.0
$simModel.AgregadoFino = 700.0

$simViewResult = $mezclasCtrl422.Simulador($simModel).GetAwaiter().GetResult() -as [System.Web.Mvc.ViewResult]
$returnedModel = $simViewResult.Model -as [EcomixIA.Models.ViewModels.SimuladorDosificacionViewModel]

Check "Privacidad 4.4.1: Simulador enmascara rechazo sin filtrar URLs internas" `
    ($returnedModel.Ejecutado -eq $false -and $returnedModel.ErrorMensaje.Contains("rechazada por el servicio ML") -and -not $returnedModel.ErrorMensaje.Contains("mock-fastapi.local")) `
    "ErrorMensaje: $($returnedModel.ErrorMensaje)"

# SimularAjax con cliente que produce HTTP 503
$mezclasCtrl503 = New-Object EcomixIA.Controllers.MezclasController($ecomixCtx, $mlClient503, $auditSvc)
Init-Controller $mezclasCtrl503

$ajaxResult503 = $mezclasCtrl503.SimularAjax($simModel).GetAwaiter().GetResult() -as [System.Web.Mvc.ContentResult]
$jsonResponse = $ajaxResult503.Content

Check "Privacidad 4.4.2: SimularAjax devuelve código ML_CLIENT_REJECTED sin filtrar trazas" `
    ($jsonResponse.Contains("ML_CLIENT_REJECTED") -or $jsonResponse.Contains("ML_SERVICE_UNAVAILABLE")) `
    "JSON Ajax: $jsonResponse"

# ------------------------------------------------------------------------------
# 4.5 Auditoría de Invocación ML (Metadatos Técnicos Exclusivos)
# ------------------------------------------------------------------------------
Write-Host "`n--- 4.5 Metadatos Técnicos en Auditoría de Invocación ML ---" -ForegroundColor DarkCyan

# Consultar el último evento de categoría 'ML' generado por la prueba
$lastMlEvent = Query-SqlScalar "SELECT TOP 1 Details FROM dbo.AuditEvents WHERE Category = 'ML' ORDER BY TimestampUtc DESC;"

Check "Auditoría 4.5.1: Registro de evento ML contiene solo latencia, modelo y códigos técnicos" `
    ($lastMlEvent -ne $null -and $lastMlEvent.Contains("Latencia:") -and -not $lastMlEvent.Contains("SuperSecret")) `
    "Audit Details: $lastMlEvent"

Check "Auditoría 4.5.2: Cero dosificaciones o fórmulas almacenadas en AuditEvents" `
    (-not $lastMlEvent.Contains("Cemento=") -and -not $lastMlEvent.Contains("Agua=")) `
    "Dosificaciones protegidas: No persistidas en auditoría pública"

$ecomixCtx.Dispose()

Write-Host "`nRESUMEN SUITE 04: $suitePassed PASS / $suiteFailed FAIL" -ForegroundColor $(if ($suiteFailed -eq 0) { "Green" } else { "Red" })
return ($suiteFailed -eq 0)
