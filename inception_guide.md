# Inception Project - Complete Implementation Guide

*This guide has been created to help understand and implement the Inception project from the 42 curriculum.*

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture Design](#architecture-design)
3. [Prerequisites](#prerequisites)
4. [Project Structure](#project-structure)
5. [Mandatory Part Implementation](#mandatory-part-implementation)
6. [Bonus Part Implementation](#bonus-part-implementation)
7. [Testing and Validation](#testing-and-validation)
8. [Common Issues and Solutions](#common-issues-and-solutions)

---

## Project Overview

### Goal
Set up a small infrastructure using Docker Compose with multiple services running in separate containers, following best practices for containerization and security.

### Key Concepts
- **Docker vs Virtual Machines**: Docker containers share the host OS kernel (lightweight, fast startup), while VMs include a full OS (isolated, heavier resource usage)
- **Secrets vs Environment Variables**: Secrets are for sensitive data with restricted access; environment variables are for configuration
- **Docker Network vs Host Network**: Docker networks isolate containers; host network removes isolation but offers better performance
- **Docker Volumes vs Bind Mounts**: Volumes are managed by Docker (portable, better performance); bind mounts link to host filesystem (direct access)

---

## Architecture Design

### Mandatory Services

```
┌─────────────────────────────────────────┐
│         Internet (Port 443)             │
└──────────────────┬──────────────────────┘
                   │ TLSv1.2/1.3
          ┌────────▼────────┐
          │     NGINX       │
          │  (Web Server)   │
          └────────┬────────┘
                   │
          ┌────────▼────────────────┐
          │   Docker Network        │
          │   (inception-network)   │
          └─┬──────────────────┬────┘
            │                  │
   ┌────────▼────────┐  ┌─────▼──────────┐
   │   WordPress     │  │    MariaDB     │
   │   + php-fpm     │  │   (Database)   │
   └────────┬────────┘  └─────┬──────────┘
            │                 │
   ┌────────▼────────┐  ┌─────▼──────────┐
   │ WordPress Files │  │ Database Data  │
   │    (Volume)     │  │    (Volume)    │
   └─────────────────┘  └────────────────┘
         │                      │
   /home/login/data/wordpress   │
                    /home/login/data/mariadb
```

### Bonus Services (Optional)

```
Additional containers:
- Redis (cache)
- FTP Server
- Adminer (database management)
- Static website
- Custom service
```

---

## Prerequisites

### System Requirements
- Virtual Machine (VirtualBox, VMware, or UTM)
- Linux OS (Ubuntu/Debian recommended)
- Docker Engine
- Docker Compose
- Make

### Installation Commands

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt-get install docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

---

## Project Structure

```
inception/
├── Makefile
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── credentials.txt
├── srcs/
│   ├── docker-compose.yml
│   ├── .env
│   └── requirements/
│       ├── mariadb/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   │   └── 50-server.cnf
│       │   └── tools/
│       │       └── init-db.sh
│       ├── nginx/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   │   └── nginx.conf
│       │   └── tools/
│       │       └── setup.sh
│       ├── wordpress/
│       │   ├── Dockerfile
│       │   ├── .dockerignore
│       │   └── tools/
│       │       └── setup.sh
│       └── bonus/
│           ├── redis/
│           ├── ftp/
│           ├── adminer/
│           └── static-site/
├── README.md
├── USER_DOC.md
└── DEV_DOC.md
```

---

## Mandatory Part Implementation

### Step 1: Create Directory Structure

```bash
mkdir -p inception/{secrets,srcs/requirements/{mariadb/{conf,tools},nginx/{conf,tools},wordpress/tools}}
cd inception
```

### Step 2: Environment Variables (.env)

Create `srcs/.env`:

```bash
# Domain Configuration
DOMAIN_NAME=login.42.fr

# MariaDB Configuration
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=secure_wp_password

# WordPress Configuration
WP_ADMIN_USER=wpadmin
WP_ADMIN_PASSWORD=secure_admin_password
WP_ADMIN_EMAIL=admin@login.42.fr
WP_USER=wpuser2
WP_USER_EMAIL=user@login.42.fr
WP_USER_PASSWORD=secure_user_password
WP_TITLE=Inception Website

# Paths
MYSQL_HOST=mariadb
```

**Important**: Add `.env` to `.gitignore`!

### Step 3: Docker Secrets

Create secret files in `secrets/`:

```bash
# secrets/db_root_password.txt
echo "very_secure_root_password" > secrets/db_root_password.txt

# secrets/db_password.txt
echo "secure_wp_password" > secrets/db_password.txt

# secrets/credentials.txt
echo "admin_credentials_here" > secrets/credentials.txt

# Secure permissions
chmod 600 secrets/*
```

### Step 4: MariaDB Container

**srcs/requirements/mariadb/Dockerfile**:

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY tools/init-db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-db.sh

RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init-db.sh"]
```

**srcs/requirements/mariadb/conf/50-server.cnf**:

```ini
[mysqld]
user                    = mysql
pid-file                = /var/run/mysqld/mysqld.pid
socket                  = /var/run/mysqld/mysqld.sock
port                    = 3306
basedir                 = /usr
datadir                 = /var/lib/mysql
tmpdir                  = /tmp
bind-address            = 0.0.0.0
skip-networking         = false
```

**srcs/requirements/mariadb/tools/init-db.sh**:

```bash
#!/bin/bash

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Start MariaDB temporarily
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

# Start MariaDB
exec mysqld --user=mysql --console
```

### Step 5: WordPress Container

**srcs/requirements/wordpress/Dockerfile**:

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-mbstring \
    php7.4-soap \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-zip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Download WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Configure PHP-FPM
RUN sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 9000/g' /etc/php/7.4/fpm/pool.d/www.conf && \
    mkdir -p /run/php

COPY tools/setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup.sh"]
```

**srcs/requirements/wordpress/tools/setup.sh**:

```bash
#!/bin/bash

cd /var/www/html

# Wait for MariaDB to be ready
while ! mysqladmin ping -h"$MYSQL_HOST" --silent; do
    echo "Waiting for MariaDB..."
    sleep 2
done

# Download WordPress if not exists
if [ ! -f wp-config.php ]; then
    echo "Setting up WordPress..."
    
    wp core download --allow-root
    
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${MYSQL_HOST}" \
        --allow-root
    
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root
    
    # Create second user
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root
    
    echo "WordPress setup complete."
fi

# Set permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Start PHP-FPM
exec php-fpm7.4 -F
```

### Step 6: NGINX Container

**srcs/requirements/nginx/Dockerfile**:

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Generate self-signed SSL certificate
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=login.42.fr"

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
```

**srcs/requirements/nginx/conf/nginx.conf**:

```nginx
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        
        server_name login.42.fr;
        
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_certificate /etc/nginx/ssl/inception.crt;
        ssl_certificate_key /etc/nginx/ssl/inception.key;
        
        root /var/www/html;
        index index.php index.html;
        
        location / {
            try_files $uri $uri/ /index.php?$args;
        }
        
        location ~ \.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass wordpress:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO $fastcgi_path_info;
        }
    }
}
```

### Step 7: Docker Compose Configuration

**srcs/docker-compose.yml**:

```yaml
version: '3.8'

services:
  mariadb:
    container_name: mariadb
    build: ./requirements/mariadb
    image: mariadb
    volumes:
      - mariadb_data:/var/lib/mysql
    networks:
      - inception-network
    env_file:
      - .env
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
      MYSQL_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_root_password
      - db_password
    restart: unless-stopped

  wordpress:
    container_name: wordpress
    build: ./requirements/wordpress
    image: wordpress
    depends_on:
      - mariadb
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - inception-network
    env_file:
      - .env
    restart: unless-stopped

  nginx:
    container_name: nginx
    build: ./requirements/nginx
    image: nginx
    depends_on:
      - wordpress
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - inception-network
    ports:
      - "443:443"
    restart: unless-stopped

volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/login/data/mariadb
  
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/login/data/wordpress

networks:
  inception-network:
    driver: bridge

secrets:
  db_root_password:
    file: ../secrets/db_root_password.txt
  db_password:
    file: ../secrets/db_password.txt
```

### Step 8: Makefile

**Makefile**:

```makefile
COMPOSE_FILE = srcs/docker-compose.yml
DATA_PATH = /home/${USER}/data

all: setup build up

setup:
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress
	@sudo chmod 755 $(DATA_PATH)
	@sudo chmod 755 $(DATA_PATH)/mariadb
	@sudo chmod 755 $(DATA_PATH)/wordpress

build:
	docker compose -f $(COMPOSE_FILE) build

up:
	docker compose -f $(COMPOSE_FILE) up -d

down:
	docker compose -f $(COMPOSE_FILE) down

start:
	docker compose -f $(COMPOSE_FILE) start

stop:
	docker compose -f $(COMPOSE_FILE) stop

clean: down
	docker system prune -af

fclean: clean
	@sudo rm -rf $(DATA_PATH)/mariadb/*
	@sudo rm -rf $(DATA_PATH)/wordpress/*
	docker volume rm srcs_mariadb_data srcs_wordpress_data 2>/dev/null || true

re: fclean all

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

status:
	docker compose -f $(COMPOSE_FILE) ps

.PHONY: all setup build up down start stop clean fclean re logs status
```

---

## Bonus Part Implementation

### Redis Cache

**srcs/requirements/bonus/redis/Dockerfile**:

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf && \
    sed -i 's/protected-mode yes/protected-mode no/g' /etc/redis/redis.conf

EXPOSE 6379

CMD ["redis-server", "--protected-mode", "no"]
```

Add to `docker-compose.yml`:

```yaml
  redis:
    container_name: redis
    build: ./requirements/bonus/redis
    image: redis
    networks:
      - inception-network
    restart: unless-stopped
```

Update WordPress to use Redis (in `setup.sh`):

```bash
wp plugin install redis-cache --activate --allow-root
wp config set WP_REDIS_HOST redis --allow-root
wp config set WP_REDIS_PORT 6379 --allow-root
wp redis enable --allow-root
```

### FTP Server

**srcs/requirements/bonus/ftp/Dockerfile**:

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    vsftpd \
    && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 21 21100-21110

ENTRYPOINT ["/usr/local/bin/setup.sh"]
```

### Adminer

**srcs/requirements/bonus/adminer/Dockerfile**:

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget -O /var/www/html/index.php https://www.adminer.org/latest.php && \
    chown -R www-data:www-data /var/www/html

RUN sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 9001/g' /etc/php/7.4/fpm/pool.d/www.conf

EXPOSE 9001

CMD ["php-fpm7.4", "-F"]
```

### Static Website

**srcs/requirements/bonus/static-site/Dockerfile**:

```dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY website/ /var/www/html/

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
```

---

## Testing and Validation

### Host Configuration

Add to `/etc/hosts`:

```bash
127.0.0.1 login.42.fr
```

### Testing Commands

```bash
# Check containers are running
docker ps

# Check volumes
docker volume ls
ls -la /home/$USER/data/

# Check networks
docker network ls

# Test database connection
docker exec -it mariadb mysql -u wpuser -p wordpress

# Check WordPress files
docker exec -it wordpress ls -la /var/www/html

# View logs
docker logs nginx
docker logs wordpress
docker logs mariadb

# Access website
curl -k https://login.42.fr
```

### Validation Checklist

- [ ] All containers restart on crash
- [ ] NGINX only accessible via port 443
- [ ] TLSv1.2 or TLSv1.3 enabled
- [ ] No passwords in Dockerfiles
- [ ] Environment variables in .env
- [ ] Secrets properly configured
- [ ] Two WordPress users created
- [ ] Admin username doesn't contain "admin"
- [ ] No `latest` tag used
- [ ] Volumes stored in /home/login/data
- [ ] No infinite loops (tail -f, sleep infinity, etc.)
- [ ] No --link or network: host
- [ ] README.md, USER_DOC.md, DEV_DOC.md present

---

## Common Issues and Solutions

### Issue 1: Permission Denied on Volumes

```bash
sudo chown -R $USER:$USER /home/$USER/data
sudo chmod -R 755 /home/$USER/data
```

### Issue 2: MariaDB Won't Start

```bash
# Check logs
docker logs mariadb

# Remove old data
sudo rm -rf /home/$USER/data/mariadb/*
make re
```

### Issue 3: WordPress Can't Connect to Database

- Verify `MYSQL_HOST` matches service name in docker-compose.yml
- Check database credentials in .env
- Ensure MariaDB is fully started before WordPress

### Issue 4: SSL Certificate Issues

```bash
# Regenerate certificate in nginx container
docker exec -it nginx bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/inception.key \
  -out /etc/nginx/ssl/inception.crt \
  -subj "/C=FR/ST=Paris/L=Paris/O=42/CN=login.42.fr"
```

### Issue 5: Containers Exit Immediately

- Check PID 1 process in Dockerfiles
- Ensure CMD/ENTRYPOINT runs a foreground process
- Avoid bash scripts that exit
- Use `exec` in shell scripts for proper signal handling

---

## Best Practices

1. **Security**
   - Never commit secrets to git
   - Use strong passwords
   - Keep images updated
   - Minimize image size

2. **Docker**
   - Use specific base image tags (not `latest`)
   - Multi-stage builds when possible
   - Clean up in same RUN layer
   - Use .dockerignore files

3. **Development**
   - Test incrementally
   - Use docker logs for debugging
   - Keep services isolated
   - Document all configurations

4. **Production Readiness**
   - Health checks
   - Resource limits
   - Backup strategies
   - Monitoring setup

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress CLI](https://wp-cli.org/)
- [MariaDB Documentation](https://mariadb.org/documentation/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

## Conclusion

This guide provides a complete implementation of the Inception project. Remember to:

1. Test each service individually before integration
2. Follow the directory structure exactly
3. Secure all credentials and secrets
4. Document your work thoroughly
5. Understand every component you implement

Good luck with your Inception project!
