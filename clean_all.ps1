# Script completo para limpiar cache, archivos temporales y pruebas obsoletas
# Mantiene solo los archivos vigentes y necesarios

Write-Host "=== LIMPIEZA COMPLETA DEL SISTEMA USERDM ===" -ForegroundColor Green
Write-Host "Iniciando limpieza de cache y archivos innecesarios..." -ForegroundColor Yellow

# Función para limpiar Docker
function Clear-DockerResources {
    Write-Host "`n=== LIMPIEZA DE DOCKER ===" -ForegroundColor Cyan
    
    Write-Host "Deteniendo y eliminando contenedores..." -ForegroundColor Yellow
    docker-compose down -v --remove-orphans 2>$null
    docker-compose -f docker-compose.test.yml down -v --remove-orphans 2>$null
    
    Write-Host "Eliminando imágenes no utilizadas..." -ForegroundColor Yellow
    docker image prune -f 2>$null
    
    Write-Host "Eliminando volúmenes no utilizados..." -ForegroundColor Yellow
    docker volume prune -f 2>$null
    
    Write-Host "Eliminando redes no utilizadas..." -ForegroundColor Yellow
    docker network prune -f 2>$null
    
    Write-Host "Limpieza completa de Docker..." -ForegroundColor Yellow
    docker system prune -af --volumes 2>$null
    
    Write-Host "✓ Limpieza de Docker completada" -ForegroundColor Green
}

# Función para limpiar archivos de cache y temporales
function Clear-CacheFiles {
    Write-Host "`n=== LIMPIEZA DE CACHE Y ARCHIVOS TEMPORALES ===" -ForegroundColor Cyan
    
    $cacheDirs = @(
        ".bundle",
        "coverage",
        "tmp",
        "log",
        "node_modules",
        ".nyc_output",
        ".cache"
    )
    
    foreach ($dir in $cacheDirs) {
        if (Test-Path $dir) {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "✓ Eliminado: $dir" -ForegroundColor Green
        }
    }
    
    # Limpiar archivos temporales
    $tempFiles = @(
        "*.tmp",
        "*.log",
        "*.pid",
        "*.lock",
        ".DS_Store",
        "Thumbs.db"
    )
    
    foreach ($pattern in $tempFiles) {
        Get-ChildItem -Path . -Filter $pattern -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force
    }
    
    Write-Host "✓ Limpieza de cache completada" -ForegroundColor Green
}

# Función para limpiar archivos de prueba obsoletos
function Clear-ObsoleteTestFiles {
    Write-Host "`n=== LIMPIEZA DE ARCHIVOS DE PRUEBA OBSOLETOS ===" -ForegroundColor Cyan
    
    # Lista de archivos de prueba obsoletos a eliminar
    $obsoleteTestFiles = @(
        "run_basic_tests.ps1",
        "run_tests_simple.ps1",
        "run_tests_main.ps1",
        "run_specific_tests_main.ps1",
        "run_specific_tests.ps1",
        "run_tests_step_by_step.ps1",
        "run_microservice_tests.ps1",
        "run_tests_auto.ps1",
        "run_tests.ps1",
        "test_with_docker.ps1",
        "test_without_docker.ps1",
        "test.ps1",
        "test-endpoints.ps1",
        "test_endpoints_simple.ps1",
        "run_simple_docker_tests.ps1",
        "run_docker_tests.ps1",
        "run_docker_tests_fixed.ps1",
        "run_microservice_docker_tests.ps1",
        "run_tests_with_corrected_dockerfile.ps1",
        "run_complete_tests.ps1",
        "Dockerfile.test",
        "Dockerfile.test.fixed",
        "test_output.txt",
        "test_connection.rb",
        "test_db_connection.rb",
        "simple_test.rb"
    )
    
    foreach ($file in $obsoleteTestFiles) {
        if (Test-Path $file) {
            Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
            Write-Host "✓ Eliminado archivo obsoleto: $file" -ForegroundColor Green
        }
    }
    
    # Limpiar scripts de fix obsoletos
    $obsoleteFixFiles = @(
        "fix_dockerfiles_simple.ps1",
        "fix_microservice_dockerfiles.ps1",
        "fix_dockerfile_and_run_tests.ps1",
        "replace_dockerfile_test.ps1",
        "fix_bcrypt_only.ps1",
        "fix_windows_gems.ps1",
        "fix_with_precompiled_gems.ps1",
        "fix_bundle_install.ps1",
        "fix-ruby-powershell.ps1",
        "quick-ruby-fix.ps1",
        "setup-ruby-path.ps1",
        "setup-ruby-environment.ps1"
    )
    
    foreach ($file in $obsoleteFixFiles) {
        if (Test-Path $file) {
            Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
            Write-Host "✓ Eliminado script de fix obsoleto: $file" -ForegroundColor Green
        }
    }
    
    Write-Host "✓ Limpieza de archivos obsoletos completada" -ForegroundColor Green
}

# Función para limpiar archivos de backup
function Clear-BackupFiles {
    Write-Host "`n=== LIMPIEZA DE ARCHIVOS DE BACKUP ===" -ForegroundColor Cyan
    
    $backupFiles = @(
        "docker-compose.yml.backup",
        "*.backup",
        "*.bak",
        "*.old",
        "*~"
    )
    
    foreach ($pattern in $backupFiles) {
        Get-ChildItem -Path . -Filter $pattern -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force
    }
    
    Write-Host "✓ Limpieza de archivos de backup completada" -ForegroundColor Green
}

# Función para limpiar directorios vacíos
function Clear-EmptyDirectories {
    Write-Host "`n=== LIMPIEZA DE DIRECTORIOS VACÍOS ===" -ForegroundColor Cyan
    
    Get-ChildItem -Path . -Directory -Recurse | Where-Object {
        (Get-ChildItem $_.FullName -Recurse | Measure-Object).Count -eq 0
    } | Remove-Item -Force -ErrorAction SilentlyContinue
    
    Write-Host "✓ Limpieza de directorios vacíos completada" -ForegroundColor Green
}

# Función para verificar archivos vigentes
function Test-VigentFiles {
    Write-Host "`n=== VERIFICACIÓN DE ARCHIVOS VIGENTES ===" -ForegroundColor Cyan
    
    $vigentFiles = @(
        "docker-compose.yml",
        "docker-compose.test.yml",
        "env.example",
        "setup_complete.ps1",
        "verify_complete_setup.ps1",
        "test_microservice_endpoints.ps1",
        "verify_services.ps1",
        "setup_microservices.ps1",
        "quick_setup.ps1",
        "clean.ps1",
        "logs.ps1",
        "init.ps1",
        "Gemfile",
        "Gemfile.lock",
        "README.md",
        "README_TESTING.md",
        "TESTING.md",
        "CHANGELOG.md",
        "Rakefile",
        "Guardfile",
        ".rspec",
        ".rspec_ci",
        ".rubocop.yml",
        ".gitignore",
        ".dockerignore"
    )
    
    $missingFiles = @()
    foreach ($file in $vigentFiles) {
        if (Test-Path $file) {
            Write-Host "✓ Archivo vigente: $file" -ForegroundColor Green
        } else {
            $missingFiles += $file
            Write-Host "⚠️  Archivo faltante: $file" -ForegroundColor Yellow
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Host "`n⚠️  Archivos vigentes faltantes:" -ForegroundColor Yellow
        foreach ($file in $missingFiles) {
            Write-Host "  - $file" -ForegroundColor Yellow
        }
    }
    
    return $missingFiles.Count -eq 0
}

# Función para mostrar resumen de limpieza
function Show-CleanupSummary {
    Write-Host "`n=== RESUMEN DE LIMPIEZA ===" -ForegroundColor Green
    Write-Host "✅ Limpieza completada exitosamente" -ForegroundColor Green
    Write-Host ""
    Write-Host "Archivos y directorios eliminados:" -ForegroundColor Cyan
    Write-Host "- Contenedores y volúmenes de Docker" -ForegroundColor White
    Write-Host "- Imágenes de Docker no utilizadas" -ForegroundColor White
    Write-Host "- Archivos de cache y temporales" -ForegroundColor White
    Write-Host "- Scripts de prueba obsoletos" -ForegroundColor White
    Write-Host "- Scripts de fix obsoletos" -ForegroundColor White
    Write-Host "- Archivos de backup" -ForegroundColor White
    Write-Host "- Directorios vacíos" -ForegroundColor White
    Write-Host ""
    Write-Host "Archivos vigentes mantenidos:" -ForegroundColor Cyan
    Write-Host "- Configuración de Docker Compose" -ForegroundColor White
    Write-Host "- Scripts principales de setup y verificación" -ForegroundColor White
    Write-Host "- Archivos de configuración de Ruby" -ForegroundColor White
    Write-Host "- Documentación" -ForegroundColor White
}

# Función principal
function Start-CompleteCleanup {
    param(
        [switch]$SkipDocker,
        [switch]$SkipCache,
        [switch]$SkipObsolete,
        [switch]$SkipBackup,
        [switch]$SkipEmpty,
        [switch]$Help
    )
    
    # Mostrar ayuda si se solicita
    if ($Help) {
        Write-Host "=== AYUDA DEL SCRIPT DE LIMPIEZA ===" -ForegroundColor Green
        Write-Host "Uso: .\clean_all.ps1 [opciones]" -ForegroundColor White
        Write-Host ""
        Write-Host "Opciones:" -ForegroundColor Cyan
        Write-Host "  -SkipDocker      Saltar limpieza de Docker" -ForegroundColor White
        Write-Host "  -SkipCache       Saltar limpieza de cache" -ForegroundColor White
        Write-Host "  -SkipObsolete    Saltar limpieza de archivos obsoletos" -ForegroundColor White
        Write-Host "  -SkipBackup      Saltar limpieza de archivos de backup" -ForegroundColor White
        Write-Host "  -SkipEmpty       Saltar limpieza de directorios vacíos" -ForegroundColor White
        Write-Host "  -Help            Mostrar esta ayuda" -ForegroundColor White
        exit 0
    }
    
    Write-Host "Iniciando limpieza completa del sistema..." -ForegroundColor Yellow
    
    # Confirmar antes de proceder
    Write-Host "`n⚠️  ADVERTENCIA: Esta operación eliminará archivos y datos." -ForegroundColor Red
    Write-Host "¿Estás seguro de que quieres continuar? (s/n)" -ForegroundColor Yellow
    $confirm = Read-Host
    
    if ($confirm -ne "s" -and $confirm -ne "S") {
        Write-Host "Limpieza cancelada." -ForegroundColor Yellow
        exit 0
    }
    
    # Ejecutar limpieza
    if (-not $SkipDocker) {
        Clear-DockerResources
    }
    
    if (-not $SkipCache) {
        Clear-CacheFiles
    }
    
    if (-not $SkipObsolete) {
        Clear-ObsoleteTestFiles
    }
    
    if (-not $SkipBackup) {
        Clear-BackupFiles
    }
    
    if (-not $SkipEmpty) {
        Clear-EmptyDirectories
    }
    
    # Verificar archivos vigentes
    $vigentFilesOk = Test-VigentFiles
    
    # Mostrar resumen
    Show-CleanupSummary
    
    if ($vigentFilesOk) {
        Write-Host "`n🎉 ¡Limpieza completada exitosamente! El sistema está listo para usar." -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  Limpieza completada, pero algunos archivos vigentes están faltantes." -ForegroundColor Yellow
    }
}

# Procesar argumentos
param(
    [switch]$SkipDocker,
    [switch]$SkipCache,
    [switch]$SkipObsolete,
    [switch]$SkipBackup,
    [switch]$SkipEmpty,
    [switch]$Help
)

# Ejecutar limpieza completa
Start-CompleteCleanup -SkipDocker:$SkipDocker -SkipCache:$SkipCache -SkipObsolete:$SkipObsolete -SkipBackup:$SkipBackup -SkipEmpty:$SkipEmpty -Help:$Help 