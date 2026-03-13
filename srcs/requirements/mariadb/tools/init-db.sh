#!/bin/bash
set -euo pipefail

# MariaDB initialization script

if [ ! -f /run/secrets/db_root_password ] || [ ! -f /run/secrets/db_password ]; then
    echo "Missing required secret files in /run/secrets"
    exit 1
fi

MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

if [ -z "${MYSQL_DATABASE:-}" ] || [ -z "${MYSQL_USER:-}" ]; then
    echo "Missing MYSQL_DATABASE or MYSQL_USER environment variable"
    exit 1
fi

echo "DATABASE: ${MYSQL_DATABASE}"
echo "USER: ${MYSQL_USER}"

mkdir -p /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql
chmod -R u+rwX /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."

    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    mysqld --user=mysql --bootstrap <<EOF
FLUSH PRIVILEGES;
USE mysql;
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

    echo "MariaDB initialization complete."
else
    echo "MariaDB already initialized, skipping..."
fi

exec mysqld --user=mysql --console

#* bootstrap mode to only read queries from stdin and exit when done