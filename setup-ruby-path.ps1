# Script completo para configurar el entorno de Ruby
Write-Host "🚀 Configurando entorno completo de Ruby..." -ForegroundColor Green

# Verificar si estamos ejecutando como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "⚠️  Este script requiere permisos de administrador para configurar el PATH del sistema" -ForegroundColor Yellow
    Write-Host " Ejecuta PowerShell como administrador y vuelve a ejecutar este script" -ForegroundColor Cyan
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

# Verificar herramienta
# Script para configurar el PATH de Ruby en Windows
Write-Host "🔧 Configurando PATH de Ruby..." -ForegroundColor Green

# Función para verificar si Ruby está instalado
function Test-RubyInstallation {
    try {
        $rubyVersion = ruby --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Ruby encontrado: $rubyVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "❌ Ruby no encontrado en el PATH" -ForegroundColor Red
        return $false
    }
    return $false
}

# Función para encontrar Ruby instalado
function Find-RubyInstallation {
    $possiblePaths = @(
        "C:\Ruby32-x64\bin",
        "C:\Ruby31-x64\bin", 
        "C:\Ruby30-x64\bin",
        "C:\Ruby29-x64\bin",
        "C:\Ruby28-x64\bin",
        "C:\Program Files\Ruby32-x64\bin",
        "C:\Program Files\Ruby31-x64\bin",
        "C:\Program Files\Ruby30-x64\bin",
        "C:\Program Files\Ruby29-x64\bin",
        "C:\Program Files\Ruby28-x64\bin",
        "$env:USERPROFILE\.rubies\ruby-3.2.8\bin",
        "$env:USERPROFILE\.rubies\ruby-3.2.7\bin",
        "$env:USERPROFILE\.rubies\ruby-3.2.6\bin",
        "$env:USERPROFILE\.rubies\ruby-3.2.5\bin",
        "$env:USERPROFILE\.rubies\ruby-3.2.4\bin",
        "$env:USERPROFILE\.rubies\ruby-3.2.3\bin",
        "$env:USERPROFILE\.rubies\ruby-3.2.2\bin",
        "$env:USERPROFILE\.rubies\ruby-3.2.1\bin",
        "$env:USERPROFILE\.rubies\ruby-3.2.0\bin"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $rubyExe = Join-Path $path "ruby.exe"
            if (Test-Path $rubyExe) {
                Write-Host "✅ Ruby encontrado en: $path" -ForegroundColor Green
                return $path
            }
        }
    }
    
    return $null
}

# Función para agregar al PATH del sistema
function Add-ToSystemPath {
    param([string]$PathToAdd)
    
    try {
        # Obtener el PATH actual del sistema
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        
        # Verificar si ya está en el PATH
        if ($currentPath -like "*$PathToAdd*") {
            Write-Host "✅ El PATH ya contiene: $PathToAdd" -ForegroundColor Green
            return $true
        }
        
        # Agregar al PATH del sistema
        $newPath = "$currentPath;$PathToAdd"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        
        Write-Host "✅ Agregado al PATH del sistema: $PathToAdd" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Error al agregar al PATH: $_" -ForegroundColor Red
        return $false
    }
}

# Función para agregar al PATH de la sesión actual
function Add-ToSessionPath {
    param([string]$PathToAdd)
    
    try {
        $env:PATH = "$env:PATH;$PathToAdd"
        Write-Host "✅ Agregado al PATH de la sesión: $PathToAdd" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Error al agregar al PATH de sesión: $_" -ForegroundColor Red
        return $false
    }
}

# Verificar si Ruby ya está en el PATH
if (Test-RubyInstallation) {
    Write-Host "🎉 Ruby ya está configurado correctamente!" -ForegroundColor Green
    exit 0
}

# Buscar Ruby instalado
Write-Host "🔍 Buscando instalación de Ruby..." -ForegroundColor Yellow
$rubyPath = Find-RubyInstallation

if ($rubyPath) {
    Write-Host "📝 Configurando PATH..." -ForegroundColor Yellow
    
    # Agregar al PATH del sistema (requiere permisos de administrador)
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if ($isAdmin) {
        if (Add-ToSystemPath $rubyPath) {
            Write-Host "✅ Ruby agregado al PATH del sistema" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️  No tienes permisos de administrador para modificar el PATH del sistema" -ForegroundColor Yellow
        Write-Host "💡 Ejecuta este script como administrador para una configuración permanente" -ForegroundColor Cyan
    }
    
    # Agregar al PATH de la sesión actual
    if (Add-ToSessionPath $rubyPath) {
        Write-Host "✅ Ruby agregado al PATH de la sesión actual" -ForegroundColor Green
    }
    
    # Verificar la configuración
    Write-Host "🔍 Verificando configuración..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    
    if (Test-RubyInstallation) {
        Write-Host "🎉 ¡Ruby configurado exitosamente!" -ForegroundColor Green
        Write-Host "💡 Reinicia tu terminal para que los cambios surtan efecto" -ForegroundColor Cyan
    } else {
        Write-Host "❌ La configuración no funcionó como esperado" -ForegroundColor Red
    }
    
} else {
    Write-Host "❌ No se encontró Ruby instalado" -ForegroundColor Red
    Write-Host " Opciones para instalar Ruby:" -ForegroundColor Yellow
    Write-Host "1. RubyInstaller: https://rubyinstaller.org/downloads/" -ForegroundColor Cyan
    Write-Host "2. Chocolatey: choco install ruby" -ForegroundColor Cyan
    Write-Host "3. Scoop: scoop install ruby" -ForegroundColor Cyan
    Write-Host "4. WSL2 con Ubuntu y Ruby" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 Recomendación: Instala Ruby 3.2.8 desde RubyInstaller" -ForegroundColor Green
}

Write-Host " Proceso completado!" -ForegroundColor Green 