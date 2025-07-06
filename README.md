# UserDM Authentication Microservices

A collection of microservices for handling user authentication, authorization, and session management for the 3D printing quote and order system.

## Architecture

The system is composed of the following microservices:

1. **Auth Register Service** - Handles user registration
2. **Auth Login Service** - Handles user login and token generation
3. **Auth Profile Service** - Manages user profile information
4. **Auth Password Service** - Handles password reset and change operations
5. **Auth Logout Service** - Manages session invalidation
6. **Auth History Service** - Tracks user login history

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
cp .env.example .env
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

El proyecto incluye un conjunto completo de pruebas unitarias, de integración y de extremo a extremo. Para ejecutar las pruebas, sigue estos pasos:

#### Requisitos previos

- Ruby 3.2.2
- PostgreSQL 13+
- Redis 6+
- Bundler

#### Configuración

1. Instala las dependencias:

```bash
bundle install
```

2. Configura las bases de datos de prueba:

```bash
bundle exec rake setup_test_db
```

#### Ejecutar pruebas

Para ejecutar todas las pruebas:

```bash
bundle exec rspec
```

Para ejecutar pruebas específicas:

```bash
# Ejecutar pruebas de un archivo específico
bundle exec rspec spec/models/user_spec.rb

# Ejecutar una prueba específica por línea
bundle exec rspec spec/models/user_spec.rb:42

# Ejecutar pruebas con cobertura
COVERAGE=true bundle exec rspec
```

#### Tareas Rake útiles

```bash
# Ejecutar todas las pruebas
bundle exec rake

# Ejecutar RuboCop
bundle exec rake rubocop

# Verificar cobertura de código
bundle exec rake coverage

# Reiniciar la base de datos de prueba
bundle exec rake reset_test_db

# Ver estado de la base de datos
bundle exec rake db_status
```

#### Pruebas en Docker

También puedes ejecutar las pruebas en un contenedor Docker:

```bash
docker-compose -f docker-compose.test.yml up --build --exit-code-from test
```

#### Informes de cobertura

Después de ejecutar las pruebas con cobertura, puedes ver el informe en:

```
coverage/index.html
```

### Linting

El proyecto utiliza RuboCop para mantener un estilo de código consistente:

```bash
# Ejecutar RuboCop
bundle exec rubocop

# Corregir automáticamente problemas
bundle exec rubocop -a

# Verificar solo archivos modificados
git diff --name-only | xargs bundle exec rubocop
```

### Integración Continua

El proyecto incluye un flujo de trabajo de GitHub Actions que se ejecuta en cada push y pull request. El flujo de trabajo:

1. Configura Ruby y las dependencias
2. Configura PostgreSQL y Redis
3. Ejecuta las pruebas
4. Genera informes de cobertura
5. Ejecuta RuboCop

Puedes ver el estado de la integración continua en la pestaña "Actions" de tu repositorio.

## Estructura de pruebas

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

### Ejecutar pruebas para el servicio de registro

```bash
docker-compose run --rm auth-register-service rspec
```

### Ejecutar pruebas para el servicio de login

```bash
docker-compose run --rm auth-login-service rspec
```

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
├── auth-alb/                # Application Load Balancer
├── lib/                    # Shared code
│   └── jwt_auth.rb         # JWT authentication module
├── docker-compose.yml      # Docker Compose configuration
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
| ALB | 80 | Application Load Balancer |
| PostgreSQL | 5432 | Database |
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
