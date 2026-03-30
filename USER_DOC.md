# Inception - User Documentation

This guide explains daily usage of the current Inception stack.

## What this stack provides

This project provides a complete web stack for a WordPress website with database, cache, and bonus tools.

## Services

### Core

- NGINX (HTTPS reverse proxy)
- WordPress (application)
- MariaDB (database)

### Bonus

- Redis (WordPress cache backend)
- Adminer (database UI)
- Static page
- 2048 game
- FTP server (WordPress files access)

## Start and Cleanup Commands

### Start project

```bash
make
```

### Stop project

```bash
make clean
```

`make clean` stops and removes the running containers while keeping project bind-mounted data.

### Full command reference

```bash
# Build and start everything
make

# Check running containers
make status

# Show service links
make links

# Follow logs
make logs

# Stop and remove containers only
make clean

# Full cleanup (containers + volumes + reset data dirs)
make fclean

# Rebuild from scratch
make re
```

## Access URLs

- WordPress: `https://sel-mlil.42.fr`
- WordPress Admin: `https://sel-mlil.42.fr/wp-admin`
- Adminer: `http://localhost:8080`
- Static page: `http://localhost:3000`
- 2048: `http://localhost:2048`
- FTP: `localhost:21` (passive ports `21000-21010`)

## Website and administration panel access

- Main website is served at `https://sel-mlil.42.fr`.
- Administration panel is available at `https://sel-mlil.42.fr/wp-admin`.
- Adminer provides database administration at `http://localhost:8080`.
- FTP is available on `localhost:21` using credentials from `.env` (`FTP_USER`, `FTP_PASSWORD`).

## Credentials

### Configuration files

- Environment file: `srcs/.env`
- Docker secrets:
  - `srcs/secrets/db_root_password.txt`
  - `srcs/secrets/db_password.txt`
  - `srcs/secrets/wp_admin_password.txt`
  - `srcs/secrets/wp_user_password.txt`

### Domain mapping

Make sure `/etc/hosts` includes:

```bash
127.0.0.1 sel-mlil.42.fr
```

### Manage credentials

- Update secret values by editing files in `srcs/secrets/`.
- Update non-secret configuration in `srcs/.env`.
- FTP credentials are configured in `srcs/.env` with `FTP_USER` and `FTP_PASSWORD`.
- After credential changes, rebuild and restart the stack:

```bash
make re
```

## Common Checks

### Container health

```bash
make status
```

### Compose validation

```bash
docker compose -f srcs/docker-compose.yml config
```

### Running state (quick check)

```bash
docker compose -f srcs/docker-compose.yml ps
```

### Service logs

```bash
# all
make logs

# specific
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

## Backup Basics

### Database dump

```bash
docker exec mariadb mysqldump -u root -p wordpress > backup_$(date +%F).sql
```

### WordPress files

```bash
sudo tar -czf wordpress_files_$(date +%F).tar.gz /home/sel/data/wordpress
```

## Troubleshooting

### Browser cannot open WordPress

1. Check `make status`.
2. Confirm `/etc/hosts` entry.
3. Verify port `443` is free.
4. Check NGINX logs:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
```

### Adminer / static / game not reachable

- Confirm ports are free and mapped:
  - `8080` (Adminer)
  - `3000` (Static page)
  - `2048` (2048)
- Rebuild and restart:

```bash
make re
```

### Reset all data

```bash
make fclean
make
```
