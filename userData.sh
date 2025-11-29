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
sudo git clone https://github.com/Kabilan2370/strapi-production-build.git strapi
sudo chown -R ubuntu:ubuntu /opt/strapi
cd /opt/strapi


# Environment variables for DB
sudo bash -c "cat <<EOF > .env
DATABASE_CLIENT=postgres
DATABASE_HOST=${db_host}
DATABASE_PORT=5432
DATABASE_USERNAME=${db_user}
DATABASE_PASSWORD=${db_password}
AWS_REGION=us-east-1
AWS_S3_BUCKET=${s3_bucket}
EOF"

# Install Strapi
sudo -u ubuntu npm install @strapi/provider-upload-aws-s3
sudo -u ubuntu npm install


# Start Strapi with PM2
sudo pm2 start npm --name "strapi" -- start
sudo pm2 save
sudo pm2 startup systemd -u ubuntu --hp /home/ubuntu
