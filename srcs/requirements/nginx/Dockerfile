# NGINX Dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Create SSL directory
RUN mkdir -p /etc/nginx/ssl

# Copy configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf
# COPY conf/default.conf /etc/nginx/conf.d/

# Copy startup script
COPY tools/start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/start.sh"]