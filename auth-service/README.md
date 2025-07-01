# 🔐 Authentication Service

A secure, scalable authentication and authorization microservice built with Ruby and Sinatra. This service provides robust identity management for the UserDM platform, handling user registration, login, JWT token generation, and real-time credential validation.

## 🚀 Key Features

- **Secure Authentication** with JWT (JSON Web Tokens)
- **User Registration** with comprehensive data validation
- **Login System** with credential verification
- **Token Refresh** for extended sessions
- **Session Management** with configurable expiration
- **Role-Based Access Control** (user/admin)
- **Distributed Architecture** with separate databases for users (PostgreSQL) and tokens (MySQL)
- **RESTful APIs** following best practices
- **Comprehensive API Documentation** with OpenAPI/Swagger
- **Rate Limiting** to prevent abuse
- **Secure Password Hashing** using bcrypt
- **Email Verification** for new accounts
- **Password Reset** functionality

## 🛠️ Technology Stack

### Core Technologies

- **Language**: Ruby 3.x
- **Web Framework**: Sinatra
- **Authentication**: JWT (JSON Web Tokens)
- **ORM**: Sequel
- **API Documentation**: OpenAPI (Swagger)

### Databases

- **PostgreSQL 13+** for user data storage
- **MySQL 8.0+** for session tokens and blacklisted tokens

### Testing

- **RSpec** for unit and integration tests
- **FactoryBot** for test data generation
- **Faker** for generating random test data
- **SimpleCov** for code coverage
- **WebMock** for HTTP request stubbing

### Development & Deployment

- **Docker** for containerization
- **Docker Compose** for local development
- **RuboCop** for code style enforcement
- **Rake** for task automation

### Security

- **bcrypt** for password hashing
- **JWT** for secure token-based authentication
- **Rack::Protection** for web security
- **Helmet** for setting secure HTTP headers

## 📦 Prerequisites

### System Requirements

- Ruby 3.x
- Bundler 2.0+
- Git

### Database Requirements

- PostgreSQL 13+ (for user data)
- MySQL 8.0+ (for session tokens)

### Development Tools (Optional)

- Docker 20.10+
- Docker Compose 2.0+
- Node.js 16+ (for frontend development)
- Yarn or npm (for frontend dependencies)

## 🚀 Deployment

### Prerequisites

- A server with Docker and Docker Compose installed
- Domain name with DNS configured
- SSL certificate (recommended: Let's Encrypt)
- At least 2GB of RAM and 1 CPU core (4GB+ recommended for production)

### Environment Variables

Create a `.env` file with the following variables:

```env
# Application
RACK_ENV=production
PORT=3000
HOST=0.0.0.0

# Database (PostgreSQL)
POSTGRES_HOST=db
POSTGRES_PORT=5432
POSTGRES_DB=auth_service
POSTGRES_USER=auth_service
POSTGRES_PASSWORD=your_secure_password_here

# Redis (for rate limiting and caching)
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# JWT Authentication
JWT_SECRET=generate_a_secure_random_string_here
JWT_EXPIRATION=3600  # 1 hour in seconds

# CORS (comma-separated list of allowed origins)
ALLOWED_ORIGINS=https://your-frontend-domain.com,https://api.yourdomain.com

# Email (for password resets, etc.)
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_DOMAIN=yourdomain.com
SMTP_USERNAME=your_email@example.com
SMTP_PASSWORD=your_email_password
SMTP_AUTH=plain
SMTP_ENABLE_STARTTLS_AUTO=true

# Rate Limiting
RATE_LIMIT=100
RATE_LIMIT_PERIOD=60  # seconds
```

### Production Docker Compose

Create a `docker-compose.prod.yml` file:

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      args:
        - RACK_ENV=production
    image: auth-service:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - RACK_ENV=production
      - PORT=3000
      - HOST=0.0.0.0
      - POSTGRES_HOST=db
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - JWT_EXPIRATION=${JWT_EXPIRATION}
      - ALLOWED_ORIGINS=${ALLOWED_ORIGINS}
      - RATE_LIMIT=${RATE_LIMIT}
      - RATE_LIMIT_PERIOD=${RATE_LIMIT_PERIOD}
    depends_on:
      - db
      - redis
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 5s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - auth-network

  db:
    image: postgres:13-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 5s
      retries: 5
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - auth-network

  redis:
    image: redis:6-alpine
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "--no-auth-warning", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - auth-network

networks:
  auth-network:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
```

### Nginx Configuration

Create an Nginx configuration file at `/etc/nginx/sites-available/auth-service`:

```nginx
upstream auth_service {
  server 127.0.0.1:3000;
  keepalive 32;
}

server {
    listen 80;
    server_name auth.yourdomain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name auth.yourdomain.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/auth.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/auth.yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;

    # Logging
    access_log /var/log/nginx/auth-service-access.log;
    error_log /var/log/nginx/auth-service-error.log;

    # Proxy Configuration
    location / {
        proxy_pass http://auth_service;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        send_timeout 300s;
        
        # Buffer size
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }

    # Health Check Endpoint
    location /health {
        access_log off;
        add_header Content-Type text/plain;
        return 200 "OK\n";
    }

    # Disable access to sensitive files
    location ~ /\.(?!well-known) {
        deny all;
    }
}
```

### Deployment Steps

1. **Server Setup**
   ```bash
   # Update system packages
   sudo apt update && sudo apt upgrade -y
   
   # Install required packages
   sudo apt install -y git docker.io docker-compose nginx certbot python3-certbot-nginx
   
   # Add your user to the docker group
   sudo usermod -aG docker $USER
   newgrp docker
   ```

2. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/auth-service.git
   cd auth-service
   ```

3. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your production values
   nano .env
   
   # Generate a secure JWT secret
   echo "JWT_SECRET=$(openssl rand -hex 32)" >> .env
   ```

4. **Obtain SSL Certificate**
   ```bash
   sudo certbot --nginx -d auth.yourdomain.com --non-interactive --agree-tos -m admin@yourdomain.com --redirect
   ```

5. **Deploy the Application**
   ```bash
   # Build and start the services
   docker-compose -f docker-compose.prod.yml up -d --build
   
   # Run database migrations
   docker-compose -f docker-compose.prod.yml run --rm app rake db:migrate
   
   # Create admin user (if needed)
   # docker-compose -f docker-compose.prod.yml run --rm app rake admin:create[admin@example.com,securepassword]
   ```

6. **Set Up Log Rotation**
7. **Start the development server**

   ```bash
   rackup -p 3000
   ```

   The service will be available at `http://localhost:3000`

### Running with Docker

1. Build and start the containers:
   ```bash
   docker-compose up --build
   ```

2. The service will be available at `http://localhost:3000`

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/controllers/auth_controller_spec.rb

# Run with coverage report
COVERAGE=true bundle exec rspec
```

## 🔧 Variables de Entorno

El servicio utiliza las siguientes variables de entorno:

### Configuración General

```env
# Entorno de ejecución (development|test|production)
RACK_ENV=development

# Puerto del servidor
PORT=4567

# Nivel de log (debug|info|warn|error|fatal)
LOG_LEVEL=info

# Orígenes permitidos para CORS (separados por comas)
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

### Base de Datos PostgreSQL (Usuarios)

```env
DB_PG_HOST=localhost
DB_PG_PORT=5432
DB_PG_NAME=auth_service_development
DB_PG_USER=postgres
DB_PG_PASSWORD=postgres
DB_PG_POOL=5
DB_PG_TIMEOUT=5000
```

### Base de Datos MySQL (Tokens)

```env
DB_MYSQL_HOST=localhost
DB_MYSQL_PORT=3306
DB_MYSQL_NAME=auth_service_tokens
DB_MYSQL_USER=root
DB_MYSQL_PASSWORD=root
DB_MYSQL_POOL=5
DB_MYSQL_TIMEOUT=5000
```

### Configuración JWT

```env
# Clave secreta para firmar tokens (¡cambiar en producción!)
JWT_SECRET=tu_clave_secreta_muy_segura

# Tiempo de expiración del token en segundos (1 hora por defecto)
JWT_EXPIRATION=3600

# Algoritmo de firma (HS256, HS384, HS512, RS256, etc.)
JWT_ALGORITHM=HS256

# Emisor del token (opcional)
JWT_ISSUER=auth-service
```

## 📚 Estructura del Proyecto

```text
auth-service/
├── app/                     # Código fuente de la aplicación
│   ├── controllers/         # Controladores de la API
│   ├── models/              # Modelos de datos
│   │   ├── user.rb          # Modelo de usuario
│   │   └── token.rb         # Modelo de token
│   └── serializers/         # Serializadores para respuestas JSON
├── config/                  # Configuraciones
│   ├── database.rb          # Configuración de bases de datos
│   ├── environment.rb       # Configuración del entorno
│   └── initializers/        # Inicializadores
├── db/                      # Migraciones y seeds
│   ├── migrate/             # Archivos de migración
│   └── seeds.rb             # Datos iniciales
├── spec/                    # Pruebas
│   ├── factories/           # Factorías para pruebas
│   ├── requests/            # Pruebas de integración
│   ├── support/             # Configuración de pruebas
│   └── spec_helper.rb       # Configuración de RSpec
├── .env.example            # Plantilla de variables de entorno
├── .gitignore              # Archivos ignorados por Git
├── config.ru               # Configuración de Rack
├── Gemfile                 # Dependencias de Ruby
├── README.md               # Este archivo
└── Rakefile               # Tareas de Rake
```

## 📡 API Endpoints

### Autenticación

#### POST /api/v1/register

Registra un nuevo usuario en el sistema.

**Parámetros (JSON):**

```json
{
  "nombre": "Juan Pérez",
  "correo": "juan@ejemplo.com",
  "password": "ContraseñaSegura123",
  "password_confirmation": "ContraseñaSegura123",
  "rol": "usuario"
}
```

**Respuesta Exitosa (201 Created):**

```json
{
  "id": 1,
  "nombre": "Juan Pérez",
  "correo": "juan@ejemplo.com",
  "rol": "usuario",
  "created_at": "2023-04-15T10:30:00Z"
}
```

**Errores (400 Bad Request):**

- `email_taken`: El correo electrónico ya está en uso
- `invalid_email`: Formato de correo electrónico inválido
- `password_too_short`: La contraseña es demasiado corta (mínimo 8 caracteres)
- `passwords_dont_match`: Las contraseñas no coinciden

#### POST /api/v1/login

Autentica a un usuario y devuelve un token JWT.

**Parámetros (JSON):**

```json
{
  "correo": "juan@ejemplo.com",
  "password": "ContraseñaSegura123"
}
```

**Respuesta Exitosa (200 OK):**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600,
  "user": {
    "id": 1,
    "nombre": "Juan Pérez",
    "correo": "juan@ejemplo.com",
    "rol": "usuario"
  }
}
```

**Errores (401 Unauthorized):**

- `invalid_credentials`: Credenciales inválidas
- `account_locked`: La cuenta ha sido bloqueada temporalmente

### Usuarios

#### GET /api/v1/me

Obtiene la información del usuario autenticado.

**Headers requeridos:**

```
Authorization: Bearer <token>
```

**Respuesta Exitosa (200 OK):**

```json
{
  "id": 1,
  "nombre": "Juan Pérez",
  "correo": "juan@ejemplo.com",
  "rol": "usuario",
  "created_at": "2023-04-15T10:30:00Z",
  "updated_at": "2023-04-15T10:30:00Z"
}
```

**Errores (401 Unauthorized):**

- `missing_token`: No se proporcionó token
- `invalid_token`: Token inválido o expirado

## 🔐 Estructura JWT

Los tokens JWT están firmados con el algoritmo especificado en `JWT_ALGORITHM` y contienen los siguientes claims:

| Claim       | Tipo    | Descripción                                  |
|-------------|---------|----------------------------------------------|
| `id`        | Integer | ID único del usuario                         |
| `email`     | String  | Correo electrónico del usuario               |
| `rol`       | String  | Rol del usuario (usuario/admin)              |
| `iat`       | Integer | Fecha de emisión (timestamp en segundos)     |
| `exp`       | Integer | Fecha de expiración (timestamp en segundos)  |
| `iss`       | String  | Emisor del token (opcional)                  |

**Ejemplo de payload decodificado:**

```json
{
  "id": 1,
  "email": "juan@ejemplo.com",
  "rol": "usuario",
  "iat": 1717011123,
  "exp": 1717014723,
  "iss": "auth-service"
}
```

## 🧪 Pruebas

El servicio incluye un conjunto completo de pruebas automatizadas:

### Pruebas Unitarias

- Modelos (User, Token)
- Controladores
- Serializadores
- Helpers

### Pruebas de Integración

- Endpoints de la API
- Flujos de autenticación
- Validaciones de seguridad

### Ejecutando las Pruebas

1. Configurar la base de datos de prueba:

   ```bash
   RACK_ENV=test ruby config/database.rb migrate
   ```

2. Ejecutar las pruebas:

   ```bash
   bundle exec rspec
   ```

3. Ver la cobertura de código (se genera en `coverage/`):

   ```bash
   open coverage/index.html
   ```

### Generar datos de prueba

```bash
# Generar 10 usuarios de prueba
bundle exec rake db:seed:users[10]

# Generar 100 tokens de prueba
bundle exec rake db:seed:tokens[100]
```

## 🚀 Despliegue

### Requisitos de Producción

- Ruby 3.x
- PostgreSQL 13+
- MySQL 8.0+
- Redis (para caché, opcional)
- Nginx o similar (como proxy inverso)

### Variables de Entorno de Producción

Asegúrate de configurar estas variables en producción:

```env
RACK_ENV=production
JWT_SECRET=clave_secreta_muy_larga_y_compleja
DB_PG_PASSWORD=contraseña_segura
DB_MYSQL_PASSWORD=contraseña_segura
```

### Despliegue con Docker

1. Construir la imagen:

   ```bash
   docker build -t auth-service .
   ```

2. Ejecutar con Docker Compose:

   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

### Despliegue en Kubernetes

Ver el directorio `kubernetes/` para los manifiestos de Kubernetes.

## 🔒 Seguridad

### Medidas de Seguridad Implementadas

1. **Autenticación**

   - Tokens JWT firmados
   - Contraseñas hasheadas con bcrypt
   - Tiempo de expiración de tokens
   - Renovación de tokens

2. **Protección de Datos**

   - Encriptación de datos sensibles
   - Contraseñas nunca registradas
   - Headers de seguridad HTTP

3. **Seguridad en la API**

   - Validación de entrada
   - Protección contra inyección SQL
   - Rate limiting
   - CORS configurado

4. **Buenas Prácticas**

   - Principio de mínimo privilegio
   - Rotación de claves JWT
   - Registro de eventos de seguridad

### Recomendaciones de Producción

1. **JWT**

   - Usa claves asimétricas (RS256) en producción
   - Implementa revocación de tokens
   - Establece un tiempo de expiración razonable

2. **Base de Datos**

   - Usa conexiones SSL/TLS
   - Limita los permisos del usuario de la base de datos
   - Realiza copias de seguridad periódicas

3. **Red**

   - Usa HTTPS con certificados válidos
   - Configura WAF (Web Application Firewall)
   - Limita el acceso a los puertos de administración

## 🤝 Contribución

1. Haz un fork del proyecto
2. Crea una rama para tu feature (`git checkout -b feature/amazing-feature`)
3. Haz commit de tus cambios (`git commit -m 'Add some amazing feature'`)
4. Haz push a la rama (`git push origin feature/amazing-feature`)
5. Abre un Pull Request

## 📝 Licencia

Distribuido bajo la licencia MIT. Ver `LICENSE` para más información.

## 📞 Soporte

Para soporte, por favor contacta al equipo de desarrollo o abre un issue en el repositorio.

## 🙏 Agradecimientos

- A todos los contribuyentes que han ayudado a mejorar este proyecto.
- A la comunidad de código abierto por las increíbles herramientas utilizadas.

---

---

<p align="center">
  <img src="https://img.shields.io/badge/Hecho%20con-%E2%9D%A4%EF%B8%8F-ff69b4" alt="Hecho con amor">
  <img src="https://img.shields.io/badge/Version-1.0.0-blue" alt="Versión 1.0.0">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="Licencia MIT">
</p>

## 🚀 Inicio Rápido

### 📚 API Documentation

### Base URL

All API endpoints are prefixed with `/api/v1`.

### Authentication

This API uses JWT (JSON Web Tokens) for authentication. Include the token in the `Authorization` header for authenticated requests:

```http
Authorization: Bearer your.jwt.token.here
```

### Endpoints

#### User Registration

Register a new user account.

```http
POST /api/v1/register
```

**Request Body**

```json
{
  "email": "user@example.com",
  "password": "securePassword123!",
  "name": "John Doe"
}
```

**Response (201 Created)**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "name": "John Doe",
  "created_at": "2025-03-20T14:30:00Z",
  "updated_at": "2025-03-20T14:30:00Z"
}
```

**Error Responses**

- `400 Bad Request`: Invalid input data
- `409 Conflict`: Email already registered

#### User Login

Authenticate a user and receive an access token.

```http
POST /api/v1/login
```

**Request Body**

```json
{
  "email": "user@example.com",
  "password": "securePassword123!"
}
```

**Response (200 OK)**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

**Error Responses**

- `401 Unauthorized`: Invalid credentials
- `404 Not Found`: User not found

#### Token Verification

Verify if a token is valid and get user information.

```http
GET /api/v1/verify
```

**Headers**

```
Authorization: Bearer your.jwt.token.here
```

**Response (200 OK)**

```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "name": "John Doe"
  },
  "exp": 1732021800
}
```

**Error Responses**

- `401 Unauthorized`: Invalid or expired token

### Error Responses

All error responses follow this format:

```json
{
  "error": {
    "code": "error_code",
    "message": "Human-readable error message",
    "details": {
      "field_name": ["validation error message"]
    }
  }
}
```

### Rate Limiting

- **Rate Limit**: 100 requests per minute per IP address

- **Headers**:

  - `X-RateLimit-Limit`: Request limit per time window
  - `X-RateLimit-Remaining`: Remaining requests in current window
  - `X-RateLimit-Reset`: Time when the rate limit resets (UTC epoch seconds)

### API Versioning

API versioning is handled through the URL path. The current version is `v1`.

### Interactive Documentation

For interactive API documentation and testing, visit the Swagger UI at:

```
http://localhost:3000/api-docs
```

This requires the development server to be running.

### Ejecutar en modo desarrollo

```bash
# Instalar dependencias de frontend (si se usa)
yarn install

# Iniciar el servidor
bundle exec rackup -p 4567
```

## 🧪 Pruebas Rápidas con curl

```bash
# Registrar un nuevo usuario
curl -X POST http://localhost:4567/api/v1/register \
     -H 'Content-Type: application/json' \
     -d '{"nombre":"Usuario Prueba","correo":"test@demo.com","password":"contraseña123","password_confirmation":"contraseña123"}'

# Iniciar sesión
curl -X POST http://localhost:4567/api/v1/login \
     -H 'Content-Type: application/json' \
     -d '{"correo":"test@demo.com","password":"contraseña123"}'

# Obtener perfil (usar token obtenido en login)
curl -X GET http://localhost:4567/api/v1/me \
     -H 'Authorization: Bearer TU_TOKEN_JWT_AQUI'

---

## Authentication Flow (simplified)
1. Client sends credentials to `/login`
2. Service verifies credentials and generates a JWT signed with `JWT_SECRET`
3. Client includes the JWT in the `Authorization: Bearer <token>` header for subsequent requests
4. Other services (e.g., `profile-service`) validate the token without contacting the `auth-service`
