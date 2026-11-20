# ==============================================================================
# EcoMix IA — Suite 01: Pruebas Unitarias de Dominio y Servicios
# ==============================================================================

. (Join-Path $PSScriptRoot "Test_Helpers.ps1")

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  SUITE 01: PRUEBAS UNITARIAS DE DOMINIO Y SERVICIOS" -ForegroundColor Cyan
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
# 1.1 DTOs de Predicción ML
# ------------------------------------------------------------------------------
Write-Host "`n--- 1.1 DTOs de Predicción ML ---" -ForegroundColor DarkCyan

$reqDto = New-Object EcomixIA.Models.Dtos.ConcretePredictionRequestDto
$reqDto.Cement = 350.0
$reqDto.BlastFurnaceSlag = 100.0
$reqDto.FlyAsh = 50.0
$reqDto.Water = 180.0
$reqDto.Superplasticizer = 5.0
$reqDto.CoarseAggregate = 1000.0
$reqDto.FineAggregate = 700.0

$jsonReq = [Newtonsoft.Json.JsonConvert]::SerializeObject($reqDto)
$deserializedReq = [Newtonsoft.Json.JsonConvert]::DeserializeObject($jsonReq, [type][EcomixIA.Models.Dtos.ConcretePredictionRequestDto])

Check "DTO 1.1.1: Serialización y deserialización de ConcretePredictionRequestDto" `
    ($deserializedReq.Cement -eq 350.0 -and $deserializedReq.Water -eq 180.0) `
    "Cement: $($deserializedReq.Cement) kg/m³, Water: $($deserializedReq.Water) kg/m³"

$respDto = New-Object EcomixIA.Models.Dtos.PredictionResponseDto
$respDto.Status = "success"
$respDto.Predictions = New-Object EcomixIA.Models.Dtos.PredictionValuesDto
$respDto.Predictions.Strength7dMpa = [decimal]28.5
$respDto.Predictions.Strength28dMpa = [decimal]42.5

$respDto.Metadata = New-Object EcomixIA.Models.Dtos.PredictionMetadataDto
$respDto.Metadata.ModelType = "VotingEnsemble"
$respDto.Metadata.ModelId = "voting_ensemble_v1"

$jsonResp = [Newtonsoft.Json.JsonConvert]::SerializeObject($respDto)
Check "DTO 1.1.2: PredictionResponseDto contiene campos requeridos y estructura JSON" `
    ($jsonResp.Contains("strength_28d_mpa") -and $jsonResp.Contains("VotingEnsemble") -and $jsonResp.Contains("success")) `
    "JSON: $jsonResp"

# ------------------------------------------------------------------------------
# 1.2 ProblemDetailsDto
# ------------------------------------------------------------------------------
Write-Host "`n--- 1.2 ProblemDetailsDto ---" -ForegroundColor DarkCyan

$prob = New-Object EcomixIA.Models.Dtos.ProblemDetailsDto
$prob.Status = 422
$prob.Title = "Unprocessable Entity"
$prob.Detail = "Dosificación fuera de rango admisible."

Check "DTO 1.2.1: ProblemDetailsDto inicializado correctamente" `
    ($prob.Status -eq 422 -and $prob.Detail.Contains("fuera de rango")) `
    "Status: $($prob.Status), Detail: $($prob.Detail)"

# ------------------------------------------------------------------------------
# 1.3 EmailDomainValidator
# ------------------------------------------------------------------------------
Write-Host "`n--- 1.3 Validación de Dominios Institucionales (D-03 / RF-04) ---" -ForegroundColor DarkCyan

$validator = New-Object EcomixIA.Services.EmailDomainValidator

$validUpt = $validator.IsDomainAllowed("estudiante@upt.pe")
$validVirtual = $validator.IsDomainAllowed("docente@virtual.upt.pe")
$validGmail = $validator.IsDomainAllowed("usuario@gmail.com")
$invalidYahoo = $validator.IsDomainAllowed("usuario@yahoo.es")
$invalidHotmail = $validator.IsDomainAllowed("usuario@hotmail.com")
$invalidNull = $validator.IsDomainAllowed($null)
$invalidEmpty = $validator.IsDomainAllowed("")

$syntaxValid = $validator.IsSyntacticallyValid("estudiante@upt.pe")
$syntaxInvalid = $validator.IsSyntacticallyValid("estudiante@")

$canonicalUpt = $validator.ExtractCanonicalDomain("Estudiante@UPT.PE")

Check "Validador 1.3.1: Dominio oficial @upt.pe admitido" ($validUpt -eq $true) "estudiante@upt.pe"
Check "Validador 1.3.2: Subdominio institucional @virtual.upt.pe admitido" ($validVirtual -eq $true) "docente@virtual.upt.pe"
Check "Validador 1.3.3: Dominio @gmail.com admitido por política base" ($validGmail -eq $true) "usuario@gmail.com"
Check "Validador 1.3.4: Dominio comercial @yahoo.es estrictamente rechazado" ($invalidYahoo -eq $false) "usuario@yahoo.es"
Check "Validador 1.3.5: Dominio comercial @hotmail.com estrictamente rechazado" ($invalidHotmail -eq $false) "usuario@hotmail.com"
Check "Validador 1.3.6: Valores nulos o vacíos rechazados de forma segura" ($invalidNull -eq $false -and $invalidEmpty -eq $false) "null y empty"
Check "Validador 1.3.7: Validación sintáctica de formato email" ($syntaxValid -and -not $syntaxInvalid) "estudiante@upt.pe vs estudiante@"
Check "Validador 1.3.8: Extracción canónica y normalización de dominio" ($canonicalUpt -eq "upt.pe") "Estudiante@UPT.PE -> $canonicalUpt"

# ------------------------------------------------------------------------------
# 1.4 Reglas de Complejidad de Contraseña (Identity PasswordValidator)
# ------------------------------------------------------------------------------
Write-Host "`n--- 1.4 Complejidad de Contraseñas (SRS v1.2 / RF-05) ---" -ForegroundColor DarkCyan

$pwdValidator = New-Object Microsoft.AspNet.Identity.PasswordValidator
$pwdValidator.RequiredLength = 8
$pwdValidator.RequireNonLetterOrDigit = $true
$pwdValidator.RequireDigit = $true
$pwdValidator.RequireLowercase = $true
$pwdValidator.RequireUppercase = $true

$strongPassRes = $pwdValidator.ValidateAsync("EcoMix2026!Seguro").GetAwaiter().GetResult()
$weakShortRes = $pwdValidator.ValidateAsync("Eco1!").GetAwaiter().GetResult()
$weakNoUpperRes = $pwdValidator.ValidateAsync("ecomix2026!seguro").GetAwaiter().GetResult()
$weakNoDigitRes = $pwdValidator.ValidateAsync("EcoMixSeguro!Pass").GetAwaiter().GetResult()
$weakNoSpecialRes = $pwdValidator.ValidateAsync("EcoMix2026Seguro").GetAwaiter().GetResult()

Check "Seguridad 1.4.1: Contraseña robusta aceptada" ($strongPassRes.Succeeded -eq $true) "EcoMix2026!Seguro"
Check "Seguridad 1.4.2: Contraseña corta (<8 caracteres) rechazada" ($weakShortRes.Succeeded -eq $false) "Eco1!"
Check "Seguridad 1.4.3: Contraseña sin mayúsculas rechazada" ($weakNoUpperRes.Succeeded -eq $false) "ecomix2026!seguro"
Check "Seguridad 1.4.4: Contraseña sin dígitos rechazada" ($weakNoDigitRes.Succeeded -eq $false) "EcoMixSeguro!Pass"
Check "Seguridad 1.4.5: Contraseña sin carácter especial rechazada" ($weakNoSpecialRes.Succeeded -eq $false) "EcoMix2026Seguro"

# ------------------------------------------------------------------------------
# 1.5 RequestRateLimiter
# ------------------------------------------------------------------------------
Write-Host "`n--- 1.5 Limitador Atómico de Solicitudes (RF-36) ---" -ForegroundColor DarkCyan

$limiter = New-Object EcomixIA.Services.RequestRateLimiter
$testKeyIp = "192.168.10.99"
$retryAfter = [TimeSpan]::Zero

$attempt1 = $limiter.TryAcquire($testKeyIp, 3, [TimeSpan]::FromSeconds(5), [ref]$retryAfter)
$attempt2 = $limiter.TryAcquire($testKeyIp, 3, [TimeSpan]::FromSeconds(5), [ref]$retryAfter)
$attempt3 = $limiter.TryAcquire($testKeyIp, 3, [TimeSpan]::FromSeconds(5), [ref]$retryAfter)
$attempt4 = $limiter.TryAcquire($testKeyIp, 3, [TimeSpan]::FromSeconds(5), [ref]$retryAfter)

Check "RateLimiter 1.5.1: Primeros intentos dentro del umbral (3) permitidos" `
    ($attempt1 -and $attempt2 -and $attempt3) `
    "Intentos 1, 2, 3 permitidos"
Check "RateLimiter 1.5.2: Intento 4 bloqueado al superar umbral de 3" `
    ($attempt4 -eq $false -and $retryAfter.TotalSeconds -gt 0) `
    "Intento 4 bloqueado (RetryAfter: $($retryAfter.TotalSeconds)s)"

# ------------------------------------------------------------------------------
# 1.6 Sanitización en AuditService (H05-A4)
# ------------------------------------------------------------------------------
Write-Host "`n--- 1.6 Sanitización y Privacidad en AuditService (H05-A4) ---" -ForegroundColor DarkCyan

# Usar reflexión para invocar el método privado SanitizeDetails
$auditType = [type]"EcomixIA.Services.AuditService"
$sanitizeMethod = $auditType.GetMethod("SanitizeDetails", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Static)

$rawSecret = "Error: Password=SuperSecret123; ApiKey: key_live_abc12345; Bearer: eyJhbGciOi..."
$sanitizedSecret = $sanitizeMethod.Invoke($null, @($rawSecret))

$rawConnStr = "Fallo de conexión a Server=tcp:sqlserver.local;Database=EcomixIA;User ID=sa;Password=P@ssw0rd123!;"
$sanitizedConnStr = $sanitizeMethod.Invoke($null, @($rawConnStr))

$rawPath = "Error al leer archivo en C:\Users\Admin\Desktop\Proyectos\ML EcomixIA Sistema\Web.config"
$sanitizedPath = $sanitizeMethod.Invoke($null, @($rawPath))

$rawStack = "Exception at EcomixIA.Controllers.MezclasController.SimularAsync() in line 500"
$sanitizedStack = $sanitizeMethod.Invoke($null, @($rawStack))

Check "Auditoría 1.6.1: Contraseñas, ApiKeys y tokens enmascarados como [PROTEGIDO]" `
    ($sanitizedSecret.Contains("[PROTEGIDO]") -and -not $sanitizedSecret.Contains("SuperSecret123") -and -not $sanitizedSecret.Contains("key_live_abc12345")) `
    "$sanitizedSecret"

Check "Auditoría 1.6.2: Cadenas de conexión SQL enmascaradas como [PROTEGIDO]" `
    ($sanitizedConnStr.Contains("[PROTEGIDO]") -and -not $sanitizedConnStr.Contains("sa") -and -not $sanitizedConnStr.Contains("P@ssw0rd123!")) `
    "$sanitizedConnStr"

Check "Auditoría 1.6.3: Rutas de disco local enmascaradas como [RUTA_PROTEGIDA]" `
    ($sanitizedPath.Contains("[RUTA_PROTEGIDA]") -and -not $sanitizedPath.Contains("C:\Users\Admin")) `
    "$sanitizedPath"

Check "Auditoría 1.6.4: Trazas de pila internas enmascaradas como [STACK_PROTEGIDO]" `
    ($sanitizedStack.Contains("[STACK_PROTEGIDO]")) `
    "$sanitizedStack"

# ------------------------------------------------------------------------------
# 1.7 SimulatedEmailService
# ------------------------------------------------------------------------------
Write-Host "`n--- 1.7 Servicio Transaccional de Correo Simulado (D-03 / RF-06) ---" -ForegroundColor DarkCyan

$outboxDir = Join-Path $baseDir "App_Data\EmailOutbox"
$emailSvc = New-Object EcomixIA.Services.SimulatedEmailService ($outboxDir)
$task = $emailSvc.SendEmailAsync("estudiante@upt.pe", "Confirmación de Cuenta", "<p>Enlace: https://localhost:44357/Account/ConfirmEmail?token=123</p>")
$task.GetAwaiter().GetResult()

Check "Email 1.7.1: Correo simulado ejecutado sin excepciones" ($task.IsCompleted -and -not $task.IsFaulted) "Confirmación enviada a outbox"

Write-Host "`nRESUMEN SUITE 01: $suitePassed PASS / $suiteFailed FAIL" -ForegroundColor $(if ($suiteFailed -eq 0) { "Green" } else { "Red" })
return ($suiteFailed -eq 0)
