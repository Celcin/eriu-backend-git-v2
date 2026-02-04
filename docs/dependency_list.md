# SYSTEM

## FRANKENPHP

libcap2-bin
libstdc++6
glibc
OpenSSL libraries


## PHP EXTENSIONS

ctype
iconv
session
tokenizer
SimpleXML
PDO
pdo_mysql
mbstring
OPcache
GD
openssl
redis


## DOCKER SERVICES (docker-compose.yml)

Redis (cache server)
MySQL (database server)
Mailpit (email debugging - dev only)
Gotenberg (PDF generation server)


## SYMFONY (CORE)

docker compose exec php composer require symfony/framework-bundle
docker compose exec php composer require symfony/runtime
docker compose exec php composer require symfony/console
docker compose exec php composer require symfony/dotenv


## DOCTRINE

docker compose exec php composer require doctrine/orm
docker compose exec php composer require doctrine/doctrine-bundle


# COMPOSER PACKAGES (PRODUCTION)

## API HANDLING AND CONFIGURATION

docker compose exec php composer require api-platform/core

## AUTHENTICATION AND USER ROLE MANAGEMENT

docker compose exec php composer require lexik/jwt-authentication-bundle
docker compose exec php composer require gesdinet/jwt-refresh-token-bundle

## IMAGE PROCESSING, FILE UPLOADING & DOCUMENT MANAGEMENT

docker compose exec php composer require intervention/image
docker compose exec php composer require vich/uploader-bundle
docker compose exec php composer require league/flysystem-bundle

## DYNAMIC PDF GENERATION

docker compose exec php composer require sensiolabs/gotenberg-bundle

## ERROR TRACKING

docker compose exec php composer require sentry/sentry-symfony

## EMAIL

docker compose exec php composer require symfony/mailer

## CACHING

(handled by phpredis extension + symfony/cache, which is a transitive dependency of framework-bundle)


# COMPOSER PACKAGES (DEV ONLY)

## AUTO-FORMATTER & REFACTORING

docker compose exec php composer require --dev rector/rector
docker compose exec php composer require --dev friendsofphp/php-cs-fixer
docker compose exec php composer require --dev symplify/config-transformer

## STATIC ANALYSIS

docker compose exec php composer require --dev phpstan/phpstan

## EMAIL TESTING

docker compose exec php composer require --dev zenstruck/mailer-test