# MariaDB Container - Configuration Explained

This document explains how the MariaDB container is configured and what each component does.

---

## Table of Contents
1. [What is MariaDB?](#what-is-mariadb)
2. [Dockerfile Breakdown](#dockerfile-breakdown)
3. [Configuration File (50-server.cnf)](#configuration-file-50-servercnf)
4. [Initialization Script (init-db.sh)](#initialization-script-init-dbsh)
5. [Environment Variables](#environment-variables)
6. [How It All Works Together](#how-it-all-works-together)
7. [Common Issues](#common-issues)

---

## What is MariaDB?

**MariaDB** is a community-driven fork of MySQL, a popular open-source relational database management system (RDBMS). It's used to store and manage data for applications like WordPress.

**Why MariaDB for Inception?**
- Lightweight and fast
- Compatible with MySQL (WordPress works seamlessly with it)
- Open-source and well-maintained
- Required by the 42 Inception project

---

## Dockerfile Breakdown

Let's break down each line of the Dockerfile:

```dockerfile
FROM debian:bullseye
```
- **What it does**: Uses Debian 11 (Bullseye) as the base operating system
- **Why**: Required by 42 project rules (penultimate stable version)

```dockerfile
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*
```
- **What it does**: 
  - Updates package lists (`apt-get update`)
  - Installs MariaDB server (the database engine) and client (command-line tools)
  - Removes package lists to reduce image size
- **Why**: Sets up everything needed to run a database server

```dockerfile
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY tools/init-db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-db.sh
```
- **What it does**: 
  - Copies our custom configuration to MariaDB's config directory
  - Copies the initialization script
  - Makes the script executable
- **Why**: We need custom settings and automation for setup

```dockerfile
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld
```
- **What it does**: 
  - Creates directory for MySQL runtime files (PID file, socket)
  - Changes ownership to `mysql` user (MariaDB runs as this user for security)
  - Sets permissions so MariaDB can write to this directory
- **Why**: MariaDB needs this directory to store its process ID and socket file

```dockerfile
EXPOSE 3306
```
- **What it does**: Documents that this container listens on port 3306
- **Why**: 3306 is the standard MySQL/MariaDB port; other containers (WordPress) will connect here

```dockerfile
ENTRYPOINT ["/usr/local/bin/init-db.sh"]
```
- **What it does**: Runs our initialization script when the container starts
- **Why**: Automates database setup and then starts the MariaDB server

---

## Configuration File (50-server.cnf)

This file configures how MariaDB runs. Let's explain each setting:

```ini
[mysqld]
```
- Section header for MySQL daemon (server) settings

```ini
user = mysql
```
- **What it does**: Runs MariaDB as the `mysql` user (not root)
- **Why**: Security - limits what the process can do if compromised

```ini
pid-file = /var/run/mysqld/mysqld.pid
```
- **What it does**: Stores the process ID in this file
- **Why**: Allows system to track if MariaDB is running and manage it

```ini
socket = /var/run/mysqld/mysqld.sock
```
- **What it does**: Creates a Unix socket file for local connections
- **Why**: Faster than TCP for local connections

```ini
port = 3306
```
- **What it does**: Listens for connections on port 3306
- **Why**: Standard MySQL/MariaDB port

```ini
basedir = /usr
datadir = /var/lib/mysql
tmpdir = /tmp
```
- **What it does**: Sets directories for:
  - `basedir`: MariaDB installation files
  - `datadir`: Where actual database files are stored
  - `tmpdir`: Temporary files during queries
- **Why**: Organizes different types of files

```ini
bind-address = 0.0.0.0
```
- **What it does**: Listens on ALL network interfaces
- **Why**: Allows WordPress container to connect from another container
- **Important**: `127.0.0.1` would only allow localhost (wouldn't work in Docker)

```ini
skip-networking = false
```
- **What it does**: Enables network connections (TCP/IP)
- **Why**: Must be enabled for remote connections (like from WordPress)

---

## Initialization Script (init-db.sh)

This script runs when the container starts. Let's break it down:

### Step 1: Check if Database Exists

```bash
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi
```
- **What it does**: Checks if MariaDB is already initialized
- **If not initialized**: Creates the initial database structure
- **Why**: Only initialize on first run (data persists in Docker volume)

### Step 2: Bootstrap Configuration

```bash
mysqld --user=mysql --bootstrap << EOF
```
- **What it does**: Starts MariaDB in "bootstrap" mode (special startup for running SQL)
- **Why**: Allows us to run setup commands before normal startup

### Step 3: Security Setup

```sql
USE mysql;
FLUSH PRIVILEGES;

DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
```
- **What it does**:
  - Uses the `mysql` system database
  - Reloads permission tables
  - Removes anonymous users (security)
  - Removes root users except from localhost (security)
- **Why**: Secures the installation (similar to `mysql_secure_installation`)

### Step 4: Set Root Password

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
```
- **What it does**: Sets password for root user from environment variable
- **Why**: Root needs a password; uses Docker secret for security

### Step 5: Create WordPress Database

```sql
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
```
- **What it does**: Creates a database for WordPress
- **Why**: WordPress needs its own database to store posts, users, settings, etc.

### Step 6: Create WordPress User

```sql
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
```
- **What it does**:
  - Creates a user for WordPress
  - `@'%'` means user can connect from any host
  - Grants full permissions on the WordPress database
- **Why**: WordPress needs its own user (not root) to access its database

### Step 7: Apply Changes

```sql
FLUSH PRIVILEGES;
```
- **What it does**: Applies all permission changes
- **Why**: Ensures changes take effect immediately

### Step 8: Start MariaDB

```bash
echo "MariaDB initialization complete."
exec mysqld --user=mysql --console
```
- **What it does**: Starts MariaDB in normal mode (foreground)
- **Why**: `exec` replaces the script process, keeping container running

---

## Environment Variables

The script expects these environment variables (set in docker-compose.yml):

| Variable | Purpose | Example |
|----------|---------|---------|
| `MYSQL_ROOT_PASSWORD` | Root user password | `super_secret_root` |
| `MYSQL_DATABASE` | WordPress database name | `wordpress` |
| `MYSQL_USER` | WordPress database user | `wpuser` |
| `MYSQL_PASSWORD` | WordPress user password | `secure_password` |

---

## How It All Works Together

### First Time Startup:

1. **Container starts** → Runs `init-db.sh`
2. **Script checks** → Database doesn't exist yet
3. **Initializes** → Creates MariaDB system tables
4. **Bootstrap mode** → Runs security setup and creates WordPress database/user
5. **Normal mode** → Starts MariaDB server listening on port 3306
6. **Ready** → WordPress can now connect and use the database

### Subsequent Startups:

1. **Container starts** → Runs `init-db.sh`
2. **Script checks** → Database already exists (in volume)
3. **Skips initialization** → Goes straight to bootstrap
4. **Reconfigures** → Ensures users/permissions are correct
5. **Normal mode** → Starts MariaDB server
6. **Ready** → All data is preserved from volume

### Connection Flow:

```
WordPress Container
       ↓
  (port 3306)
       ↓
MariaDB Container
       ↓
  Docker Volume
(/var/lib/mysql)
       ↓
   Host Machine
(/home/user/data/mariadb)
```

---

## Common Issues

### Issue 1: Permission Denied
**Error**: `mysqld: Can't create PID file: Permission denied`
**Solution**: The `/var/run/mysqld` directory setup in Dockerfile fixes this

### Issue 2: Can't Connect from WordPress
**Error**: `Can't connect to MySQL server`
**Solutions**:
- Ensure `bind-address = 0.0.0.0` (not 127.0.0.1)
- Ensure `skip-networking = false`
- Check Docker network configuration
- Verify WordPress uses correct hostname (container name)

### Issue 3: Database Doesn't Persist
**Error**: All data lost on restart
**Solution**: Ensure Docker volume is properly mounted in docker-compose.yml

### Issue 4: Syntax Errors in init-db.sh
**Error**: Script fails with bash errors
**Solution**: 
- Check file has Unix line endings (LF not CRLF)
- Ensure it's executable (`chmod +x`)

### Issue 5: Environment Variables Not Set
**Error**: `CREATE DATABASE IF NOT EXISTS ;` (empty name)
**Solution**: Verify variables are passed in docker-compose.yml

---

## Testing the Setup

### Check if MariaDB is Running:
```bash
docker exec -it mariadb bash
ps aux | grep mysql
```

### Test Database Connection:
```bash
docker exec -it mariadb mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SHOW DATABASES;"
```

### View Logs:
```bash
docker logs mariadb
```

### Check if WordPress Database Exists:
```bash
docker exec -it mariadb mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "USE wordpress; SHOW TABLES;"
```

---

## Summary

The MariaDB container:
1. ✅ Uses Debian Bullseye (42 requirement)
2. ✅ Installs MariaDB server
3. ✅ Configures network access for containers
4. ✅ Automatically initializes on first run
5. ✅ Secures the installation
6. ✅ Creates WordPress database and user
7. ✅ Persists data in Docker volume
8. ✅ Uses environment variables for configuration
9. ✅ Runs as non-root user (security)
10. ✅ Exposes port 3306 for WordPress connection

Everything is automated - just provide the environment variables and it handles the rest!
