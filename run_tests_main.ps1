# Script principal para ejecutar pruebas con Docker
Write-Host "�� Ejecutando pruebas principales..." -ForegroundColor Green

# Verificar Docker
if (-not (docker --version 2>$null)) {
    Write-Host "❌ Docker no está disponible" -ForegroundColor Red
    Write-Host "💡 Instala Docker Desktop desde: https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
    exit 1
}

# Verificar Docker Compose
if (-not (docker-compose --version 2>$null)) {
    Write-Host "❌ Docker Compose no está disponible" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Docker y Docker Compose verificados" -ForegroundColor Green

# Verificar archivos necesarios
Write-Host "🔍 Verificando archivos..." -ForegroundColor Yellow
$requiredFiles = @("docker-compose.test.yml", "Dockerfile.test", "Gemfile")
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file encontrado" -ForegroundColor Green
    } else {
        Write-Host "❌ $file no encontrado" -ForegroundColor Red
        exit 1
    }
}

# Detener contenedores existentes
Write-Host "🛑 Deteniendo contenedores existentes..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml down 2>$null

# Limpiar imágenes anteriores
Write-Host "�� Limpiando imágenes anteriores..." -ForegroundColor Yellow
docker rmi auth-tests 2>$null

# Construir imagen
Write-Host "🔨 Construyendo imagen de pruebas..." -ForegroundColor Yellow
docker build -f Dockerfile.test -t auth-tests .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Imagen construida correctamente" -ForegroundColor Green
    
    # Ejecutar pruebas con Docker Compose
    Write-Host "�� Ejecutando pruebas con Docker Compose..." -ForegroundColor Yellow
    docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit
    
    $exitCode = $LASTEXITCODE
    
    # Mostrar logs
    Write-Host "📋 Logs de las pruebas:" -ForegroundColor Cyan
    docker-compose -f docker-compose.test.yml logs test
    
    # Limpiar contenedores
    Write-Host "�� Limpiando contenedores..." -ForegroundColor Yellow
    docker-compose -f docker-compose.test.yml down
    
    # Mostrar resultado final
    if ($exitCode -eq 0) {
        Write-Host "�� ¡Todas las pruebas pasaron exitosamente!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Algunas pruebas fallaron (código: $exitCode)" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Error al construir la imagen" -ForegroundColor Red
    Write-Host "💡 Verifica que el Dockerfile.test esté corregido" -ForegroundColor Cyan
}

Write-Host "�� Proceso completado!" -ForegroundColor Green 