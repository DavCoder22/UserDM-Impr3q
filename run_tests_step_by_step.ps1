# Script para ejecutar pruebas paso a paso
Write-Host "�� Ejecutando pruebas paso a paso..." -ForegroundColor Green

# Función para verificar herramienta
function Test-Tool {
    param([string]$ToolName, [string]$Command)
    
    try {
        $result = & $Command --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $ToolName encontrado: $result" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "❌ $ToolName no encontrado" -ForegroundColor Red
        return $false
    }
    return $false
}

# Verificar herramientas
Write-Host "🔍 Verificando herramientas..." -ForegroundColor Yellow
$rubyOk = Test-Tool "Ruby" "ruby"
$gemOk = Test-Tool "Gem" "gem"
$bundleOk = Test-Tool "Bundler" "bundle"

if (-not $rubyOk) {
    Write-Host "❌ Ruby no está disponible" -ForegroundColor Red
    exit 1
}

# Instalar Bundler si no está disponible
if (-not $bundleOk) {
    Write-Host "�� Instalando Bundler..." -ForegroundColor Yellow
    gem install bundler
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Bundler instalado correctamente" -ForegroundColor Green
        $bundleOk = $true
    } else {
        Write-Host "❌ Error al instalar Bundler" -ForegroundColor Red
        exit 1
    }
}

# Instalar dependencias
Write-Host "📦 Instalando dependencias..." -ForegroundColor Yellow
bundle install
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dependencias instaladas correctamente" -ForegroundColor Green
} else {
    Write-Host "❌ Error al instalar dependencias" -ForegroundColor Red
    exit 1
}

# Verificar si existe el archivo de prueba básica
$basicTestFile = "spec/simple_test_spec.rb"
if (Test-Path $basicTestFile) {
    Write-Host "🧪 Ejecutando prueba básica..." -ForegroundColor Yellow
    bundle exec rspec $basicTestFile --format documentation
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Prueba básica pasó" -ForegroundColor Green
    } else {
        Write-Host "❌ Prueba básica falló" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  No se encontró el archivo de prueba básica" -ForegroundColor Yellow
}

# Ejecutar todas las pruebas
Write-Host "🧪 Ejecutando todas las pruebas..." -ForegroundColor Yellow
bundle exec rspec --format documentation
if ($LASTEXITCODE -eq 0) {
    Write-Host "�� ¡Todas las pruebas pasaron exitosamente!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Algunas pruebas fallaron" -ForegroundColor Yellow
}

Write-Host "�� Proceso completado!" -ForegroundColor Green 