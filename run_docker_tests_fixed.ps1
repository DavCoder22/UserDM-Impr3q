# Script corregido para ejecutar pruebas con Docker
Write-Host "�� Ejecutando pruebas con Docker (versión corregida)..." -ForegroundColor Green

# Función para verificar Docker
function Test-Docker {
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "❌ Docker no encontrado" -ForegroundColor Red
        return $false
    }
    return $false
}

# Función para verificar Docker Compose
function Test-DockerCompose {
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker Compose: $composeVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "❌ Docker Compose no encontrado" -ForegroundColor Red
        return $false
    }
    return $false
}

# Verificar herramientas
Write-Host "🔍 Verificando herramientas..." -ForegroundColor Yellow
$dockerOk = Test-Docker
$composeOk = Test-DockerCompose

if (-not $dockerOk -or -not $composeOk) {
    Write-Host "❌ Docker o Docker Compose no están disponibles" -ForegroundColor Red
    Write-Host "💡 Instala Docker Desktop desde: https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
    exit 1
}

# Verificar archivos necesarios
Write-Host "🔍 Verificando archivos de configuración..." -ForegroundColor Yellow
$requiredFiles = @("docker-compose.test.yml", "Dockerfile.test", "Gemfile")
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file encontrado" -ForegroundColor Green
    } else {
        Write-Host "❌ $file no encontrado" -ForegroundColor Red
        exit 1
    }
}

# Verificar si existe Gemfile.lock
if (Test-Path "Gemfile.lock") {
    Write-Host "✅ Gemfile.lock encontrado" -ForegroundColor Green
} else {
    Write-Host "⚠️  Gemfile.lock no encontrado, creando Dockerfile temporal..." -ForegroundColor Yellow
    
    # Crear Dockerfile temporal sin Gemfile.lock
    $dockerfileContent = @"
FROM ruby:3.2.2

WORKDIR /app

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set environment variabl 