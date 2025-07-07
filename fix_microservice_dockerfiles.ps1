# Script para verificar y corregir Dockerfiles de microservicios
# Asegura que todos los microservicios tengan Dockerfiles correctos

Write-Host "=== VERIFICACIÓN Y CORRECCIÓN DE DOCKERFILES ===" -ForegroundColor Green

# Lista de microservicios
$microservices = @(
    "auth-register-service",
    "auth-login-service", 
    "auth-profile-service",
    "auth-password-service",
    "auth-logout-service",
    "auth-history-service",
    "perfil-service",
    "historial-service"
)

# Función para crear Dockerfile estándar
function New-StandardDockerfile {
    param(
        [string]$ServiceName,
        [string]$AppFile = "app.rb"
    )
    
    $dockerfileContent = @"
FROM ruby:3.2-alpine

# Instalar dependencias del sistema
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    postgresql-client \
    git \
    && rm -rf /var/cache/apk/*

# Crear directorio de trabajo
WORKDIR /app

# Copiar Gemfile y Gemfile.lock
COPY Gemfile* ./
COPY $ServiceName/Gemfile* ./$ServiceName/ 2>`$null || echo "No Gemfile específico encontrado"

# Instalar gemas
RUN bundle config set --local build.nokogiri --use-system-libraries \
    && bundle config set --local build.bcrypt --use-system-libraries \
    && bundle install --jobs 4 --retry 3

# Copiar código de la aplicación
COPY . .

# Crear directorio para logs
RUN mkdir -p /app/logs

# Exponer puerto
EXPOSE 3000

# Variables de entorno por defecto
ENV RACK_ENV=production
ENV PORT=3000

# Comando de inicio
CMD ["ruby", "$ServiceName/$AppFile"]
"@

    return $dockerfileContent
}

# Función para verificar y corregir Dockerfile
function Test-AndFix-Dockerfile {
    param(
        [string]$ServicePath
    )
    
    $dockerfilePath = "$ServicePath/Dockerfile"
    
    Write-Host "Verificando: $ServicePath" -ForegroundColor Cyan
    
    if (Test-Path $dockerfilePath) {
        Write-Host "  ✓ Dockerfile existe" -ForegroundColor Green
        
        # Verificar contenido básico
        $content = Get-Content $dockerfilePath -Raw
        if ($content -match "FROM ruby" -and $content -match "WORKDIR /app") {
            Write-Host "  ✓ Dockerfile parece correcto" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Dockerfile puede necesitar actualización" -ForegroundColor Yellow
            $backupPath = "$dockerfilePath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item $dockerfilePath $backupPath
            Write-Host "  📋 Backup creado: $backupPath" -ForegroundColor Yellow
            
            # Crear nuevo Dockerfile
            $newContent = New-StandardDockerfile -ServiceName (Split-Path $ServicePath -Leaf)
            Set-Content $dockerfilePath $newContent
            Write-Host "  🔄 Dockerfile actualizado" -ForegroundColor Green
        }
    } else {
        Write-Host "  ✗ Dockerfile no encontrado - Creando..." -ForegroundColor Red
        
        # Crear directorio si no existe
        if (-not (Test-Path $ServicePath)) {
            New-Item -ItemType Directory -Path $ServicePath -Force | Out-Null
            Write-Host "  📁 Directorio creado: $ServicePath" -ForegroundColor Yellow
        }
        
        # Crear Dockerfile
        $newContent = New-StandardDockerfile -ServiceName (Split-Path $ServicePath -Leaf)
        Set-Content $dockerfilePath $newContent
        Write-Host "  ✅ Dockerfile creado" -ForegroundColor Green
    }
}

# Función para verificar archivos de aplicación
function Test-AppFiles {
    param(
        [string]$ServicePath
    )
    
    $appFiles = @("app.rb", "config.ru")
    $serviceName = Split-Path $ServicePath -Leaf
    
    foreach ($file in $appFiles) {
        $filePath = "$ServicePath/$file"
        if (Test-Path $filePath) {
            Write-Host "  ✓ $file existe" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ $file no encontrado en $serviceName" -ForegroundColor Yellow
        }
    }
}

# Función para verificar Gemfiles
function Test-Gemfiles {
    param(
        [string]$ServicePath
    )
    
    $gemfilePath = "$ServicePath/Gemfile"
    $serviceName = Split-Path $ServicePath -Leaf
    
    if (Test-Path $gemfilePath) {
        Write-Host "  ✓ Gemfile específico existe" -ForegroundColor Green
        
        # Verificar dependencias básicas
        $content = Get-Content $gemfilePath -Raw
        $requiredGems = @("sinatra", "pg", "bcrypt", "jwt")
        
        foreach ($gem in $requiredGems) {
            if ($content -match $gem) {
                Write-Host "    ✓ $gem incluido" -ForegroundColor Green
            } else {
                Write-Host "    ⚠ $gem no encontrado" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "  ℹ Usando Gemfile principal" -ForegroundColor Blue
    }
}

# Función para crear Gemfile específico si es necesario
function New-ServiceGemfile {
    param(
        [string]$ServicePath
    )
    
    $gemfilePath = "$ServicePath/Gemfile"
    $serviceName = Split-Path $ServicePath -Leaf
    
    if (-not (Test-Path $gemfilePath)) {
        $gemfileContent = @"
source 'https://rubygems.org'

gem 'sinatra'
gem 'sinatra-contrib'
gem 'pg'
gem 'bcrypt'
gem 'jwt'
gem 'json'
gem 'dotenv'
gem 'httparty'
gem 'rack-cors'

group :development, :test do
  gem 'rspec'
  gem 'rack-test'
  gem 'factory_bot'
  gem 'faker'
end
"@
        
        Set-Content $gemfilePath $gemfileContent
        Write-Host "  ✅ Gemfile específico creado para $serviceName" -ForegroundColor Green
    }
}

# Función para verificar estructura completa del servicio
function Test-ServiceStructure {
    param(
        [string]$ServicePath
    )
    
    $serviceName = Split-Path $ServicePath -Leaf
    Write-Host "`n=== VERIFICANDO: $serviceName ===" -ForegroundColor Magenta
    
    # Verificar Dockerfile
    Test-AndFix-Dockerfile -ServicePath $ServicePath
    
    # Verificar archivos de aplicación
    Test-AppFiles -ServicePath $ServicePath
    
    # Verificar Gemfile
    Test-Gemfiles -ServicePath $ServicePath
    
    # Crear Gemfile si es necesario
    New-ServiceGemfile -ServicePath $ServicePath
    
    # Verificar directorios importantes
    $importantDirs = @("models", "config", "spec")
    foreach ($dir in $importantDirs) {
        $dirPath = "$ServicePath/$dir"
        if (Test-Path $dirPath) {
            Write-Host "  ✓ Directorio $dir existe" -ForegroundColor Green
        } else {
            Write-Host "  ℹ Directorio $dir no encontrado (opcional)" -ForegroundColor Blue
        }
    }
}

# Función principal
function Start-DockerfileVerification {
    Write-Host "Iniciando verificación de Dockerfiles..." -ForegroundColor Yellow
    
    foreach ($service in $microservices) {
        Test-ServiceStructure -ServicePath $service
    }
    
    Write-Host "`n=== RESUMEN ===" -ForegroundColor Green
    Write-Host "Verificación completada para todos los microservicios" -ForegroundColor White
    Write-Host "Los Dockerfiles han sido verificados y corregidos según sea necesario" -ForegroundColor White
    
    Write-Host "`nPróximos pasos:" -ForegroundColor Cyan
    Write-Host "1. Ejecutar: .\run_complete_tests.ps1" -ForegroundColor White
    Write-Host "2. Verificar documentación en: http://localhost:8080" -ForegroundColor White
    Write-Host "3. Probar endpoints individuales" -ForegroundColor White
}

# Ejecutar verificación
Start-DockerfileVerification 