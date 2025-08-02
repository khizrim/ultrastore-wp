# UltraStore WordPress backend

This sub-module hosts the WordPress instance that powers product management and checkout through WooCommerce.

## 📋 Prerequisites

* Docker & Docker Compose **(recommended)**
* — or — a local PHP 8.2 + MySQL 8 stack and Composer

## 🏗 Local development with Docker

```bash
# From the repository root
# Starts only the WP & database services defined in docker-compose.yml
docker compose up wp db
```

Admin interface: <http://localhost:8080/wp-admin>  
(Default credentials are printed to the console on first run.)

## ⚙️ Alternative: `wp-env`
If you already have Node installed you can spin up WordPress with the official tool:

```bash
npm --global install @wordpress/env
wp-env start
```

## 📂 Directory structure
```
backend/
├─ plugins/     # Custom WP plugins (e.g. stock synchronisation)
├─ themes/      # Optional custom theme for preview
└─ wp-content/  # Standard WordPress content directory
```

## 🔑 Environment variables
Copy `.env.example` ➜ `.env` and adjust as needed:

```
WORDPRESS_DB_PASSWORD=secret
WOOCOMMERCE_CONSUMER_KEY=ck_…
WOOCOMMERCE_CONSUMER_SECRET=cs_…
```

## 🧪 Running tests
```bash
docker compose exec wp ./vendor/bin/phpunit
```

## 🚢 Production build

```bash
docker build -t ultrastore/wp .
```

Deploy the resulting container behind your web server / load balancer of choice.
