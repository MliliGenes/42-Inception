#!/bin/bash
# MariaDB initialization script

# # read secrets from files
# MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
# MYSQL_PASSWORD=$(cat /run/secrets/db_password)

echo $MYSQL_ROOT_PASSWORD
echo $MYSQL_PASSWORD

# check if the database was initialized before
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."
    
    # create system files for mariadb
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    # run bootstrap ONLY on first start
    mysqld --user=mysql --bootstrap << EOF
USE mysql;
FLUSH PRIVILEGES;

DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

    echo "MariaDB initialization complete."
else
    echo "MariaDB already initialized, skipping..."
fi

# Start MariaDB as PID 1
exec mysqld --user=mysql --console

#* bootstrap mode to only read queries from stdin and exit when done