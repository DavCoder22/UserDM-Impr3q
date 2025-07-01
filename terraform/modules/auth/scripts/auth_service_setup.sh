#!/bin/bash

# Update the system
sudo zypper -n refresh
sudo zypper -n update -y

# Install Docker
sudo zypper -n install docker
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user

# Install Docker Compose
sudo zypper -n install docker-compose

# Create application directory
APP_DIR="/home/ec2-user/auth-service"
sudo mkdir -p $APP_DIR
sudo chown ec2-user:ec2-user $APP_DIR

# Create docker-compose file
cat <<EOT > $APP_DIR/docker-compose.yml
version: '3.8'

services:
  auth-service:
    image: your-docker-repo/auth-service:latest
    container_name: auth-service
    restart: always
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=${environment}
      - SERVER_PORT=8080
    networks:
      - auth-network

networks:
  auth-network:
    driver: bridge
EOT

# Create systemd service
cat <<EOT | sudo tee /etc/systemd/system/auth-service.service
[Unit]
Description=Auth Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${APP_DIR}
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
Restart=always
User=ec2-user

[Install]
WantedBy=multi-user.target
EOT

# Enable and start the service
sudo systemctl enable auth-service
sudo systemctl start auth-service
