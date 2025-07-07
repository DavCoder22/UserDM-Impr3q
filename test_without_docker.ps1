# Script para ejecutar pruebas sin Docker
Write-Host "🧪 Ejecutando pruebas sin Docker..." -ForegroundColor Green

# Verificar si Ruby está disponible
try {
    $rubyVersion = ruby --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Ruby encontrado: $rubyVersion" -ForegroundColor Green
        
        # Verificar si Bundler está disponible
        try {
            $bundleVersion = bundle --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Bundler encontrado: $bundleVersion" -ForegroundColor Green
                
                # Instalar dependencias
                Write-Host "📦 Instalando dependencias..." -ForegroundColor Yellow
                bundle install
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Dependencias instaladas correctamente" -ForegroundColor Green
                    
                    # Ejecutar pruebas básicas
                    Write-Host "🧪 Ejecutando pruebas básicas..." -ForegroundColor Yellow
                    bundle exec rspec spec/simple_test_spec.rb --format documentation
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "✅ Pruebas básicas pasaron" -ForegroundColor Green
                        
                        # Intentar ejecutar todas las pruebas
                        Write-Host "🧪 Ejecutando todas las pruebas..." -ForegroundColor Yellow
                        bundle exec rspec --format documentation
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "✅ Todas las pruebas pasaron exitosamente!" -ForegroundColor Green
                        } else {
                            Write-Host "⚠️  Algunas pruebas fallaron" -ForegroundColor Yellow
                        }
                    } else {
                        Write-Host "❌ Las pruebas básicas fallaron" -ForegroundColor Red
                    }
                } else {
                    Write-Host "❌ Error al instalar dependencias" -ForegroundColor Red
                }
            } else {
                throw "Bundler no encontrado"
            }
        } catch {
            Write-Host "❌ Bundler no está instalado" -ForegroundColor Red
            Write-Host "Instalando Bundler..." -ForegroundColor Yellow
            gem install bundler
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Bundler instalado correctamente" -ForegroundColor Green
                Write-Host "Ejecuta el script nuevamente" -ForegroundColor Yellow
            } else {
                Write-Host "❌ Error al instalar Bundler" -ForegroundColor Red
            }
        }
    } else {
        throw "Ruby no encontrado"
    }
} catch {
    Write-Host "❌ Ruby no está instalado o no está en el PATH" -ForegroundColor Red
    Write-Host "Opciones para continuar:" -ForegroundColor Yellow
    Write-Host "1. Instalar Ruby desde https://www.ruby-lang.org/en/downloads/" -ForegroundColor Cyan
    Write-Host "2. Usar Docker: docker-compose -f docker-compose.test.yml up --build" -ForegroundColor Cyan
    Write-Host "3. Usar WSL2 con Ruby instalado" -ForegroundColor Cyan
}

Write-Host "🎉 Proceso completado!" -ForegroundColor Green 