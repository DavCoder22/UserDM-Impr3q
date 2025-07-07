# Script simple para ejecutar pruebas con Docker
Write-Host "�� Ejecutando pruebas simples con Docker..." -ForegroundColor Green

# Verificar Docker
if (-not (docker --version 2>$null)) {
    Write-Host "❌ Docker no está disponible" -ForegroundColor Red
    exit 1
}

# Verificar Gemfile
if (-not (Test-Path "Gemfile")) {
    Write-Host "❌ Gemfile no encontrado" -ForegroundColor Red
    exit 1
}

# Crear Dockerfile simple
Write-Host "�� Creando Dockerfile simple..." -ForegroundColor Yellow
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

# Set environment variables
ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    RAILS_ENV=test \
    RACK_ENV=test

# Install gems
COPY Gemfile ./
RUN gem install bundler -v 2.4.10 && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p /app/tmp /app/log

# Default command
CMD ["bundle", "exec", "rspec", "--format", "documentation"]
"@

$dockerfileContent | Out-File -FilePath "Dockerfile.simple" -Encoding UTF8

# Construir imagen
Write-Host "🔨 Construyendo imagen..." -ForegroundColor Yellow
docker build -f Dockerfile.simple -t simple-tests .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Imagen construida correctamente" -ForegroundColor Green
    
    # Ejecutar pruebas básicas
    Write-Host "�� Ejecutando pruebas básicas..." -ForegroundColor Yellow
    docker run --rm simple-tests bundle exec rspec spec/simple_test_spec.rb --format documentation
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Pruebas básicas pasaron" -ForegroundColor Green
        
        # Ejecutar todas las pruebas
        Write-Host "🧪 Ejecutando todas las pruebas..." -ForegroundColor Yellow
        docker run --rm simple-tests bundle exec rspec --format documentation
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "�� ¡Todas las pruebas pasaron!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Algunas pruebas fallaron" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Las pruebas básicas fallaron" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Error al construir la imagen" -ForegroundColor Red
}

# Limpiar
Remove-Item "Dockerfile.simple" -ErrorAction SilentlyContinue
docker rmi simple-tests -ErrorAction SilentlyContinue

Write-Host "�� Proceso completado!" -ForegroundColor Green 