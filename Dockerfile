# syntax=docker/dockerfile:1


# =============================================================================
# UPSTREAM BASE IMAGE
# =============================================================================


# FrankenPHP is a modern PHP application server built on top of Caddy.
# Tag "1-php8.5" = FrankenPHP major version 1, PHP 8.5, latest compatible Debian.
# Check https://hub.docker.com/r/dunglas/frankenphp/tags for available tags.
#
# REPRODUCIBILITY: For production supply-chain security, pin the base image to
# a specific SHA256 digest. This prevents silent upstream changes from altering
# the build. Update the digest deliberately when upgrading.
#
# To obtain the current digest:
#   docker pull dunglas/frankenphp:1-php8.5
#   docker inspect --format='{{index .RepoDigests 0}}' dunglas/frankenphp:1-php8.5
#
# Then replace the FROM line below with:
#   FROM dunglas/frankenphp:1-php8.5@sha256:<digest> AS frankenphp_upstream

FROM dunglas/frankenphp:1-php8.5 AS frankenphp_upstream


# =============================================================================
# BASE STAGE - COMMON CONFIGURATION FOR ALL ENVIRONMENTS
# =============================================================================


# This stage contains shared configuration used by both dev and prod stages.
# Multi-stage builds reduce duplication and ensure consistency across targets.

FROM frankenphp_upstream AS frankenphp_base

WORKDIR /app
ENV PATH="${PATH}:/app/vendor/bin"

# -----------------------------------------------------------------------------
# SYSTEM DEPENDENCIES
# -----------------------------------------------------------------------------

# Install essential system packages required at runtime.
#
# Packages:
#   file          - Required by the Symfony MimeTypes component for reliable
#                   MIME detection during file uploads in the REST API.
#   libcap2-bin   - Provides the setcap utility, required for granting the
#                   FrankenPHP binary permission to bind to privileged ports
#                   (80/443) when running as a non-root user in production.
#   ca-certificates - Ensures HTTPS connections to external services work
#                     correctly. May already be present in the base image but
#                     is declared explicitly for reproducibility.
#   curl          - Used by the HEALTHCHECK directive to probe the Caddy admin
#                   API endpoint. Also likely present in the base image but
#                   declared explicitly to guarantee availability.
#
# NOTE: git and unzip are NOT needed at runtime. Composer downloads pre-built
# distribution archives (--prefer-dist) which do not require either tool.

RUN apt-get update && apt-get install -y --no-install-recommends \
    file \
    libcap2-bin \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# PHP EXTENSIONS
# -----------------------------------------------------------------------------

# Install PHP extensions via the install-php-extensions helper script bundled
# with the FrankenPHP image. This tool automatically detects ZTS (Zend Thread
# Safety) mode - which FrankenPHP requires for its multi-threaded worker
# architecture - and compiles every extension with thread-safety enabled.
#
# Extensions installed explicitly:
#   @composer  - PHP dependency manager (latest stable release)
#   pdo_mysql  - MySQL database driver for Doctrine ORM
#   opcache    - Bytecode caching for dramatically faster PHP execution
#   gd         - Image processing library (used by intervention/image)
#   redis      - phpRedis client for caching and session storage
#
# Extensions that ship with PHP 8.5 by default (no installation needed):
#   ctype, iconv, session, tokenizer, SimpleXML, PDO, mbstring, openssl
#
# CRITICAL ZTS WARNING: Do NOT add imagick or php-vips to this image.
# Both cause segmentation faults in FrankenPHP ZTS builds:
#   - imagick: github.com/dunglas/frankenphp/issues/634
#   - php-vips: github.com/dunglas/frankenphp/issues/1019
# If advanced image processing beyond GD is needed, use a separate
# microservice or process images via CLI outside the FrankenPHP worker.

RUN install-php-extensions \
    @composer \
    pdo_mysql \
    opcache \
    gd \
    redis

# -----------------------------------------------------------------------------
# COMPOSER CONFIGURATION
# -----------------------------------------------------------------------------

# Suppress the "Running Composer as root/super user" warning. This is safe in
# a container context where the filesystem is ephemeral. Composer 2.7.0+ also
# disables plugins by default when running as root, which mitigates potential
# supply-chain risks from malicious Composer packages.
# See: https://getcomposer.org/doc/03-cli.md#composer-allow-superuser

ENV COMPOSER_ALLOW_SUPERUSER=1

# -----------------------------------------------------------------------------
# CONFIGURATION FILES
# -----------------------------------------------------------------------------

# Copy base PHP configuration (shared settings applied in all environments).

COPY --link frankenphp/conf.d/app.ini $PHP_INI_DIR/conf.d/

# Copy Docker entrypoint script (handles signal forwarding and startup logic).

COPY --link --chmod=755 frankenphp/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

# Copy Caddy web server configuration (routes, TLS, worker binding).

COPY --link frankenphp/Caddyfile /etc/caddy/Caddyfile

# -----------------------------------------------------------------------------
# CONTAINER RUNTIME CONFIGURATION
# -----------------------------------------------------------------------------

ENTRYPOINT ["docker-entrypoint"]

# Healthcheck targets Caddy's admin API on port 2019 (the default admin port).
# The /metrics endpoint is lightweight and confirms both Caddy and FrankenPHP
# are operational without touching the application layer.
#
# Timing parameters:
#   start-period=60s - Grace period for initial startup (covers Symfony cache
#                      warmup and worker initialization)
#   interval=30s     - Time between healthcheck probes
#   timeout=3s       - Maximum wait for a response before marking as failed
#   retries=3        - Consecutive failures before marking container unhealthy

HEALTHCHECK --start-period=60s --interval=30s --timeout=3s --retries=3 \
    CMD curl -f http://localhost:2019/metrics || exit 1


# =============================================================================
# DEVELOPMENT STAGE
# =============================================================================


# Development-specific configuration including Xdebug for step debugging.
# This stage is never used in production builds.

FROM frankenphp_base AS frankenphp_dev

# -----------------------------------------------------------------------------
# XDEBUG INSTALLATION
# -----------------------------------------------------------------------------

# Install Xdebug via install-php-extensions rather than pecl directly. This
# ensures the extension is compiled with ZTS (thread-safety) support, which
# FrankenPHP requires. Direct pecl installation risks downloading NTS
# (non-thread-safe) binaries that will fail to load.
#
# DEBUGGING TIP: In worker mode, breakpoints may not propagate to already-
# running workers without a container restart. For step debugging, disable
# worker mode by setting FRANKENPHP_CONFIG="" in docker-compose.override.yml
# or by using standard request mode.

RUN install-php-extensions xdebug

# -----------------------------------------------------------------------------
# DEVELOPMENT CONFIGURATION FILES
# -----------------------------------------------------------------------------

# Replace the base PHP configuration with development-specific settings
# (display_errors=On, higher memory limits, verbose error reporting, etc.).

COPY --link frankenphp/conf.d/app.dev.ini $PHP_INI_DIR/conf.d/app.ini

# Copy Xdebug configuration (mode, client_host, client_port, start triggers).
# This overwrites the default ini created by install-php-extensions with
# project-specific settings.

COPY --link frankenphp/conf.d/xdebug.ini $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini

# Use PHP's built-in development configuration as the base php.ini
# (enables display_errors, sets maximum error_reporting level, etc.).

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# -----------------------------------------------------------------------------
# DEVELOPMENT STARTUP COMMAND
# -----------------------------------------------------------------------------

# Start FrankenPHP with the --watch flag, which enables filesystem watching
# for automatic hot-reload during development. Source file changes take effect
# without a manual container restart.

CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile", "--watch"]


# =============================================================================
# PRODUCTION STAGE
# =============================================================================


# Optimized image for production deployment. This stage:
#   - Enables FrankenPHP worker mode (keeps PHP in memory between requests)
#   - Installs only production dependencies
#   - Warms the Symfony cache at build time
#   - Runs as a non-root user for defense in depth

FROM frankenphp_base AS frankenphp_prod

# -----------------------------------------------------------------------------
# PRODUCTION ENVIRONMENT VARIABLES
# -----------------------------------------------------------------------------

# APP_ENV=prod         - Activates Symfony production mode (compiled container,
#                        no debug toolbar, optimized routing).
# APP_DEBUG=0          - Disables Symfony debug mode entirely.
# FRANKENPHP_CONFIG    - Enables worker mode: the Symfony kernel stays loaded
#                        in memory between requests, yielding dramatically
#                        faster response times compared to traditional PHP-FPM.
# MAX_REQUESTS=500     - Recycles each worker after 500 requests to guard
#                        against gradual memory leaks. Tune this value based
#                        on production memory monitoring.

ENV APP_ENV=prod
ENV APP_DEBUG=0
ENV FRANKENPHP_CONFIG="worker ./public/index.php"
ENV MAX_REQUESTS=500

# -----------------------------------------------------------------------------
# PRODUCTION PHP CONFIGURATION
# -----------------------------------------------------------------------------

# Use PHP's built-in production configuration as the base php.ini
# (disables display_errors, tightens security settings, reduces verbosity).

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Copy production-specific PHP overrides. This file should contain at minimum:
#
#   ; === OPcache (bytecode caching) ===
#   opcache.enable=1
#   opcache.enable_cli=1
#   opcache.memory_consumption=256
#   opcache.interned_strings_buffer=64
#   opcache.max_accelerated_files=20000
#   opcache.validate_timestamps=0
#   opcache.revalidate_freq=0
#   opcache.enable_file_override=1
#
#   ; === JIT - KEEP DISABLED ===
#   ; FrankenPHP has documented stability issues with JIT enabled.
#   ; See: github.com/dunglas/frankenphp/issues/860
#   ; Do not enable until upstream confirms full ZTS compatibility.
#   opcache.jit=disable
#   opcache.jit_buffer_size=0
#
#   ; === Optional: Preloading ===
#   ; Preloading compiles commonly used classes into OPcache at startup.
#   ; See config/preload.php. Uncomment when ready:
#   ; opcache.preload=/app/config/preload.php
#   ; opcache.preload_user=www-data

COPY --link frankenphp/conf.d/app.prod.ini $PHP_INI_DIR/conf.d/

# -----------------------------------------------------------------------------
# DEPENDENCY INSTALLATION (LAYER-CACHE OPTIMIZED)
# -----------------------------------------------------------------------------

# Step 1: Copy only Composer metadata files. This ensures the dependency
# installation layer is cached independently of application source code.
# The layer will only rebuild when composer.json or composer.lock change -
# not on every source file edit.

COPY --link composer.json composer.lock ./

# Step 2: Install production dependencies without generating the autoloader.
# Source code has not been copied yet, so class mapping would be incomplete.
# The BuildKit cache mount persists Composer's download cache across builds,
# avoiding redundant downloads even after a full image rebuild.

RUN --mount=type=cache,target=/root/.composer/cache \
    composer install \
    --no-dev \
    --no-autoloader \
    --no-scripts \
    --no-progress \
    --prefer-dist

# Step 3: Copy the full application source code. The --exclude flag omits
# Docker configuration files that are not needed at runtime.

COPY --link --exclude=frankenphp/ . .

# Step 4: Generate the optimized autoloader, compile environment variables
# and warm the Symfony cache. This must happen after source code is copied
# so the class map and cache are complete.
#
# Operations in order:
#   1. Create var/ directories if absent
#   2. Generate classmap-authoritative autoloader (skips PSR-4 filesystem scans)
#   3. Compile .env files into an optimized PHP file (.env.local.php)
#   4. Pre-compile the Symfony dependency injection container and route matcher
#   5. Set directory permissions for the non-root runtime user

RUN set -eux; \
    mkdir -p var/cache var/log; \
    composer dump-autoload --classmap-authoritative --no-dev; \
    composer dump-env prod; \
    bin/console cache:warmup --env=prod --no-debug; \
    chmod -R 755 var; \
    chown -R www-data:www-data var

# -----------------------------------------------------------------------------
# NON-ROOT USER CONFIGURATION
# -----------------------------------------------------------------------------

# Grant the FrankenPHP binary the ability to bind to privileged ports (80/443)
# without requiring root privileges. The setcap command (provided by the
# libcap2-bin package installed in the base stage) embeds the
# CAP_NET_BIND_SERVICE capability directly into the binary.
#
# Caddy's data directory (/data/caddy) stores auto-provisioned TLS
# certificates. The config directory (/config/caddy) holds runtime state.
# Both must be writable by the non-root user.
#
# NOTE: If /data and /config are mounted as Docker volumes at runtime, the
# volume ownership must also be configured (e.g., via an init container or
# by setting the volume's UID/GID in docker-compose.yml).

RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/frankenphp; \
    chown -R www-data:www-data /data/caddy /config/caddy

USER www-data

# -----------------------------------------------------------------------------
# PRODUCTION STARTUP COMMAND
# -----------------------------------------------------------------------------

# Start FrankenPHP WITHOUT the --watch flag. Filesystem watching is a
# development convenience that adds unnecessary overhead in production.

CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]