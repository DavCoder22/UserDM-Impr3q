# Script para ejecutar pruebas específicas con Docker
Write-Host "�� Ejecutando pruebas específicas con Docker..." -ForegroundColor Green

# Parámetros
param(
    [string]$TestFile = "",
    [string]$TestPattern = "",
    [switch]$AllTests
)

# Verificar Docker
if (-not (docker --version 2>$null)) {
    Write-Host "❌ Docker no está disponible" -ForegroundColor Red
    exit 1
}

# Detener contenedores existentes
Write-Host "🛑 Deteniendo contenedores existentes..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml down 2>$null

# Construir imagen si no existe
Write-Host "�� Verificando imagen de pruebas..." -ForegroundColor Yellow
$imageExists = docker images auth-tests --format "{{.Repository}}" 2>$null
if (-not $imageExists) {
    Write-Host "🔨 Construyendo imagen de pruebas..." -ForegroundColor Yellow
    docker build -f Dockerfile.test -t auth-tests .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error al construir la imagen" -ForegroundColor Red
        exit 1
    }
}

# Determinar comando de pruebas
$testCommand = "bundle exec rspec --format documentation"

if ($TestFile) {
    $testCommand = "bundle exec rspec $TestFile --format documentation"
    Write-Host "�� Ejecutando archivo específico: $TestFile" -ForegroundColor Cyan
} elseif ($TestPattern) {
    $testCommand = "bundle exec rspec --pattern '$TestPattern' --format documentation"
    Write-Host "�� Ejecutando pruebas con patrón: $TestPattern" -ForegroundColor Cyan
} elseif ($AllTests) {
    Write-Host "🎯 Ejecutando todas las pruebas" -ForegroundColor Cyan
} else {
    Write-Host "�� Ejecutando pruebas básicas" -ForegroundColor Cyan
    $testCommand = "bundle exec rspec spec/simple_test_spec.rb --format documentation"
}

# Ejecutar pruebas
Write-Host "🧪 Ejecutando: $testCommand" -ForegroundColor Yellow
docker run --rm -v ${PWD}:/app -w /app auth-tests $testCommand

$exitCode = $LASTEXITCODE

# Mostrar resultado
if ($exitCode -eq 0) {
    Write-Host "🎉 ¡Pruebas ejecutadas exitosamente!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Algunas pruebas fallaron (código: $exitCode)" -ForegroundColor Yellow
}

Write-Host "�� Proceso completado!" -ForegroundColor Green