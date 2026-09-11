#!/bin/bash
set -e

apt-get update -y
apt-get install -y nginx awscli

mkdir -p /etc/novasphere

DB_PASSWORD=$(aws ssm get-parameter \
  --name "/novasphere/dev/db_password" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region us-east-1)

printf "DB_PASSWORD=%s\n" "$DB_PASSWORD" > /etc/novasphere/app.conf
chmod 0640 /etc/novasphere/app.conf

HOST=$(hostname)
echo "<html><body><h1>NovaSphere - dev - $HOST</h1></body></html>" > /var/www/html/index.html

systemctl enable nginx
systemctl restart nginx