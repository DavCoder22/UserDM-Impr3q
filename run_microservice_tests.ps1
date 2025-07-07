# Script para ejecutar pruebas de microservicios específicos
Write-Host "�� Ejecutando pruebas de microservicios..." -ForegroundColor Green

# Función para ejecutar pruebas en un directorio
function Run-TestsInDirectory {
    param([string]$Directory, [string]$ServiceName)
    
    if (Test-Path $Directory) {
        Write-Host "�� Ejecutando pruebas de $ServiceName..." -ForegroundColor Yellow
        Push-Location $Directory
        
        try {
            # Verificar si tiene Gemfile
            if (Test-Path "Gemfile") {
                Write-Host "📦 Instalando dependencias de $ServiceName..." -ForegroundColor Cyan
                bundle install
                
                if ($LASTEXITCODE -eq 0) {
                    # Buscar archivos de prueba
                    $specFiles = Get-ChildItem -Path "spec" -Filter "*.rb" -Recurse -ErrorAction SilentlyContinue
                    if ($specFiles) {
                        Write-Host "�� Ejecutando pruebas de $ServiceName..." -ForegroundColor Cyan
                        bundle exec rspec --format documentation
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "✅ Pruebas de $ServiceName pasaron" -ForegroundColor Green
                        } else {
                            Write-Host "❌ Algunas pruebas de $ServiceName fallaron" -ForegroundColor Red
                        }
                    } else {
                        Write-Host "⚠️  No se encontraron archivos de prueba en $ServiceName" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "❌ Error al instalar dependencias de $ServiceName" -ForegroundColor Red
                }
            } else {
                Write-Host "⚠️  No se encontró Gemfile en $ServiceName" -ForegroundColor Yellow
            }
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "⚠️  Directorio $ServiceName no encontrado" -ForegroundColor Yellow
    }
}

# Ejecutar pruebas en cada microservicio
$services = @(
    @{ Directory = "auth-service"; Name = "Auth Service" },
    @{ Directory = "perfil-service"; Name = "Perfil Service" },
    @{ Directory = "historial-service"; Name = "Historial Service" }
)

foreach ($service in $services) {
    Run-TestsInDirectory -Directory $service.Directory -ServiceName $service.Name
    Write-Host ""
}

Write-Host "🎯 Pruebas de microservicios completadas!" -ForegroundColor Green 