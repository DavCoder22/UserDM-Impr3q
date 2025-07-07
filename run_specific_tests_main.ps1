# Script para ejecutar pruebas específicas
Write-Host "�� Ejecutando pruebas específicas..." -ForegroundColor Green

# Parámetros
param(
    [string]$TestFile = "",
    [string]$TestPattern = "",
    [switch]$AllTests,
    [switch]$BasicTests
)

# Verificar Docker
if (-not (docker --version 2>$null)) {
    Write-Host "❌ Docker no está disponible" -ForegroundColor Red
    exit 1
}

# Limpiar imágenes anteriores
Write-Host "�� Limpiando imágenes anteriores..." -ForegroundColor Yellow
docker rmi auth-tests 2>$null

# Construir imagen
Write-Host "🔨 Construyendo imagen..." -ForegroundColor Yellow
docker build -f Dockerfile.test -t auth-tests .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Imagen construida correctamente" -ForegroundColor Green
    
    # Determinar comando de pruebas
    $testCommand = ""
    
    if ($TestFile) {
        $testCommand = "bundle exec rspec $TestFile --format documentation"
        Write-Host "�� Ejecutando archivo: $TestFile" -ForegroundColor Cyan
    } elseif ($TestPattern) {
        $testCommand = "bundle exec rspec --pattern '$TestPattern' --format documentation"
        Write-Host "�� Ejecutando patrón: $TestPattern" -ForegroundColor Cyan
    } elseif ($AllTests) {
        $testCommand = "bundle exec rspec --format documentation"
        Write-Host "🎯 Ejecutando todas las pruebas" -ForegroundColor Cyan
    } elseif ($BasicTests) {
        $testCommand = "bundle exec rspec spec/simple_test_spec.rb --format documentation"
        Write-Host "�� Ejecutando pruebas básicas" -ForegroundColor Cyan
    } else {
        $testCommand = "bundle exec rspec spec/simple_test_spec.rb --format documentation"
        Write-Host "�� Ejecutando pruebas básicas (por defecto)" -ForegroundColor Cyan
    }
    
    # Ejecutar pruebas
    Write-Host "🚀 Ejecutando: $testCommand" -ForegroundColor Yellow
    docker run --rm auth-tests $testCommand
    
    $exitCode = $LASTEXITCODE
    
    # Mostrar resultado
    if ($exitCode -eq 0) {
        Write-Host "✅ Pruebas ejecutadas exitosamente!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Algunas pruebas fallaron (código: $exitCode)" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Error al construir la imagen" -ForegroundColor Red
}

Write-Host "�� Proceso completado!" -ForegroundColor Green 