# Script básico para ejecutar pruebas

Write-Host "=== PRUEBAS BASICAS ===" -ForegroundColor Green

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

# Función para ejecutar pruebas con Docker
function Run-DockerTests {
    Write-Host "Ejecutando pruebas con Docker..." -ForegroundColor Yellow
    
    # Limpiar contenedores anteriores
    docker-compose -f docker-compose.test.yml down -v --remove-orphans 2>$null
    
    # Construir solo el servicio de pruebas
    Write-Host "Construyendo servicio de pruebas..." -ForegroundColor Cyan
    docker-compose -f docker-compose.test.yml build test_runner
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al construir el servicio de pruebas" -ForegroundColor Red
        return $false
    }
    
    # Levantar solo la base de datos y Redis
    Write-Host "Levantando base de datos y Redis..." -ForegroundColor Cyan
    docker-compose -f docker-compose.test.yml up -d test_db test_redis
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al levantar la base de datos" -ForegroundColor Red
        return $false
    }
    
    # Esperar a que la base de datos esté lista
    Write-Host "Esperando a que la base de datos esté lista..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
    
    # Ejecutar pruebas
    Write-Host "Ejecutando pruebas..." -ForegroundColor Green
    docker-compose -f docker-compose.test.yml run --rm test_runner bundle exec rspec --format documentation --color
    
    $testResult = $LASTEXITCODE
    
    # Limpiar
    Write-Host "Limpiando contenedores..." -ForegroundColor Yellow
    docker-compose -f docker-compose.test.yml down
    
    return $testResult -eq 0
}

# Función principal
function Start-BasicTests {
    # Verificar Docker
    if (-not (Test-DockerRunning)) {
        Write-Host "Error: Docker no está ejecutándose" -ForegroundColor Red
        Write-Host "Por favor, inicia Docker Desktop y vuelve a intentar" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Docker está funcionando correctamente" -ForegroundColor Green
    
    # Ejecutar pruebas
    $success = Run-DockerTests
    
    if ($success) {
        Write-Host ""
        Write-Host "=== RESULTADO ===" -ForegroundColor Green
        Write-Host "Pruebas ejecutadas exitosamente" -ForegroundColor White
    } else {
        Write-Host ""
        Write-Host "=== RESULTADO ===" -ForegroundColor Red
        Write-Host "Algunas pruebas fallaron" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Para ver la documentación de Swagger:" -ForegroundColor Cyan
    Write-Host "1. Ejecuta: docker-compose -f docker-compose.test.yml up swagger_ui" -ForegroundColor White
    Write-Host "2. Abre: http://localhost:8080" -ForegroundColor White
}

# Ejecutar pruebas
Start-BasicTests 