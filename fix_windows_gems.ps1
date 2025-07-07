# Script específico para solucionar errores de bigdecimal y bcrypt en Windows
Write-Host "🔧 Solucionando errores de bigdecimal y bcrypt en Windows..." -ForegroundColor Green

# Verificar si estamos en el directorio correcto
if (-not (Test-Path "Gemfile")) {
    Write-Host "❌ No se encontró Gemfile en el directorio actual" -ForegroundColor Red
    Write-Host "�� Asegúrate de estar en el directorio raíz del proyecto" -ForegroundColor Cyan
    exit 1
}

# Función para verificar si una gema está instalada
function Test-GemInstalled {
    param([string]$GemName)
    
    try {
        $result = gem list $GemName --local 2>$null
        if ($result -like "*$GemName*") {
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

# Función para instalar una gema específica
function Install-Gem {
    param([string]$GemName, [string]$Version = "")
    
    Write-Host "📦 Instalando $GemName..." -ForegroundColor Yellow
    
    if ($Version) {
        gem install $GemName -v $Version --platform=ruby
    } else {
        gem install $GemName --platform=ruby
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $GemName instalado correctamente" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Error al instalar $GemName" -ForegroundColor Red
        return $false
    }
}

# Verificar herramientas
Write-Host "🔍 Verificando herramientas..." -ForegroundColor Yellow
$rubyVersion = ruby --version 2>$null
$gemVersion = gem --version 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Ruby no está funcionando correctamente" -ForegroundColor Red
    exit 1
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Gem no está funcionando correctamente" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Ruby: $rubyVersion" -ForegroundColor Green
Write-Host "✅ Gem: $gemVersion" -ForegroundColor Green

# Actualizar RubyGems
Write-Host "�� Actualizando RubyGems..." -ForegroundColor Yellow
gem update --system
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ RubyGems actualizado" -ForegroundColor Green
} else {
    Write-Host "⚠️  No se pudo actualizar RubyGems" -ForegroundColor Yellow
}

# Limpiar cache
Write-Host "🧹 Limpiando cache..." -ForegroundColor Yellow
gem cleanup 2>$null
bundle clean --force 2>$null

# Verificar e instalar bigdecimal
Write-Host "🔍 Verificando bigdecimal..." -ForegroundColor Yellow
if (Test-GemInstalled "bigdecimal") {
    Write-Host "✅ bigdecimal ya está instalado" -ForegroundColor Green
} else {
    Write-Host "📦 Instalando bigdecimal..." -ForegroundColor Yellow
    Install-Gem "bigdecimal" "3.1.4"
}

# Verificar e instalar bcrypt
Write-Host "�� Verificando bcrypt..." -ForegroundColor Yellow
if (Test-GemInstalled "bcrypt") {
    Write-Host "✅ bcrypt ya está instalado" -ForegroundColor Green
} else {
    Write-Host "📦 Instalando bcrypt..." -ForegroundColor Yellow
    Install-Gem "bcrypt" "3.1.18"
}

# Instalar herramientas de desarrollo necesarias
Write-Host "🔧 Instalando herramientas de desarrollo..." -ForegroundColor Yellow
$devTools = @("rake", "bundler")
foreach ($tool in $devTools) {
    if (-not (Test-GemInstalled $tool)) {
        Install-Gem $tool
    } else {
        Write-Host "✅ $tool ya está instalado" -ForegroundColor Green
    }
}

# Configurar bundler para Windows
Write-Host "⚙️  Configurando Bundler para Windows..." -ForegroundColor Yellow
bundle config set --local build.bcrypt --with-opt-dir="C:\Ruby32-x64\msys64\usr" 2>$null
bundle config set --local build.bigdecimal --with-opt-dir="C:\Ruby32-x64\msys64\usr" 2>$null

# Intentar instalación con diferentes estrategias
Write-Host "📦 Intentando instalación de dependencias..." -ForegroundColor Yellow

# Estrategia 1: Instalación normal
Write-Host "�� Estrategia 1: Instalación normal..." -ForegroundColor Cyan
bundle install --retry 3

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Instalación exitosa con estrategia 1" -ForegroundColor Green
} else {
    Write-Host "⚠️  Estrategia 1 falló, intentando estrategia 2..." -ForegroundColor Yellow
    
    # Estrategia 2: Instalación con --path
    Write-Host "�� Estrategia 2: Instalación con --path vendor/bundle..." -ForegroundColor Cyan
    bundle install --path vendor/bundle --retry 3
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Instalación exitosa con estrategia 2" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Estrategia 2 falló, intentando estrategia 3..." -ForegroundColor Yellow
        
        # Estrategia 3: Instalación sin grupos de desarrollo
        Write-Host "�� Estrategia 3: Instalación sin grupos de desarrollo..." -ForegroundColor Cyan
        bundle install --without development test --retry 3
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Instalación exitosa con estrategia 3" -ForegroundColor Green
        } else {
            Write-Host "❌ Todas las estrategias fallaron" -ForegroundColor Red
        }
    }
}

# Verificar gemas críticas
Write-Host "🔍 Verificando gemas críticas..." -ForegroundColor Yellow
$criticalGems = @("bigdecimal", "bcrypt", "sinatra", "rspec")
foreach ($gem in $criticalGems) {
    $gemInstalled = bundle list | Select-String $gem
    if ($gemInstalled) {
        Write-Host "✅ $gem instalado" -ForegroundColor Green
    } else {
        Write-Host "❌ $gem no encontrado" -ForegroundColor Red
    }
}

# Mostrar información de depuración
Write-Host "�� Información de depuración:" -ForegroundColor Cyan
Write-Host "Ruby Version: $rubyVersion" -ForegroundColor White
Write-Host "Gem Version: $gemVersion" -ForegroundColor White
Write-Host "Platform: $env:PROCESSOR_ARCHITECTURE" -ForegroundColor White

Write-Host "�� Proceso completado!" -ForegroundColor Green 