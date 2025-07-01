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
APP_DIR="/home/ec2-user/profile-service"
sudo mkdir -p $APP_DIR
sudo chown ec2-user:ec2-user $APP_DIR

# Create docker-compose file
cat <<EOT > $APP_DIR/docker-compose.yml
version: '3.8'

services:
  profile:
    image: your-docker-repo/profile-service:latest
    container_name: profile-service
    restart: always
    ports:
      - "4567:4567"
    environment:
      - RACK_ENV=production
      - PORT=4567
    volumes:
      - ./:/app
    working_dir: /app

EOT

# Create systemd service
cat <<EOT | sudo tee /etc/systemd/system/profile-service.service
[Unit]
Description=Profile Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ec2-user/profile-service
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
Restart=always
User=ec2-user

[Install]
WantedBy=multi-user.target
EOT

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable profile-service
sudo systemctl start profile-service

echo "Profile service setup complete!"
