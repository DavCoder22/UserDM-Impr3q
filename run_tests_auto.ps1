# Script principal para ejecutar pruebas automáticamente
Write-Host "🚀 Iniciando ejecución automática de pruebas..." -ForegroundColor Green

# Verificar si Ruby está disponible
$rubyAvailable = $false
try {
    $rubyVersion = ruby --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $rubyAvailable = $true
        Write-Host "✅ Ruby encontrado: $rubyVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Ruby no encontrado" -ForegroundColor Red
}

# Verificar si Docker está disponible
$dockerAvailable = $false
try {
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $dockerAvailable = $true
        Write-Host "✅ Docker encontrado: $dockerVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Docker no encontrado" -ForegroundColor Red
}

# Decidir qué método usar
if ($rubyAvailable) {
    Write-Host "🎯 Usando Ruby local para ejecutar pruebas..." -ForegroundColor Cyan
    & "$PSScriptRoot\test_without_docker.ps1"
} elseif ($dockerAvailable) {
    Write-Host "🎯 Usando Docker para ejecutar pruebas..." -ForegroundColor Cyan
    & "$PSScriptRoot\test_with_docker.ps1"
} else {
    Write-Host "❌ No se encontró Ruby ni Docker" -ForegroundColor Red
    Write-Host "Opciones para continuar:" -ForegroundColor Yellow
    Write-Host "1. Instalar Ruby desde https://www.ruby-lang.org/en/downloads/" -ForegroundColor Cyan
    Write-Host "2. Instalar Docker Desktop desde https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
    Write-Host "3. Usar WSL2 con Ruby instalado" -ForegroundColor Cyan
    exit 1
}

Write-Host "🎉 Proceso completado!" -ForegroundColor Green 