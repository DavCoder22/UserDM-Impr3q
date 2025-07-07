# Script para ejecutar pruebas con Docker
Write-Host "🐳 Ejecutando pruebas con Docker..." -ForegroundColor Green

# Verificar si Docker está disponible
try {
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker encontrado: $dockerVersion" -ForegroundColor Green
        
        # Verificar si Docker Compose está disponible
        try {
            $composeVersion = docker-compose --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Docker Compose encontrado: $composeVersion" -ForegroundColor Green
                
                # Detener contenedores existentes
                Write-Host "🛑 Deteniendo contenedores existentes..." -ForegroundColor Yellow
                docker-compose -f docker-compose.test.yml down 2>$null
                
                # Construir y ejecutar pruebas
                Write-Host "🔨 Construyendo imagen de pruebas..." -ForegroundColor Yellow
                docker build -f Dockerfile.test -t auth-tests .
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Imagen construida correctamente" -ForegroundColor Green
                    
                    # Ejecutar pruebas
                    Write-Host "🧪 Ejecutando pruebas..." -ForegroundColor Yellow
                    docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "✅ Pruebas ejecutadas exitosamente!" -ForegroundColor Green
                        
                        # Mostrar logs de las pruebas
                        Write-Host "📋 Logs de las pruebas:" -ForegroundColor Cyan
                        docker-compose -f docker-compose.test.yml logs test
                        
                    } else {
                        Write-Host "⚠️  Algunas pruebas fallaron" -ForegroundColor Yellow
                        Write-Host "📋 Logs de error:" -ForegroundColor Red
                        docker-compose -f docker-compose.test.yml logs test
                    }
                } else {
                    Write-Host "❌ Error al construir la imagen" -ForegroundColor Red
                }
                
                # Limpiar contenedores
                Write-Host "🧹 Limpiando contenedores..." -ForegroundColor Yellow
                docker-compose -f docker-compose.test.yml down
                
            } else {
                throw "Docker Compose no encontrado"
            }
        } catch {
            Write-Host "❌ Docker Compose no está instalado" -ForegroundColor Red
            Write-Host "Instala Docker Desktop que incluye Docker Compose" -ForegroundColor Yellow
        }
    } else {
        throw "Docker no encontrado"
    }
} catch {
    Write-Host "❌ Docker no está instalado o no está en el PATH" -ForegroundColor Red
    Write-Host "Instala Docker Desktop desde https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
}

Write-Host "🎉 Proceso completado!" -ForegroundColor Green 