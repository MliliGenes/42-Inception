*This project has been created as part of the 42 curriculum by sel-mlil.*

# Inception

## Description

Inception is a system administration project focused on containerization with Docker. The goal is to build and run a complete multi-service web infrastructure where each service runs in its own container and all services are orchestrated with Docker Compose.

### Project goal and overview

The infrastructure includes:

- NGINX (TLS entrypoint)
- WordPress (PHP-FPM)
- MariaDB
- Redis
- Adminer
- Static page
- 2048 game

The stack runs on a dedicated bridge network (`inception_network`) with persistent bind-mounted data under `/home/sel/data`.

### Docker usage and project sources

This project uses Docker to package each service with its own dependencies and startup logic, then uses Compose to define:

- service build contexts (`srcs/requirements/<service>/Dockerfile`)
- networking rules (`srcs/docker-compose.yml`)
- persistent storage (`/home/sel/data/mysql`, `/home/sel/data/wordpress`)
- secret injection from `srcs/secrets/*`

Main source folders:

- `srcs/docker-compose.yml`: stack orchestration
- `srcs/requirements/`: Dockerfiles and startup scripts per service
- `srcs/secrets/`: local secret files mounted as compose secrets
- `Makefile`: project entrypoint commands

### Main design choices

- One process responsibility per containerized service
- Compose-managed service orchestration and restart policy
- TLS termination at NGINX
- Secret files for sensitive credentials
- Persistent host bind mounts for MariaDB and WordPress data

### Technical comparisons

#### Virtual Machines vs Docker

- **Virtual Machines** provide full OS-level isolation but are heavier on CPU/RAM and slower to start.
- **Docker** shares the host kernel, starts faster, and is better suited to reproducible service-oriented deployments like this project.

#### Secrets vs Environment Variables

- **Secrets** are used for sensitive values (DB and WordPress passwords) and mounted at runtime from files.
- **Environment variables** are used for non-sensitive configuration and service settings.
- This separation reduces accidental exposure of credentials in config and logs.

#### Docker Network vs Host Network

- **Docker bridge network** provides service isolation, internal DNS by service name, and controlled exposure through explicit port mappings.
- **Host network** can be simpler/faster but removes isolation and increases collision/security risks.
- This project uses a custom bridge network for safer multi-service communication.

#### Docker Volumes vs Bind Mounts

- **Named volumes** are Docker-managed and portable across hosts.
- **Bind mounts** map to explicit host paths and are easier to inspect/reset manually.
- This project uses bind mounts via compose volume driver options to keep data explicitly under `/home/sel/data` as required by the project structure.

## Instructions

### Prerequisites

- Linux host (Debian/Ubuntu recommended)
- Docker Engine
- Docker Compose plugin (`docker compose`)
- `make`

### Installation and execution

1. Clone the repository and move into the project folder.
2. Create `srcs/.env` with your project values.
3. Fill secret files in `srcs/secrets/`:
    - `db_root_password.txt`
    - `db_password.txt`
    - `wp_admin_password.txt`
    - `wp_user_password.txt`
4. Add your domain to hosts:

```bash
sudo sh -c 'echo "127.0.0.1 sel-mlil.42.fr" >> /etc/hosts'
```

Run commands:

```bash
# Build and start the full stack
make

# Show running containers
make status

# Follow logs
make logs

# Show all service links
make links

# Stop and remove containers (keep bind-mounted data)
make clean

# Stop and remove containers + volumes + reset /home/sel/data
make fclean

# Full rebuild
make re
```

### Service access

- WordPress: `https://sel-mlil.42.fr`
- WordPress admin: `https://sel-mlil.42.fr/wp-admin`
- Adminer: `http://localhost:8080`
- Static page: `http://localhost:3000`
- 2048 game: `http://localhost:2048`

## Resources

### Classic references

- Docker docs: [https://docs.docker.com/](https://docs.docker.com/)
- Docker Compose file reference: [https://docs.docker.com/compose/compose-file/](https://docs.docker.com/compose/compose-file/)
- NGINX docs: [https://nginx.org/en/docs/](https://nginx.org/en/docs/)
- WordPress docs: [https://wordpress.org/documentation/](https://wordpress.org/documentation/)
- MariaDB docs: [https://mariadb.com/kb/en/](https://mariadb.com/kb/en/)
- Redis docs: [https://redis.io/docs/](https://redis.io/docs/)

### Tutorials and articles

- Docker getting started: [https://docs.docker.com/get-started/](https://docs.docker.com/get-started/)
- Dockerfile best practices: [https://docs.docker.com/develop/develop-images/dockerfile_best-practices/](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- Docker networking: [https://docs.docker.com/network/](https://docs.docker.com/network/)
- Docker volumes: [https://docs.docker.com/storage/volumes/](https://docs.docker.com/storage/volumes/)

### AI usage in this project

AI assistance was used for:

- validating Docker/Compose syntax during setup
- drafting and refining documentation structure
- troubleshooting service integration issues (bonus services, ports, compose entries)

AI output was reviewed, adapted, and tested before integration into project sources.
