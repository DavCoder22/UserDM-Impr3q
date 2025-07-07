# Script simple para verificar microservicios

Write-Host "=== VERIFICACION DE MICROSERVICIOS ===" -ForegroundColor Green

# Lista de microservicios
$microservices = @(
    "auth-register-service",
    "auth-login-service", 
    "auth-profile-service",
    "auth-password-service",
    "auth-logout-service",
    "auth-history-service",
    "perfil-service",
    "historial-service"
)

# Función para verificar un servicio
function Test-Service {
    param([string]$ServicePath)
    
    $serviceName = Split-Path $ServicePath -Leaf
    Write-Host "Verificando: $serviceName" -ForegroundColor Cyan
    
    # Verificar si el directorio existe
    if (Test-Path $ServicePath) {
        Write-Host "  Directorio existe" -ForegroundColor Green
        
        # Verificar Dockerfile
        $dockerfilePath = Join-Path $ServicePath "Dockerfile"
        if (Test-Path $dockerfilePath) {
            Write-Host "  Dockerfile existe" -ForegroundColor Green
        } else {
            Write-Host "  Dockerfile no encontrado" -ForegroundColor Yellow
        }
        
        # Verificar Gemfile
        $gemfilePath = Join-Path $ServicePath "Gemfile"
        if (Test-Path $gemfilePath) {
            Write-Host "  Gemfile existe" -ForegroundColor Green
        } else {
            Write-Host "  Gemfile no encontrado" -ForegroundColor Yellow
        }
        
        # Verificar app.rb
        $appPath = Join-Path $ServicePath "app.rb"
        if (Test-Path $appPath) {
            Write-Host "  app.rb existe" -ForegroundColor Green
        } else {
            Write-Host "  app.rb no encontrado" -ForegroundColor Yellow
        }
        
        # Verificar config.ru
        $configPath = Join-Path $ServicePath "config.ru"
        if (Test-Path $configPath) {
            Write-Host "  config.ru existe" -ForegroundColor Green
        } else {
            Write-Host "  config.ru no encontrado" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "  Directorio no existe" -ForegroundColor Red
    }
}

# Función principal
function Start-Verification {
    Write-Host "Iniciando verificacion de microservicios..." -ForegroundColor Yellow
    
    foreach ($service in $microservices) {
        Write-Host ""
        Write-Host "=== VERIFICANDO: $service ===" -ForegroundColor Magenta
        Test-Service -ServicePath $service
    }
    
    Write-Host ""
    Write-Host "=== RESUMEN ===" -ForegroundColor Green
    Write-Host "Verificacion completada" -ForegroundColor White
    
    Write-Host ""
    Write-Host "Proximos pasos:" -ForegroundColor Cyan
    Write-Host "1. Ejecutar: .\run_complete_tests.ps1" -ForegroundColor White
    Write-Host "2. Verificar documentacion en: http://localhost:8080" -ForegroundColor White
    Write-Host "3. Probar endpoints: .\test_microservice_endpoints.ps1" -ForegroundColor White
}

# Ejecutar verificación
Start-Verification 