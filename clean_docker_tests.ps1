# Script para limpiar contenedores e imágenes de pruebas
Write-Host "�� Limpiando contenedores e imágenes de pruebas..." -ForegroundColor Green

# Detener contenedores
Write-Host "🛑 Deteniendo contenedores..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml down 2>$null

# Eliminar imágenes
Write-Host "🗑️  Eliminando imágenes..." -ForegroundColor Yellow
docker rmi auth-tests 2>$null
docker rmi simple-tests 2>$null

# Limpiar contenedores huérfanos
Write-Host "�� Limpiando contenedores huérfanos..." -ForegroundColor Yellow
docker container prune -f 2>$null

# Limpiar imágenes no utilizadas
Write-Host "�� Limpiando imágenes no utilizadas..." -ForegroundColor Yellow
docker image prune -f 2>$null

Write-Host "✅ Limpieza completada!" -ForegroundColor Green 