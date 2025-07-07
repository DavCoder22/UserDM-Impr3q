#!/bin/bash

# Update the system
yum update -y

# Install Docker
yum install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install additional tools
yum install -y git wget curl jq

# Create application directory
APP_DIR="/home/ec2-user/auth-microservices"
mkdir -p $APP_DIR
chown ec2-user:ec2-user $APP_DIR

# Create environment file
cat <<EOT > $APP_DIR/.env
# Database Configuration
DATABASE_URL=postgresql://${db_username}:${db_password}@${db_endpoint}/${db_name}
POSTGRES_USER=${db_username}
POSTGRES_PASSWORD=${db_password}
POSTGRES_DB=${db_name}

# Redis Configuration
REDIS_URL=redis://:${redis_password}@${redis_endpoint}:${redis_port}/0
REDIS_PASSWORD=${redis_password}

# JWT Configuration
JWT_SECRET=${jwt_secret}
JWT_EXPIRATION=3600

# Environment
RACK_ENV=production
NODE_ENV=production

# CORS Configuration
ALLOWED_ORIGINS=*
FRONTEND_URL=http://localhost:3000

# Service URLs
AUTH_SERVICE_URL=http://localhost:3000
PROFILE_SERVICE_URL=http://localhost:4567
HISTORY_SERVICE_URL=http://localhost:4567

# Security
SESSION_SECRET=${jwt_secret}
PEPPER=${jwt_secret}

# Logs
LOG_LEVEL=info
LOG_FILE=logs/app.log

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=900

# Health Check
HEALTH_CHECK_INTERVAL=30
HEALTH_CHECK_TIMEOUT=5
EOT

# Create docker-compose file
cat <<EOT > $APP_DIR/docker-compose.yml
version: '3.8'

networks:
  app_network:
    driver: bridge

services:
  # Auth Register Service
  auth-register-service:
    image: \${DOCKER_REGISTRY:-your-registry}/auth-register-service:latest
    container_name: auth_register_service
    environment:
      - RACK_ENV=production
      - JWT_SECRET=\${JWT_SECRET}
      - DATABASE_URL=\${DATABASE_URL}
      - REDIS_URL=\${REDIS_URL}
      - ALLOWED_ORIGINS=\${ALLOWED_ORIGINS}
    expose:
      - "3000"
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Auth Login Service
  auth-login-service:
    image: \${DOCKER_REGISTRY:-your-registry}/auth-login-service:latest
    container_name: auth_login_service
    environment:
      - RACK_ENV=production
      - JWT_SECRET=\${JWT_SECRET}
      - DATABASE_URL=\${DATABASE_URL}
      - REDIS_URL=\${REDIS_URL}
      - ALLOWED_ORIGINS=\${ALLOWED_ORIGINS}
    expose:
      - "3000"
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Auth Profile Service
  auth-profile-service:
    image: \${DOCKER_REGISTRY:-your-registry}/auth-profile-service:latest
    container_name: auth_profile_service
    environment:
      - RACK_ENV=production
      - JWT_SECRET=\${JWT_SECRET}
      - DATABASE_URL=\${DATABASE_URL}
      - REDIS_URL=\${REDIS_URL}
      - ALLOWED_ORIGINS=\${ALLOWED_ORIGINS}
    expose:
      - "3000"
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Auth Password Service
  auth-password-service:
    image: \${DOCKER_REGISTRY:-your-registry}/auth-password-service:latest
    container_name: auth_password_service
    environment:
      - RACK_ENV=production
      - JWT_SECRET=\${JWT_SECRET}
      - DATABASE_URL=\${DATABASE_URL}
      - REDIS_URL=\${REDIS_URL}
      - ALLOWED_ORIGINS=\${ALLOWED_ORIGINS}
    expose:
      - "3000"
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Auth Logout Service
  auth-logout-service:
    image: \${DOCKER_REGISTRY:-your-registry}/auth-logout-service:latest
    container_name: auth_logout_service
    environment:
      - RACK_ENV=production
      - JWT_SECRET=\${JWT_SECRET}
      - REDIS_URL=\${REDIS_URL}
      - ALLOWED_ORIGINS=\${ALLOWED_ORIGINS}
    expose:
      - "3000"
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Auth History Service
  auth-history-service:
    image: \${DOCKER_REGISTRY:-your-registry}/auth-history-service:latest
    container_name: auth_history_service
    environment:
      - RACK_ENV=production
      - JWT_SECRET=\${JWT_SECRET}
      - DATABASE_URL=\${DATABASE_URL}
      - REDIS_URL=\${REDIS_URL}
      - ALLOWED_ORIGINS=\${ALLOWED_ORIGINS}
    expose:
      - "3000"
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Perfil Service
  perfil-service:
    image: \${DOCKER_REGISTRY:-your-registry}/perfil-service:latest
    container_name: perfil_service
    environment:
      - RACK_ENV=production
      - JWT_SECRET=\${JWT_SECRET}
      - DATABASE_URL=\${DATABASE_URL}
      - AUTH_SERVICE_URL=\${AUTH_SERVICE_URL}
      - ALLOWED_ORIGINS=\${ALLOWED_ORIGINS}
    ports:
      - "4567:4567"
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:4567/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Historial Service
  historial-service:
    image: \${DOCKER_REGISTRY:-your-registry}/historial-service:latest
    container_name: historial_service
    environment:
      - RACK_ENV=production
      - JWT_SECRET=\${JWT_SECRET}
      - DATABASE_URL=\${DATABASE_URL}
      - ALLOWED_ORIGINS=\${ALLOWED_ORIGINS}
    ports:
      - "4568:4567"
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:4567/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Nginx Load Balancer
  nginx:
    image: nginx:alpine
    container_name: nginx_alb
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - auth-register-service
      - auth-login-service
      - auth-profile-service
      - auth-password-service
      - auth-logout-service
      - auth-history-service
      - perfil-service
      - historial-service
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
EOT

# Create nginx configuration
cat <<EOT > $APP_DIR/nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream auth_services {
        server auth-register-service:3000;
        server auth-login-service:3000;
        server auth-profile-service:3000;
        server auth-password-service:3000;
        server auth-logout-service:3000;
        server auth-history-service:3000;
    }

    upstream profile_service {
        server perfil-service:4567;
    }

    upstream history_service {
        server historial-service:4567;
    }

    server {
        listen 80;
        server_name _;

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # Auth services
        location /api/v1/auth/ {
            proxy_pass http://auth_services/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # Profile service
        location /api/v1/profile/ {
            proxy_pass http://profile_service/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # History service
        location /api/v1/history/ {
            proxy_pass http://history_service/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # Default to auth services
        location / {
            proxy_pass http://auth_services/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOT

# Create systemd service
cat <<EOT | tee /etc/systemd/system/auth-microservices.service
[Unit]
Description=Auth Microservices
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$APP_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
Restart=always
User=ec2-user

[Install]
WantedBy=multi-user.target
EOT

# Set proper permissions
chown -R ec2-user:ec2-user $APP_DIR

# Enable and start the service
systemctl enable auth-microservices
systemctl start auth-microservices

# Wait for services to be ready
sleep 30

# Test health endpoints
echo "Testing service health..."
curl -f http://localhost/health || echo "Health check failed"
curl -f http://localhost:4567/health || echo "Profile service health check failed"
curl -f http://localhost:4568/health || echo "History service health check failed"

echo "Setup completed successfully!" 