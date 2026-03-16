#!/bin/bash
# WordPress setup script

set -euo pipefail

WP_PATH="/var/www/html"

MYSQL_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASS="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASS="$(cat /run/secrets/wp_user_password)"

cd "$WP_PATH"

until mysqladmin ping -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent; do
  echo "Waiting for MariaDB..."
  sleep 2
done

if [ ! -f wp-config.php ]; then
  wp config create \
    --path="$WP_PATH" \
    --dbname="$MYSQL_DATABASE" \
    --dbuser="$MYSQL_USER" \
    --dbpass="$MYSQL_PASSWORD" \
    --dbhost="$MYSQL_HOST" \
    --allow-root
fi

if ! wp core is-installed --path="$WP_PATH" --allow-root; then
  wp core install \
    --path="$WP_PATH" \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="$WP_ADMIN_PASS" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email \
    --allow-root

  wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
    --user_pass="$WP_USER_PASS" \
    --role=author \
    --path="$WP_PATH" \
    --allow-root
fi

chown -R www-data:www-data "$WP_PATH"
mkdir -p /run/php
chown -R www-data:www-data /run/php
exec php-fpm7.4 -F  