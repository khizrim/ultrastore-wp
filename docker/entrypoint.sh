#!/usr/bin/env bash
set -euo pipefail

WP_PATH=${WP_PATH:-/var/www/html}
DB_HOST=${WORDPRESS_DB_HOST:-127.0.0.1}
DB_NAME=${WORDPRESS_DB_NAME:-wordpress}
DB_USER=${WORDPRESS_DB_USER:-wpuser}
DB_PASSWORD=${WORDPRESS_DB_PASSWORD:-wppass}
DB_PREFIX=${WORDPRESS_TABLE_PREFIX:-wp_}
ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-}
SITE_URL=${WORDPRESS_SITE_URL:-http://localhost:8080}
SITE_TITLE=${WORDPRESS_SITE_TITLE:-Ultrastore POC}
ADMIN_USER=${WORDPRESS_ADMIN_USER:-admin}
ADMIN_PASSWORD=${WORDPRESS_ADMIN_PASSWORD:-admin}
ADMIN_EMAIL=${WORDPRESS_ADMIN_EMAIL:-admin@example.com}
INSTALL_WC=${INSTALL_WOOCOMMERCE:-true}

mkdir -p /run/php
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld || true
chown -R www-data:www-data "$WP_PATH" || true
chown -R mysql:mysql /var/lib/mysql || true

if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "Initializing MariaDB data directory..."
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

# Start temporary MariaDB to run initialization SQL
/usr/sbin/mariadbd --user=mysql --datadir=/var/lib/mysql --bind-address=127.0.0.1 --socket=/run/mysqld/mysqld.sock &
MDB_PID=$!

# Wait for DB to be ready
for i in {1..60}; do
  if mariadb-admin --socket=/run/mysqld/mysqld.sock ping --silent >/dev/null 2>&1; then
    break
  fi
  sleep 1
  if [ $i -eq 60 ]; then
    echo "MariaDB did not become ready in time" >&2
    exit 1
  fi
done

# Set root password if provided
ROOT_PASS_OPT=""
if [ -n "$ROOT_PASSWORD" ]; then
  mariadb -uroot <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
FLUSH PRIVILEGES;
SQL
  ROOT_PASS_OPT="-p${ROOT_PASSWORD}"
fi

# Create DB and user
mariadb -uroot ${ROOT_PASS_OPT} <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

# Install WordPress core if missing
if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo "Bootstrapping WordPress..."
  sudo -u www-data wp core download --path="$WP_PATH" --allow-root --force
  sudo -u www-data wp config create --path="$WP_PATH" --allow-root \
    --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASSWORD" --dbhost="$DB_HOST" --dbprefix="$DB_PREFIX" \
    --skip-check
  sudo -u www-data wp core install --path="$WP_PATH" --allow-root \
    --url="$SITE_URL" --title="$SITE_TITLE" \
    --admin_user="$ADMIN_USER" --admin_password="$ADMIN_PASSWORD" --admin_email="$ADMIN_EMAIL" \
    --skip-email
fi

# Install and activate WooCommerce if requested
if [ "${INSTALL_WC}" = "true" ]; then
  sudo -u www-data wp plugin install woocommerce --activate --path="$WP_PATH" --allow-root || true
fi

# Activate headless theme if present
if [ -d "$WP_PATH/wp-content/themes/ultrastore-headless" ]; then
  sudo -u www-data wp theme activate ultrastore-headless --path="$WP_PATH" --allow-root || true
fi

# Shutdown temp DB so supervisor can manage it
mariadb-admin ${ROOT_PASS_OPT} -uroot --socket=/run/mysqld/mysqld.sock shutdown || true
wait $MDB_PID || true

# Start services
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
