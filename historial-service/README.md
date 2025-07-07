# 📊 History Service

A microservice for managing user activity history and audit logs in the UserDM platform. This service tracks user actions, login history, and provides comprehensive audit trails for security and compliance.

## 🚀 Key Features

- **Activity Tracking** - Record and retrieve user activities
- **Login History** - Track user login/logout events
- **Audit Logs** - Comprehensive audit trail for compliance
- **Authentication Integration** - Secure JWT token validation
- **Data Analytics** - Historical data analysis and reporting
- **RESTful API** - Clean, consistent API design
- **Database Integration** - PostgreSQL for history data storage
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

The history service includes comprehensive test coverage. You can run tests in multiple ways:

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
bundle exec rspec spec/models/history_spec.rb
bundle exec rspec spec/requests/history_spec.rb

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
│   └── history_spec.rb    # History model tests
├── requests/              # API endpoint tests
│   └── history_spec.rb    # History API tests
├── factories/             # Test data factories
│   └── history.rb         # History factories
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
- History factories with different event types
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
POSTGRES_DB=history_service
POSTGRES_USER=history_service
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

# History Retention
HISTORY_RETENTION_DAYS=365  # Keep history for 1 year
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
    image: history-service:latest
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
      - HISTORY_RETENTION_DAYS=${HISTORY_RETENTION_DAYS}
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
      - history-network

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
      - history-network

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
      - history-network

volumes:
  postgres_data:
  redis_data:

networks:
  history-network:
    driver: bridge
```

### Deployment Steps

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd historial-service
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
   cd historial-service
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

### History Endpoints

#### GET /history/user/:user_id
Get user activity history.

**Headers**:
```
Authorization: Bearer <access_token>
```

**Query Parameters**:
- `page` (optional): Page number for pagination
- `per_page` (optional): Items per page (default: 20)
- `event_type` (optional): Filter by event type
- `start_date` (optional): Filter from date (ISO 8601)
- `end_date` (optional): Filter to date (ISO 8601)

**Response**:
```json
{
  "history": [
    {
      "id": "uuid",
      "user_id": "user_uuid",
      "event_type": "login",
      "description": "User logged in successfully",
      "ip_address": "192.168.1.1",
      "user_agent": "Mozilla/5.0...",
      "metadata": {
        "browser": "Chrome",
        "os": "Windows 10"
      },
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

#### POST /history
Record a new activity event.

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "user_id": "user_uuid",
  "event_type": "profile_update",
  "description": "User updated profile information",
  "ip_address": "192.168.1.1",
  "user_agent": "Mozilla/5.0...",
  "metadata": {
    "updated_fields": ["nombre", "telefono"],
    "browser": "Chrome"
  }
}
```

**Response**:
```json
{
  "message": "Evento registrado exitosamente",
  "event": {
    "id": "uuid",
    "user_id": "user_uuid",
    "event_type": "profile_update",
    "description": "User updated profile information",
    "ip_address": "192.168.1.1",
    "user_agent": "Mozilla/5.0...",
    "metadata": {
      "updated_fields": ["nombre", "telefono"],
      "browser": "Chrome"
    },
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

#### GET /history/login/:user_id
Get user login history.

**Headers**:
```
Authorization: Bearer <access_token>
```

**Query Parameters**:
- `page` (optional): Page number for pagination
- `per_page` (optional): Items per page (default: 20)
- `success` (optional): Filter by success status (true/false)

**Response**:
```json
{
  "login_history": [
    {
      "id": "uuid",
      "user_id": "user_uuid",
      "ip_address": "192.168.1.1",
      "user_agent": "Mozilla/5.0...",
      "success": true,
      "reason": null,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 50,
    "total_pages": 3
  }
}
```

#### GET /history/analytics
Get analytics and statistics.

**Headers**:
```
Authorization: Bearer <access_token>
```

**Query Parameters**:
- `start_date` (optional): Start date for analytics (ISO 8601)
- `end_date` (optional): End date for analytics (ISO 8601)
- `user_id` (optional): Filter by specific user

**Response**:
```json
{
  "analytics": {
    "total_events": 1500,
    "unique_users": 250,
    "event_types": {
      "login": 800,
      "logout": 750,
      "profile_update": 150,
      "password_change": 50
    },
    "successful_logins": 750,
    "failed_logins": 50,
    "most_active_users": [
      {
        "user_id": "user_uuid",
        "event_count": 25
      }
    ],
    "top_ip_addresses": [
      {
        "ip_address": "192.168.1.1",
        "event_count": 100
      }
    ]
  },
  "period": {
    "start_date": "2024-01-01T00:00:00Z",
    "end_date": "2024-01-31T23:59:59Z"
  }
}
```

## 🔒 Security Features

- **JWT Token Validation**: Secure token verification for all endpoints
- **Input Validation**: Comprehensive data validation and sanitization
- **Rate Limiting**: Protection against abuse
- **CORS Configuration**: Cross-origin request protection
- **SQL Injection Protection**: Parameterized queries
- **XSS Protection**: Output encoding and sanitization
- **Data Retention**: Automatic cleanup of old records

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
  "redis": "connected",
  "storage": {
    "total_events": 1500,
    "database_size": "2.5GB"
  }
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
