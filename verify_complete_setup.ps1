# Script de verificación completa del sistema UserDM
# Valida todos los componentes: Docker, servicios, base de datos, pruebas y Terraform

Write-Host "=== VERIFICACIÓN COMPLETA DEL SISTEMA USERDM ===" -ForegroundColor Green
Write-Host "Iniciando verificación de todos los componentes..." -ForegroundColor Yellow

# Variables globales
$global:allChecksPassed = $true
$global:checkResults = @{}

# Función para registrar resultados de verificación
function Register-CheckResult {
    param(
        [string]$CheckName,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    $global:checkResults[$CheckName] = @{
        Passed = $Passed
        Message = $Message
    }
    
    if (-not $Passed) {
        $global:allChecksPassed = $false
    }
    
    $status = if ($Passed) { "✓" } else { "✗" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "$status $CheckName" -ForegroundColor $color
    if ($Message) {
        Write-Host "  $Message" -ForegroundColor Gray
    }
}

# 1. Verificar Docker
function Test-DockerEnvironment {
    Write-Host "`n=== VERIFICACIÓN DE DOCKER ===" -ForegroundColor Cyan
    
    try {
        $dockerVersion = docker version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Register-CheckResult -CheckName "Docker está ejecutándose" -Passed $true
        } else {
            Register-CheckResult -CheckName "Docker está ejecutándose" -Passed $false -Message "Docker no está disponible"
            return $false
        }
    }
    catch {
        Register-CheckResult -CheckName "Docker está ejecutándose" -Passed $false -Message $_.Exception.Message
        return $false
    }
    
    try {
        $dockerComposeVersion = docker-compose --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Register-CheckResult -CheckName "Docker Compose disponible" -Passed $true
        } else {
            Register-CheckResult -CheckName "Docker Compose disponible" -Passed $false -Message "Docker Compose no está disponible"
        }
    }
    catch {
        Register-CheckResult -CheckName "Docker Compose disponible" -Passed $false -Message $_.Exception.Message
    }
    
    return $true
}

# 2. Verificar archivos de configuración
function Test-ConfigurationFiles {
    Write-Host "`n=== VERIFICACIÓN DE ARCHIVOS DE CONFIGURACIÓN ===" -ForegroundColor Cyan
    
    $requiredFiles = @(
        "docker-compose.yml",
        "docker-compose.test.yml",
        "env.example",
        "Gemfile",
        "README.md"
    )
    
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Register-CheckResult -CheckName "Archivo $file existe" -Passed $true
        } else {
            Register-CheckResult -CheckName "Archivo $file existe" -Passed $false -Message "Archivo faltante"
        }
    }
    
    # Verificar archivo .env
    if (Test-Path ".env") {
        Register-CheckResult -CheckName "Archivo .env configurado" -Passed $true
    } else {
        Register-CheckResult -CheckName "Archivo .env configurado" -Passed $false -Message "Copia env.example a .env y configura las variables"
    }
}

# 3. Verificar estructura de directorios
function Test-DirectoryStructure {
    Write-Host "`n=== VERIFICACIÓN DE ESTRUCTURA DE DIRECTORIOS ===" -ForegroundColor Cyan
    
    $requiredDirs = @(
        "auth-service",
        "auth-register-service",
        "auth-login-service",
        "auth-profile-service",
        "auth-password-service",
        "auth-logout-service",
        "auth-history-service",
        "perfil-service",
        "historial-service",
        "spec",
        "terraform"
    )
    
    foreach ($dir in $requiredDirs) {
        if (Test-Path $dir) {
            Register-CheckResult -CheckName "Directorio $dir existe" -Passed $true
        } else {
            Register-CheckResult -CheckName "Directorio $dir existe" -Passed $false -Message "Directorio faltante"
        }
    }
}

# 4. Verificar servicios Docker
function Test-DockerServices {
    Write-Host "`n=== VERIFICACIÓN DE SERVICIOS DOCKER ===" -ForegroundColor Cyan
    
    # Verificar si los servicios están ejecutándose
    $runningContainers = docker ps --format "table {{.Names}}\t{{.Status}}" 2>$null
    
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
        "auth_redis",
        "health_check"
    )
    
    foreach ($service in $expectedServices) {
        if ($runningContainers -match $service) {
            Register-CheckResult -CheckName "Servicio $service ejecutándose" -Passed $true
        } else {
            Register-CheckResult -CheckName "Servicio $service ejecutándose" -Passed $false -Message "Servicio no está ejecutándose"
        }
    }
}

# 5. Verificar endpoints de servicios
function Test-ServiceEndpoints {
    Write-Host "`n=== VERIFICACIÓN DE ENDPOINTS ===" -ForegroundColor Cyan
    
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
    
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint.Url -Method GET -TimeoutSec 5 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Register-CheckResult -CheckName "$($endpoint.Name) responde" -Passed $true
            } else {
                Register-CheckResult -CheckName "$($endpoint.Name) responde" -Passed $false -Message "Status: $($response.StatusCode)"
            }
        }
        catch {
            Register-CheckResult -CheckName "$($endpoint.Name) responde" -Passed $false -Message $_.Exception.Message
        }
    }
}

# 6. Verificar base de datos
function Test-DatabaseConnection {
    Write-Host "`n=== VERIFICACIÓN DE BASE DE DATOS ===" -ForegroundColor Cyan
    
    try {
        $dbContainer = docker ps --filter "name=auth_db" --format "{{.Names}}" 2>$null
        if ($dbContainer) {
            Register-CheckResult -CheckName "Contenedor de base de datos ejecutándose" -Passed $true
            
            # Verificar conexión a la base de datos
            $dbTest = docker exec auth_db pg_isready -U postgres 2>$null
            if ($LASTEXITCODE -eq 0) {
                Register-CheckResult -CheckName "Base de datos PostgreSQL accesible" -Passed $true
            } else {
                Register-CheckResult -CheckName "Base de datos PostgreSQL accesible" -Passed $false -Message "No se puede conectar a PostgreSQL"
            }
        } else {
            Register-CheckResult -CheckName "Contenedor de base de datos ejecutándose" -Passed $false -Message "Contenedor auth_db no encontrado"
        }
    }
    catch {
        Register-CheckResult -CheckName "Verificación de base de datos" -Passed $false -Message $_.Exception.Message
    }
}

# 7. Verificar Redis
function Test-RedisConnection {
    Write-Host "`n=== VERIFICACIÓN DE REDIS ===" -ForegroundColor Cyan
    
    try {
        $redisContainer = docker ps --filter "name=auth_redis" --format "{{.Names}}" 2>$null
        if ($redisContainer) {
            Register-CheckResult -CheckName "Contenedor de Redis ejecutándose" -Passed $true
            
            # Verificar conexión a Redis
            $redisTest = docker exec auth_redis redis-cli ping 2>$null
            if ($redisTest -eq "PONG") {
                Register-CheckResult -CheckName "Redis accesible" -Passed $true
            } else {
                Register-CheckResult -CheckName "Redis accesible" -Passed $false -Message "Redis no responde correctamente"
            }
        } else {
            Register-CheckResult -CheckName "Contenedor de Redis ejecutándose" -Passed $false -Message "Contenedor auth_redis no encontrado"
        }
    }
    catch {
        Register-CheckResult -CheckName "Verificación de Redis" -Passed $false -Message $_.Exception.Message
    }
}

# 8. Verificar pruebas
function Test-TestEnvironment {
    Write-Host "`n=== VERIFICACIÓN DE ENTORNO DE PRUEBAS ===" -ForegroundColor Cyan
    
    # Verificar si las pruebas pueden ejecutarse
    try {
        $testResult = docker-compose -f docker-compose.test.yml config 2>$null
        if ($LASTEXITCODE -eq 0) {
            Register-CheckResult -CheckName "Configuración de pruebas válida" -Passed $true
        } else {
            Register-CheckResult -CheckName "Configuración de pruebas válida" -Passed $false -Message "Error en docker-compose.test.yml"
        }
    }
    catch {
        Register-CheckResult -CheckName "Configuración de pruebas válida" -Passed $false -Message $_.Exception.Message
    }
    
    # Verificar archivos de prueba
    $testFiles = @(
        "spec/spec_helper.rb",
        "spec/models/user_spec.rb",
        "spec/controllers/auth_controller_spec.rb"
    )
    
    foreach ($file in $testFiles) {
        if (Test-Path $file) {
            Register-CheckResult -CheckName "Archivo de prueba $file existe" -Passed $true
        } else {
            Register-CheckResult -CheckName "Archivo de prueba $file existe" -Passed $false -Message "Archivo de prueba faltante"
        }
    }
}

# 9. Verificar Terraform
function Test-TerraformConfiguration {
    Write-Host "`n=== VERIFICACIÓN DE TERRAFORM ===" -ForegroundColor Cyan
    
    $terraformFiles = @(
        "terraform/main.tf",
        "terraform/variables.tf",
        "terraform/outputs.tf",
        "terraform/README.md"
    )
    
    foreach ($file in $terraformFiles) {
        if (Test-Path $file) {
            Register-CheckResult -CheckName "Archivo Terraform $file existe" -Passed $true
        } else {
            Register-CheckResult -CheckName "Archivo Terraform $file existe" -Passed $false -Message "Archivo Terraform faltante"
        }
    }
    
    # Verificar módulos de Terraform
    $terraformModules = @(
        "terraform/modules/auth",
        "terraform/modules/profile",
        "terraform/modules/history"
    )
    
    foreach ($module in $terraformModules) {
        if (Test-Path $module) {
            Register-CheckResult -CheckName "Módulo Terraform $module existe" -Passed $true
        } else {
            Register-CheckResult -CheckName "Módulo Terraform $module existe" -Passed $false -Message "Módulo Terraform faltante"
        }
    }
}

# 10. Verificar scripts de PowerShell
function Test-PowerShellScripts {
    Write-Host "`n=== VERIFICACIÓN DE SCRIPTS POWERSHELL ===" -ForegroundColor Cyan
    
    $requiredScripts = @(
        "setup_complete.ps1",
        "run_complete_tests.ps1",
        "test_microservice_endpoints.ps1",
        "verify_services.ps1"
    )
    
    foreach ($script in $requiredScripts) {
        if (Test-Path $script) {
            Register-CheckResult -CheckName "Script $script existe" -Passed $true
        } else {
            Register-CheckResult -CheckName "Script $script existe" -Passed $false -Message "Script faltante"
        }
    }
}

# Función para mostrar resumen
function Show-VerificationSummary {
    Write-Host "`n=== RESUMEN DE VERIFICACIÓN ===" -ForegroundColor Green
    
    $totalChecks = $global:checkResults.Count
    $passedChecks = ($global:checkResults.Values | Where-Object { $_.Passed }).Count
    $failedChecks = $totalChecks - $passedChecks
    
    Write-Host "Total de verificaciones: $totalChecks" -ForegroundColor White
    Write-Host "Verificaciones exitosas: $passedChecks" -ForegroundColor Green
    Write-Host "Verificaciones fallidas: $failedChecks" -ForegroundColor Red
    
    if ($global:allChecksPassed) {
        Write-Host "`n🎉 ¡TODAS LAS VERIFICACIONES PASARON! El sistema está listo para usar." -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  ALGUNAS VERIFICACIONES FALLARON. Revisa los problemas antes de continuar." -ForegroundColor Yellow
        
        Write-Host "`nProblemas encontrados:" -ForegroundColor Red
        foreach ($check in $global:checkResults.GetEnumerator()) {
            if (-not $check.Value.Passed) {
                Write-Host "- $($check.Key): $($check.Value.Message)" -ForegroundColor Red
            }
        }
        
        Write-Host "`nPróximos pasos recomendados:" -ForegroundColor Cyan
        Write-Host "1. Ejecuta .\setup_complete.ps1 para configurar el sistema" -ForegroundColor White
        Write-Host "2. Verifica que Docker esté ejecutándose" -ForegroundColor White
        Write-Host "3. Configura el archivo .env con tus valores" -ForegroundColor White
        Write-Host "4. Ejecuta docker-compose up -d para levantar los servicios" -ForegroundColor White
    }
}

# Función principal
function Start-CompleteVerification {
    param(
        [switch]$SkipDocker,
        [switch]$SkipServices,
        [switch]$SkipTests,
        [switch]$SkipTerraform
    )
    
    Write-Host "Iniciando verificación completa del sistema UserDM..." -ForegroundColor Yellow
    
    # 1. Verificar Docker
    if (-not $SkipDocker) {
        if (-not (Test-DockerEnvironment)) {
            Write-Host "Error: Docker no está disponible. Abortando verificación." -ForegroundColor Red
            return
        }
    }
    
    # 2. Verificar archivos de configuración
    Test-ConfigurationFiles
    
    # 3. Verificar estructura de directorios
    Test-DirectoryStructure
    
    # 4. Verificar servicios Docker
    if (-not $SkipServices) {
        Test-DockerServices
        Test-ServiceEndpoints
        Test-DatabaseConnection
        Test-RedisConnection
    }
    
    # 5. Verificar entorno de pruebas
    if (-not $SkipTests) {
        Test-TestEnvironment
    }
    
    # 6. Verificar Terraform
    if (-not $SkipTerraform) {
        Test-TerraformConfiguration
    }
    
    # 7. Verificar scripts de PowerShell
    Test-PowerShellScripts
    
    # 8. Mostrar resumen
    Show-VerificationSummary
}

# Procesar argumentos
param(
    [switch]$SkipDocker,
    [switch]$SkipServices,
    [switch]$SkipTests,
    [switch]$SkipTerraform,
    [switch]$Help
)

# Mostrar ayuda si se solicita
if ($Help) {
    Write-Host "=== AYUDA DEL SCRIPT DE VERIFICACIÓN ===" -ForegroundColor Green
    Write-Host "Uso: .\verify_complete_setup.ps1 [opciones]" -ForegroundColor White
    Write-Host ""
    Write-Host "Opciones:" -ForegroundColor Cyan
    Write-Host "  -SkipDocker      Saltar verificación de Docker" -ForegroundColor White
    Write-Host "  -SkipServices    Saltar verificación de servicios" -ForegroundColor White
    Write-Host "  -SkipTests       Saltar verificación de pruebas" -ForegroundColor White
    Write-Host "  -SkipTerraform   Saltar verificación de Terraform" -ForegroundColor White
    Write-Host "  -Help            Mostrar esta ayuda" -ForegroundColor White
    exit 0
}

# Ejecutar verificación completa
Start-CompleteVerification -SkipDocker:$SkipDocker -SkipServices:$SkipServices -SkipTests:$SkipTests -SkipTerraform:$SkipTerraform 