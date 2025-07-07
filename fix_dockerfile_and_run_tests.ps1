# Script para corregir Dockerfile y ejecutar pruebas
Write-Host "�� Corrigiendo Dockerfile y ejecutando pruebas..." -ForegroundColor Green

# Verificar Docker
if (-not (docker --version 2>$null)) {
    Write-Host "❌ Docker no está disponible" -ForegroundColor Red
    exit 1
}

# Verificar archivos necesarios
if (-not (Test-Path "Gemfile")) {
    Write-Host "❌ Gemfile no encontrado" -ForegroundColor Red
    exit 1
}

# Crear Dockerfile corregido
Write-Host "�� Creando Dockerfile corregido..." -ForegroundColor Yellow
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

# Install gems (solo copiamos Gemfile, no Gemfile.lock)
COPY Gemfile ./
RUN gem install bundler -v 2.4.10 && \
    bundle config set --local without 'production' && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Create necessary directories and set permissions
RUN mkdir -p /app/tmp /app/log
RUN chmod -R 777 /app/tmp /app/log

# Default command
CMD ["bundle", "exec", "rspec", "--format", "documentation"]
"@

# Guardar el Dockerfile corregido
$dockerfileContent | Out-File -FilePath "Dockerfile.test.corrected" -Encoding UTF8
Write-Host "✅ Dockerfile corregido creado" -ForegroundColor Green

# Limpiar imágenes anteriores
Write-Host "�� Limpiando imágenes anteriores..." -ForegroundColor Yellow
docker rmi auth-tests 2>$null

# Construir imagen con el Dockerfile corregido
Write-Host "🔨 Construyendo imagen con Dockerfile corregido..." -ForegroundColor Yellow
docker build -f Dockerfile.test.corrected -t auth-tests .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Imagen construida correctamente" -ForegroundColor Green
    
    # Ejecutar pruebas básicas primero
    Write-Host "�� Ejecutando pruebas básicas..." -ForegroundColor Yellow
    docker run --rm auth-tests bundle exec rspec spec/simple_test_spec.rb --format documentation
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Pruebas básicas pasaron" -ForegroundColor Green
        
        # Ejecutar todas las pruebas
        Write-Host "🧪 Ejecutando todas las pruebas..." -ForegroundColor Yellow
        docker run --rm auth-tests bundle exec rspec --format documentation
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "�� ¡Todas las pruebas pasaron exitosamente!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Algunas pruebas fallaron" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Las pruebas básicas fallaron" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Error al construir la imagen" -ForegroundColor Red
}

# Limpiar archivo temporal
Remove-Item "Dockerfile.test.corrected" -ErrorAction SilentlyContinue

Write-Host "�� Proceso completado!" -ForegroundColor Green 