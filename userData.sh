#!/bin/bash

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
sudo apt-get install -y nodejs git
sudo npm install -g yarn pm2

cd /opt
git clone https://github.com/Kabilan2370/strapi-aws-production.git strapi
cd strapi


# Environment variables for DB
echo "
DATABASE_CLIENT=postgres
DATABASE_HOST=${db_host}
DATABASE_PORT=5432
DATABASE_NAME=${db_name}
DATABASE_USERNAME=${db_user}
DATABASE_PASSWORD=${db_password}
AWS_REGION=us-east-1
AWS_S3_BUCKET=${s3_bucket}
" > .env

npm install
npm run build

pm2 start npm --name "strapi" -- start
pm2 save
