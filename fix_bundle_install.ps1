# Script para solucionar problemas de bundle install
Write-Host "🔧 Solucionando problemas de bundle install..." -ForegroundColor Green

# Verificar si estamos en el directorio correcto
if (-not (Test-Path "Gemfile")) {
    Write-Host "❌ No se encontró Gemfile en el directorio actual" -ForegroundColor Red
    Write-Host "�� Asegúrate de estar en el directorio raíz del proyecto" -ForegroundColor Cyan
    exit 1
}

# Verificar herramientas
Write-Host "🔍 Verificando herramientas..." -ForegroundColor Yellow
$rubyOk = ruby --version 2>$null
$gemOk = gem --version 2>$null
$bundleOk = bundle --version 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ruby no está funcionando correctamente" -ForegroundColor Red
    exit 1
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Gem no está funcionando correctamente" -ForegroundColor Red
    exit 1
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Bundle no está funcionando correctamente" -ForegroundColor Red
    Write-Host "�� Instalando Bundler..." -ForegroundColor Yellow
    gem install bundler
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error al instalar Bundler" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Herramientas verificadas correctamente" -ForegroundColor Green

# Limpiar cache de bundler si existe
Write-Host "�� Limpiando cache de Bundler..." -ForegroundColor Yellow
bundle clean --force 2>$null
bundle config --delete path 2>$null
bundle config --delete without 2>$null

# Instalar dependencias
Write-Host "📦 Instalando dependencias..." -ForegroundColor Yellow
bundle install --retry 3

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dependencias instaladas correctamente" -ForegroundColor Green
    
    # Verificar que bcrypt esté instalado
    Write-Host "🔍 Verificando gemas críticas..." -ForegroundColor Yellow
    $bcryptInstalled = bundle list | Select-String "bcrypt"
    if ($bcryptInstalled) {
        Write-Host "✅ bcrypt instalado correctamente" -ForegroundColor Green
    } else {
        Write-Host "❌ bcrypt no se instaló correctamente" -ForegroundColor Red
    }
    
    # Verificar otras gemas importantes
    $criticalGems = @("sinatra", "rspec", "jwt", "pg")
    foreach ($gem in $criticalGems) {
        $gemInstalled = bundle list | Select-String $gem
        if ($gemInstalled) {
            Write-Host "✅ $gem instalado" -ForegroundColor Green
        } else {
            Write-Host "❌ $gem no encontrado" -ForegroundColor Red
        }
    }
    
} else {
    Write-Host "❌ Error al instalar dependencias" -ForegroundColor Red
    Write-Host "💡 Intentando soluciones alternativas..." -ForegroundColor Yellow
    
    # Intentar con --path vendor/bundle
    Write-Host "📦 Intentando instalación en vendor/bundle..." -ForegroundColor Yellow
    bundle install --path vendor/bundle --retry 3
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Dependencias instaladas en vendor/bundle" -ForegroundColor Green
    } else {
        Write-Host "❌ Error persistente al instalar dependencias" -ForegroundColor Red
        Write-Host "💡 Posibles soluciones:" -ForegroundColor Cyan
        Write-Host "1. Verificar conexión a internet" -ForegroundColor White
        Write-Host "2. Actualizar RubyGems: gem update --system" -ForegroundColor White
        Write-Host "3. Limpiar cache: gem cleanup" -ForegroundColor White
        Write-Host "4. Usar Docker para evitar problemas de dependencias" -ForegroundColor White
    }
}

Write-Host "�� Proceso completado!" -ForegroundColor Green 