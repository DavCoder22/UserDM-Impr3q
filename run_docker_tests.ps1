# Script optimizado para ejecutar pruebas con Docker Compose
Write-Host "�� Ejecutando pruebas con Docker Compose..." -ForegroundColor Green

# Función para verificar Docker
function Test-Docker {
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "❌ Docker no encontrado" -ForegroundColor Red
        return $false
    }
    return $false
}

# Función para verificar Docker Compose
function Test-DockerCompose {
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker Compose: $composeVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "❌ Docker Compose no encontrado" -ForegroundColor Red
        return $false
    }
    return $false
}

# Verificar herramientas
Write-Host "🔍 Verificando herramientas..." -ForegroundColor Yellow
$dockerOk = Test-Docker
$composeOk = Test-DockerCompose

if (-not $dockerOk -or -not $composeOk) {
    Write-Host "❌ Docker o Docker Compose no están disponibles" -ForegroundColor Red
    Write-Host "💡 Instala Docker Desktop desde: https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
    exit 1
}

# Verificar archivos necesarios
Write-Host "🔍 Verificando archivos de configuración..." -ForegroundColor Yellow
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

# Construir imagen de pruebas
Write-Host "🔨 Construyendo imagen de pruebas..." -ForegroundColor Yellow
docker build -f Dockerfile.test -t auth-tests .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Imagen construida correctamente" -ForegroundColor Green
} else {
    Write-Host "❌ Error al construir la imagen" -ForegroundColor Red
    exit 1
}

# Ejecutar pruebas
Write-Host "�� Ejecutando pruebas con Docker Compose..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit

# Capturar el código de salida
$exitCode = $LASTEXITCODE

# Mostrar logs
Write-Host "📋 Logs de las pruebas:" -ForegroundColor Cyan
docker-compose -f docker-compose.test.yml logs test

# Limpiar contenedores
Write-Host "�� Limpiando contenedores..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml down

# Mostrar resultado
if ($exitCode -eq 0) {
    Write-Host "�� ¡Todas las pruebas pasaron exitosamente!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Algunas pruebas fallaron (código: $exitCode)" -ForegroundColor Yellow
}

Write-Host "�� Proceso completado!" -ForegroundColor Green 