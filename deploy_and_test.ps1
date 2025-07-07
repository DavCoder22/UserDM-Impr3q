# Script completo para desplegar el sistema y ejecutar todas las pruebas
# Incluye configuración, despliegue, pruebas y verificación

Write-Host "=== DESPLIEGUE Y PRUEBAS COMPLETAS DEL SISTEMA USERDM ===" -ForegroundColor Green
Write-Host "Iniciando despliegue y configuración del sistema..." -ForegroundColor Yellow

# Función para verificar prerrequisitos
function Test-Prerequisites {
    Write-Host "`n=== VERIFICACIÓN DE PRERREQUISITOS ===" -ForegroundColor Cyan
    
    $prerequisites = @{
        "Docker" = $false
        "Docker Compose" = $false
        "PowerShell" = $false
        "Archivo .env" = $false
    }
    
    # Verificar Docker
    try {
        docker version | Out-Null
        $prerequisites["Docker"] = $true
        Write-Host "✓ Docker está disponible" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Docker no está disponible" -ForegroundColor Red
    }
    
    # Verificar Docker Compose
    try {
        docker-compose --version | Out-Null
        $prerequisites["Docker Compose"] = $true
        Write-Host "✓ Docker Compose está disponible" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Docker Compose no está disponible" -ForegroundColor Red
    }
    
    # Verificar PowerShell
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        $prerequisites["PowerShell"] = $true
        Write-Host "✓ PowerShell está disponible (v$($PSVersionTable.PSVersion))" -ForegroundColor Green
    } else {
        Write-Host "✗ PowerShell requiere versión 5 o superior" -ForegroundColor Red
    }
    
    # Verificar archivo .env
    if (Test-Path ".env") {
        $prerequisites["Archivo .env"] = $true
        Write-Host "✓ Archivo .env configurado" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Archivo .env no encontrado, se creará desde env.example" -ForegroundColor Yellow
        if (Test-Path "env.example") {
            Copy-Item "env.example" ".env"
            Write-Host "✓ Archivo .env creado desde env.example" -ForegroundColor Green
            $prerequisites["Archivo .env"] = $true
        } else {
            Write-Host "✗ No se puede crear .env, env.example no existe" -ForegroundColor Red
        }
    }
    
    $allPrerequisitesMet = $prerequisites.Values -notcontains $false
    
    if (-not $allPrerequisitesMet) {
        Write-Host "`n❌ No todos los prerrequisitos están cumplidos. Por favor, instala los componentes faltantes." -ForegroundColor Red
        return $false
    }
    
    Write-Host "`n✅ Todos los prerrequisitos están cumplidos" -ForegroundColor Green
    return $true
}

# Función para limpiar recursos anteriores
function Clear-PreviousResources {
    Write-Host "`n=== LIMPIEZA DE RECURSOS ANTERIORES ===" -ForegroundColor Cyan
    
    Write-Host "Deteniendo contenedores anteriores..." -ForegroundColor Yellow
    docker-compose down -v --remove-orphans 2>$null
    docker-compose -f docker-compose.test.yml down -v --remove-orphans 2>$null
    
    Write-Host "Eliminando imágenes no utilizadas..." -ForegroundColor Yellow
    docker system prune -f 2>$null
    
    Write-Host "✓ Limpieza completada" -ForegroundColor Green
}

# Función para configurar el entorno
function Initialize-Environment {
    Write-Host "`n=== CONFIGURACIÓN DEL ENTORNO ===" -ForegroundColor Cyan
    
    # Verificar y configurar archivo .env
    if (-not (Test-Path ".env")) {
        if (Test-Path "env.example") {
            Copy-Item "env.example" ".env"
            Write-Host "✓ Archivo .env creado desde env.example" -ForegroundColor Green
            Write-Host "⚠️  IMPORTANTE: Edita el archivo .env con tus valores reales" -ForegroundColor Yellow
            Write-Host "   Presiona cualquier tecla cuando hayas configurado el archivo .env..." -ForegroundColor Cyan
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        } else {
            Write-Host "✗ No se puede crear .env, env.example no existe" -ForegroundColor Red
            return $false
        }
    }
    
    # Crear directorios necesarios
    $directories = @("logs", "tmp", "coverage")
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Host "✓ Directorio creado: $dir" -ForegroundColor Green
        }
    }
    
    Write-Host "✓ Configuración del entorno completada" -ForegroundColor Green
    return $true
}

# Función para construir y desplegar servicios
function Deploy-Services {
    param(
        [string]$Mode = "production"
    )
    
    Write-Host "`n=== DESPLIEGUE DE SERVICIOS ===" -ForegroundColor Cyan
    Write-Host "Desplegando en modo: $Mode" -ForegroundColor Yellow
    
    $composeFile = if ($Mode -eq "test") { "docker-compose.test.yml" } else { "docker-compose.yml" }
    
    Write-Host "Construyendo y levantando servicios con $composeFile..." -ForegroundColor Yellow
    
    # Construir y levantar servicios
    docker-compose -f $composeFile up -d --build
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Error al desplegar los servicios" -ForegroundColor Red
        return $false
    }
    
    Write-Host "✓ Servicios desplegados exitosamente" -ForegroundColor Green
    
    # Esperar a que los servicios estén listos
    Write-Host "Esperando a que los servicios estén listos..." -ForegroundColor Yellow
    Start-Sleep -Seconds 45
    
    return $true
}

# Función para verificar salud de servicios
function Test-ServiceHealth {
    Write-Host "`n=== VERIFICACIÓN DE SALUD DE SERVICIOS ===" -ForegroundColor Cyan
    
    $services = @(
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
    
    $healthyServices = 0
    $totalServices = $services.Count
    
    foreach ($service in $services) {
        try {
            $response = Invoke-WebRequest -Uri $service.Url -Method GET -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Host "✓ $($service.Name) está saludable" -ForegroundColor Green
                $healthyServices++
            } else {
                Write-Host "⚠️  $($service.Name) responde pero con status $($response.StatusCode)" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "✗ $($service.Name) no responde: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    $healthPercentage = [math]::Round(($healthyServices / $totalServices) * 100, 1)
    Write-Host "`nSalud general del sistema: $healthPercentage% ($healthyServices/$totalServices servicios)" -ForegroundColor Cyan
    
    return $healthPercentage -ge 80
}

# Función para ejecutar pruebas unitarias
function Invoke-UnitTests {
    Write-Host "`n=== PRUEBAS UNITARIAS ===" -ForegroundColor Cyan
    
    Write-Host "Ejecutando pruebas unitarias..." -ForegroundColor Yellow
    
    try {
        docker-compose -f docker-compose.test.yml run --rm test_runner bundle exec rspec spec/models/ --format documentation
        $unitTestsPassed = $LASTEXITCODE -eq 0
    }
    catch {
        Write-Host "✗ Error al ejecutar pruebas unitarias: $($_.Exception.Message)" -ForegroundColor Red
        $unitTestsPassed = $false
    }
    
    if ($unitTestsPassed) {
        Write-Host "✓ Pruebas unitarias pasaron" -ForegroundColor Green
    } else {
        Write-Host "✗ Pruebas unitarias fallaron" -ForegroundColor Red
    }
    
    return $unitTestsPassed
}

# Función para ejecutar pruebas de integración
function Invoke-IntegrationTests {
    Write-Host "`n=== PRUEBAS DE INTEGRACIÓN ===" -ForegroundColor Cyan
    
    Write-Host "Ejecutando pruebas de integración..." -ForegroundColor Yellow
    
    try {
        docker-compose -f docker-compose.test.yml run --rm test_runner bundle exec rspec spec/integration/ --format documentation
        $integrationTestsPassed = $LASTEXITCODE -eq 0
    }
    catch {
        Write-Host "✗ Error al ejecutar pruebas de integración: $($_.Exception.Message)" -ForegroundColor Red
        $integrationTestsPassed = $false
    }
    
    if ($integrationTestsPassed) {
        Write-Host "✓ Pruebas de integración pasaron" -ForegroundColor Green
    } else {
        Write-Host "✗ Pruebas de integración fallaron" -ForegroundColor Red
    }
    
    return $integrationTestsPassed
}

# Función para ejecutar pruebas de API
function Invoke-APITests {
    Write-Host "`n=== PRUEBAS DE API ===" -ForegroundColor Cyan
    
    Write-Host "Ejecutando pruebas de endpoints de API..." -ForegroundColor Yellow
    
    try {
        .\test_microservice_endpoints.ps1
        $apiTestsPassed = $LASTEXITCODE -eq 0
    }
    catch {
        Write-Host "✗ Error al ejecutar pruebas de API: $($_.Exception.Message)" -ForegroundColor Red
        $apiTestsPassed = $false
    }
    
    if ($apiTestsPassed) {
        Write-Host "✓ Pruebas de API pasaron" -ForegroundColor Green
    } else {
        Write-Host "✗ Pruebas de API fallaron" -ForegroundColor Red
    }
    
    return $apiTestsPassed
}

# Función para ejecutar pruebas de flujo completo
function Invoke-EndToEndTests {
    Write-Host "`n=== PRUEBAS DE FLUJO COMPLETO ===" -ForegroundColor Cyan
    
    Write-Host "Ejecutando pruebas de flujo completo..." -ForegroundColor Yellow
    
    # Datos de prueba
    $testUser = @{
        nombre = "Usuario Prueba E2E"
        email = "e2e@example.com"
        password = "password123"
        rol = "cliente"
        telefono = "123456789"
    }
    
    $allFlowsPassed = $true
    
    try {
        # 1. Probar registro
        Write-Host "  Probando registro de usuario..." -ForegroundColor Gray
        $registerResponse = Invoke-WebRequest -Uri "http://localhost:3001/register" -Method POST -Body ($testUser | ConvertTo-Json) -ContentType "application/json" -UseBasicParsing
        if ($registerResponse.StatusCode -eq 201) {
            Write-Host "    ✓ Registro exitoso" -ForegroundColor Green
        } else {
            Write-Host "    ⚠️  Registro falló o usuario ya existe" -ForegroundColor Yellow
        }
        
        # 2. Probar login
        Write-Host "  Probando login..." -ForegroundColor Gray
        $loginData = @{
            email = $testUser.email
            password = $testUser.password
        }
        $loginResponse = Invoke-WebRequest -Uri "http://localhost:3002/login" -Method POST -Body ($loginData | ConvertTo-Json) -ContentType "application/json" -UseBasicParsing
        
        if ($loginResponse.StatusCode -eq 200) {
            $loginResult = $loginResponse.Content | ConvertFrom-Json
            $token = $loginResult.token
            Write-Host "    ✓ Login exitoso" -ForegroundColor Green
            
            # 3. Probar endpoints protegidos
            $headers = @{
                "Authorization" = "Bearer $token"
            }
            
            Write-Host "  Probando endpoints protegidos..." -ForegroundColor Gray
            
            # Probar obtener perfil
            $profileResponse = Invoke-WebRequest -Uri "http://localhost:3007/api/v1/profile" -Method GET -Headers $headers -UseBasicParsing
            if ($profileResponse.StatusCode -eq 200) {
                Write-Host "    ✓ Perfil accesible" -ForegroundColor Green
            } else {
                Write-Host "    ✗ Error al acceder al perfil" -ForegroundColor Red
                $allFlowsPassed = $false
            }
            
            # Probar obtener historial
            $historyResponse = Invoke-WebRequest -Uri "http://localhost:3008/api/v1/history" -Method GET -Headers $headers -UseBasicParsing
            if ($historyResponse.StatusCode -eq 200) {
                Write-Host "    ✓ Historial accesible" -ForegroundColor Green
            } else {
                Write-Host "    ✗ Error al acceder al historial" -ForegroundColor Red
                $allFlowsPassed = $false
            }
            
            # 4. Probar logout
            Write-Host "  Probando logout..." -ForegroundColor Gray
            $logoutResponse = Invoke-WebRequest -Uri "http://localhost:3005/logout" -Method DELETE -Headers $headers -UseBasicParsing
            if ($logoutResponse.StatusCode -eq 200) {
                Write-Host "    ✓ Logout exitoso" -ForegroundColor Green
            } else {
                Write-Host "    ✗ Error en logout" -ForegroundColor Red
                $allFlowsPassed = $false
            }
        } else {
            Write-Host "    ✗ Login falló" -ForegroundColor Red
            $allFlowsPassed = $false
        }
    }
    catch {
        Write-Host "✗ Error en pruebas de flujo completo: $($_.Exception.Message)" -ForegroundColor Red
        $allFlowsPassed = $false
    }
    
    if ($allFlowsPassed) {
        Write-Host "✓ Pruebas de flujo completo pasaron" -ForegroundColor Green
    } else {
        Write-Host "✗ Pruebas de flujo completo fallaron" -ForegroundColor Red
    }
    
    return $allFlowsPassed
}

# Función para mostrar información del sistema
function Show-SystemInfo {
    Write-Host "`n=== INFORMACIÓN DEL SISTEMA ===" -ForegroundColor Green
    Write-Host "Sistema desplegado exitosamente en:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🌐 Endpoints principales:" -ForegroundColor White
    Write-Host "  - Aplicación: http://localhost:80" -ForegroundColor Gray
    Write-Host "  - Health Check: http://localhost:8080" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔧 Servicios individuales:" -ForegroundColor White
    Write-Host "  - Auth Register: http://localhost:3001" -ForegroundColor Gray
    Write-Host "  - Auth Login: http://localhost:3002" -ForegroundColor Gray
    Write-Host "  - Auth Profile: http://localhost:3003" -ForegroundColor Gray
    Write-Host "  - Auth Password: http://localhost:3004" -ForegroundColor Gray
    Write-Host "  - Auth Logout: http://localhost:3005" -ForegroundColor Gray
    Write-Host "  - Auth History: http://localhost:3006" -ForegroundColor Gray
    Write-Host "  - Perfil Service: http://localhost:3007" -ForegroundColor Gray
    Write-Host "  - Historial Service: http://localhost:3008" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🗄️  Base de datos:" -ForegroundColor White
    Write-Host "  - PostgreSQL: localhost:5435" -ForegroundColor Gray
    Write-Host "  - Redis: localhost:6379" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📋 Comandos útiles:" -ForegroundColor White
    Write-Host "  - Ver logs: docker-compose logs -f [servicio]" -ForegroundColor Gray
    Write-Host "  - Detener: docker-compose down" -ForegroundColor Gray
    Write-Host "  - Reiniciar: docker-compose restart" -ForegroundColor Gray
    Write-Host "  - Verificar: .\verify_complete_setup.ps1" -ForegroundColor Gray
}

# Función para mostrar resumen de pruebas
function Show-TestSummary {
    param(
        [bool]$UnitTests,
        [bool]$IntegrationTests,
        [bool]$APITests,
        [bool]$EndToEndTests,
        [bool]$HealthCheck
    )
    
    Write-Host "`n=== RESUMEN DE PRUEBAS ===" -ForegroundColor Green
    
    $totalTests = 5
    $passedTests = 0
    
    $tests = @(
        @{Name="Verificación de Salud"; Passed=$HealthCheck},
        @{Name="Pruebas Unitarias"; Passed=$UnitTests},
        @{Name="Pruebas de Integración"; Passed=$IntegrationTests},
        @{Name="Pruebas de API"; Passed=$APITests},
        @{Name="Pruebas de Flujo Completo"; Passed=$EndToEndTests}
    )
    
    foreach ($test in $tests) {
        $status = if ($test.Passed) { "✓" } else { "✗" }
        $color = if ($test.Passed) { "Green" } else { "Red" }
        Write-Host "$status $($test.Name)" -ForegroundColor $color
        
        if ($test.Passed) {
            $passedTests++
        }
    }
    
    $successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)
    Write-Host "`nTasa de éxito: $successRate% ($passedTests/$totalTests pruebas)" -ForegroundColor Cyan
    
    if ($successRate -eq 100) {
        Write-Host "🎉 ¡TODAS LAS PRUEBAS PASARON! El sistema está funcionando correctamente." -ForegroundColor Green
    } elseif ($successRate -ge 80) {
        Write-Host "✅ La mayoría de las pruebas pasaron. El sistema está funcionando bien." -ForegroundColor Green
    } else {
        Write-Host "⚠️  Algunas pruebas fallaron. Revisa los logs para más detalles." -ForegroundColor Yellow
    }
}

# Función principal
function Start-CompleteDeployment {
    param(
        [string]$Mode = "production",
        [switch]$SkipTests,
        [switch]$SkipHealthCheck,
        [switch]$Help
    )
    
    # Mostrar ayuda si se solicita
    if ($Help) {
        Write-Host "=== AYUDA DEL SCRIPT DE DESPLIEGUE ===" -ForegroundColor Green
        Write-Host "Uso: .\deploy_and_test.ps1 [opciones]" -ForegroundColor White
        Write-Host ""
        Write-Host "Opciones:" -ForegroundColor Cyan
        Write-Host "  -Mode <modo>         Modo de despliegue (production, test)" -ForegroundColor White
        Write-Host "  -SkipTests           Saltar ejecución de pruebas" -ForegroundColor White
        Write-Host "  -SkipHealthCheck     Saltar verificación de salud" -ForegroundColor White
        Write-Host "  -Help                Mostrar esta ayuda" -ForegroundColor White
        exit 0
    }
    
    Write-Host "Iniciando despliegue completo del sistema..." -ForegroundColor Yellow
    
    # 1. Verificar prerrequisitos
    if (-not (Test-Prerequisites)) {
        Write-Host "❌ No se pueden cumplir los prerrequisitos. Abortando despliegue." -ForegroundColor Red
        exit 1
    }
    
    # 2. Limpiar recursos anteriores
    Clear-PreviousResources
    
    # 3. Configurar entorno
    if (-not (Initialize-Environment)) {
        Write-Host "❌ Error al configurar el entorno. Abortando despliegue." -ForegroundColor Red
        exit 1
    }
    
    # 4. Desplegar servicios
    if (-not (Deploy-Services -Mode $Mode)) {
        Write-Host "❌ Error al desplegar los servicios. Abortando despliegue." -ForegroundColor Red
        exit 1
    }
    
    # 5. Verificar salud de servicios
    $healthCheckPassed = $true
    if (-not $SkipHealthCheck) {
        $healthCheckPassed = Test-ServiceHealth
    }
    
    # 6. Ejecutar pruebas si no se saltan
    $unitTestsPassed = $true
    $integrationTestsPassed = $true
    $apiTestsPassed = $true
    $endToEndTestsPassed = $true
    
    if (-not $SkipTests) {
        $unitTestsPassed = Invoke-UnitTests
        $integrationTestsPassed = Invoke-IntegrationTests
        $apiTestsPassed = Invoke-APITests
        $endToEndTestsPassed = Invoke-EndToEndTests
    }
    
    # 7. Mostrar información del sistema
    Show-SystemInfo
    
    # 8. Mostrar resumen de pruebas
    Show-TestSummary -UnitTests $unitTestsPassed -IntegrationTests $integrationTestsPassed -APITests $apiTestsPassed -EndToEndTests $endToEndTestsPassed -HealthCheck $healthCheckPassed
    
    # 9. Opción para mantener servicios ejecutándose
    Write-Host "`n¿Deseas mantener los servicios ejecutándose? (s/n)" -ForegroundColor Cyan
    $keepRunning = Read-Host
    
    if ($keepRunning -eq "s" -or $keepRunning -eq "S") {
        Write-Host "Servicios mantenidos ejecutándose. Usa 'docker-compose down' para detenerlos" -ForegroundColor Green
    } else {
        Write-Host "Deteniendo servicios..." -ForegroundColor Yellow
        docker-compose down
    }
}

# Procesar argumentos
param(
    [string]$Mode = "production",
    [switch]$SkipTests,
    [switch]$SkipHealthCheck,
    [switch]$Help
)

# Ejecutar despliegue completo
Start-CompleteDeployment -Mode $Mode -SkipTests:$SkipTests -SkipHealthCheck:$SkipHealthCheck -Help:$Help 