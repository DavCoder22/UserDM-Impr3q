# Script simple para ejecutar pruebas con Docker Compose

Write-Host "=== SISTEMA DE PRUEBAS SIMPLE ===" -ForegroundColor Green
Write-Host "Iniciando configuracion de pruebas..." -ForegroundColor Yellow

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

# Función para ejecutar pruebas específicas
function Invoke-SpecificTests {
    param([string]$TestType)
    
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
    Write-Host ""
    Write-Host "=== INFORMACION DE SWAGGER ===" -ForegroundColor Green
    Write-Host "Documentacion de API disponible en:" -ForegroundColor Cyan
    Write-Host "http://localhost:8080" -ForegroundColor White
    Write-Host ""
    Write-Host "Servicios disponibles:" -ForegroundColor Cyan
    Write-Host "- Registro: http://localhost:3001" -ForegroundColor White
    Write-Host "- Login: http://localhost:3002" -ForegroundColor White
    Write-Host "- Perfil: http://localhost:3003" -ForegroundColor White
    Write-Host "- Contraseñas: http://localhost:3004" -ForegroundColor White
    Write-Host "- Logout: http://localhost:3005" -ForegroundColor White
    Write-Host "- Historial: http://localhost:3006" -ForegroundColor White
    Write-Host "- Perfil Completo: http://localhost:3007" -ForegroundColor White
    Write-Host "- Historial Completo: http://localhost:3008" -ForegroundColor White
}

# Función principal
function Start-SimpleTesting {
    param([string]$TestType = "all")
    
    # Verificar Docker
    if (-not (Test-DockerRunning)) {
        Write-Host "Error: Docker no está ejecutándose" -ForegroundColor Red
        Write-Host "Por favor, inicia Docker Desktop y vuelve a intentar" -ForegroundColor Yellow
        exit 1
    }
    
    # Limpiar contenedores anteriores
    Clear-PreviousContainers
    
    # Construir y levantar servicios
    Write-Host ""
    Write-Host "Construyendo y levantando servicios..." -ForegroundColor Yellow
    docker-compose -f docker-compose.test.yml up -d --build
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al levantar los servicios" -ForegroundColor Red
        exit 1
    }
    
    # Esperar a que los servicios estén listos
    Write-Host ""
    Write-Host "Esperando a que los servicios estén listos..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Mostrar información de Swagger
    Show-SwaggerInfo
    
    # Ejecutar pruebas
    Write-Host ""
    Write-Host "=== EJECUTANDO PRUEBAS ===" -ForegroundColor Green
    Invoke-SpecificTests -TestType $TestType
    
    # Mostrar logs si hay errores
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "=== LOGS DE ERRORES ===" -ForegroundColor Red
        docker-compose -f docker-compose.test.yml logs test_runner
    }
    
    # Opción para mantener servicios ejecutándose
    Write-Host ""
    Write-Host "¿Deseas mantener los servicios ejecutándose para pruebas manuales? (s/n)" -ForegroundColor Cyan
    $keepRunning = Read-Host
    
    if ($keepRunning -eq "s" -or $keepRunning -eq "S") {
        Write-Host "Servicios mantenidos ejecutándose. Usa 'docker-compose -f docker-compose.test.yml down' para detenerlos" -ForegroundColor Green
    } else {
        Write-Host "Deteniendo servicios..." -ForegroundColor Yellow
        docker-compose -f docker-compose.test.yml down
    }
}

# Procesar argumentos
param([string]$TestType = "all")

# Ejecutar pruebas
Start-SimpleTesting -TestType $TestType 