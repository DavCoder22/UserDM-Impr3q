# 🧑‍💼 Profile Service

[![Built with ❤️](https://img.shields.io/badge/Built%20with-%E2%9D%A4%EF%B8%8F-ff69b4)](https://github.com/your-username/profile-service)
[![Version](https://img.shields.io/badge/Version-1.0.0-blue)](https://github.com/your-username/profile-service/releases)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Ruby](https://img.shields.io/badge/Ruby-3.x-red)](https://www.ruby-lang.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13%2B-blue)](https://www.postgresql.org/)

## 📝 Description

Profile Service is a microservice responsible for managing user profile information, including personal data, preferences, and account settings in a distributed microservices environment. It integrates with the authentication service to provide a comprehensive identity and access management system.

## 🚀 Key Features

- **Complete Profile Management**: Full CRUD operations for user profiles with data validation
- **Authentication & Authorization**: JWT integration for end-to-end security
- **Personal Data**: Secure storage of personal and contact information
- **User Preferences**: Flexible system for storing user configurations
- **Avatar Management**: Storage and retrieval of profile images
- **Advanced Search**: Filtering and search by multiple criteria
- **Data Validation**: Robust input and format validation
- **RESTful API**: Well-defined endpoints following best practices
- **Comprehensive Documentation**: Integrated OpenAPI/Swagger specification
- **Automated Testing**: Complete suite of unit and integration tests
- **Scalability**: Designed to handle thousands of requests per second
- **High Availability**: Cluster deployment configuration

## 🛠️ Technology Stack

### Core Technologies

- **Ruby 3.x**: Primary programming language
- **RVM/rbenv**: Ruby version management
- **Bundler**: Dependency management

### Frameworks & Libraries

- **Sinatra**: Lightweight and modular web framework
- **Sequel**: Powerful and flexible database ORM
- **JWT**: JSON Web Token handling for authentication
- **Rodauth**: Robust authentication system
- **Puma**: Concurrent web server for Ruby
- **Rack**: Standard web server interface for Ruby

### Databases

- **PostgreSQL 13+**: Primary profile storage
- **Redis**: Cache and session storage (optional)

### Testing

- **RSpec**: Testing framework
- **FactoryBot**: Test data generation
- **Faker**: Realistic data generation
- **Shoulda-Matchers**: Expressive test matchers
- **DatabaseCleaner**: Database cleaning for tests
- **SimpleCov**: Code coverage analysis

### Development Tools

- **RuboCop**: Code linter and formatter
- **Overcommit**: Git hooks management
- **Pry**: Interactive console for debugging
- **Rake**: Task automation

### Monitoring & Logging

- **Lograge**: Log formatting
- **Sentry**: Error monitoring
- **Prometheus**: Application metrics

## 📋 System Requirements

### Minimum Requirements

- **Operating System**: Linux/macOS/Windows (WSL2 recommended for Windows)
- **Ruby**: 3.0.0 or higher
- **PostgreSQL**: 13.0 or higher
- **Authentication Service**: auth-service must be running
- **RAM**: Minimum 1GB (2GB recommended)
- **Disk Space**: Minimum 500MB

### System Dependencies

- **Development**:
  - Git 2.25+
  - Bundler 2.0+
  - PostgreSQL client libraries
  - Build essentials (compilers, make, etc.)

### Dependent Services

- **Auth Service**: For authentication and authorization
- **PostgreSQL Database**: For profile storage

## 🚀 Quick Setup

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/profile-service.git
cd profile-service
```

### 2. Install Dependencies

```bash
# Install Ruby dependencies
bundle install

# Install system dependencies (example for Ubuntu/Debian)
sudo apt-get install -y libpq-dev
```

### 3. Environment Configuration

```bash
# Copy example environment file
cp .env.example .env

# Edit the .env file with your configurations
nano .env  # or use your preferred editor
```

### 4. Database Setup

```bash
# Create databases (development and test)
createdb profile_service_development
createdb profile_service_test

# Run migrations
bundle exec rake db:migrate

# For test environment
RACK_ENV=test bundle exec rake db:migrate

# Seed with sample data (optional)
bundle exec rake db:seed
```

### 5. Start the Server

For development with auto-reload:

```bash
rerun -x 'bundle exec puma -C config/puma.rb'
```

Or for production:

```bash
RACK_ENV=production bundle exec puma -C config/puma.rb
```

### 6. Verify Installation

```bash
# Verify the server is running
curl http://localhost:4568/api/v1/health

# You should see a response like:
# {"status":"ok","message":"Profile Service is running"}
```

### 7. System Service Configuration (Optional)

To run the service as a systemd service:

```bash
# Create service file
sudo nano /etc/systemd/system/profile-service.service
```

Service file content:

```ini
[Unit]
Description=Profile Service
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/path/to/profile-service
Environment=RACK_ENV=production
EnvironmentFile=/path/to/profile-service/.env
ExecStart=/usr/local/rvm/gems/ruby-3.0.0/wrappers/bundle exec puma -C config/puma.rb
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable profile-service
sudo systemctl start profile-service
```

## 8. Nginx Configuration (Recommended for Production)

Create an Nginx configuration file:

```bash
sudo nano /etc/nginx/sites-available/profile-service
```

Example Nginx configuration:

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;  # Change to your domain
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;  # Change to your domain

    # SSL Configuration - Replace with your actual paths
    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;
    
    # SSL Security Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Logging Configuration
    access_log /var/log/nginx/profile-service-access.log;
    error_log /var/log/nginx/profile-service-error.log;

    # Reverse Proxy Configuration
    location / {
        proxy_pass http://localhost:4568;  # Port where the service runs
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Increase timeouts for heavy operations
        proxy_connect_timeout 60s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        # Maximum upload size for files (e.g., avatars)
        client_max_body_size 10M;
    }

    # CORS Configuration if needed
    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, PUT, DELETE, PATCH';
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
        add_header 'Access-Control-Max-Age' 1728000;
        add_header 'Content-Type' 'text/plain; charset=utf-8';
        add_header 'Content-Length' 0;
        return 204;
    }
| 500    | Internal server error         |

## 9. HTTPS Configuration with Let's Encrypt

Install Certbot and obtain SSL certificates:

```bash
# Install Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Obtain SSL certificate (follow instructions)
sudo certbot --nginx -d api.yourdomain.com  # Change to your domain

# Set up automatic renewal
echo "0 0,12 * * * root python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew -q" | sudo tee -a /etc/crontab > /dev/null
```

## 10. Firewall Configuration

Ensure only necessary ports are open:

```bash
# Install UFW if not installed
sudo apt-get install -y ufw

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https

# Enable firewall (be careful not to block your SSH access)
sudo ufw enable
```

## 11. Monitoring and Maintenance

### Monitoring with systemd

```bash
# Check service status
sudo systemctl status profile-service

# View service logs
sudo journalctl -u profile-service -f

# View error logs
sudo journalctl -u profile-service -p err -b
```

### Log Rotation

Set up scheduled log rotation:

```bash
# Create logrotate configuration
sudo nano /etc/logrotate.d/profile-service
```

Logrotate configuration file content:

```
/var/log/profile-service/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 deploy deploy
    sharedscripts
    postrotate
        systemctl reload profile-service >/dev/null 2>&1 || true
    endscript
}
```

## 12. Service Update

To update the service to a new version:

```bash
# Stop the service
sudo systemctl stop profile-service

# Backup the database
pg_dump profile_service_production > profile_service_backup_$(date +%Y%m%d).sql

# Update the code
git fetch origin
git checkout <tag-or-branch>
git pull

# Update dependencies
bundle install --without development test --deployment

# Run migrations if needed
bundle exec rake db:migrate RACK_ENV=production

# Restart the service
sudo systemctl start profile-service

# Verify everything is working
curl -I https://api.yourdomain.com/health
```

## 13. API Documentation

### Authentication

All endpoints require JWT authentication in the `Authorization` header:

```http
Authorization: Bearer <token>
```

### HTTP Status Codes

| Code | Description                     |
|------|---------------------------------|
| 200  | OK - Successful request         |
| 201  | Created - Resource created      |
| 400  | Bad Request - Invalid data      |
| 401  | Unauthorized                   |
| 403  | Forbidden - No permissions     |
| 404  | Not Found                      |
| 422  | Unprocessable Entity           |
| 500  | Internal Server Error          |

### 1. Profiles

#### Obtener perfil del usuario actual

Obtiene el perfil del usuario autenticado.

```http
GET /api/v1/profile
```

**Headers:**
- `Authorization: Bearer <token>`
- `Accept: application/json`

**Parámetros de consulta:**

- `include=preferences,avatar` - Incluir relaciones (opcional)

**Respuesta exitosa (200 OK):**

```json
{
  "status": "success",
  "data": {
    "id": 1,
    "user_id": 123,
    "nombre_completo": "Juan Pérez",
    "correo": "juan@ejemplo.com",
    "telefono": "+1234567890",
    "direccion": "Calle Falsa 123",
    "fecha_nacimiento": "1990-01-01",
    "genero": "M",
    "avatar_url": "https://ejemplo.com/avatars/1.jpg",
    "preferencias": {
      "tema": "claro",
      "notificaciones": true,
      "idioma": "es"
    },
    "created_at": "2023-01-01T00:00:00Z",
    "updated_at": "2023-01-01T00:00:00Z"
  },
  "meta": {
    "version": "1.0",
    "timestamp": "2023-06-29T12:00:00Z"
  }
}
```

**Errores comunes:**
- `401 Unauthorized` - Token inválido o expirado
- `404 Not Found` - Perfil no encontrado
- `500 Internal Server Error` - Error interno del servidor

#### Crear o actualizar perfil

Crea o actualiza el perfil del usuario autenticado.

```http
PUT /api/v1/profile
```

**Headers:**
- `Authorization: Bearer <token>`
- `Content-Type: application/json`
- `Accept: application/json`

**Cuerpo de la solicitud:**

```json
{
  "nombre_completo": "Juan Pérez",
  "telefono": "+1234567890",
  "direccion": "Calle Falsa 123",
  "fecha_nacimiento": "1990-01-01",
  "genero": "M",
  "preferencias": {
    "tema": "claro",
    "notificaciones": true,
    "idioma": "es"
  }
}
```

**Respuesta exitosa (200 OK):**

```json
{
  "status": "success",
  "data": {
    "id": 1,
    "user_id": 123,
    "nombre_completo": "Juan Pérez",
    "telefono": "+1234567890",
    "direccion": "Calle Falsa 123",
    "fecha_nacimiento": "1990-01-01",
    "genero": "M",
    "preferencias": {
      "tema": "claro",
      "notificaciones": true,
      "idioma": "es"
    },
    "created_at": "2023-01-01T00:00:00Z",
    "updated_at": "2023-01-01T12:00:00Z"
  },
  "meta": {
    "version": "1.0",
    "timestamp": "2023-06-29T12:00:00Z"
  }
}
```

**Errores comunes:**
- `400 Bad Request` - Datos de entrada inválidos
- `401 Unauthorized` - No autenticado
- `422 Unprocessable Entity` - Error de validación

### 2. Avatares

#### Subir avatar

Sube o actualiza el avatar del usuario.

```http
POST /api/v1/profile/avatar
Content-Type: multipart/form-data
```

**Headers:**
- `Authorization: Bearer <token>`
- `Accept: application/json`

**Parámetros del formulario:**

- `file` - Archivo de imagen (JPEG, PNG, GIF, máximo 5MB)

**Respuesta exitosa (200 OK):**

```json
{
  "status": "success",
  "data": {
    "id": 1,
    "url": "https://storage.ejemplo.com/avatars/1.jpg",
    "content_type": "image/jpeg",
    "file_size": 123456,
    "created_at": "2023-01-01T00:00:00Z"
  }
}
```

**Errores comunes:**

- `400 Bad Request` - Archivo inválido o muy grande
- `401 Unauthorized` - No autenticado
- `415 Unsupported Media Type` - Tipo de archivo no soportado

## 📊 Modelo de Datos

### Perfil de Usuario (`profiles`)

| Campo              | Tipo         | Descripción                                  |
|--------------------|--------------|----------------------------------------------|
| id                | UUID         | Identificador único del perfil              |
| user_id           | UUID         | Referencia al usuario (FK)                  |
| nombre_completo   | string(255)  | Nombre completo del usuario                 |
| telefono          | string(20)   | Número de teléfono                          |
| direccion         | text         | Dirección física                            |
| fecha_nacimiento  | date         | Fecha de nacimiento                         |
| genero            | string(1)    | Género (M, F, O)                            |
| avatar_url        | string       | URL del avatar del usuario                  |
| preferencias      | jsonb        | Preferencias del usuario en formato JSON    |
| created_at        | timestamp    | Fecha de creación                           |
| updated_at        | timestamp    | Fecha de última actualización               |

### Avatar (`avatars`)

| Campo         | Tipo         | Descripción                                  |
|---------------|--------------|----------------------------------------------|
| id            | UUID         | Identificador único del avatar              |
| profile_id    | UUID         | Referencia al perfil (FK)                   |
| file_name     | string       | Nombre del archivo original                 |
| content_type  | string       | Tipo MIME del archivo                       |
| file_size     | integer      | Tamaño del archivo en bytes                 |
| url           | string       | URL pública del archivo                     |
| metadata      | jsonb        | Metadatos adicionales                       |
| created_at    | timestamp    | Fecha de carga                              |
| updated_at    | timestamp    | Fecha de última actualización               |

**Headers:**
- `Authorization: Bearer <token>`
- `Content-Type: application/json`

**Cuerpo de la petición:**
```json
{
  "nombre_completo": "Juan Pérez",
  "correo": "juan@ejemplo.com",
  "telefono": "+1234567890",
  "direccion": "Calle Falsa 123",
  "fecha_nacimiento": "1990-01-01",
  "genero": "M",
  "preferencias": {
    "tema": "oscuro",
    "notificaciones": true,
    "idioma": "es"
  }
}
```

**Respuesta exitosa (200 OK):**

```json
{
  "status": "success",
  "message": "Perfil actualizado correctamente",
  "data": {
    "id": 1,
    "user_id": 123,
    "nombre_completo": "Juan Pérez",
    "correo": "juan@ejemplo.com",
    "telefono": "+1234567890",
    "direccion": "Calle Falsa 123",
    "fecha_nacimiento": "1990-01-01",
    "genero": "M",
    "avatar_url": "https://ejemplo.com/avatars/1.jpg",
    "created_at": "2023-01-01T00:00:00Z",
    "updated_at": "2023-01-02T12:00:00Z"
  }
}
```

### 3. Actualizar avatar

Actualiza la URL del avatar del perfil.

```http
PUT /api/v1/profile/avatar
```

**Headers:**
- `Authorization: Bearer <token>`
- `Content-Type: application/json`

**Cuerpo de la petición:**
```json
{
  "avatar_url": "https://ejemplo.com/avatars/1.jpg"
}
```

**Respuesta exitosa (200 OK):**

```json
{
  "status": "success",
  "message": "Avatar actualizado correctamente",
  "data": {
    "avatar_url": "https://ejemplo.com/avatars/1.jpg"
  }
}
```

### 4. Listar perfiles (Admin)

Obtiene una lista paginada de perfiles. Solo accesible por administradores.

```http
GET /api/v1/profiles
```

**Parámetros de consulta:**
- `page` - Número de página (predeterminado: 1)
- `per_page` - Elementos por página (predeterminado: 10, máximo: 100)
- `q` - Término de búsqueda (opcional)
- `sort` - Campo para ordenar (ej: `nombre_asc`, `fecha_desc`)

**Headers:**
- `Authorization: Bearer <token>`

**Respuesta exitosa (200 OK):**

```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "user_id": 123,
      "nombre_completo": "Juan Pérez",
      "correo": "juan@ejemplo.com",
      "avatar_url": "https://ejemplo.com/avatars/1.jpg",
      "created_at": "2023-01-01T00:00:00Z"
    },
    {
      "id": 2,
      "user_id": 124,
      "nombre_completo": "María García",
      "correo": "maria@ejemplo.com",
      "avatar_url": "https://ejemplo.com/avatars/2.jpg",
      "created_at": "2023-01-02T00:00:00Z"
    }
  ],
  "pagination": {
    "current_page": 1,
    "per_page": 10,
    "total_pages": 5,
    "total_count": 42
  }
}
```

## 🗄️ Modelo de Datos

### Tabla: profiles

| Columna           | Tipo         | Descripción                              |
|-------------------|--------------|------------------------------------------|
| id                | SERIAL       | Identificador único del perfil           |
| user_id           | INTEGER      | ID del usuario (referencia a auth-service)|
| nombre_completo   | VARCHAR(255) | Nombre completo del usuario              |
| correo            | VARCHAR(255) | Correo electrónico                       |
| telefono          | VARCHAR(50)  | Número de teléfono                       |
| direccion         | TEXT         | Dirección física                         |
| fecha_nacimiento  | DATE         | Fecha de nacimiento                      |
| genero            | VARCHAR(1)   | Género (M/F/O)                           |
| avatar_url        | TEXT         | URL de la imagen de perfil               |
| preferencias      | JSONB        | Preferencias de usuario en formato JSON  |
| created_at        | TIMESTAMPTZ  | Fecha de creación                        |
| updated_at        | TIMESTAMPTZ  | Fecha de última actualización            |

### Índices:
- Índice primario en `id`
- Índice único en `user_id`
- Índice en `correo` para búsquedas rápidas
- Índice GIN en `preferencias` para consultas JSONB eficientes

## 🧪 Pruebas

El servicio incluye un conjunto completo de pruebas unitarias y de integración para garantizar la calidad del código.

### Ejecutar pruebas

```bash
# Instalar dependencias de desarrollo
bundle install --with test

# Ejecutar todas las pruebas
bundle exec rspec

# Ejecutar pruebas en paralelo (más rápido)
bundle exec parallel_rspec spec/

# Ejecutar pruebas de un archivo específico
bundle exec rspec spec/models/profile_spec.rb

# Ejecutar una prueba específica
bundle exec rspec spec/models/profile_spec.rb:42
```

### Tipos de pruebas

1. **Pruebas de Modelo** (`spec/models/`):
   - Validaciones
   - Métodos de instancia
   - Métodos de clase
   - Relaciones

2. **Pruebas de Controlador** (`spec/requests/`):
   - Endpoints de la API
   - Autenticación y autorización
   - Manejo de errores
   - Validación de parámetros

3. **Pruebas de Integración** (`spec/integration/`):
   - Flujos completos
   - Interacción entre componentes
   - Comunicación con servicios externos

### Cobertura de código

El proyecto utiliza SimpleCov para medir la cobertura de código. Después de ejecutar las pruebas, se generará un informe en `coverage/index.html`.

```bash
# Ver informe de cobertura
open coverage/index.html  # En macOS
start coverage/index.html # En Windows
```

### Pruebas en CI/CD

El proyecto incluye configuración para ejecutar pruebas en entornos de integración continua. Ver `.github/workflows/tests.yml` para más detalles.

## 🚀 Despliegue

El servicio está diseñado para ser desplegado en diferentes entornos, desde desarrollo local hasta producción en la nube.

### Entorno de Desarrollo Local

```bash
# Usando Ruby directamente
bundle install
bundle exec ruby app.rb -p 4568

# Usando rerun para desarrollo (recarga automática)
gem install rerun
rerun -x 'bundle exec ruby app.rb -p 4568'
```

### Usando Docker

1. Construir la imagen:
   ```bash
   docker build -t perfil-service .
   ```

2. Ejecutar el contenedor:
   ```bash
   docker run -p 4568:4568 --env-file .env perfil-service
   ```

### Usando Docker Compose (recomendado)

```bash
docker-compose up --build
```

### Despliegue en Producción

#### Requisitos
- Servidor con Ruby 3.x o contenedor Docker
- PostgreSQL 13+
- Servidor de aplicaciones (Puma, Unicorn, etc.)
- Servidor web (Nginx, Apache) como proxy inverso opcional

#### Pasos

1. Clonar el repositorio en el servidor
2. Configurar las variables de entorno en `.env.production`
3. Instalar dependencias:
   ```bash
   bundle install --without development test
   ```
4. Ejecutar migraciones:
   ```bash
   RACK_ENV=production bundle exec rake db:migrate
   ```
5. Iniciar el servidor:
   ```bash
   RACK_ENV=production bundle exec puma -p 4568 -e production
   ```

#### Configuración de Nginx (opcional)

```nginx
server {
    listen 80;
    server_name api.ejemplo.com;

    location / {
        proxy_pass http://localhost:4568;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 🔒 Seguridad

### Medidas de Seguridad

1. **Autenticación y Autorización**
   - Todos los endpoints requieren autenticación mediante JWT
   - Validación de roles para operaciones sensibles
   - Tiempo de expiración corto para tokens

2. **Protección de Datos**
   - Las contraseñas nunca se almacenan en este servicio
   - Datos sensibles encriptados en tránsito (HTTPS)
   - Validación estricta de todos los datos de entrada

3. **Seguridad en la Base de Datos**
   - Conexiones SSL para la base de datos en producción
   - Usuarios con privilegios mínimos necesarios
   - Copias de seguridad automáticas

4. **Protección de la API**
   - Rate limiting para prevenir abusos
   - CORS configurado de forma restrictiva
   - Headers de seguridad HTTP

### Prácticas Recomendadas

1. **Variables de Entorno**
   - Nunca incluir credenciales en el código
   - Usar diferentes configuraciones por entorno
   - Rotar claves y contraseñas regularmente

2. **Monitoreo**
   - Configurar logs detallados
   - Monitorear intentos de acceso fallidos
   - Alertas para actividades sospechosas

3. **Actualizaciones**
   - Mantener todas las dependencias actualizadas
   - Aplicar parches de seguridad con prontitud

## 🤝 Contribución

1. Haz un fork del repositorio
2. Crea una rama para tu característica (`git checkout -b feature/nueva-caracteristica`)
3. Haz commit de tus cambios (`git commit -am 'Añade nueva característica'`)
4. Haz push a la rama (`git push origin feature/nueva-caracteristica`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

```
MIT License

Copyright (c) 2023 Tu Nombre

Se concede permiso, de forma gratuita, a cualquier persona que obtenga una copia
de este software y de la documentación asociada (el "Software"), para utilizar
el Software sin restricción, incluyendo sin limitación los derechos de uso,
copia, modificación, fusión, publicación, distribución, sublicencia y/o venta
copias del Software, y a las personas a las que se les proporcione el Software
para hacerlo, sujeto a las siguientes condiciones:

El aviso de copyright anterior y este aviso de permiso se incluirán en todas
las copias o partes sustanciales del Software.

EL SOFTWARE SE PROPORCIONA "TAL CUAL", SIN GARANTÍA DE NINGÚN TIPO, EXPRESA O
IMPLÍCITA, INCLUYENDO PERO NO LIMITADO A GARANTÍAS DE COMERCIALIZACIÓN,
IDONEIDAD PARA UN PROPÓSITO PARTICULAR Y NO INFRACCIÓN. EN NINGÚN CASO LOS
AUTORES O TITULARES DEL COPYRIGHT SERÁN RESPONSABLES DE NINGUNA RECLAMACIÓN,
DAÑO U OTRA RESPONSABILIDAD, YA SEA EN UNA ACCIÓN DE CONTRATO, AGRAVIO O DE OTRO
MODO, DERIVADA DE, FUERA DE O EN CONEXIÓN CON EL SOFTWARE O EL USO U OTROS
ACUERDOS EN EL SOFTWARE.
```

## 📞 Soporte

Para reportar problemas o solicitar características, por favor abre un [issue](https://github.com/tu-usuario/perfil-service/issues) en el repositorio.

## 🙏 Agradecimientos

- A todos los colaboradores que han ayudado a mejorar este proyecto
- A la comunidad de código abierto por las increíbles herramientas utilizadas
- A los revisores por sus valiosos comentarios
