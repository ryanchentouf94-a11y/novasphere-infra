#!/bin/bash
set -e
apt-get update -y
apt-get install -y nginx
HOST=$(hostname)
echo "<html><body><h1>NovaSphere - dev - $HOST</h1></body></html>" > /var/www/html/index.html
systemctl enable nginx
systemctl restart nginx