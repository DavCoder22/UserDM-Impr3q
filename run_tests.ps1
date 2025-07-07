# Script para ejecutar pruebas del proyecto
Write-Host "🚀 Iniciando pruebas del proyecto..." -ForegroundColor Green

# Verificar si Ruby está instalado
try {
    $rubyVersion = ruby --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Ruby encontrado: $rubyVersion" -ForegroundColor Green
    } else {
        throw "Ruby no encontrado"
    }
} catch {
    Write-Host "❌ Ruby no está instalado o no está en el PATH" -ForegroundColor Red
    Write-Host "Por favor instala Ruby desde https://www.ruby-lang.org/en/downloads/" -ForegroundColor Yellow
    exit 1
}

# Verificar si Bundler está instalado
try {
    $bundleVersion = bundle --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Bundler encontrado: $bundleVersion" -ForegroundColor Green
    } else {
        throw "Bundler no encontrado"
    }
} catch {
    Write-Host "❌ Bundler no está instalado" -ForegroundColor Red
    Write-Host "Instalando Bundler..." -ForegroundColor Yellow
    gem install bundler
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error al instalar Bundler" -ForegroundColor Red
        exit 1
    }
}

# Instalar dependencias
Write-Host "📦 Instalando dependencias..." -ForegroundColor Yellow
bundle install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error al instalar dependencias" -ForegroundColor Red
    exit 1
}

# Verificar si PostgreSQL está disponible
Write-Host "🔍 Verificando conexión a PostgreSQL..." -ForegroundColor Yellow
try {
    $testConnection = ruby test_db_connection.rb 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Conexión a PostgreSQL exitosa" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No se pudo conectar a PostgreSQL. Las pruebas pueden fallar." -ForegroundColor Yellow
        Write-Host "   Asegúrate de que PostgreSQL esté ejecutándose y configurado correctamente." -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  No se pudo verificar la conexión a PostgreSQL" -ForegroundColor Yellow
}

# Ejecutar pruebas
Write-Host "🧪 Ejecutando pruebas..." -ForegroundColor Yellow
bundle exec rspec --format documentation --color

# Mostrar resultado
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Todas las pruebas pasaron exitosamente!" -ForegroundColor Green
} else {
    Write-Host "❌ Algunas pruebas fallaron" -ForegroundColor Red
    Write-Host "Revisa el output anterior para más detalles" -ForegroundColor Yellow
}

Write-Host "📊 Generando reporte de cobertura..." -ForegroundColor Yellow
if (Test-Path "coverage/index.html") {
    Write-Host "📈 Reporte de cobertura disponible en: coverage/index.html" -ForegroundColor Green
    Start-Process "coverage/index.html"
}

Write-Host "🎉 Proceso completado!" -ForegroundColor Green 