# Inception - Developer Documentation

This document provides technical details for developers who need to understand, modify, or extend the Inception infrastructure.

## Table of Contents
1. [Environment Setup](#environment-setup)
2. [Project Architecture](#project-architecture)
3. [Building and Launching](#building-and-launching)
4. [Container Management](#container-management)
5. [Volume Management](#volume-management)
6. [Network Configuration](#network-configuration)
7. [Development Workflow](#development-workflow)
8. [Extending the Project](#extending-the-project)
9. [Debugging Guide](#debugging-guide)
10. [CI/CD Integration](#cicd-integration)

---

## Environment Setup

### Prerequisites Installation

**System Requirements:**
- Virtual Machine (VirtualBox, VMware, or similar)
- Linux OS (Ubuntu 20.04+ or Debian 11+ recommended)
- Minimum 4GB RAM, 20GB disk space
- Internet connection for package downloads

**Install Docker Engine:**

```bash
# Update package index
sudo apt-get update

# Install dependencies
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

**Post-installation:**

```bash
# Add user to docker group (avoid using sudo)
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker

# Verify docker works without sudo
docker run hello-world

# Install additional tools
sudo apt-get install -y make git vim
```

### Project Structure Setup

```bash
# Clone repository
git clone <repo-url> inception
cd inception

# Create required directory structure
mkdir -p srcs/requirements/{mariadb/{conf,tools},nginx/{conf,tools},wordpress/tools}
mkdir -p srcs/requirements/bonus/{redis,ftp,adminer,static-site}
mkdir -p secrets

# Create .gitignore
cat > .gitignore << 'EOF'
.env
secrets/
*.log
.DS_Store
/home/
EOF
```

### Configuration Files

**1. Create .env file:**

```bash
cat > srcs/.env << 'EOF'
# Domain Configuration
DOMAIN_NAME=login.42.fr

# MariaDB Configuration
MYSQL_ROOT_PASSWORD=your_root_password_here
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=your_db_password_here

# WordPress Configuration
WP_ADMIN_USER=wpadmin
WP_ADMIN_PASSWORD=your_admin_password_here
WP_ADMIN_EMAIL=admin@login.42.fr
WP_USER=wpuser2
WP_USER_EMAIL=user@login.42.fr
WP_USER_PASSWORD=your_user_password_here
WP_TITLE=Inception Website

# Service Configuration
MYSQL_HOST=mariadb
WP_REDIS_HOST=redis
WP_REDIS_PORT=6379
EOF
```

**2. Create secret files:**

```bash
# Database root password
echo "super_secure_root_password" > secrets/db_root_password.txt

# Database user password
echo "secure_database_password" > secrets/db_password.txt

# Additional credentials
cat > secrets/credentials.txt << 'EOF'
Admin User: wpadmin
Admin Pass: [defined in .env]
DB User: wpuser
DB Pass: [defined in .env]
EOF

# Set proper permissions
chmod 600 secrets/*
```

**3. Configure /etc/hosts:**

```bash
# Add domain to hosts file
echo "127.0.0.1 login.42.fr" | sudo tee -a /etc/hosts
```

Replace `login` with your actual 42 login throughout.

---

## Project Architecture

### Service Dependencies

```
┌─────────────────┐
│   User/Browser  │
└────────┬────────┘
         │ HTTPS (443)
         ▼
┌─────────────────┐
│     NGINX       │  ◄── Entry point (TLS termination)
│   (debian:11)   │
└────────┬────────┘
         │ FastCGI (9000)
         ▼
┌─────────────────┐      ┌──────────────┐
│   WordPress     │◄────►│    Redis     │
│   + php-fpm     │      │  (optional)  │
│   (debian:11)   │      └──────────────┘
└────────┬────────┘
         │ MySQL Protocol (3306)
         ▼
┌─────────────────┐
│    MariaDB      │
│   (debian:11)   │
└─────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Persistent Volumes             │
│  - /home/login/data/mariadb     │
│  - /home/login/data/wordpress   │
└─────────────────────────────────┘
```

### Container Specifications

| Container | Base Image | Exposed Ports | Volumes | Network |
|-----------|-----------|---------------|---------|---------|
| nginx | debian:bullseye | 443 | wordpress_data | inception-network |
| wordpress | debian:bullseye | 9000 | wordpress_data | inception-network |
| mariadb | debian:bullseye | 3306 | mariadb_data | inception-network |

### Volume Structure

```
/home/login/data/
├── mariadb/           # Database files
│   ├── mysql/         # System database
│   ├── wordpress/     # WordPress database
│   └── ...
└── wordpress/         # WordPress files
    ├── wp-content/    # Themes, plugins, uploads
    ├── wp-includes/   # Core files
    ├── wp-admin/      # Admin panel
    └── wp-config.php  # Configuration
```

### Network Architecture

**Bridge Network:** `inception-network`

```
inception-network (172.18.0.0/16)
│
├── nginx (172.18.0.2)
├── wordpress (172.18.0.3)
├── mariadb (172.18.0.4)
└── redis (172.18.0.5) [bonus]
```

**DNS Resolution:**
- Containers can resolve each other by service name
- Example: WordPress connects to `mariadb:3306`

---

## Building and Launching

### Makefile Targets

```makefile
all             # Complete setup: setup + build + up
setup           # Create data directories with proper permissions
build           # Build all Docker images from Dockerfiles
up              # Start all containers in detached mode
down            # Stop and remove containers (keeps volumes)
start           # Start existing containers
stop            # Stop running containers
clean           # Remove containers and dangling images
fclean          # Clean + remove all volumes and data
re              # Full rebuild: fclean + all
logs            # Show logs from all containers
status          # Show container status
```

### Build Process

**Step-by-step build:**

```bash
# 1. Create directories
make setup

# 2. Build images (no cache)
docker compose -f srcs/docker-compose.yml build --no-cache

# 3. Start containers
docker compose -f srcs/docker-compose.yml up -d

# 4. Monitor startup
docker compose -f srcs/docker-compose.yml logs -f
```

**Build individual services:**

```bash
# Build only MariaDB
docker compose -f srcs/docker-compose.yml build mariadb

# Build only WordPress
docker compose -f srcs/docker-compose.yml build wordpress

# Build only NGINX
docker compose -f srcs/docker-compose.yml build nginx
```

### Launch Sequence

**Container startup order:**

1. **MariaDB** starts first
   - Initializes database if doesn't exist
   - Creates users and grants permissions
   - Begins accepting connections on port 3306

2. **WordPress** starts after MariaDB
   - Waits for database to be ready
   - Downloads WordPress core (if needed)
   - Configures wp-config.php
   - Creates admin and regular users
   - Starts PHP-FPM on port 9000

3. **NGINX** starts last
   - Loads SSL certificates
   - Configures FastCGI to WordPress
   - Begins accepting HTTPS on port 443

**Verification:**

```bash
# All containers should be "Up"
docker ps

# Check logs for errors
docker compose -f srcs/docker-compose.yml logs

# Test endpoints
curl -k https://login.42.fr
```

---

## Container Management

### Docker Compose Commands

```bash
# Start services
docker compose -f srcs/docker-compose.yml up -d

# Stop services
docker compose -f srcs/docker-compose.yml down

# Restart specific service
docker compose -f srcs/docker-compose.yml restart wordpress

# Scale service (if configured)
docker compose -f srcs/docker-compose.yml up -d --scale wordpress=2

# View configuration
docker compose -f srcs/docker-compose.yml config

# Validate docker-compose.yml
docker compose -f srcs/docker-compose.yml config --quiet
```

### Container Inspection

```bash
# List all containers
docker ps -a

# Inspect container details
docker inspect nginx

# View container processes
docker top wordpress

# Check container resource usage
docker stats

# View container filesystem changes
docker diff wordpress
```

### Accessing Containers

```bash
# Execute command in running container
docker exec nginx ls -la /etc/nginx

# Interactive shell
docker exec -it wordpress bash

# Run command as specific user
docker exec -u www-data wordpress whoami

# Copy files to/from container
docker cp local-file.txt nginx:/etc/nginx/
docker cp nginx:/var/log/nginx/error.log ./
```

### Container Lifecycle

```bash
# Start container
docker start wordpress

# Stop container (SIGTERM, 10s grace period)
docker stop wordpress

# Kill container (SIGKILL, immediate)
docker kill wordpress

# Restart container
docker restart wordpress

# Pause container (freeze processes)
docker pause wordpress

# Unpause container
docker unpause wordpress

# Remove container
docker rm wordpress

# Force remove running container
docker rm -f wordpress
```

---

## Volume Management

### Volume Operations

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect srcs_mariadb_data

# Create volume manually
docker volume create --name custom_volume

# Remove volume
docker volume rm srcs_mariadb_data

# Remove all unused volumes
docker volume prune
```

### Volume Configuration

**In docker-compose.yml:**

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/login/data/mariadb
```

**This creates a bind-mounted named volume:**
- Managed by Docker
- Data stored at specific host path
- Portable across environments

### Data Persistence

**Where data is stored:**

```bash
# MariaDB data
/home/login/data/mariadb/
├── aria_log_control
├── ib_buffer_pool
├── ibdata1
├── mysql/
└── wordpress/

# WordPress data
/home/login/data/wordpress/
├── index.php
├── wp-admin/
├── wp-content/
│   ├── plugins/
│   ├── themes/
│   └── uploads/
├── wp-includes/
└── wp-config.php
```

**Backup volumes:**

```bash
# Backup MariaDB volume
docker run --rm \
  -v srcs_mariadb_data:/data \
  -v $(pwd):/backup \
  debian:bullseye \
  tar czf /backup/mariadb_backup.tar.gz /data

# Backup WordPress volume
docker run --rm \
  -v srcs_wordpress_data:/data \
  -v $(pwd):/backup \
  debian:bullseye \
  tar czf /backup/wordpress_backup.tar.gz /data
```

**Restore volumes:**

```bash
# Restore MariaDB
docker run --rm \
  -v srcs_mariadb_data:/data \
  -v $(pwd):/backup \
  debian:bullseye \
  tar xzf /backup/mariadb_backup.tar.gz -C /

# Restore WordPress
docker run --rm \
  -v srcs_wordpress_data:/data \
  -v $(pwd):/backup \
  debian:bullseye \
  tar xzf /backup/wordpress_backup.tar.gz -C /
```

---

## Network Configuration

### Network Inspection

```bash
# List networks
docker network ls

# Inspect network
docker network inspect srcs_inception-network

# View network containers
docker network inspect srcs_inception-network | grep -A 3 "Containers"
```

### Network Testing

```bash
# Test connectivity from one container to another
docker exec wordpress ping -c 3 mariadb
docker exec wordpress nc -zv mariadb 3306

# Test DNS resolution
docker exec wordpress nslookup mariadb
docker exec wordpress getent hosts mariadb

# Test from nginx to wordpress
docker exec nginx nc -zv wordpress 9000
```

### Port Mapping

```bash
# View port mappings
docker port nginx

# Expected output:
# 443/tcp -> 0.0.0.0:443
```

### Network Troubleshooting

```bash
# Check network exists
docker network ls | grep inception

# Verify container connectivity
docker exec wordpress curl -v http://mariadb:3306

# Check iptables rules
sudo iptables -L -n -v

# Monitor network traffic
docker exec nginx tcpdump -i any port 443
```

---

## Development Workflow

### Iterative Development

**1. Make changes to code:**

```bash
# Edit Dockerfile or scripts
vim srcs/requirements/nginx/conf/nginx.conf
```

**2. Rebuild affected service:**

```bash
# Rebuild single service
docker compose -f srcs/docker-compose.yml build nginx

# Recreate container
docker compose -f srcs/docker-compose.yml up -d --force-recreate nginx
```

**3. Test changes:**

```bash
# View logs
docker logs nginx

# Test functionality
curl -k https://login.42.fr
```

**4. Debug if needed:**

```bash
# Enter container
docker exec -it nginx bash

# Check configuration
nginx -t

# Review files
cat /etc/nginx/nginx.conf
```

### Hot Reload

**For NGINX configuration changes:**

```bash
# Test configuration
docker exec nginx nginx -t

# Reload without downtime
docker exec nginx nginx -s reload
```

**For PHP changes:**

```bash
# Restart PHP-FPM
docker exec wordpress killall -USR2 php-fpm7.4
```

### Development Best Practices

1. **Use .dockerignore files:**
   ```
   .git
   .gitignore
   *.md
   .env
   secrets/
   ```

2. **Layer caching optimization:**
   - Put frequently changing commands last
   - Combine related RUN commands
   - Order from least to most likely to change

3. **Multi-stage builds (if applicable):**
   ```dockerfile
   FROM debian:bullseye as builder
   # Build steps
   
   FROM debian:bullseye
   COPY --from=builder /app /app
   ```

4. **Use build arguments:**
   ```dockerfile
   ARG PHP_VERSION=7.4
   RUN apt-get install -y php${PHP_VERSION}-fpm
   ```

### Code Quality Checks

```bash
# Validate docker-compose.yml
docker compose -f srcs/docker-compose.yml config --quiet

# Check Dockerfile syntax
docker build --check srcs/requirements/nginx/

# Lint shell scripts
shellcheck srcs/requirements/*/tools/*.sh

# Security scanning
docker scan nginx:latest
```

---

## Extending the Project

### Adding a New Service

**1. Create service directory:**

```bash
mkdir -p srcs/requirements/bonus/myservice/{conf,tools}
```

**2. Create Dockerfile:**

```dockerfile
# srcs/requirements/bonus/myservice/Dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    your-package \
    && rm -rf /var/lib/apt/lists/*

COPY conf/myservice.conf /etc/myservice/
COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

**3. Add to docker-compose.yml:**

```yaml
  myservice:
    container_name: myservice
    build: ./requirements/bonus/myservice
    image: myservice
    networks:
      - inception-network
    ports:
      - "8080:8080"
    restart: unless-stopped
```

**4. Update Makefile if needed**

**5. Test:**

```bash
docker compose -f srcs/docker-compose.yml build myservice
docker compose -f srcs/docker-compose.yml up -d myservice
docker logs myservice
```

### Bonus Services Implementation

#### Redis Cache

```dockerfile
# srcs/requirements/bonus/redis/Dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf
RUN sed -i 's/protected-mode yes/protected-mode no/g' /etc/redis/redis.conf

EXPOSE 6379

CMD ["redis-server", "/etc/redis/redis.conf", "--daemonize", "no"]
```

**Configure WordPress to use Redis:**

```bash
# In WordPress setup script
wp plugin install redis-cache --activate --allow-root
wp config set WP_REDIS_HOST redis --allow-root
wp config set WP_REDIS_PORT 6379 --allow-root
wp redis enable --allow-root
```

#### FTP Server (vsftpd)

```dockerfile
# srcs/requirements/bonus/ftp/Dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    vsftpd \
    && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/setup-ftp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-ftp.sh

EXPOSE 21 21100-21110

ENTRYPOINT ["/usr/local/bin/setup-ftp.sh"]
```

**vsftpd.conf:**

```conf
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=21100
pasv_max_port=21110
pasv_address=127.0.0.1
```

#### Adminer

```dockerfile
# srcs/requirements/bonus/adminer/Dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html && \
    wget -O /var/www/html/index.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php

RUN sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 9001/g' /etc/php/7.4/fpm/pool.d/www.conf

EXPOSE 9001

CMD ["php-fpm7.4", "-F"]
```

**Add to NGINX:**

```nginx
location /adminer {
    alias /var/www/html;
    index index.php;
    
    location ~ \.php$ {
        fastcgi_pass adminer:9001;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /var/www/html/index.php;
    }
}
```

---

## Debugging Guide

### Container Won't Start

```bash
# View container logs
docker logs <container_name>

# Check last exit status
docker inspect <container_name> | grep -A 5 "State"

# Run container interactively
docker run -it --entrypoint /bin/bash nginx

# Override entrypoint for debugging
docker run -it --entrypoint /bin/bash wordpress
```

### Network Issues

```bash
# Check network connectivity
docker exec wordpress ping -c 3 mariadb

# Verify service is listening
docker exec mariadb netstat -tlnp

# Check firewall rules
sudo ufw status
sudo iptables -L -n

# Test DNS resolution
docker exec wordpress nslookup mariadb
```

### Volume Issues

```bash
# Check volume exists
docker volume ls | grep mariadb

# Inspect volume
docker volume inspect srcs_mariadb_data

# Check host path permissions
ls -la /home/$USER/data/

# Check mount inside container
docker exec wordpress mount | grep /var/www/html
```

### Performance Issues

```bash
# Monitor resource usage
docker stats

# Check disk I/O
iostat -x 1

# Check container logs size
docker ps -s

# Clear logs
truncate -s 0 /var/lib/docker/containers/*/*-json.log
```

### SSL/TLS Issues

```bash
# Test SSL certificate
openssl s_client -connect login.42.fr:443 -showcerts

# Verify certificate in container
docker exec nginx openssl x509 -in /etc/nginx/ssl/inception.crt -text -noout

# Check NGINX SSL configuration
docker exec nginx nginx -T | grep ssl

# Test TLS versions
nmap --script ssl-enum-ciphers -p 443 login.42.fr
```

### Database Issues

```bash
# Connect to database
docker exec -it mariadb mysql -u root -p

# Check database exists
docker exec mariadb mysql -u root -p -e "SHOW DATABASES;"

# Verify user permissions
docker exec mariadb mysql -u root -p -e "SELECT User, Host FROM mysql.user;"

# Check table structure
docker exec mariadb mysql -u root -p wordpress -e "SHOW TABLES;"

# Repair tables
docker exec mariadb mysqlcheck -u root -p --auto-repair --all-databases
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/docker-build.yml
name: Docker Build

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Validate docker-compose
      run: docker compose -f srcs/docker-compose.yml config --quiet
    
    - name: Build images
      run: docker compose -f srcs/docker-compose.yml build
    
    - name: Run tests
      run: |
        # Add your test commands here
        docker compose -f srcs/docker-compose.yml up -d
        sleep 30
        curl -k https://localhost:443 | grep -q "WordPress"
```

### Automated Testing

```bash
# Create test script
cat > tests/integration_test.sh << 'EOF'
#!/bin/bash
set -e

# Start services
docker compose -f srcs/docker-compose.yml up -d

# Wait for services
sleep 30

# Test NGINX
curl -k -f https://localhost:443 || exit 1

# Test database
docker exec mariadb mysqladmin ping || exit 1

# Test WordPress
docker exec wordpress wp core is-installed --allow-root || exit 1

# Cleanup
docker compose -f srcs/docker-compose.yml down

echo "All tests passed!"
EOF

chmod +x tests/integration_test.sh
```

---

## Security Considerations

### Dockerfile Security

```dockerfile
# Run as non-root user
RUN useradd -m -u 1000 appuser
USER appuser

# Don't install unnecessary packages
RUN apt-get install --no-install-recommends package

# Clean up in same layer
RUN apt-get update && apt-get install -y package \
    && rm -rf /var/lib/apt/lists/*

# Use specific versions
FROM debian:bullseye-20231030
```

### Secrets Management

```yaml
# Use Docker secrets
secrets:
  db_password:
    file: ../secrets/db_password.txt

services:
  mariadb:
    secrets:
      - db_password
```

**Access in container:**

```bash
# Read secret
DB_PASS=$(cat /run/secrets/db_password)
```

### Network Security

```yaml
# Isolate internal services
services:
  mariadb:
    networks:
      - backend
    # No ports exposed to host
  
  nginx:
    networks:
      - backend
      - frontend
    ports:
      - "443:443"

networks:
  backend:
    internal: true
  frontend:
```

---

## Performance Optimization

### Image Size Reduction

```dockerfile
# Use smaller base image
FROM debian:bullseye-slim

# Multi-stage build
FROM debian:bullseye as builder
RUN make build
FROM debian:bullseye-slim
COPY --from=builder /app/bin /usr/local/bin
```

### Build Cache Optimization

```dockerfile
# Order from least to most frequently changed
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
```

### Resource Limits

```yaml
services:
  mariadb:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          memory: 256M
```

---

## Maintenance

### Regular Tasks

```bash
# Update base images
docker compose -f srcs/docker-compose.yml build --pull

# Clean up unused resources
docker system prune -a

# Update WordPress
docker exec wordpress wp core update --allow-root
docker exec wordpress wp plugin update --all --allow-root

# Optimize database
docker exec wordpress wp db optimize --allow-root
```

### Monitoring

```bash
# Set up health checks
docker inspect --format='{{json .State.Health}}' nginx

# Monitor logs
docker compose -f srcs/docker-compose.yml logs -f --tail=100

# Export metrics
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

---

## Reference

### Important Paths

| Path | Description |
|------|-------------|
| `/home/login/data/mariadb` | Database files |
| `/home/login/data/wordpress` | WordPress files |
| `/var/lib/docker/volumes` | Docker volumes |
| `/run/secrets/` | Mounted secrets in containers |

### Common Docker Commands

```bash
# Cleanup
docker system prune -af --volumes

# Export/Import
docker save -o image.tar nginx
docker load -i image.tar

# Logs
docker logs -f --tail=100 nginx

# Inspect
docker inspect --format='{{json .Config}}' nginx | jq
```

---

**Last Updated:** [Current Date]  
**Maintainer:** [Your Name/Login]  
**Version:** 1.0
