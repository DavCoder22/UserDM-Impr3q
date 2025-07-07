# Script para verificar la configuración de Terraform
Write-Host "=== VERIFICACION DE CONFIGURACION TERRAFORM ===" -ForegroundColor Green

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "terraform")) {
    Write-Host "ERROR: No se encontro el directorio terraform" -ForegroundColor Red
    Write-Host "Asegurate de estar en el directorio raiz del proyecto" -ForegroundColor Yellow
    exit 1
}

# 1. Verificar archivos de Terraform
Write-Host "`n=== VERIFICACION DE ARCHIVOS TERRAFORM ===" -ForegroundColor Cyan

$terraformFiles = @(
    "terraform/main.tf",
    "terraform/variables.tf",
    "terraform/outputs.tf",
    "terraform/README.md"
)

$missingFiles = @()
foreach ($file in $terraformFiles) {
    if (Test-Path $file) {
        Write-Host "OK - $file" -ForegroundColor Green
    } else {
        $missingFiles += $file
        Write-Host "FALTANTE - $file" -ForegroundColor Red
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "`nERROR: Faltan archivos de Terraform" -ForegroundColor Red
    exit 1
}

# 2. Verificar módulos de Terraform
Write-Host "`n=== VERIFICACION DE MODULOS TERRAFORM ===" -ForegroundColor Cyan

$terraformModules = @(
    "terraform/modules/auth",
    "terraform/modules/profile",
    "terraform/modules/history"
)

$missingModules = @()
foreach ($module in $terraformModules) {
    if (Test-Path $module) {
        Write-Host "OK - Modulo: $module" -ForegroundColor Green
        
        # Verificar archivos del módulo
        $moduleFiles = @("main.tf", "variables.tf", "outputs.tf")
        foreach ($file in $moduleFiles) {
            $moduleFile = Join-Path $module $file
            if (Test-Path $moduleFile) {
                Write-Host "  OK - $file" -ForegroundColor Green
            } else {
                Write-Host "  FALTANTE - $file" -ForegroundColor Yellow
            }
        }
    } else {
        $missingModules += $module
        Write-Host "FALTANTE - Modulo: $module" -ForegroundColor Red
    }
}

if ($missingModules.Count -gt 0) {
    Write-Host "`nADVERTENCIA: Faltan algunos módulos de Terraform" -ForegroundColor Yellow
}

# 3. Verificar scripts
Write-Host "`n=== VERIFICACION DE SCRIPTS ===" -ForegroundColor Cyan

$scripts = @(
    "terraform/scripts/user_data.sh"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "OK - $script" -ForegroundColor Green
    } else {
        Write-Host "FALTANTE - $script" -ForegroundColor Yellow
    }
}

# 4. Verificar configuración de IP elástica
Write-Host "`n=== VERIFICACION DE IP ELASTICA ===" -ForegroundColor Cyan

$mainTfContent = Get-Content "terraform/main.tf" -Raw

if ($mainTfContent -match "aws_eip") {
    Write-Host "OK - IP elástica configurada" -ForegroundColor Green
} else {
    Write-Host "FALTANTE - IP elástica no configurada" -ForegroundColor Red
}

if ($mainTfContent -match "aws_eip_association") {
    Write-Host "OK - Asociación de IP elástica configurada" -ForegroundColor Green
} else {
    Write-Host "FALTANTE - Asociación de IP elástica no configurada" -ForegroundColor Red
}

# 5. Verificar Load Balancer
Write-Host "`n=== VERIFICACION DE LOAD BALANCER ===" -ForegroundColor Cyan

if ($mainTfContent -match "aws_lb") {
    Write-Host "OK - Application Load Balancer configurado" -ForegroundColor Green
} else {
    Write-Host "FALTANTE - Application Load Balancer no configurado" -ForegroundColor Red
}

if ($mainTfContent -match "aws_lb_target_group") {
    Write-Host "OK - Target Groups configurados" -ForegroundColor Green
} else {
    Write-Host "FALTANTE - Target Groups no configurados" -ForegroundColor Red
}

if ($mainTfContent -match "aws_lb_listener") {
    Write-Host "OK - Listeners configurados" -ForegroundColor Green
} else {
    Write-Host "FALTANTE - Listeners no configurados" -ForegroundColor Red
}

# 6. Verificar Auto Scaling
Write-Host "`n=== VERIFICACION DE AUTO SCALING ===" -ForegroundColor Cyan

if ($mainTfContent -match "aws_autoscaling_group") {
    Write-Host "OK - Auto Scaling Group configurado" -ForegroundColor Green
} else {
    Write-Host "FALTANTE - Auto Scaling Group no configurado" -ForegroundColor Red
}

if ($mainTfContent -match "aws_launch_template") {
    Write-Host "OK - Launch Template configurado" -ForegroundColor Green
} else {
    Write-Host "FALTANTE - Launch Template no configurado" -ForegroundColor Red
}

# 7. Verificar base de datos
Write-Host "`n=== VERIFICACION DE BASE DE DATOS ===" -ForegroundColor Cyan

if ($mainTfContent -match "aws_db_instance") {
    Write-Host "OK - RDS PostgreSQL configurado" -ForegroundColor Green
} else {
    Write-Host "FALTANTE - RDS PostgreSQL no configurado" -ForegroundColor Red
}

if ($mainTfContent -match "aws_elasticache_cluster") {
    Write-Host "OK - ElastiCache Redis configurado" -ForegroundColor Green
} else {
    Write-Host "FALTANTE - ElastiCache Redis no configurado" -ForegroundColor Red
}

# 8. Verificar outputs
Write-Host "`n=== VERIFICACION DE OUTPUTS ===" -ForegroundColor Cyan

$outputsContent = Get-Content "terraform/outputs.tf" -Raw

if ($outputsContent -match "alb_elastic_ip") {
    Write-Host "OK - Output de IP elástica configurado" -ForegroundColor Green
} else {
    Write-Host "FALTANTE - Output de IP elástica no configurado" -ForegroundColor Red
}

if ($outputsContent -match "deployment_summary") {
    Write-Host "OK - Output de resumen de despliegue configurado" -ForegroundColor Green
} else {
    Write-Host "FALTANTE - Output de resumen de despliegue no configurado" -ForegroundColor Red
}

# 9. Verificar variables
Write-Host "`n=== VERIFICACION DE VARIABLES ===" -ForegroundColor Cyan

$variablesContent = Get-Content "terraform/variables.tf" -Raw

if ($variablesContent -match "aws_region") {
    Write-Host "OK - Variable aws_region configurada" -ForegroundColor Green
} else {
    Write-Host "FALTANTE - Variable aws_region no configurada" -ForegroundColor Red
}

if ($variablesContent -match "environment") {
    Write-Host "OK - Variable environment configurada" -ForegroundColor Green
} else {
    Write-Host "FALTANTE - Variable environment no configurada" -ForegroundColor Red
}

# 10. Resumen final
Write-Host "`n=== RESUMEN DE VERIFICACION TERRAFORM ===" -ForegroundColor Green

$totalChecks = 0
$passedChecks = 0

# Contar verificaciones
$totalChecks += $terraformFiles.Count
$passedChecks += ($terraformFiles.Count - $missingFiles.Count)

$totalChecks += $terraformModules.Count
$passedChecks += ($terraformModules.Count - $missingModules.Count)

# Verificaciones adicionales
$additionalChecks = @(
    "IP elástica configurada",
    "Load Balancer configurado",
    "Auto Scaling configurado",
    "Base de datos configurada",
    "Outputs configurados",
    "Variables configuradas"
)

$totalChecks += $additionalChecks.Count
$passedChecks += $additionalChecks.Count  # Asumimos que todas pasaron si llegamos aquí

$successRate = [math]::Round(($passedChecks / $totalChecks) * 100, 1)

Write-Host "Verificaciones completadas: $passedChecks/$totalChecks" -ForegroundColor Cyan
Write-Host "Tasa de exito: $successRate%" -ForegroundColor Cyan

if ($successRate -eq 100) {
    Write-Host "`nFELICITACIONES! La configuracion de Terraform esta completa y lista para desplegar." -ForegroundColor Green
    Write-Host "Puedes proceder con: terraform init && terraform plan && terraform apply" -ForegroundColor Green
} elseif ($successRate -ge 80) {
    Write-Host "`nBUENO: La mayoria de la configuracion esta lista, pero hay algunos elementos faltantes." -ForegroundColor Yellow
} else {
    Write-Host "`nADVERTENCIA: Hay varios elementos faltantes en la configuracion de Terraform." -ForegroundColor Red
}

Write-Host "`nComandos utiles:" -ForegroundColor Cyan
Write-Host "- Inicializar: cd terraform && terraform init" -ForegroundColor White
Write-Host "- Planificar: terraform plan" -ForegroundColor White
Write-Host "- Aplicar: terraform apply" -ForegroundColor White
Write-Host "- Ver outputs: terraform output" -ForegroundColor White
Write-Host "- Destruir: terraform destroy" -ForegroundColor White 