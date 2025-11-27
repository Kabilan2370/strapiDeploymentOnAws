#!/bin/bash

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
sudo apt-get install -y nodejs git
sudo npm install -g yarn pm2

cd /opt
git clone https://github.com/strapi/strapi-app-template.git strapi
cd strapi

yarn install

# Environment variables for DB
echo "
DATABASE_CLIENT=postgres
DATABASE_HOST=${db_host}
DATABASE_PORT=5432
DATABASE_NAME=${db_name}
DATABASE_USERNAME=${db_user}
DATABASE_PASSWORD=${db_password}
" > .env

yarn build
pm2 start yarn --name strapi -- start
pm2 save
