#!/bin/bash

sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

sudo apt-get update -y

sudo curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
sudo apt-get install -y nodejs git
sudo npm install -g yarn pm2
sudo apt-get install -y postgresql-client

cd /opt
sudo git clone https://github.com/Kabilan2370/my-strapi-app-Deployment.git strapi
sudo chown -R ubuntu:ubuntu /opt/strapi



# Environment variables for DB
cd /opt/strapi
sudo bash -c 'cat <<EOF > .env
HOST=0.0.0.0
PORT=1337

APP_KEYS=$(openssl rand -base64 32)
API_TOKEN_SALT=$(openssl rand -base64 32)
ADMIN_JWT_SECRET=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 32)

DATABASE_CLIENT=postgres
DATABASE_HOST=${db_host}
DATABASE_PORT=5432
DATABASE_USERNAME=${db_user}
DATABASE_PASSWORD=${db_password}
DATABASE_NAME=${db_name}

AWS_REGION=us-east-1
AWS_S3_BUCKET=${s3_bucket}
EOF'

sudo chown ubuntu:ubuntu /opt/strapi/.env

# Install Strapi
sudo -u ubuntu npm install
sudo -u ubuntu npm install pg
sudo -u ubuntu npm install @strapi/provider-upload-aws-s3

sudo -u ubuntu npm run build

# Start Strapi with PM2
sudo pm2 start npm --name "strapi" -- start
sudo pm2 save
sudo pm2 startup systemd -u ubuntu --hp /home/ubuntu
