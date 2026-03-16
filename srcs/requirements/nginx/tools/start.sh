#!/bin/bash
# NGINX setup script

set -euo pipefail

# Generate self-signed SSL certificate (first run only)
if [ ! -f /etc/nginx/ssl/nginx.crt ] || [ ! -f /etc/nginx/ssl/nginx.key ]; then
    openssl req -x509 -nodes -days 365 \
    -subj "/C=MA/ST=Tetouan/L=Tetouan/O=42/OU=Inception/CN=sel-mlil.42.fr" \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt
fi

echo "127.0.0.1 sel-mlil.42.fr" >> /etc/hosts

# Start nginx in foreground
exec nginx -g "daemon off;"