# TABLE OF CONTENT

• 01: introduction
• 02: container naming convention
• 03: install make for make terminal commands
• 04: fix Linux file system permissions
• 05: quick start/stop commands
• 06: check software component versions
• 07: check latest Symfony & FrankenPHP versions
• 08: cloning project to a new device
• 09: prerequisites and environment verification
• 10: install trusted certificates
• 11: install VSC extensions
• 12: install Stardust for seeing paths and branches in the terminal (optional)
• 13: install newest Symfony version with FrankenPHP
• 14: remove all bloat dependencies
• 15: install all required dependencies & update them to the newest version
• 16: convert all YAML config files to PHP config files
• 17: auto-format all JSON files according to the style guide
• 18: auto-format all PHP files according to the style guide
• 19: configure doctrine ORM 3.6
• 20: configure cache with phpredis
• 21: configure MySQL
• 22: configure Mailpit
• 23: configure Gotenberg
• 24: configure Symfony messenger with Redis streams
• 25: configure health checks & security endpoints
• 26: test your software components
• 27: common errors & troubleshooting
• 28: copy the live database into local WSL via bash script
• 29: update the database to the newest SQL version and fix the geo data
• 30: auto-create the src/entities from the database schema (optional)


# 01: INTRODUCTION

• this guide sets up a minimal Symfony 8 REST API backend with FrankenPHP and PHP 8.5
• no frontend, no Twig templates, no Node.js
• just a pure API foundation with Redis caching and Gotenberg for PDF generation


# 02: CONTAINER NAMING CONVENTION

• all containers use the prefix »eriu-backend-«


# 03: INSTALL AND CONFIGURE MAKE

## 03-01: INSTALL MAKE

sudo apt install make
make up will work


## 03-02: CONFIGURE SHELL

nano ~/.bashrc

Add the following:

m() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/Makefile" && -f "$dir/compose.yaml" ]]; then
            if [[ "$1" == "root" ]]; then
                cd "$dir"
                return
            fi
            make -C "$dir" --no-print-directory "$@"
            return
        fi
        dir="$(dirname "$dir")"
    done
    echo "Error: No Makefile found in any parent directory"
    return 1
}

## 03-03: RELOAD SHELL

source ~/.bashrc


# 04: FIX LINUX FILE SYSTEM PERMISSIONS

m change_file_ownership			➤ fix the file ownership errors inside WSL
m fix_system_file_permissions		➤ fix permission denied errors inside WSL
m fix_ownership_warning			➤ fix git file ownership warnings


# 05: QUICK START/STOP COMMANDS

## 05-01: START

m root					➤ go to project root
m start_containers			➤ start ALL containers
m start_php				➤ start only the PHP container
m start_mysql				➤ start only the MYSQL container
m start_redis				➤ start only the REDIS container
m start_gotenberg			➤ start only the GOTENBERG container
m start_mailpit				➤ start only the MAILPIT container

## 05-02: START WITH DEBUG

m start_containers_with_debug		➤ start ALL containers with XDEBUG
m start_php_with_debug			➤ start only the PHP container with XDEBUG
m start_mysql_with_debug		➤ start only the MYSQL container with XDEBUG
m start_redis_with_debug		➤ start only the REDIS container with XDEBUG
m start_gotenberg_with_debug		➤ start only the GOTENBERG container with XDEBUG
m start_mailpit_with_debug		➤ start only the MAILPIT container with XDEBUG

## 05-03: STOP

m stop_containers			➤ stop ALL containers
m stop_php				➤ stop only the PHP container
m stop_mysql				➤ stop only the MYSQL container
m stop_redis				➤ stop only the REDIS container
m stop_gotenberg			➤ stop only the GOTENBERG container
m stop_mailpit				➤ stop only the MAILPIT container

## 05-04: REBUILD CONTAINERS AFTER DOCKERFILE CHANGES

m rebuild_project			➤ rebuild all containers after the Dockerfile has changed
m rebuild_project_with_cleared_cache	➤ rebuild all containers without cache to fix caching errors
m fresh					➤ nuclear option: remove volumes, rebuild from scratch - WARNING: destroys all database data and Redis cache!

## 05-05: SHOW RUNNING CONTAINERS

m show_containers			➤ show the status and health of ALL containers

## 05-06: SHOW LOGS FILES

m show_logs_all_containers		➤ show the logs of ALL containers
m show_logs_php				➤ show the logs of only the PHP container
m show_logs_database			➤ show the logs of only the MYSQL container
m show_logs_redis			➤ show the logs of only the REDIS container
m show_logs_gotenberg			➤ show the logs of only the GOTENBERG container
m show_logs_mailpit			➤ show the logs of only the MAILPIT container


# 06: CHECK SOFTWARE COMPONENT VERSIONS

m show_php				➤ show the PHP version
m show_Symfony				➤ show the SYMFONY version
m show_mySQL				➤ show the MYSQL version
m show_redis				➤ show the REDIS version
m show_gotenberg			➤ show the GOTENBERG version
m show_mailpit				➤ show the MAILPIT version
m show_XDEBUG				➤ show the XDEBUG version
m show_Docker				➤ show the DOCKER version
m show_Docker_compose			➤ show the DOCKER COMPOSE version


# 07: CHECK LATEST SYMFONY & FRANKENPHP VERSIONS

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


# 08: CLONING PROJECT TO A NEW DEVICE

1: clone the repository
2: clone ".env.local", ".env.staging.local" and ".env.prod.local" from an existing project into the project root folder
3: start containers

m start_containers

• Caddy auto-generates SSL certificates for localhost
• if you previously set up mkcert certificates, you will also need to run "mkcert -install" and regenerate certificates (step 09)
• when cloning an existing project (that already has Symfony installed), you can start all containers directly
• the phased approach in step 11 is only needed for initial setup


# 09: PREREQUISITES AND ENVIRONMENT VERIFICATION

m show_Docker				➤ show the DOCKER version
m show_Docker_compose			➤ show the DOCKER COMPOSE version
wsl --status				➤ in PowerShell: confirms WSL 2.x
m verify_systemd			➤ check if systemd is enabled for proper Docker integration


# 10: INSTALL TRUSTED CERTIFICATES

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


# 11: INSTALL VSC EXTENSIONS

• PHP Debug (xdebug.php-debug) → Required for Xdebug
• PHP Intelephense (bmewburn.vscode-intelephense-client)
• Docker (ms-azuretools.vscode-docker)
• WSL (ms-vscode-remote.remote-wsl)
• LTeX+ (optional for grammar checking)


# 12: INSTALL STARSHIP FOR SEEING PATHS AND BRANCHES IN THE TERMINAL (OPTIONAL)

## 12-01: INSTALL STARSHIP

curl -sS https://starship.rs/install.sh | sh

## 12-02: ADD STARSHIP TO THE SHELL CONFIG

sudo nano ~/.bashrc

Add the very end, add:
basheval "$(starship init bash)"

## 12-03: CONFIGURE STARSHIP TO SHOW FULL PATH * GIT BRANCH

mkdir -p ~/.config && nano ~/.config/starship.toml

In the file, add:
[directory]
truncation_length = 0    # 0 = no truncation, show full path
truncate_to_repo = false # don't shorten to the repo root

[git_branch]
format = "on [$symbol$branch]($style) "

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'

## 12-04: RELOAD SHELL

source ~/.bashrc


# 13: INSTALL NEWEST SYMFONY VERSION WITH FRANKENPHP

## 13-01: CREATE PROJECT DIRECTORY

m root
mkdir -p frankenphp/conf.d


## 13-02: CREATE THE DOCKER FILE

• copy the template from docs/installation_guide/config_templates.txt to project_root/Dockerfile


## 13-03: CREATE THE COMPOSE FILES

• copy the template from docs/installation_guide/config_templates.txt to project_root/compose.yaml


## 13-04: CREATE ENVIRONMENT FILES

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


## 13-05: CREATE THE PHP CONFIG FILES

• copy the template from docs/installation_guide/config_templates.txt to project_root/frankenphp/conf.d/app.ini
• copy the template from docs/installation_guide/config_templates.txt to project_root/frankenphp/conf.d/app.dev.ini
• copy the template from docs/installation_guide/config_templates.txt to project_root/frankenphp/conf.d/xdebug.ini


## 13-06: CREATE THE CADDYFILE (REST API OPTIMIZED)

• copy the template from docs/installation_guide/config_templates.txt to project_root/frankenphp/Caddyfile


## 13-07: CREATE THE DOCKER ENTRYPOINT SCRIPT

• copy the template from docs/installation_guide/config_templates.txt to project_root/frankenphp/docker-entrypoint.sh
• make the script executable:

chmod +x frankenphp/docker-entrypoint.sh


## 13-08: BUILD AND INSTALL SYMFONY

• the PHP container depends on the database and Redis containers being healthy
• to avoid chicken-and-egg (start/shutdown/start loop) problems during initial setup, we use a phased approach


### phase 1: start database and redis

• the PHP container depends on both database AND redis being healthy
• both services must be running before starting the PHP container

#### build images first (without starting)

m root
m rebuild_project

#### start database and redis (IMPORTANT: Do NOT run "m start_containers" yet - only start these services!)

m start_mysql
m start_redis

#### wait until BOTH services show "healthy" status

• eriu-backend-database: may take 30-60 seconds
• eriu-backend-redis: usually ready within 10 seconds


### phase 2: install Symfony using a temporary folder

• since the folder Symfony is installed in must be empty but our project root already holds the Git and config files, we will use an empty temp folder for the installation
• after installation, move the Symfony files into the project root

#### create Symfony project in /tmp, copy to /app (installs the LATEST Symfony version and overwrites any placeholders)

m install_Symfony

#### after installation completes, verify Symfony was installed:

ls -la

You should see: bin/, config/, public/, src/, var/, vendor/, composer.json, etc.

#### verify index.php is the real Symfony front controller (not placeholder)

head -5 public/index.php

Should show: use App\Kernel;


### phase 3: start all containers

#### start all containers

m start_containers

#### verify all containers are running and healthy

m show_containers

#### verify installed versions

m show_php
m show_Symfony

### troubleshooting: if PHP container still restarts

If the PHP container keeps restarting, check the logs:

docker compose logs php

common issues:
• Database not ready: Wait longer or check database logs with »docker compose logs database«
• Permission issues: Run »sudo chown -R $USER:$USER .« in the project directory
• Port conflicts: Check if ports 80, 443, or 3307 are already in use


### troubleshooting: placeholder instead of real app

If you see the "Symfony not installed yet" JSON response after installation, the real »index.php« was not copied.
This can happen if you accidentally ran »docker compose up -d« before completing Phase 2.


## 13-09: ADD XDEBUG LAUNCH CONFIGURATION FOR VSC

• copy the template from docs/installation_guide/config_templates.txt to project_root/.vscode/launch.json


## 13-10: CREATE GITIGNORE

• copy the template from docs/installation_guide/config_templates.txt to project_root/.gitignore


## 13-11: CLEAR CACHE AND TEST

### clear cache

m clear_cache

### test basic connectivity

curl -k https://localhost

You should see a 404 or welcome page (Symfony is running, just no routes yet)


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