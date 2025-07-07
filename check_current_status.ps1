# Script para verificar el estado actual de las gemas
Write-Host "�� Verificando estado actual de las gemas..." -ForegroundColor Green

# Información del sistema
Write-Host "📊 Información del sistema:" -ForegroundColor Cyan
Write-Host "Ruby Version: $(ruby --version)" -ForegroundColor White
Write-Host "Gem Version: $(gem --version)" -ForegroundColor White
Write-Host "Platform: $env:PROCESSOR_ARCHITECTURE" -ForegroundColor White

# Verificar gemas instaladas globalmente
Write-Host "📦 Gemas instaladas globalmente:" -ForegroundColor Cyan
Write-Host "bigdecimal: $(gem list bigdecimal --local)" -ForegroundColor White
Write-Host "bcrypt: $(gem list bcrypt --local)" -ForegroundColor White
Write-Host "bundler: $(gem list bundler --local)" -ForegroundColor White

# Verificar bundler
Write-Host "🔧 Estado de bundler:" -ForegroundColor Cyan
try {
    $bundleVersion = bundle --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Bundler: $bundleVersion" -ForegroundColor Green
    } else {
        Write-Host "❌ Bundler no disponible" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Bundler no disponible" -ForegroundColor Red
}

# Verificar Gemfile.lock
if (Test-Path "Gemfile.lock") {
    Write-Host "📋 Gemfile.lock encontrado" -ForegroundColor Green
    Write-Host "Gemas en Gemfile.lock:" -ForegroundColor Cyan
    Get-Content "Gemfile.lock" | Select-String -Pattern "bcrypt|bigdecimal|sinatra|rspec" | ForEach-Object {
        Write-Host "  $_" -ForegroundColor White
    }
} else {
    Write-Host "⚠️  No se encontró Gemfile.lock" -ForegroundColor Yellow
}

# Verificar bundle check
Write-Host "�� Verificando bundle check..." -ForegroundColor Cyan
bundle check 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Bundle está actualizado" -ForegroundColor Green
} else {
    Write-Host "❌ Bundle necesita actualización" -ForegroundColor Red
}

Write-Host "🎯 Verificación completada!" -ForegroundColor Green 