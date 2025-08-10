FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    WP_PATH=/var/www/html

# Install packages: Nginx, PHP-FPM + extensions, MariaDB, Supervisor, WP-CLI deps
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nginx \
        supervisor \
        mariadb-server mariadb-client \
        php-fpm php-mysql php-xml php-curl php-gd php-mbstring php-zip php-intl php-bcmath php-exif \
        ca-certificates curl less unzip sudo \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Configure PHP-FPM to listen on TCP for Nginx
RUN PHPV=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;') \
    && mkdir -p /etc/php/${PHPV}/fpm/pool.d \
    && echo "$PHPV" > /php.version
COPY docker/php-fpm-www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Configure Nginx
COPY docker/nginx.conf /etc/nginx/sites-available/default

# Supervisor configuration
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Entrypoint
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p ${WP_PATH} \
    && chown -R www-data:www-data ${WP_PATH} \
    && mkdir -p /run/php

# Provide wp-config.php with reverse-proxy HTTPS awareness and env-based config
COPY wp-config.php ${WP_PATH}/wp-config.php
RUN chown www-data:www-data ${WP_PATH}/wp-config.php

EXPOSE 80

CMD ["/usr/local/bin/entrypoint.sh"]
