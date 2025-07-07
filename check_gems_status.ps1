# Script para verificar el estado de las gemas
Write-Host "�� Verificando estado de las gemas..." -ForegroundColor Green

# Verificar gemas instaladas globalmente
Write-Host "📦 Gemas instaladas globalmente:" -ForegroundColor Yellow
gem list --local | Select-String -Pattern "bcrypt|sinatra|rspec|jwt|pg"

# Verificar gemas del proyecto
if (Test-Path "Gemfile.lock") {
    Write-Host "�� Gemas del proyecto (desde Gemfile.lock):" -ForegroundColor Yellow
    Get-Content "Gemfile.lock" | Select-String -Pattern "bcrypt|sinatra|rspec|jwt|pg"
} else {
    Write-Host "⚠️  No se encontró Gemfile.lock" -ForegroundColor Yellow
}

# Verificar bundle
Write-Host "�� Estado de bundle:" -ForegroundColor Yellow
bundle check
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Bundle está actualizado" -ForegroundColor Green
} else {
    Write-Host "❌ Bundle necesita actualización" -ForegroundColor Red
}

# Mostrar gemas del bundle
Write-Host "�� Gemas del bundle:" -ForegroundColor Yellow
bundle list | Select-String -Pattern "bcrypt|sinatra|rspec|jwt|pg"

Write-Host "🎯 Verificación completada!" -ForegroundColor Green 