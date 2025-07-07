# Script simplificado para limpiar cache y archivos obsoletos
Write-Host "=== LIMPIEZA SIMPLIFICADA DEL SISTEMA USERDM ===" -ForegroundColor Green

# Confirmar antes de proceder
Write-Host "Esta operacion eliminara archivos y datos." -ForegroundColor Red
Write-Host "Estas seguro de que quieres continuar? (s/n)" -ForegroundColor Yellow
$confirm = Read-Host

if ($confirm -ne "s" -and $confirm -ne "S") {
    Write-Host "Limpieza cancelada." -ForegroundColor Yellow
    exit 0
}

# 1. Limpiar Docker
Write-Host "`n=== LIMPIEZA DE DOCKER ===" -ForegroundColor Cyan
Write-Host "Deteniendo contenedores..." -ForegroundColor Yellow
docker-compose down -v --remove-orphans 2>$null
docker-compose -f docker-compose.test.yml down -v --remove-orphans 2>$null

Write-Host "Eliminando imagenes no utilizadas..." -ForegroundColor Yellow
docker image prune -f 2>$null

Write-Host "Eliminando volumenes no utilizados..." -ForegroundColor Yellow
docker volume prune -f 2>$null

Write-Host "Limpieza completa de Docker..." -ForegroundColor Yellow
docker system prune -af --volumes 2>$null

Write-Host "OK - Limpieza de Docker completada" -ForegroundColor Green

# 2. Limpiar archivos de cache
Write-Host "`n=== LIMPIEZA DE CACHE ===" -ForegroundColor Cyan

$cacheDirs = @(".bundle", "coverage", "tmp", "log", "node_modules", ".nyc_output", ".cache")

foreach ($dir in $cacheDirs) {
    if (Test-Path $dir) {
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "OK - Eliminado: $dir" -ForegroundColor Green
    }
}

# Limpiar archivos temporales
$tempFiles = @("*.tmp", "*.log", "*.pid", "*.lock", ".DS_Store", "Thumbs.db")

foreach ($pattern in $tempFiles) {
    Get-ChildItem -Path . -Filter $pattern -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force
}

Write-Host "OK - Limpieza de cache completada" -ForegroundColor Green

# 3. Limpiar archivos de prueba obsoletos
Write-Host "`n=== LIMPIEZA DE ARCHIVOS OBSOLETOS ===" -ForegroundColor Cyan

$obsoleteFiles = @(
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
    "simple_test.rb",
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

foreach ($file in $obsoleteFiles) {
    if (Test-Path $file) {
        Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
        Write-Host "OK - Eliminado: $file" -ForegroundColor Green
    }
}

# 4. Limpiar archivos de backup
Write-Host "`n=== LIMPIEZA DE ARCHIVOS DE BACKUP ===" -ForegroundColor Cyan

$backupPatterns = @("*.backup", "*.bak", "*.old", "*~")

foreach ($pattern in $backupPatterns) {
    Get-ChildItem -Path . -Filter $pattern -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force
}

if (Test-Path "docker-compose.yml.backup") {
    Remove-Item -Path "docker-compose.yml.backup" -Force -ErrorAction SilentlyContinue
    Write-Host "OK - Eliminado: docker-compose.yml.backup" -ForegroundColor Green
}

Write-Host "OK - Limpieza de archivos de backup completada" -ForegroundColor Green

# 5. Verificar archivos vigentes
Write-Host "`n=== VERIFICACION DE ARCHIVOS VIGENTES ===" -ForegroundColor Cyan

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
        Write-Host "OK - Archivo vigente: $file" -ForegroundColor Green
    } else {
        $missingFiles += $file
        Write-Host "FALTANTE - Archivo: $file" -ForegroundColor Yellow
    }
}

# Resumen final
Write-Host "`n=== RESUMEN DE LIMPIEZA ===" -ForegroundColor Green
Write-Host "Limpieza completada exitosamente!" -ForegroundColor Green
Write-Host ""
Write-Host "Archivos eliminados:" -ForegroundColor Cyan
Write-Host "- Contenedores y volumenes de Docker" -ForegroundColor White
Write-Host "- Imagenes de Docker no utilizadas" -ForegroundColor White
Write-Host "- Archivos de cache y temporales" -ForegroundColor White
Write-Host "- Scripts de prueba obsoletos" -ForegroundColor White
Write-Host "- Scripts de fix obsoletos" -ForegroundColor White
Write-Host "- Archivos de backup" -ForegroundColor White
Write-Host ""

if ($missingFiles.Count -eq 0) {
    Write-Host "FELICITACIONES! Todos los archivos vigentes estan presentes." -ForegroundColor Green
    Write-Host "El sistema esta listo para usar." -ForegroundColor Green
} else {
    Write-Host "ADVERTENCIA: Algunos archivos vigentes estan faltantes." -ForegroundColor Yellow
    Write-Host "Archivos faltantes:" -ForegroundColor Yellow
    foreach ($file in $missingFiles) {
        Write-Host "  - $file" -ForegroundColor Yellow
    }
}

Write-Host "`nProximos pasos:" -ForegroundColor Cyan
Write-Host "1. Ejecutar: .\quick_verify.ps1" -ForegroundColor White
Write-Host "2. Ejecutar: .\deploy_and_test.ps1" -ForegroundColor White 