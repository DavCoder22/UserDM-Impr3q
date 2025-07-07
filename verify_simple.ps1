# Script simplificado para verificar el estado del sistema
Write-Host "=== VERIFICACION RAPIDA DEL SISTEMA USERDM ===" -ForegroundColor Green

# 1. Verificar archivos esenciales
Write-Host "`n=== VERIFICACION DE ARCHIVOS ESENCIALES ===" -ForegroundColor Cyan

$essentialFiles = @(
    "docker-compose.yml",
    "env.example",
    "Gemfile",
    "README.md"
)

$missingFiles = @()
foreach ($file in $essentialFiles) {
    if (Test-Path $file) {
        Write-Host "OK - $file" -ForegroundColor Green
    } else {
        $missingFiles += $file
        Write-Host "FALTANTE - $file" -ForegroundColor Red
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "ERROR: Faltan archivos esenciales" -ForegroundColor Red
    exit 1
}

# 2. Verificar Docker
Write-Host "`n=== VERIFICACION DE DOCKER ===" -ForegroundColor Cyan

try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "OK - Docker: $dockerVersion" -ForegroundColor Green
    } else {
        throw "Docker no disponible"
    }
} catch {
    Write-Host "ERROR: Docker no esta disponible" -ForegroundColor Red
    Write-Host "Instala Docker Desktop" -ForegroundColor Yellow
    exit 1
}

# 3. Verificar estado de contenedores
Write-Host "`n=== ESTADO DE CONTENEDORES ===" -ForegroundColor Cyan

$containers = docker-compose ps --format "table {{.Name}}\t{{.Status}}" 2>$null

if ($containers) {
    $runningContainers = ($containers | Select-String "Up").Count
    $totalContainers = ($containers | Measure-Object -Line).Lines - 1
    
    Write-Host "Contenedores ejecutandose: $runningContainers/$totalContainers" -ForegroundColor Cyan
    
    if ($runningContainers -eq $totalContainers -and $totalContainers -gt 0) {
        Write-Host "OK - Todos los contenedores estan ejecutandose" -ForegroundColor Green
    } else {
        Write-Host "ADVERTENCIA: Algunos contenedores no estan ejecutandose" -ForegroundColor Yellow
    }
    
    # Mostrar estado detallado
    docker-compose ps
} else {
    Write-Host "INFO: No hay contenedores ejecutandose" -ForegroundColor Yellow
}

# 4. Verificar endpoints de servicios
Write-Host "`n=== VERIFICACION DE ENDPOINTS ===" -ForegroundColor Cyan

$endpoints = @(
    @{Name="Auth Service"; URL="http://localhost:3000/health"},
    @{Name="Profile Service"; URL="http://localhost:3001/health"},
    @{Name="History Service"; URL="http://localhost:3002/health"}
)

$workingEndpoints = 0
$totalEndpoints = $endpoints.Count

foreach ($endpoint in $endpoints) {
    try {
        $response = Invoke-WebRequest -Uri $endpoint.URL -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "OK - $($endpoint.Name): Funcionando" -ForegroundColor Green
            $workingEndpoints++
        } else {
            Write-Host "FALLO - $($endpoint.Name): Status $($response.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "FALLO - $($endpoint.Name): No responde" -ForegroundColor Red
    }
}

# 5. Verificar recursos del sistema
Write-Host "`n=== RECURSOS DEL SISTEMA ===" -ForegroundColor Cyan

# Memoria disponible
$memory = Get-CimInstance -ClassName Win32_OperatingSystem
$freeMemoryGB = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)
$totalMemoryGB = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 1)
$memoryUsage = [math]::Round((($totalMemoryGB - $freeMemoryGB) / $totalMemoryGB) * 100, 1)

Write-Host "Memoria: $freeMemoryGB GB libres de $totalMemoryGB GB ($memoryUsage% usado)" -ForegroundColor Cyan

# Espacio en disco
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 1)
$totalSpaceGB = [math]::Round($disk.Size / 1GB, 1)
$diskUsage = [math]::Round((($totalSpaceGB - $freeSpaceGB) / $totalSpaceGB) * 100, 1)

Write-Host "Disco C: $freeSpaceGB GB libres de $totalSpaceGB GB ($diskUsage% usado)" -ForegroundColor Cyan

# 6. Resumen final
Write-Host "`n=== RESUMEN DE VERIFICACION ===" -ForegroundColor Green

$overallStatus = "OK"
$issues = @()

if ($missingFiles.Count -gt 0) {
    $overallStatus = "ERROR"
    $issues += "Faltan archivos esenciales"
}

if ($workingEndpoints -lt $totalEndpoints) {
    $overallStatus = "ADVERTENCIA"
    $issues += "Algunos servicios no responden"
}

if ($memoryUsage -gt 90) {
    $overallStatus = "ADVERTENCIA"
    $issues += "Memoria muy alta"
}

if ($diskUsage -gt 90) {
    $overallStatus = "ADVERTENCIA"
    $issues += "Disco muy lleno"
}

$endpointSuccess = [math]::Round(($workingEndpoints / $totalEndpoints) * 100, 1)

Write-Host "Estado general: $overallStatus" -ForegroundColor $(if ($overallStatus -eq "OK") { "Green" } elseif ($overallStatus -eq "ADVERTENCIA") { "Yellow" } else { "Red" })
Write-Host "Endpoints funcionando: $endpointSuccess% ($workingEndpoints/$totalEndpoints)" -ForegroundColor Cyan

if ($issues.Count -gt 0) {
    Write-Host "`nProblemas detectados:" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "- $issue" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nNo se detectaron problemas" -ForegroundColor Green
}

Write-Host "`nComandos utiles:" -ForegroundColor Cyan
Write-Host "- Iniciar servicios: docker-compose up -d" -ForegroundColor White
Write-Host "- Ver logs: docker-compose logs -f" -ForegroundColor White
Write-Host "- Detener servicios: docker-compose down" -ForegroundColor White
Write-Host "- Limpiar: .\clean_simple.ps1" -ForegroundColor White
Write-Host "- Desplegar: .\deploy_simple.ps1" -ForegroundColor White 