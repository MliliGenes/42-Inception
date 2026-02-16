# Inception

*This project has been created as part of the 42 curriculum by sel-mlil.*

## Description

Inception is a System Administration project that focuses on containerization using Docker. The goal is to set up a small infrastructure composed of different services following Docker best practices. The project involves creating a multi-container application with NGINX, WordPress, and MariaDB, all running in separate Docker containers with proper networking, volumes, and security configurations.

This project deepens understanding of:
- Docker containerization and orchestration
- Docker Compose for multi-container applications
- Networking between containers
- Data persistence with volumes
- SSL/TLS configuration
- Service isolation and security

## Instructions

### Prerequisites

- A Virtual Machine running Linux (Ubuntu/Debian recommended)
- Docker Engine installed
- Docker Compose plugin installed
- Make utility installed
- Minimum 4GB RAM, 20GB disk space

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository_url>
   cd inception
   ```

2. **Configure environment variables**
   - Copy `.env.example` to `srcs/.env`
   - Edit `srcs/.env` and replace placeholders with your values:
     - Replace `login` with your 42 login
     - Set secure passwords for database and WordPress users
     - Configure domain name (sel-mlil.42.fr)

3. **Set up secrets**
   ```bash
   # Create secret files in secrets/ directory
   echo "your_root_password" > secrets/db_root_password.txt
   echo "your_db_password" > secrets/db_password.txt
   chmod 600 secrets/*
   ```

4. **Update /etc/hosts**
   ```bash
   sudo echo "127.0.0.1 sel-mlil.42.fr" >> /etc/hosts
   ```
   Replace `login` with your actual login.

### Compilation and Execution

```bash
# Build and start all services
make

# Stop services
make stop

# Start services
make start

# Stop and remove containers
make down

# Clean everything (containers, images, volumes)
make fclean

# Rebuild from scratch
make re

# View logs
make logs

# Check container status
make status
```

### Access the Application

- **WordPress Website**: https://sel-mlil.42.fr (replace `login` with your login)
- **WordPress Admin**: https://sel-mlil.42.fr/wp-admin
  - Username: (as configured in .env)
  - Password: (as configured in .env)

**Note**: You'll need to accept the self-signed SSL certificate in your browser.

## Project Structure

```
inception/
├── Makefile                    # Build and management commands
├── secrets/                    # Sensitive data (not in git)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── credentials.txt
└── srcs/
    ├── docker-compose.yml      # Container orchestration
    ├── .env                    # Environment variables (not in git)
    └── requirements/
        ├── mariadb/            # Database container
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── nginx/              # Web server container
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/          # WordPress container
        │   ├── Dockerfile
        │   └── tools/
        └── bonus/              # Optional services
            ├── redis/
            ├── ftp/
            ├── adminer/
            └── static-site/
```

## Resources

### Documentation
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Codex](https://wordpress.org/documentation/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [WP-CLI Commands](https://developer.wordpress.org/cli/commands/)

### Tutorials and Articles
- [Docker for Beginners](https://docker-curriculum.com/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Networking](https://docs.docker.com/network/)
- [Docker Volumes](https://docs.docker.com/storage/volumes/)
- [NGINX SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)

### AI Usage
AI tools were used in this project for the following purposes:

1. **Code Generation Assistance**
   - Dockerfile syntax and best practices verification
   - Shell script generation for container initialization
   - NGINX configuration optimization

2. **Documentation**
   - Markdown formatting and structure
   - README template creation
   - Command reference documentation

3. **Troubleshooting**
   - Debugging container startup issues
   - Resolving permission problems with volumes
   - Network connectivity troubleshooting

4. **Learning and Research**
   - Understanding Docker concepts (volumes vs bind mounts, networks)
   - SSL/TLS configuration best practices
   - Security considerations for containerized applications

**Important**: All AI-generated code was thoroughly reviewed, tested, and understood before integration. Each component was validated manually and adapted to meet specific project requirements.

## Technical Choices

### Virtual Machines vs Docker

**Docker was chosen for this project because:**
- **Lightweight**: Containers share the host OS kernel, requiring less resources than VMs
- **Fast startup**: Containers start in seconds vs minutes for VMs
- **Portability**: Images can run consistently across different environments
- **Scalability**: Easier to scale horizontally with multiple container instances
- **Development efficiency**: Quick iteration and testing cycles

**When VMs are better:**
- Complete OS isolation needed
- Running different OS kernels
- Legacy application compatibility
- Maximum security isolation

### Secrets vs Environment Variables

**Secrets** (used for sensitive data):
- Stored in separate files with restricted permissions
- Not in version control
- Mounted as read-only in containers
- Better access control and audit trails
- Used for: passwords, API keys, certificates

**Environment Variables** (used for configuration):
- Stored in .env file
- Can be in version control (without sensitive data)
- Easily modified per environment
- Used for: domain names, service names, non-sensitive config

### Docker Network vs Host Network

**Docker Bridge Network** (used in this project):
- **Isolation**: Containers are isolated from host network
- **Security**: Controlled communication between containers
- **Portability**: Same configuration works across hosts
- **DNS**: Automatic service discovery by container name
- **Best for**: Multi-container applications

**Host Network**:
- Better performance (no network translation)
- Simpler troubleshooting
- Less isolation
- Port conflicts with host
- **Best for**: Performance-critical single containers

### Docker Volumes vs Bind Mounts

**Named Volumes** (used in this project):
- **Managed by Docker**: Automatic creation and management
- **Portability**: Can be easily backed up and migrated
- **Performance**: Better on non-Linux hosts
- **Isolation**: Separated from host filesystem structure
- **Best for**: Production data persistence

**Bind Mounts**:
- Direct access to host filesystem
- Real-time file synchronization
- Easier development workflow
- Host path dependencies
- **Best for**: Development environments

## Design Decisions

### Why Debian Bullseye?
- Stable, well-tested base
- Good package availability
- Smaller than Ubuntu, larger than Alpine
- Better compatibility with certain packages (MariaDB, PHP)

### Why php-fpm Instead of Apache?
- Better performance with NGINX
- Lower memory footprint
- More efficient process management
- Industry-standard for high-traffic WordPress sites

### Why Self-Signed Certificates?
- Project is local/development environment
- Demonstrates SSL/TLS configuration
- No dependency on external certificate authorities
- Easy to generate and manage

### Why WP-CLI?
- Automated WordPress installation
- Reproducible deployments
- Scriptable configuration
- No manual browser-based setup needed

## Security Considerations

1. **Secrets Management**: All passwords stored in separate files, not in code
2. **TLS Only**: Enforced HTTPS with TLSv1.2/1.3 minimum
3. **No Root Containers**: Services run as non-root users where possible
4. **Minimal Base Images**: Only necessary packages installed
5. **Network Isolation**: Services communicate only through defined networks
6. **No Hardcoded Credentials**: All sensitive data from environment/secrets

## Performance Optimizations

1. **Image Layers**: Combined RUN commands to reduce layer count
2. **Caching**: Leveraged Docker build cache effectively
3. **Minimal Images**: Removed unnecessary packages and files
4. **PHP-FPM Tuning**: Optimized process manager settings
5. **NGINX Optimization**: Configured worker connections and buffers

## Troubleshooting

### Common Issues

**Containers won't start:**
```bash
# Check logs
docker logs <container_name>

# Verify configuration
docker compose config
```

**Permission denied on volumes:**
```bash
sudo chown -R $USER:$USER /home/$USER/data
```

**Can't access website:**
```bash
# Check if containers are running
docker ps

# Verify /etc/hosts entry
cat /etc/hosts | grep 42.fr

# Test SSL
curl -k https://sel-mlil.42.fr
```

**Database connection failed:**
```bash
# Check MariaDB is running
docker exec -it mariadb mysqladmin ping

# Verify credentials
cat srcs/.env | grep MYSQL
```

## Future Improvements

- Implement automated backups for database and files
- Add monitoring with Prometheus/Grafana
- Implement log aggregation
- Add health checks to docker-compose
- Configure automatic SSL certificate renewal (if using Let's Encrypt)
- Implement resource limits for containers

## License

This project is part of the 42 School curriculum and is subject to the school's academic policies.

## Author

sel-mlil

## Acknowledgments

- 42 Network for the project subject
- Docker and open-source community for excellent documentation
- Peers for collaboration and knowledge sharing
