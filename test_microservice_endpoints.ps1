# Script para probar endpoints de microservicios
# Verifica el funcionamiento de todos los servicios

Write-Host "=== PRUEBAS DE ENDPOINTS DE MICROSERVICIOS ===" -ForegroundColor Green

# Configuración de servicios
$services = @{
    "auth-register" = @{
        BaseUrl = "http://localhost:3001"
        Endpoints = @(
            @{Method="GET"; Path="/health"; Description="Health Check"}
        )
    }
    "auth-login" = @{
        BaseUrl = "http://localhost:3002"
        Endpoints = @(
            @{Method="GET"; Path="/health"; Description="Health Check"}
        )
    }
    "auth-profile" = @{
        BaseUrl = "http://localhost:3003"
        Endpoints = @(
            @{Method="GET"; Path="/health"; Description="Health Check"}
        )
    }
    "auth-password" = @{
        BaseUrl = "http://localhost:3004"
        Endpoints = @(
            @{Method="GET"; Path="/health"; Description="Health Check"}
        )
    }
    "auth-logout" = @{
        BaseUrl = "http://localhost:3005"
        Endpoints = @(
            @{Method="GET"; Path="/health"; Description="Health Check"}
        )
    }
    "auth-history" = @{
        BaseUrl = "http://localhost:3006"
        Endpoints = @(
            @{Method="GET"; Path="/health"; Description="Health Check"}
        )
    }
    "perfil-service" = @{
        BaseUrl = "http://localhost:3007"
        Endpoints = @(
            @{Method="GET"; Path="/health"; Description="Health Check"}
        )
    }
    "historial-service" = @{
        BaseUrl = "http://localhost:3008"
        Endpoints = @(
            @{Method="GET"; Path="/health"; Description="Health Check"}
        )
    }
}

# Función para probar un endpoint
function Test-Endpoint {
    param(
        [string]$ServiceName,
        [string]$BaseUrl,
        [string]$Method,
        [string]$Path,
        [string]$Description,
        [object]$Body = $null,
        [hashtable]$Headers = @{}
    )
    
    $url = "$BaseUrl$Path"
    $fullDescription = "$ServiceName - $Description"
    
    Write-Host "Probando: $fullDescription" -ForegroundColor Cyan
    Write-Host "  URL: $url" -ForegroundColor Gray
    
    try {
        $params = @{
            Uri = $url
            Method = $Method
            TimeoutSec = 10
            UseBasicParsing = $true
        }
        
        if ($Headers.Count -gt 0) {
            $params.Headers = $Headers
        }
        
        if ($Body -and $Method -in @("POST", "PUT", "PATCH")) {
            $params.Body = $Body | ConvertTo-Json -Depth 10
            $params.ContentType = "application/json"
        }
        
        $response = Invoke-WebRequest @params
        
        if ($response.StatusCode -eq 200) {
            Write-Host "  Exito (200)" -ForegroundColor Green
            if ($response.Content) {
                try {
                    $jsonResponse = $response.Content | ConvertFrom-Json
                    Write-Host "  📄 Respuesta: $($jsonResponse | ConvertTo-Json -Compress)" -ForegroundColor Gray
                }
                catch {
                    Write-Host "  📄 Respuesta: $($response.Content)" -ForegroundColor Gray
                }
            }
            return $true
        } else {
            Write-Host "  Respuesta inesperada: $($response.StatusCode)" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Función para probar flujo completo de autenticación
function Test-AuthenticationFlow {
    Write-Host "`n=== PRUEBA DE FLUJO DE AUTENTICACIÓN ===" -ForegroundColor Magenta
    
    # Datos de prueba
    $testUser = @{
        nombre = "Usuario Prueba"
        email = "test@example.com"
        password = "password123"
        rol = "cliente"
        telefono = "123456789"
    }
    
    $token = $null
    
    # 1. Probar registro
    Write-Host "1. Probando registro de usuario..." -ForegroundColor Yellow
    $registerResult = Test-Endpoint -ServiceName "auth-register" -BaseUrl $services["auth-register"].BaseUrl -Method "POST" -Path "/register" -Description "Registro de usuario" -Body $testUser
    
    if ($registerResult) {
        Write-Host "  Registro exitoso" -ForegroundColor Green
    } else {
        Write-Host "  Registro fallo o usuario ya existe" -ForegroundColor Yellow
    }
    
    # 2. Probar login
    Write-Host "2. Probando login..." -ForegroundColor Yellow
    $loginData = @{
        email = $testUser.email
        password = $testUser.password
    }
    
    try {
        $response = Invoke-WebRequest -Uri "$($services["auth-login"].BaseUrl)/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json" -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $loginResponse = $response.Content | ConvertFrom-Json
            $token = $loginResponse.token
            Write-Host "  Login exitoso" -ForegroundColor Green
            Write-Host "  Token obtenido" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  Login fallo: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 3. Probar endpoints protegidos si tenemos token
    if ($token) {
        $headers = @{
            "Authorization" = "Bearer $token"
        }
        
        Write-Host "3. Probando endpoints protegidos..." -ForegroundColor Yellow
        
        # Probar obtener perfil
        Test-Endpoint -ServiceName "perfil-service" -BaseUrl $services["perfil-service"].BaseUrl -Method "GET" -Path "/api/v1/profile" -Description "Obtener perfil" -Headers $headers
        
        # Probar obtener historial
        Test-Endpoint -ServiceName "historial-service" -BaseUrl $services["historial-service"].BaseUrl -Method "GET" -Path "/api/v1/history" -Description "Obtener historial" -Headers $headers
        
        # 4. Probar logout
        Write-Host "4. Probando logout..." -ForegroundColor Yellow
        Test-Endpoint -ServiceName "auth-logout" -BaseUrl $services["auth-logout"].BaseUrl -Method "DELETE" -Path "/logout" -Description "Logout" -Headers $headers
    }
}

# Función para probar todos los health checks
function Test-AllHealthChecks {
    Write-Host "`n=== PRUEBAS DE HEALTH CHECK ===" -ForegroundColor Magenta
    
    $results = @{}
    
    foreach ($serviceName in $services.Keys) {
        $service = $services[$serviceName]
        Write-Host "`nProbando: $serviceName" -ForegroundColor Cyan
        
        $success = $false
        foreach ($endpoint in $service.Endpoints) {
            if ($endpoint.Description -eq "Health Check") {
                $success = Test-Endpoint -ServiceName $serviceName -BaseUrl $service.BaseUrl -Method $endpoint.Method -Path $endpoint.Path -Description $endpoint.Description
                break
            }
        }
        
        $results[$serviceName] = $success
    }
    
    return $results
}

# Función para mostrar resumen
function Show-TestSummary {
    param(
        [hashtable]$Results
    )
    
    Write-Host "`n=== RESUMEN DE PRUEBAS ===" -ForegroundColor Green
    
    $total = $Results.Count
    $successful = ($Results.Values | Where-Object { $_ -eq $true }).Count
    $failed = $total - $successful
    
    Write-Host "Total de servicios: $total" -ForegroundColor White
    Write-Host "Servicios funcionando: $successful" -ForegroundColor Green
    Write-Host "Servicios con problemas: $failed" -ForegroundColor Red
    
    if ($failed -gt 0) {
        Write-Host "`nServicios con problemas:" -ForegroundColor Red
        foreach ($service in $Results.Keys) {
            if (-not $Results[$service]) {
                Write-Host "  - $service" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "`nRecomendaciones:" -ForegroundColor Cyan
    if ($failed -eq 0) {
        Write-Host "✓ Todos los servicios están funcionando correctamente" -ForegroundColor Green
        Write-Host "✓ Puedes proceder con las pruebas completas" -ForegroundColor Green
    } else {
        Write-Host "⚠ Algunos servicios tienen problemas" -ForegroundColor Yellow
        Write-Host "⚠ Verifica los logs de Docker: docker-compose -f docker-compose.test.yml logs" -ForegroundColor Yellow
        Write-Host "⚠ Asegúrate de que todos los servicios estén ejecutándose" -ForegroundColor Yellow
    }
}

# Función principal
function Start-EndpointTesting {
    param(
        [switch]$SkipAuthFlow,
        [switch]$OnlyHealthCheck
    )
    
    Write-Host "Iniciando pruebas de endpoints..." -ForegroundColor Yellow
    
    # Verificar que Docker esté ejecutándose
    try {
        docker version | Out-Null
    }
    catch {
        Write-Host "Error: Docker no está ejecutándose" -ForegroundColor Red
        Write-Host "Por favor, inicia Docker Desktop y vuelve a intentar" -ForegroundColor Yellow
        exit 1
    }
    
    # Verificar que los servicios estén ejecutándose
    Write-Host "Verificando que los servicios estén ejecutándose..." -ForegroundColor Yellow
    $runningServices = docker-compose -f docker-compose.test.yml ps --services --filter "status=running" 2>$null
    
    if (-not $runningServices) {
        Write-Host "Los servicios no están ejecutándose. Iniciando..." -ForegroundColor Yellow
        docker-compose -f docker-compose.test.yml up -d
        Write-Host "Esperando 30 segundos para que los servicios se inicien..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
    }
    
    # Probar health checks
    $healthResults = Test-AllHealthChecks
    
    # Probar flujo de autenticación si no se omite
    if (-not $SkipAuthFlow -and -not $OnlyHealthCheck) {
        Test-AuthenticationFlow
    }
    
    # Mostrar resumen
    Show-TestSummary -Results $healthResults
}

# Procesar argumentos
param(
    [switch]$SkipAuthFlow,
    [switch]$OnlyHealthCheck,
    [switch]$Help
)

if ($Help) {
    Write-Host "=== AYUDA DEL SCRIPT ===" -ForegroundColor Green
    Write-Host "Uso: .\test_microservice_endpoints.ps1 [opciones]" -ForegroundColor White
    Write-Host ""
    Write-Host "Opciones:" -ForegroundColor Cyan
    Write-Host "  -SkipAuthFlow        Saltar pruebas de flujo de autenticación" -ForegroundColor White
    Write-Host "  -OnlyHealthCheck     Solo probar health checks" -ForegroundColor White
    Write-Host "  -Help                Mostrar esta ayuda" -ForegroundColor White
    Write-Host ""
    Write-Host "Ejemplos:" -ForegroundColor Cyan
    Write-Host "  .\test_microservice_endpoints.ps1" -ForegroundColor White
    Write-Host "  .\test_microservice_endpoints.ps1 -OnlyHealthCheck" -ForegroundColor White
    Write-Host "  .\test_microservice_endpoints.ps1 -SkipAuthFlow" -ForegroundColor White
    exit 0
}

# Ejecutar pruebas
Start-EndpointTesting -SkipAuthFlow:$SkipAuthFlow -OnlyHealthCheck:$OnlyHealthCheck 