# Inception - User Documentation

This document explains how to use the Inception infrastructure as an end user or system administrator.

## Table of Contents
1. [Overview](#overview)
2. [Services Provided](#services-provided)
3. [Starting and Stopping](#starting-and-stopping)
4. [Accessing the Services](#accessing-the-services)
5. [Managing Credentials](#managing-credentials)
6. [Checking Service Health](#checking-service-health)
7. [Common Tasks](#common-tasks)
8. [Troubleshooting](#troubleshooting)

---

## Overview

The Inception infrastructure provides a complete WordPress hosting environment with the following components:
- **Web Server** (NGINX): Handles HTTPS requests and serves your website
- **Application Server** (WordPress + PHP-FPM): Runs your WordPress website
- **Database** (MariaDB): Stores all website data and content
- **Bonus Services** (optional): Redis cache, FTP server, Adminer, etc.

All services run in isolated Docker containers and communicate through a private network.

---

## Services Provided

### Core Services

| Service | Purpose | Accessible To |
|---------|---------|---------------|
| NGINX | Web server with SSL/TLS | Internet (port 443) |
| WordPress | Content management system | Via NGINX only |
| MariaDB | Database server | WordPress only |

### Bonus Services (if configured)

| Service | Purpose | Access Point |
|---------|---------|--------------|
| Redis | Caching layer for WordPress | WordPress only |
| FTP | File transfer for WordPress files | Port 21 |
| Adminer | Database management interface | Via NGINX |
| Static Site | Additional static website | Port 8080 |

---

## Starting and Stopping

### Starting the Infrastructure

**First-time setup:**
```bash
make
```
This command will:
1. Create necessary directories
2. Build all Docker images
3. Start all containers

**Subsequent starts:**
```bash
make start
```

**What happens:**
- MariaDB starts and initializes the database
- WordPress connects to MariaDB and configures itself
- NGINX starts and begins accepting connections
- All services should be ready within 30-60 seconds

### Stopping the Infrastructure

**Graceful stop (preserves data):**
```bash
make stop
```
This stops all containers but keeps your data intact.

**Complete shutdown:**
```bash
make down
```
This stops and removes containers, but volumes (your data) remain.

**Warning**: Never use `make fclean` unless you want to delete ALL data!

### Checking Status

```bash
make status
```

Expected output when running:
```
NAME        IMAGE       STATUS       PORTS
nginx       nginx       Up 2 mins    0.0.0.0:443->443/tcp
wordpress   wordpress   Up 2 mins    
mariadb     mariadb     Up 2 mins    
```

---

## Accessing the Services

### WordPress Website

**URL:** https://sel-mlil.42.fr (replace `login` with your actual login)

**First visit:**
1. Your browser will show a security warning (self-signed certificate)
2. Click "Advanced" → "Proceed to site" (exact wording varies by browser)
3. You should see your WordPress website

### WordPress Administration Panel

**URL:** https://sel-mlil.42.fr/wp-admin

**Login credentials:**
- **Admin User**:
  - Username: (defined in your `.env` file as `WP_ADMIN_USER`)
  - Password: (defined in your `.env` file as `WP_ADMIN_PASSWORD`)

- **Regular User**:
  - Username: (defined in your `.env` file as `WP_USER`)
  - Password: (defined in your `.env` file as `WP_USER_PASSWORD`)

**What you can do:**
- Create and publish posts and pages
- Install themes and plugins
- Manage users
- Configure site settings
- Upload media files

### Adminer (if configured)

**URL:** https://sel-mlil.42.fr/adminer

**Login credentials:**
- System: MySQL
- Server: mariadb
- Username: (your `MYSQL_USER` from `.env`)
- Password: (your `MYSQL_PASSWORD` from `.env`)
- Database: (your `MYSQL_DATABASE` from `.env`)

### FTP Access (if configured)

**Connection details:**
- Host: sel-mlil.42.fr
- Port: 21
- Protocol: FTP
- Username: (configured in FTP setup)
- Password: (configured in FTP setup)

**FTP clients:**
- FileZilla (GUI)
- WinSCP (Windows)
- Cyberduck (Mac)
- Command line: `ftp sel-mlil.42.fr`

---

## Managing Credentials

### Location of Credentials

Credentials are stored in two places:

1. **Environment file:** `srcs/.env`
   - Contains non-sensitive configuration
   - Database names, usernames
   - Domain settings

2. **Secrets directory:** `secrets/`
   - Contains sensitive passwords
   - `db_root_password.txt` - MariaDB root password
   - `db_password.txt` - WordPress database password
   - `credentials.txt` - Additional credentials

### Viewing Current Credentials

```bash
# View environment variables (safe to display)
cat srcs/.env

# View secrets (be careful - sensitive!)
cat secrets/db_password.txt
cat secrets/db_root_password.txt
```

### Changing Passwords

**To change the WordPress admin password:**

1. Log into WordPress admin panel
2. Go to Users → Your Profile
3. Scroll to "New Password"
4. Click "Generate Password" or enter a new one
5. Click "Update Profile"

**To change database passwords:**

⚠️ **Warning**: This requires recreating the database!

1. Stop all services: `make down`
2. Edit password files in `secrets/`
3. Edit corresponding values in `srcs/.env`
4. Remove old database data: `sudo rm -rf /home/$USER/data/mariadb/*`
5. Rebuild: `make re`

### Security Best Practices

- **Never commit** `.env` or `secrets/` to version control
- Use **strong passwords** (16+ characters, mixed case, numbers, symbols)
- **Change default passwords** immediately after setup
- **Limit access** to the server and credential files
- **Regular backups** of credentials (stored securely offline)

---

## Checking Service Health

### Quick Health Check

```bash
# Check if all containers are running
docker ps

# Expected: 3 containers (nginx, wordpress, mariadb) all "Up"
```

### Detailed Service Checks

**1. NGINX (Web Server)**
```bash
# Check NGINX is responding
curl -k https://sel-mlil.42.fr

# View NGINX logs
docker logs nginx
```

**2. WordPress**
```bash
# Check WordPress container logs
docker logs wordpress

# Verify WordPress files exist
docker exec wordpress ls -la /var/www/html

# Expected: index.php, wp-config.php, etc.
```

**3. MariaDB (Database)**
```bash
# Ping database server
docker exec mariadb mysqladmin ping

# Expected output: "mysqld is alive"

# Connect to database
docker exec -it mariadb mysql -u root -p
# Enter password from secrets/db_root_password.txt

# Inside MySQL prompt:
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
EXIT;
```

### Monitoring Logs

**View all logs:**
```bash
make logs
```

**View specific service logs:**
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

**Follow logs in real-time:**
```bash
docker logs -f nginx
docker logs -f wordpress
```
Press `Ctrl+C` to stop following.

### Resource Usage

```bash
# Check container resource usage
docker stats

# Shows CPU, memory, network I/O for each container
```

---

## Common Tasks

### Creating Content

1. Log into WordPress admin (https://sel-mlil.42.fr/wp-admin)
2. Click "Posts" → "Add New" or "Pages" → "Add New"
3. Enter your title and content
4. Click "Publish"
5. View your site to see the new content

### Installing Plugins/Themes

1. Go to WordPress admin
2. Click "Plugins" → "Add New" or "Appearance" → "Themes" → "Add New"
3. Search for the plugin/theme you want
4. Click "Install Now"
5. Click "Activate" (for plugins)

### Backing Up Your Site

**Manual backup:**
```bash
# Backup database
docker exec mariadb mysqldump -u root -p wordpress > backup_$(date +%Y%m%d).sql

# Backup WordPress files
sudo tar -czf wordpress_backup_$(date +%Y%m%d).tar.gz /home/$USER/data/wordpress/

# Store backups in a safe location!
```

**What to backup:**
- Database dump (.sql file)
- WordPress files (entire /home/$USER/data/wordpress directory)
- Credentials (secrets/ directory and .env file)

### Restoring from Backup

**Restore database:**
```bash
# Copy SQL file into container
docker cp backup.sql mariadb:/tmp/

# Restore
docker exec -it mariadb mysql -u root -p wordpress < /tmp/backup.sql
```

**Restore WordPress files:**
```bash
# Stop services
make stop

# Restore files
sudo rm -rf /home/$USER/data/wordpress/*
sudo tar -xzf wordpress_backup.tar.gz -C /

# Start services
make start
```

### Updating WordPress

**Via Admin Panel (recommended):**
1. WordPress will notify you of updates
2. Click "Update Now"
3. Wait for completion

**Via Command Line:**
```bash
docker exec wordpress wp core update --allow-root
docker exec wordpress wp plugin update --all --allow-root
docker exec wordpress wp theme update --all --allow-root
```

---

## Troubleshooting

### Website Not Accessible

**Symptom:** Cannot access https://sel-mlil.42.fr

**Solutions:**

1. **Check containers are running:**
   ```bash
   docker ps
   ```
   If any are missing, start them: `make start`

2. **Check /etc/hosts:**
   ```bash
   cat /etc/hosts | grep 42.fr
   ```
   Should show: `127.0.0.1 sel-mlil.42.fr`

3. **Check NGINX logs:**
   ```bash
   docker logs nginx
   ```

4. **Test with curl:**
   ```bash
   curl -k https://sel-mlil.42.fr
   ```

### White Screen / 500 Error

**Symptom:** WordPress shows blank page or error

**Solutions:**

1. **Check WordPress logs:**
   ```bash
   docker logs wordpress
   ```

2. **Verify database connection:**
   ```bash
   docker exec wordpress wp db check --allow-root
   ```

3. **Check file permissions:**
   ```bash
   docker exec wordpress ls -la /var/www/html
   ```

4. **Restart WordPress:**
   ```bash
   docker restart wordpress
   ```

### Database Connection Error

**Symptom:** "Error establishing database connection"

**Solutions:**

1. **Verify MariaDB is running:**
   ```bash
   docker ps | grep mariadb
   docker exec mariadb mysqladmin ping
   ```

2. **Check database credentials:**
   ```bash
   cat srcs/.env | grep MYSQL
   ```

3. **Restart in order:**
   ```bash
   docker restart mariadb
   sleep 10
   docker restart wordpress
   docker restart nginx
   ```

### Slow Performance

**Symptoms:** Website loads slowly

**Solutions:**

1. **Check resource usage:**
   ```bash
   docker stats
   ```

2. **Clear WordPress cache** (if Redis configured):
   ```bash
   docker exec wordpress wp cache flush --allow-root
   ```

3. **Optimize database:**
   ```bash
   docker exec wordpress wp db optimize --allow-root
   ```

4. **Check host machine resources:**
   ```bash
   htop  # or top
   df -h  # disk space
   ```

### Container Keeps Restarting

**Symptom:** Container status shows "Restarting"

**Solutions:**

1. **Check container logs:**
   ```bash
   docker logs <container_name>
   ```

2. **Check for configuration errors:**
   ```bash
   docker compose config
   ```

3. **Remove and rebuild:**
   ```bash
   make down
   make re
   ```

### Lost Admin Password

**Solution:**

1. **Reset via database:**
   ```bash
   docker exec -it mariadb mysql -u root -p
   ```

2. **In MySQL prompt:**
   ```sql
   USE wordpress;
   UPDATE wp_users SET user_pass=MD5('new_password') WHERE user_login='admin_username';
   EXIT;
   ```

3. **Login with new password**

---

## Getting Help

### Log Files Location

- **NGINX logs:** `docker logs nginx`
- **WordPress logs:** `docker logs wordpress`
- **MariaDB logs:** `docker logs mariadb`

### Useful Commands Reference

```bash
# Start everything
make

# Stop everything
make stop

# View status
make status

# View logs
make logs

# Access container shell
docker exec -it <container_name> bash

# List all containers
docker ps -a

# List volumes
docker volume ls

# Check disk usage
docker system df
```

### Support

For technical issues:
1. Check logs: `make logs`
2. Review this documentation
3. Consult Docker documentation: https://docs.docker.com
4. Consult WordPress documentation: https://wordpress.org/support/

---

## Maintenance Schedule

### Daily
- Monitor disk space: `df -h`
- Check container status: `make status`

### Weekly
- Review logs for errors: `make logs`
- Check for WordPress updates
- Verify backups are working

### Monthly
- Update WordPress core, themes, and plugins
- Review and optimize database
- Test backup restoration
- Review user accounts and permissions

---

## Emergency Procedures

### Complete System Failure

```bash
# 1. Stop everything
make down

# 2. Check system resources
df -h
free -h

# 3. Rebuild from scratch
make re

# 4. If still failing, restore from backup
# (follow restoration procedure above)
```

### Data Corruption

```bash
# 1. Stop services immediately
make stop

# 2. Copy current data
sudo cp -r /home/$USER/data /home/$USER/data.backup

# 3. Restore from last known good backup
# (follow restoration procedure)

# 4. Start services
make start
```

---

**Last Updated:** [02/16/2026]  
**Version:** 1.0  
**Maintainer:** [sel-mlil]
