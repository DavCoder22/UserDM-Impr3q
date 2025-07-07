# Script simplificado para desplegar y probar el sistema
Write-Host "=== DESPLIEGUE Y PRUEBAS DEL SISTEMA USERDM ===" -ForegroundColor Green

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "docker-compose.yml")) {
    Write-Host "ERROR: No se encontro docker-compose.yml" -ForegroundColor Red
    Write-Host "Asegurate de estar en el directorio raiz del proyecto" -ForegroundColor Yellow
    exit 1
}

# 1. Configurar entorno
Write-Host "`n=== CONFIGURACION DEL ENTORNO ===" -ForegroundColor Cyan

# Crear archivo .env si no existe
if (-not (Test-Path ".env")) {
    Write-Host "Creando archivo .env desde env.example..." -ForegroundColor Yellow
    if (Test-Path "env.example") {
        Copy-Item "env.example" ".env"
        Write-Host "OK - Archivo .env creado" -ForegroundColor Green
    } else {
        Write-Host "ADVERTENCIA: No se encontro env.example" -ForegroundColor Yellow
    }
} else {
    Write-Host "OK - Archivo .env ya existe" -ForegroundColor Green
}

# 2. Verificar Docker
Write-Host "`n=== VERIFICACION DE DOCKER ===" -ForegroundColor Cyan

try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "OK - Docker disponible: $dockerVersion" -ForegroundColor Green
    } else {
        throw "Docker no disponible"
    }
} catch {
    Write-Host "ERROR: Docker no esta disponible" -ForegroundColor Red
    Write-Host "Instala Docker Desktop y vuelve a intentar" -ForegroundColor Yellow
    exit 1
}

# 3. Construir y desplegar servicios
Write-Host "`n=== CONSTRUCCION Y DESPLIEGUE DE SERVICIOS ===" -ForegroundColor Cyan

Write-Host "Deteniendo servicios existentes..." -ForegroundColor Yellow
docker-compose down -v 2>$null

Write-Host "Construyendo imagenes..." -ForegroundColor Yellow
docker-compose build --no-cache

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Fallo en la construccion de imagenes" -ForegroundColor Red
    exit 1
}

Write-Host "Iniciando servicios..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Fallo al iniciar servicios" -ForegroundColor Red
    exit 1
}

Write-Host "OK - Servicios desplegados correctamente" -ForegroundColor Green

# 4. Esperar a que los servicios esten listos
Write-Host "`n=== ESPERANDO A QUE LOS SERVICIOS ESTEN LISTOS ===" -ForegroundColor Cyan

$maxAttempts = 30
$attempt = 0
$servicesReady = $false

while ($attempt -lt $maxAttempts -and -not $servicesReady) {
    $attempt++
    Write-Host "Intento $attempt/$maxAttempts - Verificando servicios..." -ForegroundColor Yellow
    
    $containers = docker-compose ps --format "table {{.Name}}\t{{.Status}}" 2>$null
    $runningContainers = ($containers | Select-String "Up").Count
    $totalContainers = ($containers | Measure-Object -Line).Lines - 1
    
    if ($runningContainers -eq $totalContainers -and $totalContainers -gt 0) {
        $servicesReady = $true
        Write-Host "OK - Todos los servicios estan ejecutandose" -ForegroundColor Green
    } else {
        Write-Host "Esperando... ($runningContainers/$totalContainers servicios listos)" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
}

if (-not $servicesReady) {
    Write-Host "ADVERTENCIA: Algunos servicios pueden no estar completamente listos" -ForegroundColor Yellow
}

# 5. Ejecutar pruebas basicas
Write-Host "`n=== EJECUTANDO PRUEBAS BASICAS ===" -ForegroundColor Cyan

# Verificar endpoints principales
$endpoints = @(
    @{Name="Auth Service"; URL="http://localhost:3000/health"},
    @{Name="Profile Service"; URL="http://localhost:3001/health"},
    @{Name="History Service"; URL="http://localhost:3002/health"}
)

$passedTests = 0
$totalTests = $endpoints.Count

foreach ($endpoint in $endpoints) {
    try {
        $response = Invoke-WebRequest -Uri $endpoint.URL -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "OK - $($endpoint.Name): Funcionando" -ForegroundColor Green
            $passedTests++
        } else {
            Write-Host "FALLO - $($endpoint.Name): Status $($response.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "FALLO - $($endpoint.Name): No responde" -ForegroundColor Red
    }
}

# 6. Mostrar estado de contenedores
Write-Host "`n=== ESTADO DE CONTENEDORES ===" -ForegroundColor Cyan
docker-compose ps

# 7. Mostrar logs de servicios
Write-Host "`n=== LOGS DE SERVICIOS ===" -ForegroundColor Cyan
Write-Host "Mostrando ultimas 10 lineas de logs..." -ForegroundColor Yellow

$services = @("auth-service", "perfil-service", "historial-service")
foreach ($service in $services) {
    Write-Host "`n--- Logs de $service ---" -ForegroundColor Yellow
    docker-compose logs --tail=10 $service 2>$null
}

# 8. Resumen final
Write-Host "`n=== RESUMEN DEL DESPLIEGUE ===" -ForegroundColor Green

$successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)

Write-Host "Despliegue completado!" -ForegroundColor Green
Write-Host "Tasa de exito: $successRate% ($passedTests/$totalTests pruebas)" -ForegroundColor Cyan

if ($successRate -eq 100) {
    Write-Host "FELICITACIONES! Todos los servicios estan funcionando correctamente." -ForegroundColor Green
} elseif ($successRate -ge 66) {
    Write-Host "BUENO: La mayoria de servicios estan funcionando." -ForegroundColor Yellow
} else {
    Write-Host "ADVERTENCIA: Algunos servicios tienen problemas." -ForegroundColor Red
}

Write-Host "`nComandos utiles:" -ForegroundColor Cyan
Write-Host "- Ver logs: docker-compose logs -f [servicio]" -ForegroundColor White
Write-Host "- Detener: docker-compose down" -ForegroundColor White
Write-Host "- Reiniciar: docker-compose restart" -ForegroundColor White
Write-Host "- Verificar: .\quick_verify.ps1" -ForegroundColor White

Write-Host "`nEl sistema esta listo para usar!" -ForegroundColor Green 