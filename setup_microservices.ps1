# Script simple para configurar microservicios

Write-Host "=== CONFIGURACIÓN DE MICROSERVICIOS ===" -ForegroundColor Green

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

# Función para crear Dockerfile
function Create-Dockerfile {
    param([string]$ServiceName)
    
    $content = @"
FROM ruby:3.2-alpine

RUN apk add --no-cache build-base postgresql-dev postgresql-client git

WORKDIR /app

COPY Gemfile* ./
COPY $ServiceName/Gemfile* ./$ServiceName/ 2>/dev/null || echo "No Gemfile específico"

RUN bundle config set --local build.bcrypt --use-system-libraries
RUN bundle install --jobs 4 --retry 3

COPY . .

RUN mkdir -p /app/logs

EXPOSE 3000

ENV RACK_ENV=production
ENV PORT=3000

CMD ["ruby", "$ServiceName/app.rb"]
"@
    
    return $content
}

# Función para crear Gemfile
function Create-Gemfile {
    param([string]$ServiceName)
    
    $content = @"
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
    
    return $content
}

# Función para verificar y crear archivos
function Setup-Service {
    param([string]$ServicePath)
    
    $serviceName = Split-Path $ServicePath -Leaf
    Write-Host "Configurando: $serviceName" -ForegroundColor Cyan
    
    # Crear directorio si no existe
    if (-not (Test-Path $ServicePath)) {
        New-Item -ItemType Directory -Path $ServicePath -Force | Out-Null
        Write-Host "  📁 Directorio creado: $ServicePath" -ForegroundColor Yellow
    }
    
    # Verificar Dockerfile
    $dockerfilePath = Join-Path $ServicePath "Dockerfile"
    if (Test-Path $dockerfilePath) {
        Write-Host "  ✓ Dockerfile existe" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Dockerfile no encontrado - Creando..." -ForegroundColor Red
        $dockerfileContent = Create-Dockerfile -ServiceName $serviceName
        Set-Content -Path $dockerfilePath -Value $dockerfileContent
        Write-Host "  ✅ Dockerfile creado" -ForegroundColor Green
    }
    
    # Verificar Gemfile
    $gemfilePath = Join-Path $ServicePath "Gemfile"
    if (Test-Path $gemfilePath) {
        Write-Host "  ✓ Gemfile existe" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Gemfile no encontrado - Creando..." -ForegroundColor Red
        $gemfileContent = Create-Gemfile -ServiceName $serviceName
        Set-Content -Path $gemfilePath -Value $gemfileContent
        Write-Host "  ✅ Gemfile creado" -ForegroundColor Green
    }
    
    # Verificar archivos de aplicación
    $appFiles = @("app.rb", "config.ru")
    foreach ($file in $appFiles) {
        $filePath = Join-Path $ServicePath $file
        if (Test-Path $filePath) {
            Write-Host "  ✓ $file existe" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ $file no encontrado en $serviceName" -ForegroundColor Yellow
        }
    }
}

# Función principal
function Start-Setup {
    Write-Host "Iniciando configuración de microservicios..." -ForegroundColor Yellow
    
    foreach ($service in $microservices) {
        Write-Host "`n=== CONFIGURANDO: $service ===" -ForegroundColor Magenta
        Setup-Service -ServicePath $service
    }
    
    Write-Host "`n=== RESUMEN ===" -ForegroundColor Green
    Write-Host "Configuración completada para todos los microservicios" -ForegroundColor White
    
    Write-Host "`nPróximos pasos:" -ForegroundColor Cyan
    Write-Host "1. Ejecutar: .\run_complete_tests.ps1" -ForegroundColor White
    Write-Host "2. Verificar documentación en: http://localhost:8080" -ForegroundColor White
    Write-Host "3. Probar endpoints: .\test_microservice_endpoints.ps1" -ForegroundColor White
}

# Ejecutar configuración
Start-Setup 