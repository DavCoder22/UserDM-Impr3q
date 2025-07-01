#!/bin/bash

# Update the system
sudo yum update -y

# Install Docker
sudo amazon-linux-extras install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user

# Install Docker Compose
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create application directory
APP_DIR="/home/ec2-user/catalog-${service_name}"
sudo mkdir -p $APP_DIR
sudo chown ec2-user:ec2-user $APP_DIR

# Create docker-compose file
cat <<EOT > $APP_DIR/docker-compose.yml
version: '3.8'

services:
  ${service_name}:
    image: your-docker-repo/catalog-${service_name}:latest
    container_name: catalog-${service_name}
    restart: always
    ports:
      - "${service_port}:${service_port}"
    environment:
      - SPRING_PROFILES_ACTIVE=${environment}
      - SERVER_PORT=${service_port}
    networks:
      - catalog-network

networks:
  catalog-network:
    driver: bridge
EOT

# Create systemd service
cat <<EOT | sudo tee /etc/systemd/system/catalog-${service_name}.service
[Unit]
Description=Catalog ${service_name} Service
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
sudo systemctl daemon-reload
sudo systemctl enable catalog-${service_name}
sudo systemctl start catalog-${service_name}

# Install and configure Nginx as a reverse proxy
sudo amazon-linux-extras install -y nginx1

# Configure Nginx for the service
cat <<EOT | sudo tee /etc/nginx/conf.d/catalog-${service_name}.conf
server {
    listen 80;
    server_name ${service_name}.example.com;

    location / {
        proxy_pass http://localhost:${service_port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOT

# Start Nginx
sudo systemctl enable nginx
sudo systemctl restart nginx

echo "Catalog ${service_name} setup complete!"
