FRANKENPHP_TAG			➤ Base image tag for Dockerfile FROM dunglas/frankenphp:{tag}
MYSQL_VERSION			➤ MySQL Docker image tag (mysql:{version})
REDIS_VERSION			➤ Redis Docker image tag (redis:{version})
GOTENBERG_VERSION		➤ Gotenberg Docker image tag (gotenberg/gotenberg:{version})
MAILPIT_VERSION			➤ Mailpit Docker image tag (axllent/mailpit:{version})
ALPINE_VERSION			➤ Alpine image for env-info debug container

HTTP_PORT			➤ Host port for Caddy HTTP (maps to container :80)
HTTPS_PORT			➤ Host port for Caddy HTTPS (maps to container :443 TCP+UDP)
MYSQL_PORT			➤ Host port for MySQL (maps to container :3306)
REDIS_PORT			➤ Host port for Redis (maps to container :6379)
GOTENBERG_PORT			➤ Host port for Gotenberg API (maps to container :3000)
MAILPIT_UI_PORT			➤ Host port for Mailpit web UI (maps to container :8025)
MAILPIT_SMTP_PORT		➤ Host port for Mailpit SMTP (maps to container :1025)

APP_ENV				➤ Symfony environment (dev/staging/prod)
APP_DEBUG			➤ Enable/disable Symfony debug mode (1/0)
APP_SECRET			➤ Symfony CSRF tokens, signed URLs, remember-me cookies

MYSQL_DATABASE			➤ Database name to create on first run
MYSQL_USER			➤ Application database user
MYSQL_PASSWORD			➤ Password for MYSQL_USER
MYSQL_ROOT_PASSWORD		➤ MySQL root password
DATABASE_URL			➤ Full Doctrine DBAL DSN string

REDIS_MAXMEMORY			➤ Redis max memory allocation
REDIS_URL			➤ Redis connection URL for Symfony cache
MESSENGER_TRANSPORT_DSN		➤ Redis Streams URL for Symfony Messenger (Beanstalkd replacement)

GOTENBERG_TIMEOUT		➤ API request timeout
GOTENBERG_LOG_LEVEL		➤ Gotenberg log verbosity
GOTENBERG_CHROMIUM_QUEUE	➤ Max queued Chromium conversion requests
GOTENBERG_LIBREOFFICE_QUEUE	➤ Max queued LibreOffice conversion requests
GOTENBERG_URL			➤ Gotenberg API URL for Symfony bundle

MAILPIT_MAX_MESSAGES		➤ Max stored emails before oldest are purged
MAILER_DSN			➤ Symfony Mailer transport DSN

SERVER_NAME			➤ Caddy site address / hostname
FRANKENPHP_CONFIG		➤ FrankenPHP worker mode config (empty = disabled)
TRUSTED_PROXIES	IP		➤ ranges Symfony trusts for X-Forwarded-* headers
TRUSTED_HOSTS			➤ Regex of allowed Host header values

JWT_SECRET_KEY			➤ Path to private PEM key file
JWT_PUBLIC_KEY			➤ Path to public PEM key file
JWT_PASSPHRASE			➤ Passphrase used to encrypt/decrypt the private key

SENTRY_DSN			➤ Sentry error tracking DSN (empty = disabled)
DEFAULT_URI			➤ Base URL for Symfony router (used in CLI URL generation)

XDEBUG_MODE			➤ XDEBUG mode (off/debug/develop/coverage/profile)
XDEBUG_SESSION			➤ IDE session key for XDEBUG

COMPOSE_PROFILES		➤ Active Docker Compose profile (dev/staging/prod)
COMPOSE_ENV_FILES		➤ Which .env files Docker Compose loads for interpolation
DOCKER_REGISTRY			➤ Docker registry prefix for pre-built images
IMAGE_TAG			➤ Docker image tag for pre-built images
TZ				➤ Container timezone