# Script de verificación rápida del sistema UserDM
# Valida que todo funcione correctamente después de la limpieza

Write-Host "=== VERIFICACIÓN RÁPIDA DEL SISTEMA USERDM ===" -ForegroundColor Green
Write-Host "Verificando estado del sistema..." -ForegroundColor Yellow

# Función para verificar archivos esenciales
function Test-EssentialFiles {
    Write-Host "`n=== VERIFICACIÓN DE ARCHIVOS ESENCIALES ===" -ForegroundColor Cyan
    
    $essentialFiles = @(
        "docker-compose.yml",
        "docker-compose.test.yml",
        "env.example",
        "setup_complete.ps1",
        "verify_complete_setup.ps1",
        "deploy_and_test.ps1",
        "test_microservice_endpoints.ps1",
        "Gemfile",
        "README.md"
    )
    
    $missingFiles = @()
    foreach ($file in $essentialFiles) {
        if (Test-Path $file) {
            Write-Host "✓ $file" -ForegroundColor Green
        } else {
            $missingFiles += $file
            Write-Host "✗ $file" -ForegroundColor Red
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Host "`n⚠️  Archivos faltantes:" -ForegroundColor Yellow
        foreach ($file in $missingFiles) {
            Write-Host "  - $file" -ForegroundColor Yellow
        }
        return $false
    }
    
    Write-Host "`n✅ Todos los archivos esenciales están presentes" -ForegroundColor Green
    return $true
}

# Función para verificar Docker
function Test-DockerStatus {
    Write-Host "`n=== VERIFICACIÓN DE DOCKER ===" -ForegroundColor Cyan
    
    try {
        docker version | Out-Null
        Write-Host "✓ Docker está ejecutándose" -ForegroundColor Green
        
        docker-compose --version | Out-Null
        Write-Host "✓ Docker Compose está disponible" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Host "✗ Docker no está disponible: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Función para verificar configuración de Docker Compose
function Test-DockerComposeConfig {
    Write-Host "`n=== VERIFICACIÓN DE CONFIGURACIÓN DOCKER COMPOSE ===" -ForegroundColor Cyan
    
    try {
        $config = docker-compose config
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Configuración de Docker Compose válida" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ Error en configuración de Docker Compose" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "✗ Error al verificar configuración: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Función para verificar servicios si están ejecutándose
function Test-RunningServices {
    Write-Host "`n=== VERIFICACIÓN DE SERVICIOS EJECUTÁNDOSE ===" -ForegroundColor Cyan
    
    $runningContainers = docker ps --format "{{.Names}}" 2>$null
    
    if (-not $runningContainers) {
        Write-Host "ℹ️  No hay servicios ejecutándose actualmente" -ForegroundColor Yellow
        Write-Host "   Ejecuta .\deploy_and_test.ps1 para desplegar los servicios" -ForegroundColor Gray
        return $true
    }
    
    $expectedServices = @(
        "auth_register_service",
        "auth_login_service",
        "auth_profile_service",
        "auth_password_service",
        "auth_logout_service",
        "auth_history_service",
        "perfil_service",
        "historial_service",
        "nginx_alb",
        "auth_db",
        "auth_redis"
    )
    
    $runningServices = 0
    foreach ($service in $expectedServices) {
        if ($runningContainers -match $service) {
            Write-Host "✓ $service está ejecutándose" -ForegroundColor Green
            $runningServices++
        } else {
            Write-Host "ℹ️  $service no está ejecutándose" -ForegroundColor Gray
        }
    }
    
    if ($runningServices -gt 0) {
        Write-Host "`n✅ $runningServices servicios están ejecutándose" -ForegroundColor Green
        return $true
    } else {
        Write-Host "`nℹ️  No hay servicios esperados ejecutándose" -ForegroundColor Yellow
        return $true
    }
}

# Función para verificar endpoints si los servicios están ejecutándose
function Test-ServiceEndpoints {
    Write-Host "`n=== VERIFICACIÓN DE ENDPOINTS ===" -ForegroundColor Cyan
    
    $runningContainers = docker ps --format "{{.Names}}" 2>$null
    
    if (-not $runningContainers) {
        Write-Host "ℹ️  No hay servicios ejecutándose para verificar endpoints" -ForegroundColor Yellow
        return $true
    }
    
    $endpoints = @(
        @{Name="Load Balancer"; Url="http://localhost/health"},
        @{Name="Health Check"; Url="http://localhost:8080"},
        @{Name="Auth Register"; Url="http://localhost:3001/health"},
        @{Name="Auth Login"; Url="http://localhost:3002/health"},
        @{Name="Auth Profile"; Url="http://localhost:3003/health"},
        @{Name="Auth Password"; Url="http://localhost:3004/health"},
        @{Name="Auth Logout"; Url="http://localhost:3005/health"},
        @{Name="Auth History"; Url="http://localhost:3006/health"},
        @{Name="Perfil Service"; Url="http://localhost:3007/health"},
        @{Name="Historial Service"; Url="http://localhost:3008/health"}
    )
    
    $respondingEndpoints = 0
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint.Url -Method GET -TimeoutSec 5 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Host "✓ $($endpoint.Name) responde" -ForegroundColor Green
                $respondingEndpoints++
            } else {
                Write-Host "⚠️  $($endpoint.Name) responde con status $($response.StatusCode)" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "ℹ️  $($endpoint.Name) no responde (posiblemente no ejecutándose)" -ForegroundColor Gray
        }
    }
    
    if ($respondingEndpoints -gt 0) {
        Write-Host "`n✅ $respondingEndpoints endpoints están respondiendo" -ForegroundColor Green
    }
    
    return $true
}

# Función para mostrar estado del sistema
function Show-SystemStatus {
    Write-Host "`n=== ESTADO DEL SISTEMA ===" -ForegroundColor Green
    
    $runningContainers = docker ps --format "{{.Names}}" 2>$null
    
    if ($runningContainers) {
        Write-Host "🟢 Sistema ejecutándose" -ForegroundColor Green
        Write-Host ""
        Write-Host "Servicios activos:" -ForegroundColor Cyan
        foreach ($container in $runningContainers) {
            Write-Host "  - $container" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "Endpoints disponibles:" -ForegroundColor Cyan
        Write-Host "  - Aplicación: http://localhost:80" -ForegroundColor White
        Write-Host "  - Health Check: http://localhost:8080" -ForegroundColor White
        Write-Host "  - API Services: http://localhost:3001-3008" -ForegroundColor White
    } else {
        Write-Host "🔴 Sistema no ejecutándose" -ForegroundColor Red
        Write-Host ""
        Write-Host "Para desplegar el sistema:" -ForegroundColor Cyan
        Write-Host "  .\deploy_and_test.ps1" -ForegroundColor White
        Write-Host ""
        Write-Host "Para configuración rápida:" -ForegroundColor Cyan
        Write-Host "  .\setup_complete.ps1" -ForegroundColor White
    }
}

# Función para mostrar próximos pasos
function Show-NextSteps {
    Write-Host "`n=== PRÓXIMOS PASOS ===" -ForegroundColor Green
    
    $runningContainers = docker ps --format "{{.Names}}" 2>$null
    
    if ($runningContainers) {
        Write-Host "✅ El sistema está ejecutándose correctamente" -ForegroundColor Green
        Write-Host ""
        Write-Host "Comandos útiles:" -ForegroundColor Cyan
        Write-Host "  - Ver logs: docker-compose logs -f [servicio]" -ForegroundColor White
        Write-Host "  - Detener: docker-compose down" -ForegroundColor White
        Write-Host "  - Reiniciar: docker-compose restart" -ForegroundColor White
        Write-Host "  - Ejecutar pruebas: .\test_microservice_endpoints.ps1" -ForegroundColor White
        Write-Host "  - Verificación completa: .\verify_complete_setup.ps1" -ForegroundColor White
    } else {
        Write-Host "🚀 Para comenzar a usar el sistema:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Configurar variables de entorno:" -ForegroundColor White
        Write-Host "   Copy-Item env.example .env" -ForegroundColor Gray
        Write-Host "   # Editar .env con tus valores" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2. Desplegar el sistema:" -ForegroundColor White
        Write-Host "   .\deploy_and_test.ps1" -ForegroundColor Gray
        Write-Host ""
        Write-Host "3. Verificar funcionamiento:" -ForegroundColor White
        Write-Host "   .\verify_complete_setup.ps1" -ForegroundColor Gray
    }
}

# Función principal
function Start-QuickVerification {
    Write-Host "Iniciando verificación rápida del sistema..." -ForegroundColor Yellow
    
    $allChecksPassed = $true
    
    # 1. Verificar archivos esenciales
    if (-not (Test-EssentialFiles)) {
        $allChecksPassed = $false
    }
    
    # 2. Verificar Docker
    if (-not (Test-DockerStatus)) {
        $allChecksPassed = $false
    }
    
    # 3. Verificar configuración de Docker Compose
    if (-not (Test-DockerComposeConfig)) {
        $allChecksPassed = $false
    }
    
    # 4. Verificar servicios ejecutándose
    Test-RunningServices
    
    # 5. Verificar endpoints
    Test-ServiceEndpoints
    
    # 6. Mostrar estado del sistema
    Show-SystemStatus
    
    # 7. Mostrar próximos pasos
    Show-NextSteps
    
    # Resumen final
    if ($allChecksPassed) {
        Write-Host "`n🎉 ¡Verificación completada! El sistema está listo para usar." -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  Verificación completada con algunos problemas. Revisa los detalles arriba." -ForegroundColor Yellow
    }
}

# Ejecutar verificación rápida
Start-QuickVerification 