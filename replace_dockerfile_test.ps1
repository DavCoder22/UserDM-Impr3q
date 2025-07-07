# Script para reemplazar el Dockerfile.test original
Write-Host "🔧 Reemplazando Dockerfile.test original..." -ForegroundColor Green

# Hacer backup del archivo original
if (Test-Path "Dockerfile.test") {
    Copy-Item "Dockerfile.test" "Dockerfile.test.backup"
    Write-Host "✅ Backup creado: Dockerfile.test.backup" -ForegroundColor Green
}

# Crear nuevo Dockerfile.test corregido
$newDockerfileContent = @"
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

# Reemplazar el archivo original
$newDockerfileContent | Out-File -FilePath "Dockerfile.test" -Encoding UTF8
Write-Host "✅ Dockerfile.test reemplazado correctamente" -ForegroundColor Green

Write-Host "🎯 Dockerfile.test corregido!" -ForegroundColor Green 