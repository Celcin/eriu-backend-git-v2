# TABLE OF CONTENT

• 01: introduction
• 02: container naming convention
• 03: fix Linux file system permissions
• 04: quick start/stop commands
• 05: check software component versions
• 06: check latest Symfony & FrankenPHP versions
• 07: cloning project to a new device
• 08: prerequisites and environment verification
• 09: install trusted certificates
• 10: install VSC extensions
• 11: install Stardust for seeing paths and branches in the terminal (optional)
• 12: install newest Symfony version with FrankenPHP
• 13: remove all bloat dependencies
• 14: install all required dependencies & update them to the newest version
• 15: convert all YAML config files to PHP config files
• 16: auto-format all JSON files according to the style guide
• 17: auto-format all PHP files according to the style guide
• 18: configure doctrine ORM 3.6
• 19: configure cache with phpredis
• 20: configure MySQL
• 21: configure Mailpit
• 22: configure Gotenberg
• 23: configure Symfony messenger with Redis streams
• 24: configure health checks & security endpoints
• 25: test your software components
• 26: common errors & troubleshooting
• 27: copy the live database into local WSL via bash script
• 28: update the database to the newest SQL version and fix the geo data
• 29: auto-create the src/entities from the database schema (optional)


# 01: INTRODUCTION

• this guide sets up a minimal Symfony 8 REST API backend with FrankenPHP and PHP 8.5
• no frontend, no Twig templates, no Node.js
• just a pure API foundation with Redis caching and Gotenberg for PDF generation


# 02: CONTAINER NAMING CONVENTION

• all containers use the prefix »eriu-backend-«


# 03: FIX LINUX FILE SYSTEM PERMISSIONS

## CHANGE FILE OWNERSHIP TO YOUR USER

sudo chown -R $USER:$USER ~/projects


## FIX PERMISSIONS IF NEEDED

chmod -R u+rw ~/projects


## FIX GIT OWNERSHIP WARNING

docker compose exec php git config --global --add safe.directory /app


# 04: QUICK START/STOP COMMANDS

## NAVIGATE TO PROJECT

cd path/to/your/project


## START

docker compose up -d


## STOP

docker compose down


## REBUILD IF DOCKERFILE HAS CHANGED

docker compose down
docker compose up -d --build


## FORCE REBUILD WITH CLEARED CACHE TO FIX CACHING ERRORS

docker compose down
docker compose up -d --build --force-recreate


## ENABLE XDEBUG

XDEBUG_MODE=debug docker compose up -d


## RUN SYMFONY COMMANDS

docker compose exec php php bin/console <command>
docker compose exec php composer <command>


## CHECK IF CONTAINERS ARE RUNNING

docker compose ps


## VIEW LOGS

docker compose logs -f				→ all containers
docker compose logs -f php			→ PHP only
docker compose logs -f database			→ MySQL only
docker compose logs -f redis			→ Redis only
docker compose logs -f gotenberg		→ Gotenberg only


# 05: CHECK SOFTWARE COMPONENT VERSIONS

## PHP

docker compose exec php php -v

## SYMFONY

docker compose exec php php bin/console --version

## MYSQL

docker compose exec database mysql --version

## REDIS

docker compose exec redis redis-server --version

## GOTENBERG

docker compose exec gotenberg gotenberg --version

## XDEBUG

docker compose exec php php -v | grep -i xdebug


# 06: CHECK LATEST SYMFONY & FRANKENPHP VERSIONS

## CHECK THE LATEST SYMFONY VERSION AND WHAT PHP VERSION IT REQUIRES

curl -s https://repo.packagist.org/p2/symfony/framework-bundle.json | jq '[.packages["symfony/framework-bundle"][] | select(.version | test("^v[0-9]") and (contains("dev") | not))] | first | {version, php: .require.php}'

## CHECK THE LATEST FRANKENPHP RELEASES

• go to https://hub.docker.com/r/dunglas/frankenphp/tags
• the tag pattern is explained in the docs as [frankenphp-version-]php[php-version-][os], where each segment can range from major to minor to patch precision
• when the OS is omitted, it defaults to Trixie
• for short, try rebuilding the container with "dunglas/frankenphp:1-php8.X" or "dunglas/frankenphp:1-php8.X-trixie" as it uses the most open version constraints

Tag				FrankenPHP		PHP			OS
1-php8.5-trixie			any 1.x			any 8.5.x		Trixie
1-php8.5			any 1.x			any 8.5.x		Trixie (default)
1.11-php8.5-trixie		any 1.11.x		any 8.5.x		Trixie
1.11.1-php8.5.2-trixie		exactly 1.11.1		exactly 8.5.2		Trixie


# 07: CLONING PROJECT TO A NEW DEVICE

1: clone the repository
2: clone ".env.local", ".env.staging.local" and ".env.prod.local" from an existing project into the project root folder
3: start containers

docker compose up -d --build

• Caddy auto-generates SSL certificates for localhost
• if you previously set up mkcert certificates, you will also need to run "mkcert -install" and regenerate certificates (step 09)
• when cloning an existing project (that already has Symfony installed), you can start all containers directly
• the phased approach in step 11 is only needed for initial setup


# 08: PREREQUISITES AND ENVIRONMENT VERIFICATION

## 08-01: VERIFY DOCKER IS ACCESSIBLE FROM WSL2

docker --version		→ should show Docker 29.x+
docker compose version		→ should show Compose v2.x


## 08-02: VERIFY WSL2 INTEGRATION

wsl --status			→ confirms WSL 2.x


## 08-03: VERIFY SYSTEMD IS ENABLED (REQUIRED FOR PROPER DOCKER INTEGRATION)

systemctl --version		→ should work if systemd is enabled


# 09: INSTALL TRUSTED CERTIFICATES

• Caddy automatically generates self-signed certificates for localhost
• however, if you want browsers to trust these certificates without warnings, you can install mkcert


## 09-01: INSTALL MKCERT

sudo apt update
sudo apt install -y libnss3-tools


## 09-02: DOWNLOAD LATEST MKCERT

curl -JLO "https://github.com/FiloSottile/mkcert/releases/latest/download/mkcert-v1.4.4-linux-amd64"
chmod +x mkcert-v1.4.4-linux-amd64
sudo mv mkcert-v1.4.4-linux-amd64 /usr/local/bin/mkcert


## 09-03: INSTALL THE LOCAL CA

mkcert -install


# 10: INSTALL VSC EXTENSIONS

• PHP Debug (xdebug.php-debug) → Required for Xdebug
• PHP Intelephense (bmewburn.vscode-intelephense-client)
• Docker (ms-azuretools.vscode-docker)
• WSL (ms-vscode-remote.remote-wsl)
• LTeX+ (optional for grammar checking)


# 11: INSTALL STARSHIP FOR SEEING PATHS AND BRANCHES IN THE TERMINAL (OPTIONAL)

## 11-01: INSTALL STARSHIP

curl -sS https://starship.rs/install.sh | sh

## 11-02: ADD STARSHIP TO THE SHELL CONFIG

sudo nano ~/.bashrc

Add the very end, add:
basheval "$(starship init bash)"

## 11-03: CONFIGURE STARSHIP TO SHOW FULL PATH * GIT BRANCH

mkdir -p ~/.config && nano ~/.config/starship.toml

In the file, add:
[directory]
truncation_length = 0    # 0 = no truncation, show full path
truncate_to_repo = false # don't shorten to the repo root

[git_branch]
format = "on [$symbol$branch]($style) "

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'

## 11-04: RELOAD SHELL

source ~/.bashrc


# 12: INSTALL NEWEST SYMFONY VERSION WITH FRANKENPHP

## 12-01: CREATE PROJECT DIRECTORY

mkdir -p frankenphp/conf.d


## 12-02: CREATE THE DOCKER FILE

• copy the template from docs/installation_guide/config_templates.txt to project_root/Dockerfile


## 12-03: CREATE THE COMPOSE FILES

• copy the template from docs/installation_guide/config_templates.txt to project_root/compose.yaml


## 12-04: CREATE ENVIRONMENT FILES

### understanding environment files

• in a production setting with no real environment variables, we have six env files
• .env: global template that holds no sensitive data such as credentials (commit = yes)
• .env.staging: config for the staging environment that inherits .env and overrides and expands it; does not hold sensitive data (commit = yes)
• .env.prod: config for the production environment that inherits .env and overrides and expands it; does not hold sensitive data (commit = yes)
• .env.local: config for the local environment that inherits .env and overrides and expands it; holds sensitive data such as credentials for local environment (commit = no)
• .env.staging.local: config for the staging environment that inherits .env and overrides and expands it; holds sensitive data such as credentials for local environment (commit = no)
• .env.prod.local: config for the production environment that inherits .env and overrides and expands it; holds sensitive data such as credentials for local environment (commit = no)
• the inheritance chain for .env.staging.local and .env.prod.local is te following .env -> .env.local -> env.staging/prod -> .env.staing/prod.local
• so .env.staging.local does not merely inherit from .env - it sits at the top of a stack that includes .env.staging and .env.local as well
• the same applies to .env.prod.local when APP_ENV=prod

EXAMPLE:
.env:
A = A
B = B
database_URL = postgresql://user:password@database_IP:database_port/app?serverVersion=server_version6&charset=charset"

.env.local:
A = B
C = C
DATABASE_URL="postgresql://root:12345@127.0.0.1:5432/app?serverVersion=16&charset=utf8"

all local variables:
A = B (overridden)
B = B (inherited from .env)
C = C (expanded)
DATABASE_URL="postgresql://root:12345@127.0.0.1:5432/app?serverVersion=16&charset=utf8"

.env.staging.
D = D

.env.staging.local:
DATABASE_URL="postgresql://root:6789@60.0.0.1:5432/app?serverVersion=16&charset=utf8"

all staging local variables:
A = B (inherited from .env.local)
B = B (inherited from .env.local)
C = C (inherited from .env.local)
D = D (inherited from .env.staging)
DATABASE_URL="postgresql://root:6789@60.0.0.1:5432/app?serverVersion=16&charset=utf8"

### copy the env files

• copy the template from docs/installation_guide/config_templates.txt to project_root/.env
• copy the template from docs/installation_guide/config_templates.txt to project_root/.env.local
• copy the template from docs/installation_guide/config_templates.txt to project_root/.env.prod
• copy the template from docs/installation_guide/config_templates.txt to project_root/.env.prod.local
• copy the template from docs/installation_guide/config_templates.txt to project_root/.env.staging
• copy the template from docs/installation_guide/config_templates.txt to project_root/.env.staging.local











# 13: REMOVE ALL BLOAT DEPENDENCIES
# 14: INSTALL ALL REQUIRED DEPENDENCIES & UPDATE THEM TO THE NEWEST VERSION
# 15: CONVERT ALL YAML CONFIG FILES TO PHP CONFIG FILES
# 16: AUTO-FORMAT ALL JSON FILES ACCORDING TO THE STYLE GUIDE
# 17: AUTO-FORMAT ALL PHP FILES ACCORDING TO THE STYLE GUIDE
# 18: CONFIGURE DOCTRINE ORM 3.6
# 19: CONFIGURE CACHE WITH PHPREDIS
# 20: CONFIGURE MYSQL
# 21: CONFIGURE MAILPIT
# 22: CONFIGURE GOTENBERG
# 23: CONFIGURE SYMFONY MESSENGER WITH REDIS STREAMS
# 24: CONFIGURE HEALTH CHECKS & SECURITY ENDPOINTS
# 25: TEST YOUR SOFTWARE COMPONENTS
# 26: COMMON ERRORS & TROUBLESHOOTING
# 27: COPY THE LIVE DATABASE INTO LOCAL WSL VIA BASH SCRIPT
# 28: UPDATE THE DATABASE TO THE NEWEST SQL VERSION AND FIX THE GEO DATA
# 29: AUTO-CREATE THE SRC/ENTITIES FROM THE DATABASE SCHEMA (OPTIONAL)