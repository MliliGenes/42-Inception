# Inception - Developer Documentation

This document describes the current implementation and how to extend it safely.

## Environment setup from scratch

### Prerequisites

- Linux host (Debian/Ubuntu recommended)
- Docker Engine and `docker compose` plugin
- `make`

### Required configuration files

- `srcs/.env` for non-secret environment configuration
- `srcs/docker-compose.yml` for stack orchestration

### Required secrets

Create and fill these files in `srcs/secrets/`:

- `db_root_password.txt`
- `db_password.txt`
- `wp_admin_password.txt`
- `wp_user_password.txt`

Also ensure `/etc/hosts` contains:

```bash
127.0.0.1 sel-mlil.42.fr
```

## Current Architecture

### Compose file

- Path: `srcs/docker-compose.yml`
- Network: `inception_network` (bridge)
- Persistent bind mounts:
  - `/home/sel/data/mysql`
  - `/home/sel/data/wordpress`

### Running services

- `mariadb`
- `redis`
- `wordpress`
- `nginx`
- `adminer`
- `static_page`
- `game` (2048)
- `ftp`

### Public ports

- `443:443` (NGINX)
- `8080:8080` (Adminer)
- `3000:3000` (Static page)
- `2048:8080` (2048 container)
- `21:21` + `21000-21010:21000-21010` (FTP passive mode)

## Makefile Contract

Main targets in `Makefile`:

- `make` / `make all`: create host directories, build images, start stack
- `make links`: print service endpoints
- `make status`: list containers
- `make logs`: follow logs
- `make clean`: `docker compose down`
- `make fclean`: `down -v` + reset `/home/sel/data/*`
- `make re`: full rebuild (`fclean` then `all`)
- `make hardclean`: aggressive Docker prune

Utility shell targets:

- `make bash-mariadb`
- `make bash-wordpress`
- `make bash-nginx`

## Build and launch

Use Makefile (recommended):

```bash
make
```

Equivalent Compose flow:

```bash
docker compose -f srcs/docker-compose.yml up --build -d
```

## Service Build Pattern

Each service uses a local Dockerfile under:

```text
srcs/requirements/<service>/Dockerfile
```

Compose pattern:

```yaml
<service_name>:
  image: <service_name>:1
  build: ./requirements/<service_name>
  container_name: <service_name>
  restart: always
  networks:
    - inception_network
```

Add `ports`, `volumes`, `depends_on`, `env_file`, and `secrets` only when needed.

## Secrets and Environment

### Compose secrets

Defined in `srcs/docker-compose.yml`:

- `db_root_password`
- `db_password`
- `wp_admin_password`
- `wp_user_password`

Mapped from files in `srcs/secrets/`.

### Environment file

- `srcs/.env` is consumed by services that need non-secret config.
- FTP service expects `FTP_USER` and `FTP_PASSWORD` in `srcs/.env` (with defaults in container script if unset).

## Development Workflow

### Validate config

```bash
docker compose -f srcs/docker-compose.yml config
```

### Rebuild one service

```bash
docker compose -f srcs/docker-compose.yml build --no-cache <service>
docker compose -f srcs/docker-compose.yml up -d <service>
```

### Stop and remove stack

```bash
docker compose -f srcs/docker-compose.yml down
```

### Inspect logs

```bash
docker compose -f srcs/docker-compose.yml logs --tail=100 <service>
```

### Inspect network

```bash
docker network inspect inception_network
```

## Container and volume management commands

### Containers

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs <service>
docker compose -f srcs/docker-compose.yml restart <service>
docker compose -f srcs/docker-compose.yml exec <service> sh
```

### Volumes and storage

```bash
docker volume ls
docker volume inspect srcs_db_data
docker volume inspect srcs_wp_data
```

Full cleanup including volumes and local data reset:

```bash
make fclean
```

## Data location and persistence

Project data persists through bind mounts configured in Compose volumes:

- MariaDB data: `/home/sel/data/mysql`
- WordPress data: `/home/sel/data/wordpress`
- FTP container mounts WordPress data (`wp_data`) at `/var/www/html` for file transfer.

Persistence behavior:

- `make clean` stops/removes containers but keeps persisted data.
- `make fclean` removes volumes and resets host data directories.

## Adding a New Bonus Service

- Create directory:

```bash
mkdir -p srcs/requirements/<new_service>
```

- Add `Dockerfile` in that directory.
- Add service block in `srcs/docker-compose.yml`.
- Expose host port only if the service must be accessed from host.
- Validate:

```bash
docker compose -f srcs/docker-compose.yml config
```

- Build and start:

```bash
docker compose -f srcs/docker-compose.yml build <new_service>
docker compose -f srcs/docker-compose.yml up -d <new_service>
```

## Debugging Notes

### Port conflicts

If `443`, `8080`, `3000`, or `2048` is already in use, free the port or change mapping in compose.

### Broken startup order

Use:

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs <service>
```

### Data reset

For a clean state:

```bash
make fclean
make
```

## Documentation Alignment Rule

When changing `docker-compose.yml` or `Makefile`, update these files together:

- `README.md`
- `USER_DOC.md`
- `DEV_DOC.md`

This keeps commands, endpoints, and service inventory consistent.
