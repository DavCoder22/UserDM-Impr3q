# Script completo para ejecutar pruebas con Docker Compose
# Incluye configuración de Swagger y verificación de microservicios

Write-Host "=== SISTEMA DE PRUEBAS COMPLETO ===" -ForegroundColor Green
Write-Host "Iniciando configuración de pruebas..." -ForegroundColor Yellow

# Función para verificar si Docker está ejecutándose
function Test-DockerRunning {
    try {
        docker version | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Función para limpiar contenedores anteriores
function Clear-PreviousContainers {
    Write-Host "Limpiando contenedores anteriores..." -ForegroundColor Yellow
    docker-compose -f docker-compose.test.yml down -v --remove-orphans 2>$null
    docker system prune -f 2>$null
}

# Función para verificar la salud de los servicios
function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$Url,
        [int]$MaxRetries = 30
    )
    
    Write-Host "Verificando salud del servicio: $ServiceName" -ForegroundColor Cyan
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 5 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Host "✓ $ServiceName está funcionando correctamente" -ForegroundColor Green
                return $true
            }
        }
        catch {
            Write-Host "Intento $i/$MaxRetries - $ServiceName no está listo aún..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    }
    
    Write-Host "✗ $ServiceName no respondió después de $MaxRetries intentos" -ForegroundColor Red
    return $false
}

# Función para ejecutar pruebas específicas
function Invoke-SpecificTests {
    param(
        [string]$TestType
    )
    
    Write-Host "Ejecutando pruebas de: $TestType" -ForegroundColor Magenta
    
    switch ($TestType) {
        "unit" {
            docker-compose -f docker-compose.test.yml run --rm test_runner bundle exec rspec spec/models/ --format documentation
        }
        "integration" {
            docker-compose -f docker-compose.test.yml run --rm test_runner bundle exec rspec spec/integration/ --format documentation
        }
        "api" {
            docker-compose -f docker-compose.test.yml run --rm test_runner bundle exec rspec spec/requests/ --format documentation
        }
        "all" {
            docker-compose -f docker-compose.test.yml run --rm test_runner bundle exec rspec --format documentation --color
        }
        default {
            Write-Host "Tipo de prueba no reconocido: $TestType" -ForegroundColor Red
        }
    }
}

# Función para mostrar información de Swagger
function Show-SwaggerInfo {
    Write-Host "`n=== INFORMACIÓN DE SWAGGER ===" -ForegroundColor Green
    Write-Host "Documentación de API disponible en:" -ForegroundColor Cyan
    Write-Host "http://localhost:8080" -ForegroundColor White
    Write-Host "`nServicios disponibles:" -ForegroundColor Cyan
    Write-Host "- Registro: http://localhost:3001" -ForegroundColor White
    Write-Host "- Login: http://localhost:3002" -ForegroundColor White
    Write-Host "- Perfil: http://localhost:3003" -ForegroundColor White
    Write-Host "- Contraseñas: http://localhost:3004" -ForegroundColor White
    Write-Host "- Logout: http://localhost:3005" -ForegroundColor White
    Write-Host "- Historial: http://localhost:3006" -ForegroundColor White
    Write-Host "- Perfil Completo: http://localhost:3007" -ForegroundColor White
    Write-Host "- Historial Completo: http://localhost:3008" -ForegroundColor White
}

# Función para ejecutar pruebas de endpoints
function Test-APIEndpoints {
    Write-Host "`n=== PRUEBAS DE ENDPOINTS ===" -ForegroundColor Green
    
    $endpoints = @(
        @{Service="Registro"; Url="http://localhost:3001/health"},
        @{Service="Login"; Url="http://localhost:3002/health"},
        @{Service="Perfil"; Url="http://localhost:3003/health"},
        @{Service="Contraseñas"; Url="http://localhost:3004/health"},
        @{Service="Logout"; Url="http://localhost:3005/health"},
        @{Service="Historial"; Url="http://localhost:3006/health"},
        @{Service="Perfil Completo"; Url="http://localhost:3007/health"},
        @{Service="Historial Completo"; Url="http://localhost:3008/health"}
    )
    
    foreach ($endpoint in $endpoints) {
        Test-ServiceHealth -ServiceName $endpoint.Service -Url $endpoint.Url
    }
}

# Función principal
function Start-CompleteTesting {
    param(
        [string]$TestType = "all",
        [switch]$SkipHealthCheck,
        [switch]$SkipSwagger
    )
    
    # Verificar Docker
    if (-not (Test-DockerRunning)) {
        Write-Host "Error: Docker no está ejecutándose" -ForegroundColor Red
        Write-Host "Por favor, inicia Docker Desktop y vuelve a intentar" -ForegroundColor Yellow
        exit 1
    }
    
    # Limpiar contenedores anteriores
    Clear-PreviousContainers
    
    # Construir y levantar servicios
    Write-Host "`nConstruyendo y levantando servicios..." -ForegroundColor Yellow
    docker-compose -f docker-compose.test.yml up -d --build
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al levantar los servicios" -ForegroundColor Red
        exit 1
    }
    
    # Esperar a que los servicios estén listos
    Write-Host "`nEsperando a que los servicios estén listos..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Verificar salud de servicios (opcional)
    if (-not $SkipHealthCheck) {
        Test-APIEndpoints
    }
    
    # Mostrar información de Swagger
    if (-not $SkipSwagger) {
        Show-SwaggerInfo
    }
    
    # Ejecutar pruebas
    Write-Host "`n=== EJECUTANDO PRUEBAS ===" -ForegroundColor Green
    Invoke-SpecificTests -TestType $TestType
    
    # Mostrar logs si hay errores
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n=== LOGS DE ERRORES ===" -ForegroundColor Red
        docker-compose -f docker-compose.test.yml logs test_runner
    }
    
    # Opción para mantener servicios ejecutándose
    Write-Host "`n¿Deseas mantener los servicios ejecutándose para pruebas manuales? (s/n)" -ForegroundColor Cyan
    $keepRunning = Read-Host
    
    if ($keepRunning -eq "s" -or $keepRunning -eq "S") {
        Write-Host "Servicios mantenidos ejecutándose. Usa 'docker-compose -f docker-compose.test.yml down' para detenerlos" -ForegroundColor Green
    } else {
        Write-Host "Deteniendo servicios..." -ForegroundColor Yellow
        docker-compose -f docker-compose.test.yml down
    }
}

# Función para mostrar ayuda
function Show-Help {
    Write-Host "=== AYUDA DEL SCRIPT ===" -ForegroundColor Green
    Write-Host "Uso: .\run_complete_tests.ps1 [opciones]" -ForegroundColor White
    Write-Host ""
    Write-Host "Opciones:" -ForegroundColor Cyan
    Write-Host "  -TestType <tipo>     Tipo de pruebas a ejecutar (unit, integration, api, all)" -ForegroundColor White
    Write-Host "  -SkipHealthCheck     Saltar verificación de salud de servicios" -ForegroundColor White
    Write-Host "  -SkipSwagger         Saltar información de Swagger" -ForegroundColor White
    Write-Host "  -Help                Mostrar esta ayuda" -ForegroundColor White
    Write-Host ""
    Write-Host "Ejemplos:" -ForegroundColor Cyan
    Write-Host "  .\run_complete_tests.ps1" -ForegroundColor White
    Write-Host "  .\run_complete_tests.ps1 -TestType unit" -ForegroundColor White
    Write-Host "  .\run_complete_tests.ps1 -TestType integration -SkipHealthCheck" -ForegroundColor White
}

# Procesar argumentos
param(
    [string]$TestType = "all",
    [switch]$SkipHealthCheck,
    [switch]$SkipSwagger,
    [switch]$Help
)

if ($Help) {
    Show-Help
    exit 0
}

# Ejecutar pruebas
Start-CompleteTesting -TestType $TestType -SkipHealthCheck:$SkipHealthCheck -SkipSwagger:$SkipSwagger 