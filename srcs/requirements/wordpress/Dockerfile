# WordPress Dockerfile
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    # CA trust store for HTTPS downloads
    ca-certificates \
    # MySQL client utilities (mysqladmin) used by setup script
    mariadb-client \
    # PHP command-line interpreter
    php-cli \
    # PHP FastCGI process manager
    php-fpm \
    # PHP extension for MySQL/MariaDB connectivity
    php-mysql \
    # PHP extension for HTTP/URL operations
    php-curl \
    # PHP extension for image processing
    php-gd \
    # PHP extension for multibyte string support
    php-mbstring \
    # PHP extension for XML parsing/handling
    php-xml \
    # PHP extension for ZIP archive support
    php-zip \
    # PHP extension for Redis connectivity
    php-redis \
    # Archive extraction utility (used for WordPress tarball)
    tar \
    # Download utility for fetching WordPress archive
    wget \
    # ZIP extraction utility
    unzip \
    # HTTP client (used to install WP-CLI)
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

RUN sed -i 's|^listen = .*|listen = 9000|' /etc/php/7.4/fpm/pool.d/www.conf

#! wp tarball (for manual installation)
RUN mkdir -p /var/www \
    && wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz \
    && tar -xzf /tmp/wordpress.tar.gz -C /var/www/ \
    && mv /var/www/wordpress /var/www/html \
    && rm /tmp/wordpress.tar.gz

#! Set WordPress directory
WORKDIR /var/www/html

#! Entry point setup
COPY tools/setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup.sh


RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

EXPOSE 9000

# Use your init script to handle config and start PHP-FPM
ENTRYPOINT ["/usr/local/bin/setup.sh"]