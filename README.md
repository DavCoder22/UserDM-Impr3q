# 🧩 User Domain Microservices System

A distributed system built with microservices architecture to handle user management, authentication, and related functionalities. This project follows domain-driven design principles to provide scalable and maintainable user management capabilities.

## 🏗️ System Architecture

The system is composed of the following microservices:

1. **🔐 Authentication Service** (`auth-service`)
   - Handles user registration, login, and JWT token issuance
   - Manages user sessions and authentication state
   - Provides role-based access control (RBAC)

2. **👤 Profile Service** (`perfil-service`)
   - Manages user profile information and preferences
   - Handles personal data and account settings
   - Provides user search and management capabilities

3. **📜 History Service** (`historial-service`)
   - Tracks and logs user activities and system events
   - Provides audit trails for security and compliance
   - Enables activity monitoring and reporting

4. **🖨️ Printer Profile Service** (Planned)
   - Manages printer profiles and configurations
   - Handles print quotas and availability
   - Tracks printer usage and performance

## 🚀 Getting Started

### Prerequisites

- Ruby 3.x
- Bundler (`gem install bundler`)
- PostgreSQL 14+
- MySQL 8.0+ (for history service)
- Docker and Docker Compose (optional but recommended)

### Quick Start with Docker

1. Clone the repository:

   ```bash
   git clone <repo-url>
   cd UserDM-Proyect
   ```

2. Start all services:

   ```bash
   docker-compose up --build
   ```

This will start the following services:

- 🔐 **Auth Service**: `http://localhost:4000`
- 👤 **Profile Service**: `http://localhost:4001`
- 📜 **History Service**: `http://localhost:4002`
- 📊 PostgreSQL database
- 🗄️ MySQL database (for history)
- 🔍 **Adminer** (database management): `http://localhost:8080`

### Manual Setup

For manual setup, please refer to each service's README for specific instructions.

## 🔗 Service Communication

Services communicate using HTTP/REST APIs and JWT tokens for authentication. The typical flow is:

1. User authenticates with `auth-service`
2. Receives a JWT token
3. Uses the token to access other services
4. Each service validates the token with `auth-service`

## 📚 Documentation

Each service has its own detailed documentation in its respective directory:

- [Authentication Service](./auth-service/README.md)
- [Profile Service](./perfil-service/README.md)
- [History Service](./historial-service/README.md)

## 🛠️ Development

### Project Structure

```text
UserDM-Proyect/
├── auth-service/         # Authentication microservice
├── perfil-service/       # User profile microservice
├── historial-service/    # Activity logging microservice
├── terraform/           # Infrastructure as Code
└── docker-compose.yml   # Local development setup
```

### Contributing

We welcome contributions! If you'd like to contribute, please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with Ruby and Sinatra for lightweight, scalable microservices
- Uses PostgreSQL and MySQL for reliable data storage
- Follows RESTful API design principles
- Implements JWT for secure service-to-service communication

The client includes the token in the header when making requests to protected endpoints:

```http
Authorization: Bearer your.jwt.token.here
```
The `perfil-service` verifies the token's signature and validity locally using a public key or shared secret.

## 🤝 Contributing
Fork the repo and create your branch:
git checkout -b feature/my-feature
Commit and push your changes:
git commit -am 'Add new feature' && git push origin feature/my-feature
Open a pull request ✅

📄 License
Distributed under the MIT License.