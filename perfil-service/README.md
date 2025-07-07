# 👤 Profile Service

A microservice for managing user profiles in the UserDM platform. This service handles user profile information, preferences, and settings with secure authentication integration.

## 🚀 Key Features

- **Profile Management** - Create, read, update, and delete user profiles
- **Authentication Integration** - Secure JWT token validation
- **Data Validation** - Comprehensive input validation and sanitization
- **RESTful API** - Clean, consistent API design
- **Database Integration** - PostgreSQL for profile data storage
- **Caching** - Redis for performance optimization
- **Rate Limiting** - Protection against abuse
- **Comprehensive Testing** - Full test coverage with RSpec

## 🛠️ Technology Stack

### Core Technologies

- **Language**: Ruby 3.x
- **Web Framework**: Sinatra
- **Authentication**: JWT (JSON Web Tokens)
- **Database**: PostgreSQL
- **Caching**: Redis
- **API Documentation**: OpenAPI (Swagger)

### Testing

- **RSpec** for unit and integration tests
- **FactoryBot** for test data generation
- **Faker** for generating random test data
- **SimpleCov** for code coverage
- **Database Cleaner** for test isolation

### Development & Deployment

- **Docker** for containerization
- **Docker Compose** for local development
- **RuboCop** for code style enforcement
- **Rake** for task automation

## 📦 Prerequisites

### System Requirements

- Ruby 3.x
- Bundler 2.0+
- PostgreSQL 13+
- Redis 6+
- Git

### Development Tools (Optional)

- Docker 20.10+
- Docker Compose 2.0+

## 🧪 Testing

### Running Tests

The profile service includes comprehensive test coverage. You can run tests in multiple ways:

#### Option 1: Automatic Detection (Recommended)
```bash
# Windows PowerShell
.\run_tests_auto.ps1

# Linux/Mac
./run_tests_auto.sh
```

This script automatically detects if you have Ruby or Docker available and uses the appropriate method.

#### Option 2: With Ruby (Local)
```bash
# Install dependencies
bundle install

# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/models/profile_spec.rb
bundle exec rspec spec/requests/profiles_spec.rb

# Run with coverage report
bundle exec rspec --format documentation
```

#### Option 3: With Docker
```bash
# Build and run tests
docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit

# Or use the script
.\test_with_docker.ps1
```

### Test Structure

```
spec/
├── models/                 # Model tests
│   └── profile_spec.rb    # Profile model tests
├── requests/              # API endpoint tests
│   └── profiles_spec.rb   # Profile API tests
├── factories/             # Test data factories
│   └── profiles.rb        # Profile factories
├── support/               # Test configuration
│   ├── database_setup.rb
│   ├── factory_bot.rb
│   └── test_environment.rb
└── spec_helper.rb         # Main test configuration
```

### Test Coverage

The service maintains high test coverage:
- **Overall Coverage**: 80% minimum
- **Critical Files**: 100% coverage required
- **Models**: 90%+ coverage
- **API Endpoints**: 85%+ coverage

### Test Data

Tests use FactoryBot for generating test data:
- Profile factories with different user types
- Authentication token factories
- Test data for various scenarios

### Database Testing

Tests automatically:
- Create test database tables
- Clean data between tests
- Use transaction-based isolation
- Handle database connection errors gracefully

## 🚀 Deployment

### Prerequisites

- A server with Docker and Docker Compose installed
- Domain name with DNS configured
- SSL certificate (recommended: Let's Encrypt)
- At least 1GB of RAM and 1 CPU core

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
POSTGRES_DB=profile_service
POSTGRES_USER=profile_service
POSTGRES_PASSWORD=your_secure_password_here

# Redis (for caching)
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# JWT Authentication
JWT_SECRET=generate_a_secure_random_string_here
JWT_EXPIRATION=3600  # 1 hour in seconds

# CORS (comma-separated list of allowed origins)
ALLOWED_ORIGINS=https://your-frontend-domain.com,https://api.yourdomain.com

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
    image: profile-service:latest
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
      - profile-network

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
      - profile-network

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - profile-network

volumes:
  postgres_data:
  redis_data:

networks:
  profile-network:
    driver: bridge
```

### Deployment Steps

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd perfil-service
   ```

2. **Set up environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your production values
   ```

3. **Deploy with Docker Compose**:
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

4. **Verify deployment**:
   ```bash
   curl http://localhost:3000/health
   ```

## 🔧 Development

### Local Development Setup

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd perfil-service
   bundle install
   ```

2. **Set up databases**:
   ```bash
   # Start PostgreSQL and Redis with Docker
   docker-compose up -d db redis
   
   # Run migrations
   bundle exec rake db:migrate
   ```

3. **Start the development server**:
   ```bash
   bundle exec rackup
   ```

### Code Quality

- **RuboCop**: Code style enforcement
  ```bash
  bundle exec rubocop
  ```

- **RSpec**: Test execution
  ```bash
  bundle exec rspec
  ```

- **SimpleCov**: Coverage reports
  ```bash
  bundle exec rspec
  open coverage/index.html
  ```

## 📚 API Documentation

### Profile Endpoints

#### GET /profiles/:id
Get a user's profile by ID.

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response**:
```json
{
  "id": "uuid",
  "user_id": "user_uuid",
  "nombre": "John",
  "apellido": "Doe",
  "telefono": "+1234567890",
  "direccion": "123 Main St",
  "ciudad": "New York",
  "pais": "USA",
  "preferencias": {
    "notificaciones": true,
    "tema": "dark"
  },
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

#### POST /profiles
Create a new user profile.

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "nombre": "John",
  "apellido": "Doe",
  "telefono": "+1234567890",
  "direccion": "123 Main St",
  "ciudad": "New York",
  "pais": "USA",
  "preferencias": {
    "notificaciones": true,
    "tema": "dark"
  }
}
```

**Response**:
```json
{
  "message": "Perfil creado exitosamente",
  "profile": {
    "id": "uuid",
    "user_id": "user_uuid",
    "nombre": "John",
    "apellido": "Doe",
    "telefono": "+1234567890",
    "direccion": "123 Main St",
    "ciudad": "New York",
    "pais": "USA",
    "preferencias": {
      "notificaciones": true,
      "tema": "dark"
    },
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
}
```

#### PUT /profiles/:id
Update an existing user profile.

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "nombre": "John Updated",
  "telefono": "+1987654321",
  "preferencias": {
    "notificaciones": false,
    "tema": "light"
  }
}
```

**Response**:
```json
{
  "message": "Perfil actualizado exitosamente",
  "profile": {
    "id": "uuid",
    "user_id": "user_uuid",
    "nombre": "John Updated",
    "apellido": "Doe",
    "telefono": "+1987654321",
    "direccion": "123 Main St",
    "ciudad": "New York",
    "pais": "USA",
    "preferencias": {
      "notificaciones": false,
      "tema": "light"
    },
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z"
  }
}
```

#### DELETE /profiles/:id
Delete a user profile.

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response**:
```json
{
  "message": "Perfil eliminado exitosamente"
}
```

## 🔒 Security Features

- **JWT Token Validation**: Secure token verification for all endpoints
- **Input Validation**: Comprehensive data validation and sanitization
- **Rate Limiting**: Protection against abuse
- **CORS Configuration**: Cross-origin request protection
- **SQL Injection Protection**: Parameterized queries
- **XSS Protection**: Output encoding and sanitization

## 📊 Monitoring & Health Checks

### Health Check Endpoint
```
GET /health
```

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00Z",
  "version": "1.0.0",
  "database": "connected",
  "redis": "connected"
}
```

### Metrics Endpoints
- `GET /metrics` - Application metrics
- `GET /health/detailed` - Detailed health information

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

### Testing Guidelines

- Write tests for all new features
- Maintain test coverage above 80%
- Use descriptive test names
- Follow the existing test patterns
- Test both success and failure scenarios

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the [documentation](docs/)
- Review the [API documentation](docs/api.md)
