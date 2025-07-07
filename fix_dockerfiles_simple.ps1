# Script simplificado para verificar y corregir Dockerfiles de microservicios

Write-Host "=== VERIFICACIÓN DE DOCKERFILES ===" -ForegroundColor Green

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
    param([string]$ServiceName)
    
    return @"
FROM ruby:3.2-alpine

RUN apk add --no-cache build-base postgresql-dev postgresql-client git

WORKDIR /app

COPY Gemfile* ./
COPY $ServiceName/Gemfile* ./$ServiceName/ 2>/dev/null || echo "No Gemfile específico"

RUN bundle config set --local build.bcrypt --use-system-libraries && bundle install --jobs 4 --retry 3

COPY . .

RUN mkdir -p /app/logs

EXPOSE 3000

ENV RACK_ENV=production
ENV PORT=3000

CMD ["ruby", "$ServiceName/app.rb"]
"@
}

# Función para verificar y corregir Dockerfile
function Test-AndFix-Dockerfile {
    param([string]$ServicePath)
    
    $dockerfilePath = "$ServicePath/Dockerfile"
    $serviceName = Split-Path $ServicePath -Leaf
    
    Write-Host "Verificando: $serviceName" -ForegroundColor Cyan
    
    if (Test-Path $dockerfilePath) {
        Write-Host "  ✓ Dockerfile existe" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Dockerfile no encontrado - Creando..." -ForegroundColor Red
        
        if (-not (Test-Path $ServicePath)) {
            New-Item -ItemType Directory -Path $ServicePath -Force | Out-Null
            Write-Host "  📁 Directorio creado: $ServicePath" -ForegroundColor Yellow
        }
        
        $newContent = New-StandardDockerfile -ServiceName $serviceName
        Set-Content $dockerfilePath $newContent
        Write-Host "  ✅ Dockerfile creado" -ForegroundColor Green
    }
}

# Función para verificar archivos de aplicación
function Test-AppFiles {
    param([string]$ServicePath)
    
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

# Función para crear Gemfile específico
function New-ServiceGemfile {
    param([string]$ServicePath)
    
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

# Función principal
function Start-DockerfileVerification {
    Write-Host "Iniciando verificación de Dockerfiles..." -ForegroundColor Yellow
    
    foreach ($service in $microservices) {
        Write-Host "`n=== VERIFICANDO: $service ===" -ForegroundColor Magenta
        
        Test-AndFix-Dockerfile -ServicePath $service
        Test-AppFiles -ServicePath $service
        New-ServiceGemfile -ServicePath $service
    }
    
    Write-Host "`n=== RESUMEN ===" -ForegroundColor Green
    Write-Host "Verificación completada para todos los microservicios" -ForegroundColor White
    
    Write-Host "`nPróximos pasos:" -ForegroundColor Cyan
    Write-Host "1. Ejecutar: .\run_complete_tests.ps1" -ForegroundColor White
    Write-Host "2. Verificar documentación en: http://localhost:8080" -ForegroundColor White
}

# Ejecutar verificación
Start-DockerfileVerification 