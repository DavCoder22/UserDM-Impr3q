# Script optimizado para ejecutar pruebas con Docker Compose
Write-Host " Ejecutando pruebas con Docker Compose..." -ForegroundColor Green

# Función para verificar Docker
function Test-Docker {
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "❌ Docker no encontrado" -ForegroundColor Red
        return $false
    }
    return $false
}

# Función para verificar Docker Compose
function Test-DockerCompose {
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Docker Compose: $composeVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "❌ Docker Compose no encontrado" -ForegroundColor Red
        return $false
    }
    return $false
}

# Verificar herramientas
Write-Host "🔍 Verificando herramientas..." -ForegroundColor Yellow
$dockerOk = Test-Docker
$composeOk = Test-DockerCompose

if (-not $dockerOk -or -not $composeOk) {
    Write-Host "❌ Docker o Docker Compose no están disponibles" -ForegroundColor Red
    Write-Host "💡 Instala Docker Desktop desde: https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
    exit 1
}

# Verificar archivos necesarios
Write-Host "🔍 Verificando archivos de configuración..." -ForegroundColor Yellow
$requiredFiles = @("docker-compose.test.yml", "Dockerfile.test", "Gemfile")
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file encontrado" -ForegroundColor Green
    } else {
        Write-Host "❌ $file no encontrado" -ForegroundColor Red
        exit 1
    }
}

# Detener contenedores existentes
Write-Host "🛑 Deteniendo contenedores existentes..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml down 2>$null

# Limpiar imágenes anteriores
Write-Host " Limpiando imágenes anteriores..." -ForegroundColor Yellow
docker rmi auth-tests 2>$null

# Construir imagen de pruebas
Write-Host "🔨 Construyendo imagen de pruebas..." -ForegroundColor Yellow
docker build -f Dockerfile.test -t auth-tests .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Imagen construida correctamente" -ForegroundColor Green
} else {
    Write-Host "❌ Error al construir la imagen" -ForegroundColor Red
    exit 1
}

# Ejecutar pruebas
Write-Host " Ejecutando pruebas con Docker Compose..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit

# Capturar el código de salida
$exitCode = $LASTEXITCODE

# Mostrar logs
Write-Host "📋 Logs de las pruebas:" -ForegroundColor Cyan
docker-compose -f docker-compose.test.yml logs test

# Limpiar contenedores
Write-Host " Limpiando contenedores..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml down

# Mostrar resultado
if ($exitCode -eq 0) {
    Write-Host " ¡Todas las pruebas pasaron exitosamente!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Algunas pruebas fallaron (código: $exitCode)" -ForegroundColor Yellow
}

Write-Host " Proceso completado!" -ForegroundColor Green
```

También voy a crear un script para ejecutar pruebas específicas:

```powershell:run_specific_tests.ps1
# Script para ejecutar pruebas específicas con Docker
Write-Host " Ejecutando pruebas específicas con Docker..." -ForegroundColor Green

# Parámetros
param(
    [string]$TestFile = "",
    [string]$TestPattern = "",
    [switch]$AllTests
)

# Verificar Docker
if (-not (docker --version 2>$null)) {
    Write-Host "❌ Docker no está disponible" -ForegroundColor Red
    exit 1
}

# Detener contenedores existentes
Write-Host "🛑 Deteniendo contenedores existentes..." -ForegroundColor Yellow
docker-compose -f docker-compose.test.yml down 2>$null

# Construir imagen si no existe
Write-Host " Verificando imagen de pruebas..." -ForegroundColor Yellow
$imageExists = docker images auth-tests --format "{{.Repository}}" 2>$null
if (-not $imageExists) {
    Write-Host "🔨 Construyendo imagen de pruebas..." -ForegroundColor Yellow
    docker build -f Dockerfile.test -t auth-tests .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error al construir la imagen" -ForegroundColor Red
        exit 1
    }
}

# Determinar comando de pruebas
$testCommand = "bundle exec rspec --format documentation"

if ($TestFile) {
    $testCommand = "bundle exec rspec $TestFile --format documentation"
    Write-Host " Ejecutando archivo específico: $TestFile" -ForegroundColor Cyan
} elseif ($TestPattern) {
    $testCommand = "bundle exec rspec --pattern '$TestPattern' --format documentation"
    Write-Host " Ejecutando pruebas con patrón: $TestPattern" -ForegroundColor Cyan
} elseif ($AllTests) {
    Write-Host "🎯 Ejecutando todas las pruebas" -ForegroundColor Cyan
} else {
    Write-Host " Ejecutando pruebas básicas" -ForegroundColor Cyan
    $testCommand = "bundle exec rspec spec/simple_test_spec.rb --format documentation"
}

# Ejecutar pruebas
Write-Host "🧪 Ejecutando: $testCommand" -ForegroundColor Yellow
docker run --rm -v ${PWD}:/app -w /app auth-tests $testCommand

$exitCode = $LASTEXITCODE

# Mostrar resultado
if ($exitCode -eq 0) {
    Write-Host "🎉 ¡Pruebas ejecutadas exitosamente!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Algunas pruebas fallaron (código: $exitCode)" -ForegroundColor Yellow
}

Write-Host " Proceso completado!" -ForegroundColor Green
```

Y un script para ejecutar pruebas de microservicios específicos:

```powershell:run_microservice_docker_tests.ps1
# Script para ejecutar pruebas de microservicios con Docker
Write-Host " Ejecutando pruebas de microservicios con Docker..." -ForegroundColor Green

# Verificar Docker
if (-not (docker --version 2>$null)) {
    Write-Host "❌ Docker no está disponible" -ForegroundColor Red
    exit 1
}

# Función para ejecutar pruebas en un microservicio
function Run-MicroserviceTests {
    param([string]$ServiceName, [string]$ServicePath)
    
    if (Test-Path $ServicePath) {
        Write-Host " Ejecutando pruebas de $ServiceName..." -ForegroundColor Yellow
        
        # Verificar si tiene Dockerfile
        $dockerfilePath = Join-Path $ServicePath "Dockerfile"
        if (Test-Path $dockerfilePath) {
            Write-Host "🔨 Construyendo imagen de $ServiceName..." -ForegroundColor Cyan
            docker build -t "$ServiceName-tests" $ServicePath
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host " Ejecutando pruebas de $ServiceName..." -ForegroundColor Cyan
                docker run --rm -v ${PWD}\$ServicePath:/app -w /app "$ServiceName-tests" bundle exec rspec --format documentation
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Pruebas de $ServiceName pasaron" -ForegroundColor Green
                } else {
                    Write-Host "❌ Algunas pruebas de $ServiceName fallaron" -ForegroundColor Red
                }
            } else {
                Write-Host "❌ Error al construir imagen de $ServiceName" -ForegroundColor Red
            }
        } else {
            Write-Host "⚠️  No se encontró Dockerfile en $ServiceName" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️  Directorio $ServiceName no encontrado" -ForegroundColor Yellow
    }
}

# Ejecutar pruebas en cada microservicio
$services = @(
    @{ Name = "Auth Service"; Path = "auth-service" },
    @{ Name = "Perfil Service"; Path = "perfil-service" },
    @{ Name = "Historial Service"; Path = "historial-service" }
)

foreach ($service in $services) {
    Run-MicroserviceTests -ServiceName $service.Name -ServicePath $service.Path
    Write-Host ""
}

Write-Host "🐳 Pruebas de microservicios completadas!" -ForegroundColor Green
```

## Comandos para ejecutar las pruebas con Docker:

### **Opción 1: Ejecutar todas las pruebas**
```powershell
# Ejecuta todas las pruebas con Docker Compose
.\run_docker_tests.ps1
```

### **Opción 2: Ejecutar pruebas específicas**
```powershell
# Pruebas básicas
.\run_specific_tests.ps1

# Archivo específico
.\run_specific_tests.ps1 -TestFile "spec/auth_spec.rb"

# Patrón específico
.\run_specific_tests.ps1 -TestPattern "*auth*"

# Todas las pruebas
.\run_specific_tests.ps1 -AllTests
```

### **Opción 3: Comandos manuales**
```powershell
# Construir imagen de pruebas
docker build -f Dockerfile.test -t auth-tests .

# Ejecutar todas las pruebas
docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit

# Ejecutar pruebas específicas
docker run --rm -v ${PWD}:/app -w /app auth-tests bundle exec rspec spec/simple_test_spec.rb --format documentation
```

### **Opción 4: Pruebas de microservicios**
```powershell
# Ejecutar pruebas de cada microservicio
.\run_microservice_docker_tests.ps1
```

## **Recomendación:**

Te sugiero empezar con:

```powershell
.\run_docker_tests.ps1
```

Este script:
1. 🐳 Verifica que Docker esté disponible
2. 🔨 Construye la imagen de pruebas
3. 🧪 Ejecuta todas las pruebas con Docker Compose
4. 📋 Muestra los logs de las pruebas
5. 🧹 Limpia los contenedores automáticamente

**¿Quieres que ejecutemos las pruebas con Docker para evitar los problemas de dependencias?** 