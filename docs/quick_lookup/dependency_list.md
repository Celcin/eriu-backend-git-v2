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

m install symfony/console
m install symfony/dotenv
m install symfony/framework-bundle
m install symfony/runtime
m install symfony/yaml


## DOCTRINE

m install doctrine/orm
m install doctrine/doctrine-bundle


# COMPOSER PACKAGES (PRODUCTION)

## API HANDLING AND CONFIGURATION

m install api-platform/core

## AUTHENTICATION AND USER ROLE MANAGEMENT

m install lexik/jwt-authentication-bundle
m install gesdinet/jwt-refresh-token-bundle

## IMAGE PROCESSING, FILE UPLOADING & DOCUMENT MANAGEMENT

m install intervention/image
m install vich/uploader-bundle
m install league/flysystem-bundle

## DYNAMIC PDF GENERATION

m install sensiolabs/gotenberg-bundle

## ERROR TRACKING

m install sentry/sentry-symfony

## EMAIL

m install symfony/mailer

## CACHING

(handled by phpredis extension + symfony/cache, which is a transitive dependency of framework-bundle)


# COMPOSER PACKAGES (DEV ONLY)

## AUTO-FORMATTER & REFACTORING

m install_for_dev rector/rector
m install_for_dev friendsofphp/php-cs-fixer
m install_for_dev symplify/config-transformer

## STATIC ANALYSIS

m install_for_dev phpstan/phpstan

## EMAIL TESTING

m install_for_dev zenstruck/mailer-test