#!/bin/sh
set -e

if [ "$1" = 'frankenphp' ] || [ "$1" = 'php' ] || [ "$1" = 'bin/console' ]; then
    # Check if this is a fresh install (no Symfony project yet)
    # Use src/Kernel.php as the definitive indicator - it only exists after real Symfony install
    if [ ! -f src/Kernel.php ]; then
        echo "No Symfony project found. Creating placeholder..."
        mkdir -p public
        printf '%s\n' '<?php' 'header("Content-Type: application/json");' 'echo json_encode(["status"=>"placeholder","message"=>"Symfony not installed yet"]);' > public/index.php
        exec docker-php-entrypoint "$@"
    fi

    # Create necessary directories
    mkdir -p var/cache var/log

    # Install dependencies if vendor is empty but composer.json exists
    if [ -f composer.json ] && [ -z "$(ls -A vendor 2>/dev/null)" ]; then
        composer install --prefer-dist --no-progress --no-interaction
    fi

    # Set permissions
    setfacl -R -m u:www-data:rwX -m u:"$(whoami)":rwX var 2>/dev/null || true
    setfacl -dR -m u:www-data:rwX -m u:"$(whoami)":rwX var 2>/dev/null || true

    # Run migrations in dev (only if bin/console exists and doctrine is installed)
    if [ "$APP_ENV" = 'dev' ] && [ -f bin/console ]; then
        php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration 2>/dev/null || true
    fi
fi

exec docker-php-entrypoint "$@"