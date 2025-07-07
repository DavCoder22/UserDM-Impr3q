# Solución rápida para Ruby en PowerShell
Write-Host "⚡ Solución rápida para Ruby en PowerShell..." -ForegroundColor Green

# Buscar Ruby usando cmd
Write-Host "🔍 Buscando Ruby..." -ForegroundColor Yellow
$rubyPath = cmd /c "where ruby" 2>$null

if ($rubyPath) {
    $rubyDir = Split-Path $rubyPath.Trim() -Parent
    Write-Host "✅ Ruby encontrado en: $rubyDir" -ForegroundColor Green
    
    # Agregar al PATH de la sesión actual
    $env:PATH = "$env:PATH;$rubyDir"
    Write-Host "✅ Agregado al PATH de la sesión" -ForegroundColor Green
    
    # Verificar
    $rubyVersion = ruby --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "🎉 Ruby funciona: $rubyVersion" -ForegroundColor Green
        
        # Probar gem y bundle
        gem --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Gem funciona" -ForegroundColor Green
        }
        
        bundle --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Bundle funciona" -ForegroundColor Green
        }
    }
} else {
    Write-Host "❌ No se encontró Ruby" -ForegroundColor Red
} 