FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php \
    php-mysql \
    php-fpm \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Download Adminer
RUN curl -L https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-en.php -o index.php

# Create a simple PHP configuration
RUN mkdir -p /run/php-fpm && \
    chown www-data:www-data /run/php-fpm && \
    chown -R www-data:www-data /var/www/html

# Expose port for Adminer
EXPOSE 8080

# Start PHP built-in server
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]
