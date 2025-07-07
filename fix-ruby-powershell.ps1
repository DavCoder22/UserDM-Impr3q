# Script para solucionar el problema de Ruby en PowerShell
Write-Host "🔧 Solucionando problema de Ruby en PowerShell..." -ForegroundColor Green

# Función para encontrar dónde está instalado Ruby
function Find-RubyFromCmd {
    Write-Host "🔍 Buscando Ruby desde Command Prompt..." -ForegroundColor Yellow
    
    # Intentar ejecutar cmd para encontrar Ruby
    try {
        $cmdOutput = cmd /c "where ruby" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $rubyPath = $cmdOutput.Trim()
            if ($rubyPath) {
                $rubyDir = Split-Path $rubyPath -Parent
                Write-Host "✅ Ruby encontrado en: $rubyDir" -ForegroundColor Green
                return $rubyDir
            }
        }
    } catch {
        Write-Host "❌ No se pudo encontrar Ruby desde cmd" -ForegroundColor Red
    }
    
    return $null
}

# Función para verificar si Ruby funciona en PowerShell
function Test-RubyInPowerShell {
    try {
        $rubyVersion = ruby --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Ruby funciona en PowerShell: $rubyVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "❌ Ruby no funciona en PowerShell" -ForegroundColor Red
        return $false
    }
    return $false
}

# Función para agregar al PATH de la sesión actual
function Add-ToSessionPath {
    param([string]$PathToAdd)
    
    try {
        # Verificar si ya está en el PATH de la sesión
        if ($env:PATH -like "*$PathToAdd*") {
            Write-Host "✅ Ya está en el PATH de la sesión: $PathToAdd" -ForegroundColor Green
            return $true
        }
        
        $env:PATH = "$env:PATH;$PathToAdd"
        Write-Host "✅ Agregado al PATH de la sesión: $PathToAdd" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Error al agregar al PATH de sesión: $_" -ForegroundColor Red
        return $false
    }
}

# Función para agregar al PATH del sistema
function Add-ToSystemPath {
    param([string]$PathToAdd)
    
    try {
        # Obtener el PATH actual del sistema
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        
        # Verificar si ya está en el PATH
        if ($currentPath -like "*$PathToAdd*") {
            Write-Host "✅ Ya está en el PATH del sistema: $PathToAdd" -ForegroundColor Green
            return $true
        }
        
        # Agregar al PATH del sistema
        $newPath = "$currentPath;$PathToAdd"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        
        Write-Host "✅ Agregado al PATH del sistema: $PathToAdd" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Error al agregar al PATH del sistema: $_" -ForegroundColor Red
        return $false
    }
}

# Verificar si Ruby ya funciona en PowerShell
if (Test-RubyInPowerShell) {
    Write-Host "🎉 Ruby ya funciona correctamente en PowerShell!" -ForegroundColor Green
    exit 0
}

# Buscar Ruby desde Command Prompt
$rubyDir = Find-RubyFromCmd

if ($rubyDir) {
    Write-Host "📝 Configurando PATH para PowerShell..." -ForegroundColor Yellow
    
    # Agregar al PATH de la sesión actual
    if (Add-ToSessionPath $rubyDir) {
        Write-Host "✅ Ruby agregado al PATH de la sesión actual" -ForegroundColor Green
    }
    
    # Verificar si tenemos permisos de administrador
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if ($isAdmin) {
        # Agregar al PATH del sistema para que sea permanente
        if (Add-ToSystemPath $rubyDir) {
            Write-Host "✅ Ruby agregado al PATH del sistema (permanente)" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️  No tienes permisos de administrador" -ForegroundColor Yellow
        Write-Host "💡 Para hacer la configuración permanente, ejecuta PowerShell como administrador" -ForegroundColor Cyan
    }
    
    # Verificar la configuración
    Write-Host "🔍 Verificando configuración..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    
    if (Test-RubyInPowerShell) {
        Write-Host "🎉 ¡Ruby ahora funciona en PowerShell!" -ForegroundColor Green
        
        # Probar gem y bundle
        Write-Host "🔍 Verificando gem y bundle..." -ForegroundColor Yellow
        try {
            $gemVersion = gem --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Gem funciona: $gemVersion" -ForegroundColor Green
            }
        } catch {
            Write-Host "❌ Gem no funciona" -ForegroundColor Red
        }
        
        try {
            $bundleVersion = bundle --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Bundle funciona: $bundleVersion" -ForegroundColor Green
            }
        } catch {
            Write-Host "❌ Bundle no funciona" -ForegroundColor Red
        }
        
    } else {
        Write-Host "❌ La configuración no funcionó como esperado" -ForegroundColor Red
        Write-Host "💡 Intenta reiniciar PowerShell" -ForegroundColor Cyan
    }
    
} else {
    Write-Host "❌ No se pudo encontrar Ruby" -ForegroundColor Red
    Write-Host "💡 Verifica que Ruby esté instalado correctamente" -ForegroundColor Cyan
}

Write-Host "�� Proceso completado!" -ForegroundColor Green 