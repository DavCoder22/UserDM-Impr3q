# Script simple para probar endpoints

Write-Host "=== PRUEBA DE ENDPOINTS ===" -ForegroundColor Green

# Función para probar un endpoint
function Test-Endpoint {
    param([string]$Url, [string]$ServiceName)
    
    Write-Host "Probando: $ServiceName" -ForegroundColor Cyan
    Write-Host "  URL: $Url" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "  Exito (200)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Respuesta inesperada: $($response.StatusCode)" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Lista de endpoints a probar
$endpoints = @(
    @{Url="http://localhost:3001/health"; Service="auth-register-service"},
    @{Url="http://localhost:3002/health"; Service="auth-login-service"},
    @{Url="http://localhost:3003/health"; Service="auth-profile-service"},
    @{Url="http://localhost:3004/health"; Service="auth-password-service"},
    @{Url="http://localhost:3005/health"; Service="auth-logout-service"},
    @{Url="http://localhost:3006/health"; Service="auth-history-service"},
    @{Url="http://localhost:3007/health"; Service="perfil-service"},
    @{Url="http://localhost:3008/health"; Service="historial-service"}
)

# Probar todos los endpoints
$results = @()
foreach ($endpoint in $endpoints) {
    $success = Test-Endpoint -Url $endpoint.Url -ServiceName $endpoint.Service
    $results += @{Service=$endpoint.Service; Success=$success}
}

# Mostrar resumen
Write-Host ""
Write-Host "=== RESUMEN ===" -ForegroundColor Green
$total = $results.Count
$successful = ($results | Where-Object { $_.Success }).Count
$failed = $total - $successful

Write-Host "Total de servicios: $total" -ForegroundColor White
Write-Host "Servicios funcionando: $successful" -ForegroundColor Green
Write-Host "Servicios con problemas: $failed" -ForegroundColor Red

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Servicios con problemas:" -ForegroundColor Red
    foreach ($result in $results) {
        if (-not $result.Success) {
            Write-Host "  - $($result.Service)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Documentacion de API disponible en:" -ForegroundColor Cyan
Write-Host "http://localhost:8080" -ForegroundColor White 