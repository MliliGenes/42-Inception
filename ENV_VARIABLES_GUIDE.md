# Environment Variables Guide

This document explains all environment variables needed for the Inception project and how they're used.

---

## Quick Setup

1. **Edit the .env file**: [srcs/.env](srcs/.env)
2. **Change these values**:
   - Replace `login` with your 42 login in `DOMAIN_NAME`
   - Change all passwords to secure values
   - Update email addresses

3. **Update secrets files** (already populated with defaults):
   - `secrets/db_root_password.txt` - MariaDB root password
   - `secrets/db_password.txt` - WordPress database user password

4. **Update /etc/hosts** on your host machine:
   ```bash
   sudo echo "127.0.0.1 sel-mlil.42.fr" >> /etc/hosts
   ```
   (Replace `login` with your actual 42 login)

---

## Environment Variables Explained

### Domain Configuration

#### `DOMAIN_NAME`
- **Current Value**: `sel-mlil.42.fr`
- **What it does**: The domain name for your website
- **Action Required**: Replace `login` with your 42 login
- **Example**: If your login is `jdoe`, use `jdoe.42.fr`
- **Used by**: NGINX (SSL certificate), WordPress (site URL)

---

### MariaDB Configuration

#### `MYSQL_DATABASE`
- **Current Value**: `wordpress`
- **What it does**: Name of the database WordPress will use
- **Action Required**: Can keep default or change
- **Used by**: MariaDB (creates this database), WordPress (connects to it)

#### `MYSQL_USER`
- **Current Value**: `wpuser`
- **What it does**: Database username for WordPress
- **Action Required**: Can keep default or change (don't use 'root')
- **Security**: This user only has access to the WordPress database
- **Used by**: MariaDB (creates this user), WordPress (authenticates with it)

#### `MYSQL_PASSWORD`
- **Current Value**: `secure_wp_password_123`
- **What it does**: Password for the WordPress database user
- **Action Required**: **CHANGE THIS** to a strong password
- **Security**: Should be different from root password
- **Used by**: MariaDB (sets password), WordPress (authenticates)
- **Must Match**: The value in `secrets/db_password.txt`

---

### WordPress Configuration

#### `WP_ADMIN_USER`
- **Current Value**: `wpadmin`
- **What it does**: Username for WordPress administrator account
- **Action Required**: Can keep or change to your preferred admin username
- **Used by**: WordPress initialization script
- **This is**: The account you'll use to manage WordPress

#### `WP_ADMIN_PASSWORD`
- **Current Value**: `secure_admin_password_123`
- **What it does**: Password for WordPress admin login
- **Action Required**: **CHANGE THIS** to a strong password
- **Security**: This is your main WordPress admin password
- **Used by**: WordPress (creates admin account)

#### `WP_ADMIN_EMAIL`
- **Current Value**: `admin@sel-mlil.42.fr`
- **What it does**: Email for WordPress admin account
- **Action Required**: Update `login` part to match your DOMAIN_NAME
- **Used by**: WordPress (admin account, notifications)

#### `WP_USER`
- **Current Value**: `wpuser2`
- **What it does**: Username for a second WordPress user (required by 42)
- **Action Required**: Can keep or change
- **42 Requirement**: Project requires 2 WordPress users
- **Used by**: WordPress initialization script

#### `WP_USER_EMAIL`
- **Current Value**: `user@sel-mlil.42.fr`
- **What it does**: Email for second WordPress user
- **Action Required**: Update `login` part to match your DOMAIN_NAME
- **Used by**: WordPress (second user account)

#### `WP_USER_PASSWORD`
- **Current Value**: `secure_user_password_123`
- **What it does**: Password for second WordPress user
- **Action Required**: **CHANGE THIS** to a different password
- **Used by**: WordPress (creates second user)

#### `WP_TITLE`
- **Current Value**: `Inception Website`
- **What it does**: The title of your WordPress site
- **Action Required**: Can customize to your preference
- **Used by**: WordPress (site title displayed in browser, headers)

---

### System Configuration

#### `MYSQL_HOST`
- **Current Value**: `mariadb`
- **What it does**: Hostname of the MariaDB container
- **Action Required**: **DO NOT CHANGE** (must match service name in docker-compose.yml)
- **Important**: This is the Docker container name, not a URL
- **Used by**: WordPress (to connect to database)

---

## Secrets Files

In addition to environment variables, you have **secrets files** for sensitive data:

### `secrets/db_root_password.txt`
- **Current Value**: `super_secure_root_password_123`
- **What it does**: Root password for MariaDB
- **Action Required**: **CHANGE THIS**
- **Security**: Root has full database access
- **Used by**: MariaDB initialization (via Docker secrets)

### `secrets/db_password.txt`
- **Current Value**: `secure_wp_password_123`
- **What it does**: WordPress database user password
- **Action Required**: **MUST MATCH** the `MYSQL_PASSWORD` environment variable
- **Used by**: MariaDB initialization (via Docker secrets)

### `secrets/credentials.txt`
- **What it does**: Human-readable summary of all credentials
- **Action Required**: Update after changing passwords
- **Security**: Keep this file secure (already in .gitignore)

---

## Security Best Practices

### ✅ DO:
- Use different passwords for each service
- Use strong passwords (12+ characters, mixed case, numbers, symbols)
- Keep secrets files permissions restricted (`chmod 600`)
- Replace `login` with your actual 42 login in domain/emails
- Update `credentials.txt` when you change passwords

### ❌ DON'T:
- Use default passwords in production
- Commit .env or secrets/ to git (already in .gitignore)
- Use 'root' as MYSQL_USER
- Share passwords
- Use simple passwords like "password123"

---

## How These Variables Are Used

### In Docker Compose:
```yaml
services:
  mariadb:
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
```

### In MariaDB init-db.sh:
```bash
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
```

### In WordPress setup.sh:
```bash
wp config create \
    --dbname="${MYSQL_DATABASE}" \
    --dbuser="${MYSQL_USER}" \
    --dbpass="${MYSQL_PASSWORD}" \
    --dbhost="${MYSQL_HOST}"
```

---

## Validation Checklist

Before running `make`:

- [ ] Changed `DOMAIN_NAME` to use your 42 login
- [ ] Updated all passwords (at least 3 different passwords)
- [ ] Ensured `MYSQL_PASSWORD` matches `secrets/db_password.txt`
- [ ] Updated email addresses to match your domain
- [ ] Added your domain to `/etc/hosts`
- [ ] Verified `MYSQL_HOST=mariadb` (don't change)
- [ ] Updated `secrets/credentials.txt` with your new values
- [ ] Checked file permissions on secrets (`chmod 600`)

---

## Example .env File

**For user "jdoe"**:

```bash
# Domain Configuration
DOMAIN_NAME=jdoe.42.fr

# MariaDB Configuration
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=MyStr0ng!DB_P@ssw0rd

# WordPress Configuration
WP_ADMIN_USER=jdoe_admin
WP_ADMIN_PASSWORD=Adm1n!P@ssw0rd_V3ryStr0ng
WP_ADMIN_EMAIL=admin@jdoe.42.fr
WP_USER=jdoe_author
WP_USER_EMAIL=author@jdoe.42.fr
WP_USER_PASSWORD=Auth0r!P@ssw0rd_Strong
WP_TITLE=John's Inception Project

# Database Host
MYSQL_HOST=mariadb
```

---

## Troubleshooting

### WordPress can't connect to database
- Check `MYSQL_HOST=mariadb` (must match container name)
- Verify `MYSQL_PASSWORD` matches `secrets/db_password.txt`
- Ensure all variables are set (no empty values)

### Can't access website
- Check `/etc/hosts` has correct entry
- Verify `DOMAIN_NAME` matches what's in `/etc/hosts`

### Permission errors
- Run: `chmod 600 secrets/*`
- Check container has access to secrets

---

## Quick Reference

| Variable | Required | Change? | Where Used |
|----------|----------|---------|-----------|
| `DOMAIN_NAME` | Yes | **YES** | NGINX, WordPress |
| `MYSQL_DATABASE` | Yes | Optional | MariaDB, WordPress |
| `MYSQL_USER` | Yes | Optional | MariaDB, WordPress |
| `MYSQL_PASSWORD` | Yes | **YES** | MariaDB, WordPress |
| `WP_ADMIN_USER` | Yes | Optional | WordPress |
| `WP_ADMIN_PASSWORD` | Yes | **YES** | WordPress |
| `WP_ADMIN_EMAIL` | Yes | **YES** | WordPress |
| `WP_USER` | Yes | Optional | WordPress |
| `WP_USER_EMAIL` | Yes | **YES** | WordPress |
| `WP_USER_PASSWORD` | Yes | **YES** | WordPress |
| `WP_TITLE` | Yes | Optional | WordPress |
| `MYSQL_HOST` | Yes | **NO** | WordPress |

---

**Next Steps**: After configuring environment variables, proceed to set up the docker-compose.yml file to use these variables!
