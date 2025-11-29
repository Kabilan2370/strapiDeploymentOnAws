#!/bin/bash

sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make swap permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

sudo apt-get update -y

sudo curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
sudo apt-get install -y nodejs git
sudo npm install -g yarn pm2

cd /opt
sudo git clone https://github.com/Kabilan2370/my-strapi-app-Deployment.git strapi
sudo chown -R ubuntu:ubuntu /opt/strapi
cd /opt/strapi



# Environment variables for DB
cd /opt/strapi
sudo bash -c "cat <<EOF > .env
HOST=0.0.0.0
PORT=1337

APP_KEYS=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex') + ',' + require('crypto').randomBytes(32).toString('hex') + ',' + require('crypto').randomBytes(32).toString('hex') + ',' + require('crypto').randomBytes(32).toString('hex'))")
API_TOKEN_SALT=$(node -e "console.log(require('crypto').randomBytes(16).toString('hex'))")
ADMIN_JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")

DATABASE_CLIENT=postgres
DATABASE_HOST=${db_host}
DATABASE_PORT=5432
DATABASE_USERNAME=${db_user}
DATABASE_PASSWORD=${db_password}
DATABASE_NAME=strapi

AWS_REGION=us-east-1
AWS_S3_BUCKET=${s3_bucket}
EOF"

sudo chown ubuntu:ubuntu .env

# Install Strapi
sudo -u ubuntu npm install --production
sudo -u ubuntu npm install pg
sudo -u ubuntu npm install @strapi/provider-upload-aws-s3

sudo -u ubuntu NODE_OPTIONS="--max_old_space_size=4096" npm run build




# Start Strapi with PM2
sudo pm2 start npm --name "strapi" -- start
sudo pm2 save
sudo pm2 startup systemd -u ubuntu --hp /home/ubuntu
