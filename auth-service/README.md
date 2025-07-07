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

## 🧪 Testing

### Running Tests

The authentication service includes comprehensive test coverage. You can run tests in multiple ways:

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
bundle exec rspec spec/models/user_spec.rb
bundle exec rspec spec/controllers/auth_controller_spec.rb

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
│   ├── user_spec.rb       # User model tests
│   └── session_spec.rb    # Session model tests
├── controllers/           # Controller tests
│   └── auth_controller_spec.rb
├── integration/          # Integration tests
├── factories/           # Test data factories
│   └── user_factory.rb
├── support/             # Test configuration
│   ├── database_setup.rb
│   ├── factory_bot.rb
│   └── test_environment.rb
└── spec_helper.rb       # Main test configuration
```

### Test Coverage

The service maintains high test coverage:
- **Overall Coverage**: 80% minimum
- **Critical Files**: 100% coverage required
- **Models**: 90%+ coverage
- **Controllers**: 85%+ coverage

### Test Data

Tests use FactoryBot for generating test data:
- User factories with different roles (cliente, impresor, admin)
- Session factories with various states
- Login history factories

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
      - auth-network

volumes:
  postgres_data:
  redis_data:

networks:
  auth-network:
    driver: bridge
```

### Deployment Steps

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd auth-service
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
   cd auth-service
   bundle install
   ```

2. **Set up databases**:
   ```bash
   # Start PostgreSQL and MySQL with Docker
   docker-compose up -d db mysql
   
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

### Authentication Endpoints

#### POST /auth/register
Register a new user account.

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "securepassword",
  "nombre": "John",
  "apellido": "Doe",
  "telefono": "+1234567890",
  "rol": "cliente"
}
```

**Response**:
```json
{
  "message": "Usuario registrado exitosamente",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "nombre": "John",
    "rol": "cliente"
  }
}
```

#### POST /auth/login
Authenticate user and receive JWT tokens.

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response**:
```json
{
  "access_token": "jwt_token_here",
  "refresh_token": "refresh_token_here",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

#### POST /auth/refresh-token
Refresh access token using refresh token.

**Request Body**:
```json
{
  "refresh_token": "refresh_token_here"
}
```

**Response**:
```json
{
  "access_token": "new_jwt_token_here",
  "refresh_token": "new_refresh_token_here",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

#### DELETE /auth/logout
Logout and invalidate tokens.

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response**:
```json
{
  "message": "Sesión cerrada exitosamente"
}
```

## 🔒 Security Features

- **JWT Token Management**: Secure token generation and validation
- **Password Hashing**: bcrypt for secure password storage
- **Rate Limiting**: Protection against brute force attacks
- **CORS Configuration**: Cross-origin request protection
- **Input Validation**: Comprehensive data validation
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
