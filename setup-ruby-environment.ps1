# Script completo para configurar el entorno de Ruby
Write-Host "🚀 Configurando entorno completo de Ruby..." -ForegroundColor Green

# Verificar si estamos ejecutando como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "⚠️  Este script requiere permisos de administrador para configurar el PATH del sistema" -ForegroundColor Yellow
    Write-Host "�� Ejecuta PowerShell como administrador y vuelve a ejecutar este script" -ForegroundColor Cyan
    Write-Host "   O ejecuta: Start-Process PowerShell -Verb RunAs" -ForegroundColor Cyan
}

# Función para verificar herramientas
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

# Verificar herramientas instaladas
Write-Host "🔍 Verificando herramientas..." -ForegroundColor Yellow

$ru 