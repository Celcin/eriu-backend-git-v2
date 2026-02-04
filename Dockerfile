# syntax=docker/dockerfile:1


# =============================================================================
# UPSTREAM BASE IMAGE
# =============================================================================


# FrankenPHP is a modern PHP application server built on top of Caddy.
# Tag "1-php8.5" = FrankenPHP major version 1, PHP 8.5, latest compatible OS.
# Check https://hub.docker.com/r/dunglas/frankenphp/tags for available tags.

FROM dunglas/frankenphp:1-php8.5 AS frankenphp_upstream


# =============================================================================
# BASE STAGE - COMMON CONFIGURATION FOR ALL ENVIRONMENTS
# =============================================================================


# This stage contains shared configuration used by both dev and prod stages.
# Using multi-stage builds reduces duplication and ensures consistency.

FROM frankenphp_upstream AS frankenphp_base

WORKDIR /app

# -----------------------------------------------------------------------------
# SYSTEM DEPENDENCIES
# -----------------------------------------------------------------------------

# Install essential system packages required for PHP and Symfony development.
# Packages:
# - file: Symfony MimeTypes component (needed for file uploads in REST API)
# - ca-certificates: HTTPS connections to external services
# - curl: healthcheck endpoint verification
# NOTE: git and unzip are NOT needed at runtime - Composer installs from dist

RUN apt-get update && apt-get install -y --no-install-recommends \
    file \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# PHP EXTENSIONS
# -----------------------------------------------------------------------------

# Install PHP extensions using the install-php-extensions helper script.
# Extensions:
#   - @composer: PHP dependency manager
#   - pdo_mysql: MySQL database driver for Doctrine
#   - opcache: Bytecode caching for faster PHP execution
#   - redis: phpRedis client for caching and sessions
#   - intl: Internationalization extension for locale-aware formatting
#   - zip: Archive handling for Composer and file uploads
# CRITICAL: Do NOT install apcu, imagick, or libvips - they cause segfaults in ZTS builds

RUN install-php-extensions \
    @composer \
    pdo_mysql \
    opcache \
    gd \
    redis \
    zip \
    intl

# -----------------------------------------------------------------------------
# COMPOSER CONFIGURATION
# -----------------------------------------------------------------------------

# Allow Composer to run as root without warnings (safe in container context).

ENV COMPOSER_ALLOW_SUPERUSER=1

# -----------------------------------------------------------------------------
# CONFIGURATION FILES
# -----------------------------------------------------------------------------

# Copy PHP configuration file.

COPY --link frankenphp/conf.d/app.ini $PHP_INI_DIR/conf.d/

# Copy Docker entrypoint script.

COPY --link --chmod=755 frankenphp/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

# Copy Caddy web server configuration.

COPY --link frankenphp/Caddyfile /etc/caddy/Caddyfile

# -----------------------------------------------------------------------------
# CONTAINER RUNTIME CONFIGURATION
# -----------------------------------------------------------------------------

ENTRYPOINT ["docker-entrypoint"]

# Healthcheck using Caddy's metrics endpoint (more reliable than PHP endpoint)
HEALTHCHECK --start-period=60s --interval=30s --timeout=3s --retries=3 CMD curl -f http://localhost:2019/metrics || exit 1


# =============================================================================
# DEVELOPMENT STAGE
# =============================================================================


# Development-specific tools and settings including Xdebug.

FROM frankenphp_base AS frankenphp_dev

# -----------------------------------------------------------------------------
# XDEBUG INSTALLATION
# -----------------------------------------------------------------------------

# Install Xdebug for debugging. Check https://pecl.php.net/package/xdebug for version compatibility with your PHP version.

RUN pecl install xdebug || true; \
    EXT_DIR=$(php -n -r 'echo ini_get("extension_dir");'); \
    if [ -f "$EXT_DIR/xdebug.so" ]; then \
        echo "zend_extension=xdebug" > $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini; \
    else \
        echo "ERROR: xdebug.so not found in $EXT_DIR" && exit 1; \
    fi

# -----------------------------------------------------------------------------
# DEVELOPMENT CONFIGURATION FILES
# -----------------------------------------------------------------------------

# Copy development-specific PHP settings (display_errors, memory limits, etc.).

COPY --link frankenphp/conf.d/app.dev.ini $PHP_INI_DIR/conf.d/app.ini

# Copy Xdebug configuration.

COPY --link frankenphp/conf.d/xdebug.ini $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini

# Use development PHP settings

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY --link frankenphp/conf.d/app.dev.ini $PHP_INI_DIR/conf.d/

# -----------------------------------------------------------------------------
# DEVELOPMENT STARTUP COMMAND
# -----------------------------------------------------------------------------

# Start FrankenPHP with file watching for hot reload during development.

CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile", "--watch"]


# =============================================================================
# PRODUCTION STAGE
# =============================================================================


# Optimized image for production deployment.

FROM frankenphp_base AS frankenphp_prod

# -----------------------------------------------------------------------------
# PRODUCTION ENVIRONMENT VARIABLES
# -----------------------------------------------------------------------------

# APP_ENV=prod: Symfony production mode (caching, no debug toolbar)
# FRANKENPHP_CONFIG: Worker mode for better performance (keeps PHP alive)
# MAX_REQUESTS: Restart worker after N requests to prevent memory leaks

ENV APP_ENV=prod
ENV FRANKENPHP_CONFIG="worker ./public/index.php"
ENV MAX_REQUESTS=500
ENV APP_DEBUG=0










# Use production PHP settings
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY --link frankenphp/conf.d/app.prod.ini $PHP_INI_DIR/conf.d/

# Step 1: Copy Composer files FIRST (maximizes layer cache hits)
COPY --link composer.json composer.lock symfony.lock ./

# Step 2: Install dependencies WITHOUT autoloader (source not yet copied)
RUN --mount=type=cache,target=/root/.composer/cache \
    composer install \
    --no-dev \
    --no-autoloader \
    --no-scripts \
    --no-progress \
    --prefer-dist

# Step 3: Copy application source (excluding frankenphp/ and other build files)
COPY --link --exclude=frankenphp/ . .

# Step 4: Generate optimized autoloader, dump env, warm cache
RUN set -eux; \
    mkdir -p var/cache var/log; \
    composer dump-autoload --classmap-authoritative --no-dev; \
    composer dump-env prod; \
    composer run-script --no-dev post-install-cmd; \
    bin/console cache:warmup --env=prod --no-debug; \
    chmod -R 755 var; \
    chown -R www-data:www-data var; \
    sync

# Production: NO --watch flag (file watcher disabled)
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]