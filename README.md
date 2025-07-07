# UserDM Authentication Microservices

A collection of microservices for handling user authentication, authorization, and session management for the 3D printing quote and order system.

## 🚀 Inicio Rápido

### 1. Limpieza del Sistema (Opcional)
Si tienes archivos obsoletos o cache acumulado, ejecuta la limpieza:

```powershell
.\clean_all.ps1
```

### 2. Verificación Rápida
Verifica que todo esté en orden:

```powershell
.\quick_verify.ps1
```

### 3. Configuración y Despliegue
Configura y despliega todo el sistema:

```powershell
.\deploy_and_test.ps1
```

### 4. Verificación Completa
Ejecuta una verificación completa del sistema:

```powershell
.\verify_complete_setup.ps1
```

## Architecture

The system is composed of the following microservices:

1. **Auth Register Service** - Handles user registration
2. **Auth Login Service** - Handles user login and token generation
3. **Auth Profile Service** - Manages user profile information
4. **Auth Password Service** - Handles password reset and change operations
5. **Auth Logout Service** - Manages session invalidation
6. **Auth History Service** - Tracks user login history
7. **Perfil Service** - Complete profile management
8. **Historial Service** - Complete history management

## Prerequisites

- Docker and Docker Compose
- Ruby 3.0+
- PostgreSQL 13+
- Redis 6+

## Getting Started

### 1. Clone the repository

```bash
git clone <repository-url>
cd UserDM-Impr3q
```

### 2. Set up environment variables

Copy the example environment file and update the values:

```bash
cp env.example .env
```

Edit the `.env` file with your configuration.

### 3. Set up the Docker network

```powershell
.\setup-network.ps1
```

### 4. Build and start the services

```bash
docker-compose up -d --build
```

### 5. Run database migrations

```bash
docker-compose exec db psql -U postgres -d auth_db -f /docker-entrypoint-initdb.d/001_create_schema.sql
```

## 🧹 Limpieza del Sistema

### Limpieza Completa
Elimina cache, archivos temporales y pruebas obsoletas:

```powershell
.\clean_all.ps1
```

Opciones disponibles:
- `-SkipDocker`: Saltar limpieza de Docker
- `-SkipCache`: Saltar limpieza de cache
- `-SkipObsolete`: Saltar limpieza de archivos obsoletos
- `-SkipBackup`: Saltar limpieza de archivos de backup
- `-SkipEmpty`: Saltar limpieza de directorios vacíos

### Limpieza Selectiva
```powershell
# Solo limpiar Docker
.\clean_all.ps1 -SkipCache -SkipObsolete -SkipBackup -SkipEmpty

# Solo limpiar archivos obsoletos
.\clean_all.ps1 -SkipDocker -SkipCache -SkipBackup -SkipEmpty
```

## 🚀 Despliegue y Pruebas

### Despliegue Completo
Despliega el sistema y ejecuta todas las pruebas:

```powershell
.\deploy_and_test.ps1
```

Opciones disponibles:
- `-Mode production|test`: Modo de despliegue
- `-SkipTests`: Saltar ejecución de pruebas
- `-SkipHealthCheck`: Saltar verificación de salud

### Despliegue Rápido
```powershell
# Solo despliegue sin pruebas
.\deploy_and_test.ps1 -SkipTests

# Solo verificación de salud
.\deploy_and_test.ps1 -SkipTests -SkipHealthCheck
```

## 🔍 Verificación del Sistema

### Verificación Rápida
Verificación básica del estado del sistema:

```powershell
.\quick_verify.ps1
```

### Verificación Completa
Verificación exhaustiva de todos los componentes:

```powershell
.\verify_complete_setup.ps1
```

Opciones disponibles:
- `-SkipDocker`: Saltar verificación de Docker
- `-SkipServices`: Saltar verificación de servicios
- `-SkipTests`: Saltar verificación de pruebas
- `-SkipTerraform`: Saltar verificación de Terraform

## CORS Configuration

This application is configured with Cross-Origin Resource Sharing (CORS) to allow requests from specific origins. The configuration varies by environment:

### Development
- All origins are allowed (`*`)
- No credentials required
- All headers are exposed

### Production/Staging
- Only allowed origins are permitted (configured via environment variables)
- Credentials are required for authenticated requests
- Only necessary headers are exposed

### Allowed Origins
- `STAGING_FRONTEND_URL`
- `PRODUCTION_FRONTEND_URL`
- Mobile app domains matching patterns:
  - `https://([a-z0-9-]+\.)?impr3q\.(com|dev)`
  - `https://impr3q\.web\.app`

## Login Alerts

For security purposes, the following login alerts are implemented:

1. **Failed Login Attempts**
   - After 3 failed attempts, the account will be temporarily locked
   - An email notification is sent after 3 failed attempts
   - The account will be unlocked after 30 minutes or by an admin

2. **New Device Login**
   - Email notification sent when logging in from a new device
   - Includes device information and location
   - Provides an option to revoke access if suspicious

3. **Password Change Alerts**
   - Email notification when password is changed
   - Includes timestamp and device information

4. **Suspicious Activity**
   - Alerts for logins from unusual locations
   - Multiple failed login attempts
   - Multiple password reset requests

## API Endpoints

### Auth Register Service

- `POST /register` - Register a new user

### Auth Login Service

- `POST /login` - Authenticate user and get JWT token
- `GET /verify` - Verify token (used by Traefik middleware)

### Auth Profile Service

- `GET /profile` - Get user profile
- `PUT /profile` - Update user profile

### Auth Password Service

- `POST /forgot-password` - Request password reset
- `POST /reset-password` - Reset password with token
- `POST /change-password` - Change password (requires authentication)

### Auth Logout Service

- `POST /logout` - Invalidate current token
- `GET /check-token` - Check if token is valid

### Auth History Service

- `GET /history` - Get user login history

## Health Check

Access the health check dashboard at: [http://localhost/health](http://localhost/health)

## Development

### CORS in Development

When running in development, CORS is configured to allow all origins. To test with specific origins, you can modify the `config/initializers/cors.rb` file.

### Environment Variables

For CORS and security features, ensure these environment variables are set:

```bash
# CORS Configuration
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:4000
FRONTEND_URL=http://localhost:3000

# Security
JWT_SECRET=your_jwt_secret_here
PEPPER=your_pepper_here

# Email (for alerts)
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password
```

## Running Tests

El proyecto incluye un conjunto completo de pruebas unitarias, de integración y de extremo a extremo.

### Ejecutar Todas las Pruebas

```powershell
.\deploy_and_test.ps1
```

### Ejecutar Pruebas Específicas

```powershell
# Solo pruebas unitarias
docker-compose -f docker-compose.test.yml run --rm test_runner bundle exec rspec spec/models/

# Solo pruebas de integración
docker-compose -f docker-compose.test.yml run --rm test_runner bundle exec rspec spec/integration/

# Solo pruebas de API
.\test_microservice_endpoints.ps1
```

### Pruebas con Cobertura

```bash
COVERAGE=true bundle exec rspec
```

### Informes de Cobertura

Después de ejecutar las pruebas con cobertura, puedes ver el informe en:

```
coverage/index.html
```

## Linting

El proyecto utiliza RuboCop para mantener un estilo de código consistente:

```bash
# Ejecutar RuboCop
bundle exec rubocop

# Corregir automáticamente problemas
bundle exec rubocop -a

# Verificar solo archivos modificados
git diff --name-only | xargs bundle exec rubocop
```

## Integración Continua

El proyecto incluye un flujo de trabajo de GitHub Actions que se ejecuta en cada push y pull request. El flujo de trabajo:

1. Configura Ruby y las dependencias
2. Configura PostgreSQL y Redis
3. Ejecuta las pruebas
4. Genera informes de cobertura
5. Ejecuta RuboCop

Puedes ver el estado de la integración continua en la pestaña "Actions" de tu repositorio.

## Estructura de Pruebas

```
spec/
├── controllers/           # Pruebas de controladores
│   └── auth_controller_spec.rb
├── factories/            # Fábricas para datos de prueba
│   ├── user_factory.rb
│   ├── session_factory.rb
│   └── login_history_factory.rb
├── integration/          # Pruebas de integración
│   └── auth_flow_spec.rb
├── lib/                  # Pruebas de bibliotecas
│   └── jwt_auth_spec.rb
├── models/               # Pruebas de modelos
│   ├── user_spec.rb
│   ├── session_spec.rb
│   └── login_history_spec.rb
├── support/              # Configuración de soporte
│   ├── database_cleaner.rb
│   ├── factory_bot.rb
│   ├── rack_test.rb
│   ├── simplecov.rb
│   ├── timecop.rb
│   └── webmock.rb
└── spec_helper.rb        # Configuración principal de RSpec
```

## 🏗️ Despliegue en Producción

### Con Docker Compose

```powershell
# Configurar variables de producción
Copy-Item env.example .env
# Editar .env con valores de producción

# Desplegar
.\deploy_and_test.ps1 -Mode production
```

### Con Terraform (AWS)

```bash
cd terraform

# Configurar variables
# Crear terraform.tfvars con tus valores

# Desplegar
terraform init
terraform plan
terraform apply
```

#### Infraestructura Desplegada
- **VPC** con subnets públicas y privadas
- **Application Load Balancer** con IP elástica fija
- **Auto Scaling Group** para alta disponibilidad
- **RDS PostgreSQL** para base de datos
- **ElastiCache Redis** para cache
- **Security Groups** configurados
- **IAM Roles** para permisos

#### URLs de Acceso
Después del despliegue, obtendrás:
- **Load Balancer DNS**: `http://[alb-dns-name]`
- **IP Elástica**: `http://[elastic-ip]`
- **Auth Service**: `http://[alb-dns-name]/api/v1/auth`
- **Profile Service**: `http://[alb-dns-name]/api/v1/profile`
- **History Service**: `http://[alb-dns-name]/api/v1/history`
- **Health Check**: `http://[alb-dns-name]/health`

Ver la documentación completa en [terraform/README.md](terraform/README.md).

## 📋 Comandos Útiles

### Gestión de Servicios

```powershell
# Ver logs de un servicio específico
docker-compose logs -f auth-login-service

# Reiniciar un servicio
docker-compose restart auth-login-service

# Detener todos los servicios
docker-compose down

# Ver estado de los servicios
docker-compose ps
```

### Pruebas y Verificación

```powershell
# Verificación rápida
.\quick_verify.ps1

# Verificación completa
.\verify_complete_setup.ps1

# Pruebas de endpoints
.\test_microservice_endpoints.ps1

# Limpieza del sistema
.\clean_all.ps1
```

### Desarrollo

```powershell
# Configuración completa
.\setup_complete.ps1

# Despliegue y pruebas (Script simplificado)
.\deploy_simple.ps1

# Verificación rápida (Script simplificado)
.\verify_simple.ps1

# Verificación de Terraform
.\verify_terraform.ps1

# Scripts originales (pueden tener problemas de codificación)
.\deploy_and_test.ps1
.\quick_verify.ps1
```

## Troubleshooting

### Problemas Comunes

1. **Docker no está ejecutándose**
   ```powershell
   # Verificar Docker
   docker version
   ```

2. **Servicios no inician**
   ```powershell
   # Ver logs
   docker-compose logs
   
   # Verificar configuración
   docker-compose config
   ```

3. **Pruebas fallan**
   ```powershell
   # Limpiar y reintentar (Scripts simplificados)
   .\clean_simple.ps1
   .\deploy_simple.ps1
   
   # Scripts originales (pueden tener problemas de codificación)
   .\clean_all.ps1
   .\deploy_and_test.ps1
   ```

4. **Endpoints no responden**
   ```powershell
   # Verificar salud (Script simplificado)
   .\verify_simple.ps1
   
   # Script original (puede tener problemas de codificación)
   .\quick_verify.ps1
   
   # Verificar servicios
   docker-compose ps
   ```

### Logs y Diagnóstico

```powershell
# Ver logs de todos los servicios
docker-compose logs

# Ver logs de un servicio específico
docker-compose logs auth-login-service

# Ver logs en tiempo real
docker-compose logs -f

# Verificar configuración
docker-compose config
```

## Contribuyendo

1. Haz un fork del proyecto
2. Crea una rama para tu característica (`git checkout -b feature/AmazingFeature`)
3. Haz commit de tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Haz push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

Asegúrate de que todas las pruebas pasen antes de enviar tu PR.

## Licencia

Distribuido bajo la licencia MIT. Ver `LICENSE` para más información.

## Contacto

Tu Nombre - [@tu_usuario](https://twitter.com/tu_usuario)

Enlace del proyecto: [https://github.com/tu_usuario/UserDM-Impr3q](https://github.com/tu_usuario/UserDM-Impr3q)

### Environment Variables

- `JWT_SECRET` - Secret key for JWT token signing
- `POSTGRES_*` - Database connection settings
- `REDIS_*` - Redis connection settings
- `TRAEFIK_*` - Traefik configuration

## Deployment

1. Update the `.env` file with production values
2. Set up SSL certificates (Traefik will handle this automatically with Let's Encrypt)
3. Deploy using Docker Swarm or Kubernetes

## Security

- All passwords are hashed using BCrypt
- JWT tokens are used for authentication
- Redis is used for token blacklisting
- All services communicate over HTTPS
- Rate limiting is implemented at the Traefik level

## Monitoring

Access the Traefik dashboard at: [http://localhost:8080](http://localhost:8080)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Prerequisites

- Docker and Docker Compose
- Ruby 3.2+ (for local development)
- PostgreSQL (for local development)

### Environment Variables

Create a `.env` file in the project root with the following variables:

```
JWT_SECRET=your_jwt_secret_key
DATABASE_URL=postgres://postgres:postgres@localhost:5432/auth_db
RACK_ENV=development
```

### Running with Docker Compose

1. Build and start all services:
   ```bash
   docker-compose up --build
   ```

2. To run in detached mode:
   ```bash
   docker-compose up -d
   ```

3. View logs:
   ```bash
   docker-compose logs -f
   ```

## 🏗️ Project Structure

```
UserDM-Impr3q/
├── auth-register-service/    # User registration service
├── auth-login-service/      # User login service
├── auth-profile-service/    # User profile management
├── auth-password-service/   # Password reset functionality
├── auth-logout-service/     # Session termination
├── auth-history-service/    # Login history
├── perfil-service/          # Complete profile management
├── historial-service/       # Complete history management
├── auth-alb/                # Application Load Balancer
├── lib/                    # Shared code
│   └── jwt_auth.rb         # JWT authentication module
├── docker-compose.yml      # Docker Compose configuration
├── docker-compose.test.yml # Docker Compose for testing
├── terraform/              # Infrastructure as Code
└── README.md               # This file
```

## 🔧 Services

| Service | Port | Description |
|---------|------|-------------|
| Register | 3001 | User registration |
| Login | 3002 | User authentication |
| Profile | 3003 | User profile management |
| Password | 3004 | Password reset |
| Logout | 3005 | Session termination |
| History | 3006 | Login history |
| Perfil | 3007 | Complete profile management |
| Historial | 3008 | Complete history management |
| ALB | 80 | Application Load Balancer |
| PostgreSQL | 5435 | Database |
| Redis | 6379 | Token blacklist |

## 🔐 Authentication

All authenticated endpoints require a JWT token in the `Authorization` header:

```
Authorization: Bearer <your_jwt_token>
```

## 🧪 Testing

To run tests for a specific service:

```bash
cd auth-<service>-service
bundle exec rspec
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
