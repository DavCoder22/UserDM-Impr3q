#!/bin/bash

# Update the system
sudo yum update -y

# Install required packages
sudo yum install -y git ruby ruby-devel gcc gcc-c++ make zlib-devel openssl-devel readline-devel sqlite-devel

# Install Node.js and Yarn (needed for some Ruby gems)
curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
sudo yum install -y nodejs
curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
sudo yum install -y yarn

# Install Ruby version manager (rbenv)
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install ruby-build plugin for rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Install Ruby 3.3.0
rbenv install 3.3.0
rbenv global 3.3.0

echo 'export PATH="$HOME/.rbenv/shims:$PATH"' >> ~/.bashrc
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Install bundler
gem install bundler

# Clone the repository (replace with your actual repository)
git clone https://github.com/your-username/UserDM-Proyect.git /home/ec2-user/UserDM-Proyect
cd /home/ec2-user/UserDM-Proyect/auth-service

# Install dependencies
bundle install

# Set up environment variables
echo 'export RACK_ENV=production' >> ~/.bashrc
echo 'export JWT_SECRET=your_jwt_secret_here' >> ~/.bashrc
echo 'export PORT=3000' >> ~/.bashrc
source ~/.bashrc

# Install systemd service
cat <<EOT | sudo tee /etc/systemd/system/auth-service.service
[Unit]
Description=Auth Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/UserDM-Proyect/auth-service
Environment=RACK_ENV=production
Environment=JWT_SECRET=your_jwt_secret_here
Environment=PORT=3000
ExecStart=/home/ec2-user/.rbenv/shims/bundle exec rackup -p 3000 -o 0.0.0.0
Restart=always

[Install]
WantedBy=multi-user.target
EOT

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable auth-service
sudo systemctl start auth-service

# Install and configure Nginx as a reverse proxy
sudo amazon-linux-extras install -y nginx1

# Configure Nginx
cat <<EOT | sudo tee /etc/nginx/conf.d/auth-service.conf
upstream auth_service {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    server_name _;


    location / {
        proxy_pass http://auth_service;
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
sudo systemctl start nginx

# Enable firewall
sudo yum install -y firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

echo "Setup complete!"
