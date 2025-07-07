# Script para usar gemas precompiladas en Windows
Write-Host "🔧 Solucionando con gemas precompiladas..." -ForegroundColor Green

# Verificar si estamos en el directorio correcto
if (-not (Test-Path "Gemfile")) {
    Write-Host "❌ No se encontró Gemfile en el directorio actual" -ForegroundColor Red
    exit 1
}

# Función para instalar gema precompilada
function Install-PrecompiledGem {
    param([string]$GemName, [string]$Version = "")
    
    Write-Host "📦 Instalando $GemName (precompilada)..." -ForegroundColor Yellow
    
    if ($Version) {
        gem install $GemName -v $Version --platform=x64-mingw32
    } else {
        gem install $GemName --platform=x64-mingw32
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $GemName instalado correctamente" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Error al instalar $GemName" -ForegroundColor Red
        return $false
    }
}

# Limpiar instalaciones previas
Write-Host "🧹 Limpiando instalaciones previas..." -ForegroundColor Yellow
gem uninstall bcrypt -x 2>$null
gem uninstall bigdecimal -x 2>$null
bundle clean --force 2>$null

# Instalar gemas precompiladas
Write-Host "📦 Instalando gemas precompiladas..." -ForegroundColor Yellow

# Instalar bigdecimal precompilado
Install-PrecompiledGem "bigdecimal" "3.1.4"

# Instalar bcrypt precompilado
Install-PrecompiledGem "bcrypt" "3.1.18"

# Configurar bundler para usar gemas precompiladas
Write-Host "⚙️  Configurando Bundler..." -ForegroundColor Yellow
bundle config set --local build.bcrypt --platform=x64-mingw32
bundle config set --local build.bigdecimal --platform=x64-mingw32

# Instalar dependencias
Write-Host "📦 Instalando dependencias..." -ForegroundColor Yellow
bundle install --retry 3

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dependencias instaladas correctamente" -ForegroundColor Green
} else {
    Write-Host "❌ Error al instalar dependencias" -ForegroundColor Red
}

Write-Host "�� Proceso completado!" -ForegroundColor Green 