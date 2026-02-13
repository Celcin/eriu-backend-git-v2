# =============================================================================
# ERIU-BACKEND MAKEFILE
# =============================================================================
#
# This Makefile wraps docker compose commands with the correct --env-file flags so you never have to type them manually.
#
# -----------------------------------------------------------------------------
# ENVIRONMENT SELECTION
# -----------------------------------------------------------------------------
#
#   make <target>                 Dev (default)
#   make <target> env=staging     Staging
#   make <target> env=prod        Production
#
# -----------------------------------------------------------------------------
# HOW TO ADD NEW COMMANDS
# -----------------------------------------------------------------------------
#
# 1. For commands that run INSIDE the PHP container:
#
#      my_command:
#          $(EXEC) <your command here>
#
#    Example - run a custom script:
#
#      run_my_script:
#          $(EXEC) php scripts/my-script.php
#
# 2. For commands that run on the HOST (not in a container):
#
#      my_host_command:
#          <your command here>
#
#    Example - open a URL in the browser:
#
#      open_app:
#          xdg-open https://localhost
#
# 3. For commands that need ARGUMENTS passed through:
#
#      my_command:
#          $(EXEC) some-binary $(ARGS)
#
#    Then call it as: make my_command arg1 arg2
#
# 4. For commands targeting a SPECIFIC container (not PHP):
#
#      my_mysql_command:
#          $(DC) exec $(MYSQL) mysql -u root -p
#
# Remember to add your new target to the .PHONY list in its section!
#
# =============================================================================


# -----------------------------------------------------------------------------
# Environment Resolution
# -----------------------------------------------------------------------------

env ?= dev

ifeq ($(env),prod)
    PROFILE = prod
else ifeq ($(env),staging)
    PROFILE = staging
else
    PROFILE = dev
endif


# -----------------------------------------------------------------------------
# Env File Resolution
# -----------------------------------------------------------------------------

ENV_FILES = --env-file .env

ifneq (,$(wildcard .env.local))
    ENV_FILES += --env-file .env.local
endif

ifneq (,$(wildcard .env.$(env)))
    ENV_FILES += --env-file .env.$(env)
endif

ifneq (,$(wildcard .env.$(env).local))
    ENV_FILES += --env-file .env.$(env).local
endif


# -----------------------------------------------------------------------------
# Base Command and Service Names
# -----------------------------------------------------------------------------

EXEC = $(DC) exec -e PATH="/app/vendor/bin:$$PATH" -w /app $(PHP_SVC)
DC = docker compose $(ENV_FILES) --profile $(PROFILE)

# Service names (used by exec, run, logs)
ifeq ($(env),prod)
    PHP_SVC = eriu-backend-php-prod
else ifeq ($(env),staging)
    PHP_SVC = eriu-backend-php-staging
else
    PHP_SVC = eriu-backend-php
endif

MYSQL = eriu-backend-mysql
REDIS = eriu-backend-redis
GOTENBERG = eriu-backend-gotenberg
MAILPIT = eriu-backend-mailpit

# Argument passthrough for commands like: make install symfony/mailer
ARGS = $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))


# =============================================================================
# FILE SYSTEM / PERMISSIONS
# =============================================================================

.PHONY: root change_file_ownership fix_system_file_permissions fix_ownership_warning

## Print the project root path
## Usage: make root
root:
	@pwd

## Change file ownership to current user
## Usage: make change_file_ownership
change_file_ownership:
	sudo chown -R $(USER):$(USER) .

## Fix file permissions
## Usage: make fix_system_file_permissions
fix_system_file_permissions:
	chmod -R u+rw .

## Fix git safe.directory warning inside container
## Usage: make fix_ownership_warning
fix_ownership_warning:
	$(EXEC) git config --global --add safe.directory /app


# =============================================================================
# START CONTAINERS
# =============================================================================

.PHONY: start_containers start_php start_mysql start_redis start_gotenberg start_mailpit
.PHONY: start_containers_with_debug start_php_with_debug

## Start all containers
## Usage: make start_containers
start_containers:
	$(DC) up -d

## Start PHP container only
## Usage: make start_php
start_php:
	$(DC) up -d $(PHP_SVC)

## Start MySQL container only
## Usage: make start_mysql
start_mysql:
	$(DC) up -d $(MYSQL)

## Start Redis container only
## Usage: make start_redis
start_redis:
	$(DC) up -d $(REDIS)

## Start Gotenberg container only
## Usage: make start_gotenberg
start_gotenberg:
	$(DC) up -d $(GOTENBERG)

## Start Mailpit container only
## Usage: make start_mailpit
start_mailpit:
	$(DC) up -d $(MAILPIT)

## Start all containers with Xdebug enabled
## Usage: make start_containers_with_debug
start_containers_with_debug:
	XDEBUG_MODE=debug,develop $(DC) up -d

## Start PHP container with Xdebug enabled
## Usage: make start_php_with_debug
start_php_with_debug:
	XDEBUG_MODE=debug,develop $(DC) up -d $(PHP_SVC)


# =============================================================================
# STOP CONTAINERS
# =============================================================================

.PHONY: stop_containers stop_php stop_mysql stop_redis stop_gotenberg stop_mailpit

## Stop all containers
## Usage: make stop_containers
stop_containers:
	$(DC) down

## Stop PHP container only
## Usage: make stop_php
stop_php:
	$(DC) stop $(PHP_SVC)

## Stop MySQL container only
## Usage: make stop_mysql
stop_mysql:
	$(DC) stop $(MYSQL)

## Stop Redis container only
## Usage: make stop_redis
stop_redis:
	$(DC) stop $(REDIS)

## Stop Gotenberg container only
## Usage: make stop_gotenberg
stop_gotenberg:
	$(DC) stop $(GOTENBERG)

## Stop Mailpit container only
## Usage: make stop_mailpit
stop_mailpit:
	$(DC) stop $(MAILPIT)


# =============================================================================
# REBUILD
# =============================================================================

.PHONY: rebuild_project rebuild_project_with_cleared_cache fresh

## Rebuild containers after Dockerfile or compose.yaml changes
## Usage: make rebuild_project
rebuild_project:
	$(DC) down
	$(DC) up -d --build

## Rebuild with cleared cache (fixes caching errors)
## Usage: make rebuild_project_with_cleared_cache
rebuild_project_with_cleared_cache:
	$(DC) down
	$(DC) up -d --build --force-recreate

## Nuclear option: remove volumes, rebuild from scratch
## WARNING: Destroys all database data and Redis cache!
## Usage: make fresh
fresh:
	$(DC) down -v
	$(DC) build --no-cache
	$(DC) up -d


# =============================================================================
# SYMFONY / COMPOSER COMMANDS
# =============================================================================

.PHONY: run_console_command run_Symfony_command clear_cache

## Run a Symfony console command
## Usage: make run_console_command cache:clear
##        make run_console_command doctrine:migrations:migrate
##        make run_console_command debug:router
run_console_command:
	$(EXEC) php bin/console $(ARGS)

## Run a Composer command
## Usage: make run_Symfony_command require symfony/mailer
##        make run_Symfony_command update
run_Symfony_command:
	$(EXEC) composer $(ARGS)

## Clear the Symfony cache
## Usage: make clear_cache
clear_cache:
	$(EXEC) php bin/console cache:clear


# =============================================================================
# SHOW CONTAINERS AND LOGS
# =============================================================================

.PHONY: show_containers show_logs_all_containers
.PHONY: show_logs_php show_logs_database show_logs_redis show_logs_gotenberg show_logs_mailpit

## Show running containers
## Usage: make show_containers
show_containers:
	$(DC) ps

## Tail logs from all containers
## Usage: make show_logs_all_containers
show_logs_all_containers:
	$(DC) logs -f

## Tail PHP container logs
## Usage: make show_logs_php
show_logs_php:
	$(DC) logs -f $(PHP_SVC)

## Tail MySQL container logs
## Usage: make show_logs_database
show_logs_database:
	$(DC) logs -f $(MYSQL)

## Tail Redis container logs
## Usage: make show_logs_redis
show_logs_redis:
	$(DC) logs -f $(REDIS)

## Tail Gotenberg container logs
## Usage: make show_logs_gotenberg
show_logs_gotenberg:
	$(DC) logs -f $(GOTENBERG)

## Tail Mailpit container logs
## Usage: make show_logs_mailpit
show_logs_mailpit:
	$(DC) logs -f $(MAILPIT)


# =============================================================================
# SHOW VERSIONS
# =============================================================================

.PHONY: show_php show_Symfony show_mySQL show_redis show_gotenberg show_mailpit
.PHONY: show_XDEBUG show_Docker show_Docker_compose show_WSL verify_systemd

## Show PHP version
## Usage: make show_php
show_php:
	$(EXEC) php -v

## Show Symfony version
## Usage: make show_Symfony
show_Symfony:
	$(EXEC) php bin/console --version

## Show MySQL version
## Usage: make show_mySQL
show_mySQL:
	$(DC) exec $(MYSQL) mysql --version

## Show Redis version
## Usage: make show_redis
show_redis:
	$(DC) exec $(REDIS) redis-server --version

## Show Gotenberg version
## Usage: make show_gotenberg
show_gotenberg:
	$(DC) exec $(GOTENBERG) gotenberg --version

## Show Mailpit version
## Usage: make show_mailpit
show_mailpit:
	$(DC) exec $(MAILPIT) /mailpit version

## Show Xdebug status
## Usage: make show_XDEBUG
show_XDEBUG:
	@$(EXEC) php -v | grep -i xdebug || echo "Xdebug is not enabled"

## Show Docker version (host)
## Usage: make show_Docker
show_Docker:
	docker --version

## Show Docker Compose version (host)
## Usage: make show_Docker_compose
show_Docker_compose:
	docker compose version

## Show WSL status (host, Windows only)
## Usage: make show_WSL
show_WSL:
	wsl --status

## Verify systemd is running (host)
## Usage: make verify_systemd
verify_systemd:
	systemctl --version


# =============================================================================
# SHOW PACKAGES
# =============================================================================

.PHONY: show_packages show_direct_packages show_outdated_packages

## Show all installed packages
## Usage: make show_packages
show_packages:
	$(EXEC) composer show

## Show only direct dependencies
## Usage: make show_direct_packages
show_direct_packages:
	$(EXEC) composer show --direct

## Show outdated packages
## Usage: make show_outdated_packages
show_outdated_packages:
	$(EXEC) composer outdated


# =============================================================================
# INSTALL / REMOVE PACKAGES
# =============================================================================

.PHONY: install install_for_dev install_Symfony remove

## Install a package
## Usage: make install symfony/mailer
##        make install symfony/orm-pack
install:
	$(EXEC) composer require $(ARGS)

## Install a package as dev dependency
## Usage: make install_for_dev phpunit/phpunit
##        make install_for_dev symfony/debug-bundle
install_for_dev:
	$(EXEC) composer require --dev $(ARGS)

## Install Symfony skeleton into the project
## Usage: make install_Symfony
install_Symfony:
	$(DC) run --rm --no-deps --entrypoint="" $(PHP_SVC) \
		bash -c "composer create-project symfony/skeleton /tmp/symfony-temp --no-interaction \
		         && cp -rn /tmp/symfony-temp/. /app/"

## Remove a package
## Usage: make remove symfony/mailer
remove:
	$(EXEC) composer remove $(ARGS)


# =============================================================================
# UPDATE / UPGRADE DEPENDENCIES
# =============================================================================

.PHONY: update_dependencies upgrade_dependencies update upgrade

## Update all dependencies (respects version constraints)
## Usage: make update_dependencies
update_dependencies:
	$(EXEC) composer update

## Upgrade all dependencies (includes transitive dependencies)
## Usage: make upgrade_dependencies
upgrade_dependencies:
	$(EXEC) composer update --with-all-dependencies

## Update a specific package
## Usage: make update symfony/mailer
update:
	$(EXEC) composer update $(ARGS)

## Upgrade a specific package (includes its dependencies)
## Usage: make upgrade symfony/mailer
upgrade:
	$(EXEC) composer update --with-all-dependencies $(ARGS)


# =============================================================================
# CODE QUALITY - CONFIG TRANSFORMER
# =============================================================================

.PHONY: convert_YAML_to_PHP_files_dry_run convert_YAML_to_PHP_files

## Convert YAML config to PHP (dry run)
## Usage: make convert_YAML_to_PHP_files_dry_run
convert_YAML_to_PHP_files_dry_run:
	$(EXEC) vendor/bin/config-transformer --dry-run

## Convert YAML config to PHP
## Usage: make convert_YAML_to_PHP_files
convert_YAML_to_PHP_files:
	$(EXEC) vendor/bin/config-transformer


# =============================================================================
# CODE QUALITY - PHP CS FIXER
# =============================================================================

.PHONY: format_PHP_files_dry_run format_PHP_files

## Check code style (dry run)
## Usage: make format_PHP_files_dry_run
format_PHP_files_dry_run:
	$(EXEC) composer cs-dry

## Fix code style
## Usage: make format_PHP_files
format_PHP_files:
	$(EXEC) composer cs-fix


# =============================================================================
# VENDOR BINARIES (GENERIC)
# =============================================================================

## Run any vendor binary
## Usage: make vendor/bin/phpstan analyse src
##        make vendor/bin/rector process
vendor/bin/%:
	$(EXEC) $@ $(ARGS)


# =============================================================================
# SHELL ACCESS
# =============================================================================

.PHONY: shell shell_mysql shell_redis

## Open a bash shell in the PHP container
## Usage: make shell
shell:
	$(EXEC) bash

## Open a MySQL shell
## Usage: make shell_mysql
shell_mysql:
	$(DC) exec $(MYSQL) mysql -u eriu -p eriu

## Open a Redis CLI
## Usage: make shell_redis
shell_redis:
	$(DC) exec $(REDIS) redis-cli


# =============================================================================
# DEBUGGING / INFO
# =============================================================================

.PHONY: config env_info

## Print the fully resolved compose configuration
## Usage: make config
config:
	$(DC) config

## Show which environment, profile and env files are active
## Usage: make env_info
env_info:
	@echo "========================================"
	@echo " ERIU-BACKEND ENVIRONMENT"
	@echo "========================================"
	@echo " env:         $(env)"
	@echo " profile:     $(PROFILE)"
	@echo " php service: $(PHP_SVC)"
	@echo " env files:   $(ENV_FILES)"
	@echo "========================================"


# =============================================================================
# CLEANUP
# =============================================================================

.PHONY: prune

## Remove stopped containers, unused networks, dangling images
## Usage: make prune
prune:
	docker system prune -f


# =============================================================================
# HELP
# =============================================================================

.PHONY: help

## Show available commands
help:
	@echo ""
	@echo "Usage: make <target> [env=dev|staging|prod]"
	@echo ""
	@echo "FILE SYSTEM / PERMISSIONS"
	@echo "  root                                  Print project root path"
	@echo "  change_file_ownership                 sudo chown -R to current user"
	@echo "  fix_system_file_permissions           chmod -R u+rw"
	@echo "  fix_ownership_warning                 Fix git safe.directory warning"
	@echo ""
	@echo "START CONTAINERS"
	@echo "  start_containers                      Start all containers"
	@echo "  start_php                             Start PHP only"
	@echo "  start_mysql                           Start MySQL only"
	@echo "  start_redis                           Start Redis only"
	@echo "  start_gotenberg                       Start Gotenberg only"
	@echo "  start_mailpit                         Start Mailpit only"
	@echo "  start_containers_with_debug           Start all with Xdebug"
	@echo "  start_php_with_debug                  Start PHP with Xdebug"
	@echo ""
	@echo "STOP CONTAINERS"
	@echo "  stop_containers                       Stop all containers"
	@echo "  stop_php                              Stop PHP only"
	@echo "  stop_mysql                            Stop MySQL only"
	@echo "  stop_redis                            Stop Redis only"
	@echo "  stop_gotenberg                        Stop Gotenberg only"
	@echo "  stop_mailpit                          Stop Mailpit only"
	@echo ""
	@echo "REBUILD"
	@echo "  rebuild_project                       Rebuild containers"
	@echo "  rebuild_project_with_cleared_cache    Rebuild with cache cleared"
	@echo "  fresh                                 Nuclear rebuild (destroys data!)"
	@echo ""
	@echo "SYMFONY / COMPOSER"
	@echo "  run_console_command <cmd>             Run bin/console command"
	@echo "  run_Symfony_command <cmd>             Run composer command"
	@echo "  clear_cache                           Clear Symfony cache"
	@echo ""
	@echo "LOGS"
	@echo "  show_containers                       Show running containers"
	@echo "  show_logs_all_containers              Tail all logs"
	@echo "  show_logs_php                         Tail PHP logs"
	@echo "  show_logs_database                    Tail MySQL logs"
	@echo "  show_logs_redis                       Tail Redis logs"
	@echo "  show_logs_gotenberg                   Tail Gotenberg logs"
	@echo "  show_logs_mailpit                     Tail Mailpit logs"
	@echo ""
	@echo "VERSIONS"
	@echo "  show_php                              PHP version"
	@echo "  show_Symfony                          Symfony version"
	@echo "  show_mySQL                            MySQL version"
	@echo "  show_redis                            Redis version"
	@echo "  show_gotenberg                        Gotenberg version"
	@echo "  show_mailpit                          Mailpit version"
	@echo "  show_XDEBUG                           Xdebug status"
	@echo "  show_Docker                           Docker version"
	@echo "  show_Docker_compose                   Docker Compose version"
	@echo "  show_WSL                              WSL status"
	@echo "  verify_systemd                        Verify systemd"
	@echo ""
	@echo "PACKAGES"
	@echo "  show_packages                         All installed packages"
	@echo "  show_direct_packages                  Direct dependencies only"
	@echo "  show_outdated_packages                Outdated packages"
	@echo ""
	@echo "INSTALL / REMOVE"
	@echo "  install <pkg>                         composer require"
	@echo "  install_for_dev <pkg>                 composer require --dev"
	@echo "  install_Symfony                       Install Symfony skeleton"
	@echo "  remove <pkg>                          composer remove"
	@echo ""
	@echo "UPDATE / UPGRADE"
	@echo "  update_dependencies                   Update all dependencies"
	@echo "  upgrade_dependencies                  Upgrade all (with transitive)"
	@echo "  update <pkg>                          Update specific package"
	@echo "  upgrade <pkg>                         Upgrade specific package"
	@echo ""
	@echo "CODE QUALITY"
	@echo "  convert_YAML_to_PHP_files_dry_run     Config transformer dry run"
	@echo "  convert_YAML_to_PHP_files             Config transformer"
	@echo "  format_PHP_files_dry_run              PHP CS Fixer dry run"
	@echo "  format_PHP_files                      PHP CS Fixer"
	@echo "  vendor/bin/<cmd>                      Run any vendor binary"
	@echo ""
	@echo "SHELL ACCESS"
	@echo "  shell                                 Bash into PHP container"
	@echo "  shell_mysql                           MySQL shell"
	@echo "  shell_redis                           Redis CLI"
	@echo ""
	@echo "DEBUG"
	@echo "  config                                Show resolved compose config"
	@echo "  env_info                              Show active environment"
	@echo "  prune                                 Clean up Docker resources"
	@echo ""


# =============================================================================
# CATCH-ALL (must be last)
# =============================================================================

%:
	@: