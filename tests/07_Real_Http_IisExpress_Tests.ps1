# ==============================================================================
# EcoMix IA — Suite 07: Pruebas HTTP Completas en Servidor Real (IIS Express)
# ==============================================================================

Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue

$baseDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

# 1. Validación de base de datos objetivo
$targetDb = if (![string]::IsNullOrWhiteSpace($env:TARGET_DATABASE)) { $env:TARGET_DATABASE.Trim() } else { "EcomixIA_Trial" }
$allowedDatabases = @("EcomixIA_Trial", "EcomixIA_Test")
if ($targetDb -notin $allowedDatabases) {
    throw "[SEGURIDAD CRÍTICA] La base de datos objetivo '$targetDb' no está autorizada para pruebas."
}

. (Join-Path $PSScriptRoot "Test_Helpers.ps1")

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  SUITE 07: PRUEBAS HTTP COMPLETAS CON SERVIDOR REAL (IIS EXPRESS)" -ForegroundColor Cyan
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

function Extract-CsrfToken([string]$html) {
    $match = [regex]::Match($html, 'name="__RequestVerificationToken"\s+type="hidden"\s+value="([^"]+)"')
    if (!$match.Success) {
        $match = [regex]::Match($html, '<input[^>]*name="__RequestVerificationToken"[^>]*value="([^"]+)"')
    }
    if (!$match.Success) {
        $match = [regex]::Match($html, '<input[^>]*value="([^"]+)"[^>]*name="__RequestVerificationToken"')
    }
    if ($match.Success) { return $match.Groups[1].Value }
    return ""
}

# 2. Localizar iisexpress.exe
$iisPath = "C:\Program Files\IIS Express\iisexpress.exe"
if (!(Test-Path $iisPath)) {
    $iisPath = "C:\Program Files (x86)\IIS Express\iisexpress.exe"
}
if (!(Test-Path $iisPath)) {
    throw "IIS Express no fue encontrado en las rutas estándar de Program Files."
}

$port = 58085
$webConfigPath = Join-Path $baseDir "Web.config"
$webConfigBak = Join-Path $baseDir "Web.config.httpbak"

# 3. Preparar credenciales conocidas en la base de datos de ensayo
$adminEmail = "joamedina@upt.pe"
$adminPassword = "Admin2026!RealPass"
$user2Email = "joamedina2@upt.pe"
$user2Password = "User2026!RealPass"

$hasher = New-Object Microsoft.AspNet.Identity.PasswordHasher
$adminHash = $hasher.HashPassword($adminPassword)
$user2Hash = $hasher.HashPassword($user2Password)

Execute-SqlNonQuery "UPDATE dbo.AspNetUsers SET PasswordHash = '$adminHash', IsEnabled = 1, EmailConfirmed = 1 WHERE Email = '$adminEmail';" | Out-Null
Execute-SqlNonQuery "UPDATE dbo.AspNetUsers SET PasswordHash = '$user2Hash', IsEnabled = 1, EmailConfirmed = 1 WHERE Email = '$user2Email';" | Out-Null

$adminRole = Query-SqlScalar "SELECT Id FROM dbo.AspNetRoles WHERE Name = 'Administrador'"
$adminId = Query-SqlScalar "SELECT Id FROM dbo.AspNetUsers WHERE Email = '$adminEmail'"
$user2Id = Query-SqlScalar "SELECT Id FROM dbo.AspNetUsers WHERE Email = '$user2Email'"

Execute-SqlNonQuery "DELETE FROM dbo.AspNetUserRoles WHERE RoleId = '$adminRole';" | Out-Null
Execute-SqlNonQuery "INSERT INTO dbo.AspNetUserRoles (UserId, RoleId) VALUES ('$adminId', '$adminRole');" | Out-Null

# Asegurar mezcla privada perteneciente exclusivamente a user2
$existingMixId = Query-SqlScalar "SELECT TOP 1 Id FROM dbo.Mezclas WHERE OwnerUserId = '$user2Id';"
if ($null -eq $existingMixId) {
    Execute-SqlNonQuery @"
INSERT INTO dbo.Mezclas (Nombre, ResistenciaMPa, EdadDias, RelacionAguaCemento, AsentamientoCm, Notas, OwnerUserId)
VALUES ('Mezcla Privada User2', 25.0, 28, 0.50, 10.0, 'Mezcla privada de prueba IDOR', '$user2Id');
"@ | Out-Null
    $existingMixId = Query-SqlScalar "SELECT TOP 1 Id FROM dbo.Mezclas WHERE OwnerUserId = '$user2Id';"
}

# 4. Aislar Web.config para que IIS Express apunte a TargetDatabase
Copy-Item $webConfigPath $webConfigBak -Force
$configContent = [System.IO.File]::ReadAllText($webConfigBak)
$isolatedContent = $configContent.Replace("Initial Catalog=EcomixIA;", "Initial Catalog=$targetDb;")
[System.IO.File]::WriteAllText($webConfigPath, $isolatedContent, [System.Text.Encoding]::UTF8)

# 5. Iniciar IIS Express en subproceso
Write-Host "`n>> Iniciando IIS Express en puerto $port contra base de datos $targetDb..." -ForegroundColor Yellow
$iisProcess = Start-Process -FilePath $iisPath -ArgumentList "/path:`"$baseDir`"", "/port:$port", "/systray:false" -PassThru -WindowStyle Hidden

# Esperar disponibilidad del servidor
$serverReady = $false
for ($attempt = 1; $attempt -le 15; $attempt++) {
    Start-Sleep -Seconds 1
    try {
        $testPing = Invoke-WebRequest -Uri "http://localhost:$port/" -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($testPing -and $testPing.StatusCode -eq 200) {
            $serverReady = $true
            break
        }
    } catch {
        # Esperando inicio
    }
}

if (!$serverReady) {
    if ($iisProcess -and !$iisProcess.HasExited) { Stop-Process -Id $iisProcess.Id -Force }
    Copy-Item $webConfigBak $webConfigPath -Force
    Remove-Item $webConfigBak -Force -ErrorAction SilentlyContinue
    throw "El servidor IIS Express no respondió dentro de los 15 segundos iniciales."
}

Write-Host ">> IIS Express listo y respondiendo en http://localhost:$port/`n" -ForegroundColor Green

try {
    # --------------------------------------------------------------------------
    # 7.1 GET anónimo a ruta protegida (/Materiales)
    # --------------------------------------------------------------------------
    Write-Host "--- 7.1 Solicitud GET Anónima a Ruta Protegida (/Materiales) ---" -ForegroundColor DarkCyan
    
    $handlerAnon = New-Object System.Net.Http.HttpClientHandler
    $handlerAnon.AllowAutoRedirect = $false
    $clientAnon = New-Object System.Net.Http.HttpClient($handlerAnon)
    
    $responseAnon = $clientAnon.GetAsync("http://localhost:$port/Materiales").GetAwaiter().GetResult()
    $statusAnon = [int]$responseAnon.StatusCode
    $locationAnon = if ($responseAnon.Headers.Location) { $responseAnon.Headers.Location.ToString() } else { "" }
    
    Check "HTTP 7.1.1: Solicitud GET anónima a /Materiales redirigida con HTTP 302 a Login" `
        ($statusAnon -eq 302 -and $locationAnon.Contains("/Account/Login")) `
        "HTTP $statusAnon -> Location: $locationAnon"

    # --------------------------------------------------------------------------
    # 7.2 Login con Cookie Válida
    # --------------------------------------------------------------------------
    Write-Host "`n--- 7.2 Autenticación Real y Adquisición de Cookie de Sesión ---" -ForegroundColor DarkCyan
    
    $cookieContainerAdmin = New-Object System.Net.CookieContainer
    $handlerAdmin = New-Object System.Net.Http.HttpClientHandler
    $handlerAdmin.CookieContainer = $cookieContainerAdmin
    $handlerAdmin.AllowAutoRedirect = $false
    $clientAdmin = New-Object System.Net.Http.HttpClient($handlerAdmin)
    
    # Obtener formulario de login y token anti-falsificación
    $loginHtmlResp = $clientAdmin.GetAsync("http://localhost:$port/Account/Login").GetAwaiter().GetResult()
    $loginHtml = $loginHtmlResp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    $csrfToken = Extract-CsrfToken $loginHtml
    
    $loginForm = New-Object 'System.Collections.Generic.Dictionary[string,string]'
    $loginForm.Add("__RequestVerificationToken", $csrfToken)
    $loginForm.Add("Email", $adminEmail)
    $loginForm.Add("Password", $adminPassword)
    $loginForm.Add("RememberMe", "false")
    
    $loginPostContent = New-Object System.Net.Http.FormUrlEncodedContent($loginForm)
    $loginPostResp = $clientAdmin.PostAsync("http://localhost:$port/Account/Login", $loginPostContent).GetAwaiter().GetResult()
    $loginPostStatus = [int]$loginPostResp.StatusCode
    $loginLocation = if ($loginPostResp.Headers.Location) { $loginPostResp.Headers.Location.ToString() } else { "" }
    
    $adminCookies = $cookieContainerAdmin.GetCookies((New-Object Uri("http://localhost:$port/")))
    $hasAppCookie = $false
    foreach ($c in $adminCookies) {
        if ($c.Name -eq ".AspNet.ApplicationCookie") { $hasAppCookie = $true }
    }
    
    # Probar acceso a ruta protegida con la cookie adquirida
    $mezclasAuthResp = $clientAdmin.GetAsync("http://localhost:$port/Mezclas").GetAwaiter().GetResult()
    $mezclasAuthStatus = [int]$mezclasAuthResp.StatusCode
    
    Check "HTTP 7.2.1: Login exitoso retorna HTTP 302 y emite cookie .AspNet.ApplicationCookie" `
        (($loginPostStatus -eq 302 -or $loginPostStatus -eq 200) -and $hasAppCookie) `
        "Status: $loginPostStatus. Cookie ApplicationCookie emitida"
        
    Check "HTTP 7.2.2: Petición autenticada con cookie accede a /Mezclas con HTTP 200 OK" `
        ($mezclasAuthStatus -eq 200) `
        "Status: $mezclasAuthStatus"

    # --------------------------------------------------------------------------
    # 7.3 POST Administrativo sin Token CSRF (Rechazo Mandatorio)
    # --------------------------------------------------------------------------
    Write-Host "`n--- 7.3 POST Administrativo Sin Token CSRF ---" -ForegroundColor DarkCyan
    
    $user2StatusBefore = [bool](Query-SqlScalar "SELECT IsEnabled FROM dbo.AspNetUsers WHERE Id = '$user2Id';")
    
    # Enviar POST sin incluir el token anti-falsificación
    $noCsrfForm = New-Object 'System.Collections.Generic.Dictionary[string,string]'
    $noCsrfForm.Add("userId", $user2Id)
    $noCsrfContent = New-Object System.Net.Http.FormUrlEncodedContent($noCsrfForm)
    
    $noCsrfResp = $clientAdmin.PostAsync("http://localhost:$port/Admin/ToggleUserStatus", $noCsrfContent).GetAwaiter().GetResult()
    $noCsrfStatus = [int]$noCsrfResp.StatusCode
    
    $user2StatusAfterNoCsrf = [bool](Query-SqlScalar "SELECT IsEnabled FROM dbo.AspNetUsers WHERE Id = '$user2Id';")
    
    Check "HTTP 7.3.1: POST administrativo sin token CSRF rechazado con error HTTP (>=400)" `
        ($noCsrfStatus -ge 400 -and $user2StatusBefore -eq $user2StatusAfterNoCsrf) `
        "HTTP $noCsrfStatus devuelto. Estado del usuario intacto en base de datos"

    # --------------------------------------------------------------------------
    # 7.4 POST Administrativo con Token CSRF Válido
    # --------------------------------------------------------------------------
    Write-Host "`n--- 7.4 POST Administrativo Con Token CSRF Válido ---" -ForegroundColor DarkCyan
    
    # Obtener token CSRF válido para la sesión administrativa
    $adminUsersResp = $clientAdmin.GetAsync("http://localhost:$port/Admin/Users").GetAwaiter().GetResult()
    $adminUsersHtml = $adminUsersResp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    $adminCsrfToken = Extract-CsrfToken $adminUsersHtml
    
    $validCsrfForm = New-Object 'System.Collections.Generic.Dictionary[string,string]'
    $validCsrfForm.Add("__RequestVerificationToken", $adminCsrfToken)
    $validCsrfForm.Add("userId", $user2Id)
    $validCsrfContent = New-Object System.Net.Http.FormUrlEncodedContent($validCsrfForm)
    
    $validCsrfResp = $clientAdmin.PostAsync("http://localhost:$port/Admin/ToggleUserStatus", $validCsrfContent).GetAwaiter().GetResult()
    $validCsrfStatus = [int]$validCsrfResp.StatusCode
    
    $user2StatusAfterValidCsrf = [bool](Query-SqlScalar "SELECT IsEnabled FROM dbo.AspNetUsers WHERE Id = '$user2Id';")
    
    # Revertir estado de user2
    Execute-SqlNonQuery "UPDATE dbo.AspNetUsers SET IsEnabled = 1 WHERE Id = '$user2Id';" | Out-Null
    
    Check "HTTP 7.4.1: POST administrativo con token CSRF válido aceptado (HTTP 302/200) y muta estado" `
        (($validCsrfStatus -eq 302 -or $validCsrfStatus -eq 200) -and $user2StatusBefore -ne $user2StatusAfterValidCsrf) `
        "HTTP $validCsrfStatus. Estado mutado exitosamente de $user2StatusBefore a $user2StatusAfterValidCsrf"

    # --------------------------------------------------------------------------
    # 7.5 Acceso a Mezclas Privadas de Otro Usuario (IDOR)
    # --------------------------------------------------------------------------
    Write-Host "`n--- 7.5 Prevención IDOR en Acceso a Mezclas Privadas (/Mezclas/Details) ---" -ForegroundColor DarkCyan
    
    # El administrador joamedina intenta consultar la receta privada de user2
    $idorResp = $clientAdmin.GetAsync("http://localhost:$port/Mezclas/Details/$existingMixId").GetAwaiter().GetResult()
    $idorStatus = [int]$idorResp.StatusCode
    
    Check "HTTP 7.5.1: Intento de acceso a mezcla ajena rechazado con HTTP 404/403" `
        ($idorStatus -eq 404 -or $idorStatus -eq 403) `
        "HTTP $idorStatus devuelto (Acceso bloqueado por OwnerUserId)"

    # --------------------------------------------------------------------------
    # 7.6 Revocación de Acceso tras Deshabilitar Cuenta (H05-A3)
    # --------------------------------------------------------------------------
    Write-Host "`n--- 7.6 Revocación Inmediata de Sesión tras Deshabilitar Cuenta ---" -ForegroundColor DarkCyan
    
    # Autenticar a user2 y verificar acceso
    $cookieContainerUser2 = New-Object System.Net.CookieContainer
    $handlerUser2 = New-Object System.Net.Http.HttpClientHandler
    $handlerUser2.CookieContainer = $cookieContainerUser2
    $handlerUser2.AllowAutoRedirect = $false
    $clientUser2 = New-Object System.Net.Http.HttpClient($handlerUser2)
    
    $loginHtmlU2Resp = $clientUser2.GetAsync("http://localhost:$port/Account/Login").GetAwaiter().GetResult()
    $loginHtmlU2 = $loginHtmlU2Resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    $tokenU2 = Extract-CsrfToken $loginHtmlU2
    
    $formU2 = New-Object 'System.Collections.Generic.Dictionary[string,string]'
    $formU2.Add("__RequestVerificationToken", $tokenU2)
    $formU2.Add("Email", $user2Email)
    $formU2.Add("Password", $user2Password)
    $formU2.Add("RememberMe", "false")
    
    $loginU2Post = $clientUser2.PostAsync("http://localhost:$port/Account/Login", (New-Object System.Net.Http.FormUrlEncodedContent($formU2))).GetAwaiter().GetResult()
    
    # Confirmar que user2 accede inicialmente a ruta protegida (/Materiales)
    $u2ActiveResp = $clientUser2.GetAsync("http://localhost:$port/Materiales").GetAwaiter().GetResult()
    $u2ActiveStatus = [int]$u2ActiveResp.StatusCode
    
    # Inhabilitar cuenta de user2 directamente en la base de datos
    Execute-SqlNonQuery "UPDATE dbo.AspNetUsers SET IsEnabled = 0 WHERE Id = '$user2Id';" | Out-Null
    
    # Enviar siguiente solicitud HTTP con la cookie de sesión activa a ruta protegida (/Materiales)
    $u2RevokedResp = $clientUser2.GetAsync("http://localhost:$port/Materiales").GetAwaiter().GetResult()
    $u2RevokedStatus = [int]$u2RevokedResp.StatusCode
    $u2RevokedLocation = if ($u2RevokedResp.Headers.Location) { $u2RevokedResp.Headers.Location.ToString() } else { "" }
    
    # Restaurar user2
    Execute-SqlNonQuery "UPDATE dbo.AspNetUsers SET IsEnabled = 1 WHERE Id = '$user2Id';" | Out-Null
    
    Check "HTTP 7.6.1: Sesión activa de usuario inhabilitado interceptada y redirigida a Login?disabled=1" `
        ($u2ActiveStatus -eq 200 -and $u2RevokedStatus -eq 302 -and $u2RevokedLocation.Contains("Login?disabled=1")) `
        "Pre-inhabilitación: HTTP $u2ActiveStatus -> Post-inhabilitación: HTTP $u2RevokedStatus (Location: $u2RevokedLocation)"

} finally {
    # 6. Detener servidor y restaurar Web.config
    Write-Host "`n>> Deteniendo servidor IIS Express..." -ForegroundColor Yellow
    if ($iisProcess -and !$iisProcess.HasExited) {
        Stop-Process -Id $iisProcess.Id -Force
    }
    
    Write-Host ">> Restaurando Web.config original..." -ForegroundColor Yellow
    if (Test-Path $webConfigBak) {
        Copy-Item $webConfigBak $webConfigPath -Force
        Remove-Item $webConfigBak -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`nRESUMEN SUITE 07: $suitePassed PASS / $suiteFailed FAIL" -ForegroundColor $(if ($suiteFailed -eq 0) { "Green" } else { "Red" })
return ($suiteFailed -eq 0)
