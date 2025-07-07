# Despliegue de Infraestructura con Terraform

Este directorio contiene la configuración de Terraform para desplegar la infraestructura completa del sistema de microservicios UserDM en AWS.

## Arquitectura

La infraestructura incluye:

- **VPC** con subnets públicas y privadas
- **Application Load Balancer** con IP elástica fija
- **Auto Scaling Group** para escalabilidad automática
- **RDS PostgreSQL** para la base de datos
- **ElastiCache Redis** para caché y sesiones
- **EC2 Instances** para los microservicios
- **Security Groups** para control de acceso
- **Elastic IP** para acceso estable al Load Balancer

## Prerrequisitos

1. **AWS CLI** configurado con credenciales
2. **Terraform** versión 1.2.0 o superior
3. **SSH Key Pair** en AWS
4. **Docker Images** subidos a un registry (ECR o Docker Hub)

## Configuración

### 1. Variables de Entorno

Crea un archivo `terraform.tfvars` con tus valores:

```hcl
aws_region = "us-east-1"
aws_profile = "default"
environment = "dev"
instance_type = "t2.micro"
key_name = "tu-key-pair"
db_password = "tu-password-segura"
jwt_secret = "tu-jwt-secret-muy-largo"
redis_password = "tu-redis-password"
domain_name = "tu-dominio.com"
certificate_arn = "arn:aws:acm:region:account:certificate/cert-id"
```

### 2. Configurar Docker Registry

Actualiza las referencias de imágenes en `scripts/user_data.sh`:

```bash
# Cambiar esto:
image: \${DOCKER_REGISTRY:-your-registry}/auth-register-service:latest

# Por esto (ejemplo con ECR):
image: ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/auth-register-service:latest
```

## Despliegue

### 1. Inicializar Terraform

```bash
cd terraform
terraform init
```

### 2. Planificar el Despliegue

```bash
terraform plan
```

### 3. Aplicar la Configuración

```bash
terraform apply
```

### 4. Verificar el Despliegue

```bash
terraform output
```

## Estructura de Archivos

```
terraform/
├── main.tf                 # Configuración principal
├── variables.tf            # Variables de entrada
├── outputs.tf              # Valores de salida
├── README.md              # Esta documentación
├── modules/               # Módulos reutilizables
│   ├── auth/             # Módulo para servicio de autenticación
│   ├── profile/          # Módulo para servicio de perfil
│   └── history/          # Módulo para servicio de historial
└── scripts/              # Scripts de configuración
    └── user_data.sh      # Script de inicialización de instancias
```

## Módulos

### Auth Module

Configura el servicio de autenticación con:
- Instancia EC2
- Security Groups
- Target Group attachment

### Profile Module

Configura el servicio de perfil con:
- Instancia EC2
- Security Groups
- Target Group attachment

### History Module

Configura el servicio de historial con:
- Instancia EC2
- Security Groups
- Target Group attachment

## Recursos Creados

### Redes
- VPC con CIDR 10.0.0.0/16
- 2 subnets públicas (10.0.101.0/24, 10.0.102.0/24)
- 2 subnets privadas (10.0.1.0/24, 10.0.2.0/24)
- NAT Gateway para acceso a internet desde subnets privadas

### Seguridad
- Security Group para instancias EC2
- Security Group para RDS
- Security Group para Redis
- Reglas de firewall configuradas

### Base de Datos
- RDS PostgreSQL 15.4
- Instancia t3.micro
- 20GB de almacenamiento GP2
- Backup automático habilitado

### Caché
- ElastiCache Redis 7
- Instancia cache.t3.micro
- Configurado con autenticación

### Load Balancer
- Application Load Balancer con IP elástica fija
- Target Groups para cada servicio
- Health checks configurados
- Routing basado en paths
- HTTP/2 habilitado para mejor rendimiento

### Auto Scaling
- Auto Scaling Group
- 2-4 instancias
- Launch Template con user data
- Health checks integrados

## Endpoints Disponibles

Después del despliegue, los siguientes endpoints estarán disponibles:

- **Aplicación Principal**: `http://[ALB-DNS]` o `http://[ELASTIC-IP]`
- **Health Check**: `http://[ALB-DNS]/health` o `http://[ELASTIC-IP]/health`
- **API Auth**: `http://[ALB-DNS]/api/v1/auth` o `http://[ELASTIC-IP]/api/v1/auth`
- **API Profile**: `http://[ALB-DNS]/api/v1/profile` o `http://[ELASTIC-IP]/api/v1/profile`
- **API History**: `http://[ALB-DNS]/api/v1/history` o `http://[ELASTIC-IP]/api/v1/history`

### IP Elástica
El sistema incluye una IP elástica fija que proporciona:
- **Acceso estable** sin cambios de IP
- **DNS consistente** para configuraciones
- **Failover automático** en caso de problemas
- **Monitoreo mejorado** con IP fija

## Monitoreo y Logs

### CloudWatch
- Métricas automáticas de EC2, RDS y ALB
- Logs de aplicación disponibles

### Health Checks
- Endpoint `/health` en cada servicio
- Configurado en ALB y Auto Scaling

## Escalabilidad

### Auto Scaling
- Escala automáticamente basado en CPU
- Mínimo 1, máximo 4 instancias
- Health checks para reemplazar instancias fallidas

### Load Balancer
- Distribuye tráfico entre instancias
- Health checks cada 30 segundos
- Routing inteligente por servicio

## Seguridad

### Network Security
- VPC aislada
- Security Groups restrictivos
- Subnets privadas para bases de datos

### Data Security
- RDS encriptado
- Redis con autenticación
- JWT tokens para autenticación

### Access Control
- SSH solo desde IPs autorizadas
- IAM roles para instancias EC2
- Secrets manejados por variables de Terraform

## Mantenimiento

### Actualizaciones
```bash
# Actualizar configuración
terraform plan
terraform apply

# Actualizar solo un módulo
terraform apply -target=module.auth_service
```

### Backup
- RDS: Backups automáticos diarios
- Redis: Snapshots manuales si es necesario
- Configuración: Versionada en Git

### Monitoreo
```bash
# Ver estado de recursos
terraform show

# Ver outputs
terraform output

# Ver logs de instancias
aws ec2 get-console-output --instance-id i-1234567890abcdef0
```

## Troubleshooting

### Problemas Comunes

1. **Instancias no inician**
   - Verificar user data script
   - Revisar logs de CloudWatch
   - Verificar security groups

2. **Load Balancer no responde**
   - Verificar target groups
   - Revisar health checks
   - Verificar security groups

3. **Base de datos no accesible**
   - Verificar security groups
   - Revisar subnet groups
   - Verificar credenciales

### Comandos de Diagnóstico

```bash
# Ver estado de Terraform
terraform state list

# Ver detalles de un recurso
terraform state show aws_instance.auth_service

# Importar recursos existentes
terraform import aws_instance.auth_service i-1234567890abcdef0

# Destruir recursos específicos
terraform destroy -target=aws_instance.auth_service
```

## Costos Estimados

Para el entorno de desarrollo (us-east-1):
- EC2 t2.micro: ~$8.47/mes por instancia
- RDS t3.micro: ~$12.41/mes
- ElastiCache t3.micro: ~$13.68/mes
- ALB: ~$16.20/mes
- NAT Gateway: ~$45.00/mes
- **Total estimado**: ~$120/mes

## Limpieza

Para destruir toda la infraestructura:

```bash
terraform destroy
```

**⚠️ ADVERTENCIA**: Esto eliminará todos los recursos y datos.

## Soporte

Para problemas o preguntas:
1. Revisar logs de CloudWatch
2. Verificar configuración de Terraform
3. Consultar documentación de AWS
4. Revisar issues en el repositorio
