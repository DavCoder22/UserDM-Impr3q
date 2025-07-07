# Script específico para instalar bcrypt en Windows
Write-Host "🔧 Instalando bcrypt en Windows..." -ForegroundColor Green

# Verificar si estamos en el directorio correcto
if (-not (Test-Path "Gemfile")) {
    Write-Host "❌ No se encontró Gemfile en el directorio actual" -ForegroundColor Red
    Write-Host "�� Asegúrate de estar en el directorio raíz del proyecto" -ForegroundColor Cyan
    exit 1
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

# Verificar bigdecimal (ya está instalado por defecto)
Write-Host "🔍 Verificando bigdecimal..." -ForegroundColor Yellow
$bigdecimalVersion = gem list bigdecimal --local 2>$null
if ($bigdecimalVersion -like "*bigdecimal*") {
    Write-Host "✅ bigdecimal ya está instalado: $bigdecimalVersion" -ForegroundColor Green
} else {
    Write-Host "❌ bigdecimal no encontrado" -ForegroundColor Red
}

# Verificar bcrypt
Write-Host "�� Verificando bcrypt..." -ForegroundColor Yellow
$bcryptVersion = gem list bcrypt --local 2>$null
if ($bcryptVersion -like "*bcrypt*") {
    Write-Host "✅ bcrypt ya está instalado: $bcryptVersion" -ForegroundColor Green
} else {
    Write-Host "📦 bcrypt no está instalado, instalando..." -ForegroundColor Yellow
    
    # Intentar diferentes métodos de instalación de bcrypt
    Write-Host " Método 1: Instalación normal..." -ForegroundColor Cyan
    gem install bcrypt -v 3.1.18
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ bcrypt instalado correctamente" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Método 1 falló, intentando método 2..." -ForegroundColor Yellow
        
        # Método 2: Instalación con plataforma específica
        Write-Host " Método 2: Instalación con plataforma x64-mingw32..." -ForegroundColor Cyan
        gem install bcrypt -v 3.1.18 --platform=x64-mingw32
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ bcrypt instalado correctamente con plataforma específica" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Método 2 falló, intentando método 3..." -ForegroundColor Yellow
            
            # Método 3: Instalación sin versión específica
            Write-Host " Método 3: Instalación sin versión específica..." -ForegroundColor Cyan
            gem install bcrypt --platform=x64-mingw32
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ bcrypt instalado correctamente" -ForegroundColor Green
            } else {
                Write-Host "❌ No se pudo instalar bcrypt" -ForegroundColor Red
                Write-Host "💡 Considera usar Docker para evitar problemas de compilación" -ForegroundColor Cyan
            }
        }
    }
}

# Verificar bundler
Write-Host "🔍 Verificando bundler..." -ForegroundColor Yellow
$bundleVersion = bundle --version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Bundler encontrado: $bundleVersion" -ForegroundColor Green
} else {
    Write-Host "�� Instalando bundler..." -ForegroundColor Yellow
    gem install bundler
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Bundler instalado correctamente" -ForegroundColor Green
    } else {
        Write-Host "❌ Error al instalar bundler" -ForegroundColor Red
        exit 1
    }
}

# Limpiar cache de bundler
Write-Host "�� Limpiando cache de bundler..." -ForegroundColor Yellow
bundle clean --force 2>$null
bundle config --delete path 2>$null
bundle config --delete without 2>$null

# Configurar bundler para Windows
Write-Host "⚙️  Configurando bundler para Windows..." -ForegroundColor Yellow
bundle config set --local build.bcrypt --platform=x64-mingw32 2>$null

# Instalar dependencias
Write-Host "📦 Instalando dependencias del proyecto..." -ForegroundColor Yellow
bundle install --retry 3

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dependencias instaladas correctamente" -ForegroundColor Green
    
    # Verificar gemas críticas
    Write-Host "🔍 Verificando gemas críticas..." -ForegroundColor Yellow
    $criticalGems = @("bcrypt", "sinatra", "rspec")
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
    Write-Host "💡 Intentando instalación sin grupos de desarrollo..." -ForegroundColor Yellow
    bundle install --without development test --retry 3
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Dependencias instaladas sin grupos de desarrollo" -ForegroundColor Green
    } else {
        Write-Host "❌ Error persistente al instalar dependencias" -ForegroundColor Red
    }
}

Write-Host "�� Proceso completado!" -ForegroundColor Green 