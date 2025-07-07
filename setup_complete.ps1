# Script completo para configurar y ejecutar el sistema de microservicios UserDM
# Incluye configuración de entorno, Docker Compose y pruebas

Write-Host "=== CONFIGURACIÓN COMPLETA DEL SISTEMA USERDM ===" -ForegroundColor Green
Write-Host "Iniciando configuración del sistema de microservicios..." -ForegroundColor Yellow

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

# Función para crear archivo .env si no existe
function Initialize-EnvironmentFile {
    Write-Host "Configurando archivo de variables de entorno..." -ForegroundColor Cyan
    
    if (-not (Test-Path ".env")) {
        if (Test-Path "env.example") {
            Copy-Item "env.example" ".env"
            Write-Host "✓ Archivo .env creado desde env.example" -ForegroundColor Green
            Write-Host "⚠️  IMPORTANTE: Edita el archivo .env con tus valores reales antes de continuar" -ForegroundColor Yellow
            Write-Host "   Presiona cualquier tecla cuando hayas configurado el archivo .env..." -ForegroundColor Cyan
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        } else {
            Write-Host "✗ No se encontró el archivo env.example" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "✓ Archivo .env ya existe" -ForegroundColor Green
    }
    return $true
}

# Función para limpiar contenedores anteriores
function Clear-PreviousContainers {
    Write-Host "Limpiando contenedores anteriores..." -ForegroundColor Yellow
    docker-compose down -v --remove-orphans 2>$null
    docker-compose -f docker-compose.test.yml down -v --remove-orphans 2>$null
    docker system prune -f 2>$null
    Write-Host "✓ Limpieza completada" -ForegroundColor Green
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

# Función para ejecutar pruebas
function Invoke-Tests {
    param(
        [string]$TestType = "all"
    )
    
    Write-Host "`n=== EJECUTANDO PRUEBAS ===" -ForegroundColor Green
    
    switch ($TestType) {
        "unit" {
            Write-Host "Ejecutando pruebas unitarias..." -ForegroundColor Cyan
            docker-compose -f docker-compose.test.yml run --rm test_runner bundle exec rspec spec/models/ --format documentation
        }
        "integration" {
            Write-Host "Ejecutando pruebas de integración..." -ForegroundColor Cyan
            docker-compose -f docker-compose.test.yml run --rm test_runner bundle exec rspec spec/integration/ --format documentation
        }
        "api" {
            Write-Host "Ejecutando pruebas de API..." -ForegroundColor Cyan
            docker-compose -f docker-compose.test.yml run --rm test_runner bundle exec rspec spec/requests/ --format documentation
        }
        "endpoints" {
            Write-Host "Ejecutando pruebas de endpoints..." -ForegroundColor Cyan
            .\test_microservice_endpoints.ps1
        }
        "all" {
            Write-Host "Ejecutando todas las pruebas..." -ForegroundColor Cyan
            docker-compose -f docker-compose.test.yml run --rm test_runner bundle exec rspec --format documentation --color
        }
        default {
            Write-Host "Tipo de prueba no reconocido: $TestType" -ForegroundColor Red
        }
    }
}

# Función para mostrar información del sistema
function Show-SystemInfo {
    Write-Host "`n=== INFORMACIÓN DEL SISTEMA ===" -ForegroundColor Green
    Write-Host "Servicios disponibles:" -ForegroundColor Cyan
    Write-Host "- Load Balancer: http://localhost:80" -ForegroundColor White
    Write-Host "- Health Check: http://localhost:8080" -ForegroundColor White
    Write-Host "- Auth Register: http://localhost:3001" -ForegroundColor White
    Write-Host "- Auth Login: http://localhost:3002" -ForegroundColor White
    Write-Host "- Auth Profile: http://localhost:3003" -ForegroundColor White
    Write-Host "- Auth Password: http://localhost:3004" -ForegroundColor White
    Write-Host "- Auth Logout: http://localhost:3005" -ForegroundColor White
    Write-Host "- Auth History: http://localhost:3006" -ForegroundColor White
    Write-Host "- Perfil Service: http://localhost:3007" -ForegroundColor White
    Write-Host "- Historial Service: http://localhost:3008" -ForegroundColor White
    Write-Host "- Database: localhost:5435" -ForegroundColor White
    Write-Host "- Redis: localhost:6379" -ForegroundColor White
    
    Write-Host "`nComandos útiles:" -ForegroundColor Cyan
    Write-Host "- Ver logs: docker-compose logs -f [servicio]" -ForegroundColor White
    Write-Host "- Detener servicios: docker-compose down" -ForegroundColor White
    Write-Host "- Reiniciar servicios: docker-compose restart" -ForegroundColor White
    Write-Host "- Ejecutar pruebas: .\run_complete_tests.ps1" -ForegroundColor White
}

# Función para verificar servicios
function Test-AllServices {
    Write-Host "`n=== VERIFICACIÓN DE SERVICIOS ===" -ForegroundColor Green
    
    $services = @(
        @{Name="Load Balancer"; Url="http://localhost/health"},
        @{Name="Health Check"; Url="http://localhost:8080"},
        @{Name="Auth Register"; Url="http://localhost:3001/health"},
        @{Name="Auth Login"; Url="http://localhost:3002/health"},
        @{Name="Auth Profile"; Url="http://localhost:3003/health"},
        @{Name="Auth Password"; Url="http://localhost:3004/health"},
        @{Name="Auth Logout"; Url="http://localhost:3005/health"},
        @{Name="Auth History"; Url="http://localhost:3006/health"},
        @{Name="Perfil Service"; Url="http://localhost:3007/health"},
        @{Name="Historial Service"; Url="http://localhost:3008/health"}
    )
    
    $allHealthy = $true
    
    foreach ($service in $services) {
        $healthy = Test-ServiceHealth -ServiceName $service.Name -Url $service.Url -MaxRetries 10
        if (-not $healthy) {
            $allHealthy = $false
        }
    }
    
    if ($allHealthy) {
        Write-Host "`n✓ Todos los servicios están funcionando correctamente" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  Algunos servicios no están respondiendo. Revisa los logs con 'docker-compose logs'" -ForegroundColor Yellow
    }
    
    return $allHealthy
}

# Función principal
function Start-CompleteSetup {
    param(
        [string]$Mode = "production",
        [string]$TestType = "none",
        [switch]$SkipTests,
        [switch]$SkipHealthCheck
    )
    
    # Verificar Docker
    if (-not (Test-DockerRunning)) {
        Write-Host "Error: Docker no está ejecutándose" -ForegroundColor Red
        Write-Host "Por favor, inicia Docker Desktop y vuelve a intentar" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "✓ Docker está ejecutándose" -ForegroundColor Green
    
    # Configurar archivo de entorno
    if (-not (Initialize-EnvironmentFile)) {
        Write-Host "Error: No se pudo configurar el archivo de entorno" -ForegroundColor Red
        exit 1
    }
    
    # Limpiar contenedores anteriores
    Clear-PreviousContainers
    
    # Construir y levantar servicios
    Write-Host "`nConstruyendo y levantando servicios en modo $Mode..." -ForegroundColor Yellow
    
    if ($Mode -eq "test") {
        docker-compose -f docker-compose.test.yml up -d --build
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error al levantar los servicios de prueba" -ForegroundColor Red
            exit 1
        }
    } else {
        docker-compose up -d --build
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error al levantar los servicios" -ForegroundColor Red
            exit 1
        }
    }
    
    # Esperar a que los servicios estén listos
    Write-Host "`nEsperando a que los servicios estén listos..." -ForegroundColor Yellow
    Start-Sleep -Seconds 45
    
    # Verificar salud de servicios
    if (-not $SkipHealthCheck) {
        Test-AllServices
    }
    
    # Mostrar información del sistema
    Show-SystemInfo
    
    # Ejecutar pruebas si se solicita
    if (-not $SkipTests -and $TestType -ne "none") {
        Invoke-Tests -TestType $TestType
    }
    
    # Opción para mantener servicios ejecutándose
    Write-Host "`n¿Deseas mantener los servicios ejecutándose? (s/n)" -ForegroundColor Cyan
    $keepRunning = Read-Host
    
    if ($keepRunning -eq "s" -or $keepRunning -eq "S") {
        Write-Host "Servicios mantenidos ejecutándose." -ForegroundColor Green
        Write-Host "Usa 'docker-compose down' para detenerlos cuando termines" -ForegroundColor Yellow
    } else {
        Write-Host "Deteniendo servicios..." -ForegroundColor Yellow
        if ($Mode -eq "test") {
            docker-compose -f docker-compose.test.yml down
        } else {
            docker-compose down
        }
    }
}

# Función para mostrar ayuda
function Show-Help {
    Write-Host "=== AYUDA DEL SCRIPT ===" -ForegroundColor Green
    Write-Host "Uso: .\setup_complete.ps1 [opciones]" -ForegroundColor White
    Write-Host ""
    Write-Host "Opciones:" -ForegroundColor Cyan
    Write-Host "  -Mode <modo>           Modo de ejecución (production, test)" -ForegroundColor White
    Write-Host "  -TestType <tipo>       Tipo de pruebas a ejecutar (unit, integration, api, endpoints, all, none)" -ForegroundColor White
    Write-Host "  -SkipTests             Saltar ejecución de pruebas" -ForegroundColor White
    Write-Host "  -SkipHealthCheck       Saltar verificación de salud de servicios" -ForegroundColor White
    Write-Host "  -Help                  Mostrar esta ayuda" -ForegroundColor White
    Write-Host ""
    Write-Host "Ejemplos:" -ForegroundColor Cyan
    Write-Host "  .\setup_complete.ps1" -ForegroundColor White
    Write-Host "  .\setup_complete.ps1 -Mode test -TestType all" -ForegroundColor White
    Write-Host "  .\setup_complete.ps1 -Mode production -SkipTests" -ForegroundColor White
}

# Procesar argumentos
param(
    [string]$Mode = "production",
    [string]$TestType = "none",
    [switch]$SkipTests,
    [switch]$SkipHealthCheck,
    [switch]$Help
)

# Mostrar ayuda si se solicita
if ($Help) {
    Show-Help
    exit 0
}

# Ejecutar configuración completa
Start-CompleteSetup -Mode $Mode -TestType $TestType -SkipTests:$SkipTests -SkipHealthCheck:$SkipHealthCheck 