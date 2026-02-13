m root					➤ go to project root
m change_file_ownership			➤ fix the file ownership errors inside WSL
m fix_system_file_permissions		➤ fix permission denied errors inside WSL
m fix_ownership_warning			➤ fix git file ownership warnings
m verify_systemd			➤ check if systemd is enabled for proper Docker integration

m start_containers			➤ start ALL containers
m start_php				➤ start only the PHP container
m start_mysql				➤ start only the MYSQL container
m start_redis				➤ start only the REDIS container
m start_gotenberg			➤ start only the GOTENBERG container
m start_mailpit				➤ start only the MAILPIT container

m start_containers_with_debug		➤ start ALL containers with XDEBUG
m start_php_with_debug			➤ start only the PHP container with XDEBUG
m start_mysql_with_debug		➤ start only the MYSQL container with XDEBUG
m start_redis_with_debug		➤ start only the REDIS container with XDEBUG
m start_gotenberg_with_debug		➤ start only the GOTENBERG container with XDEBUG
m start_mailpit_with_debug		➤ start only the MAILPIT container with XDEBUG

m stop_containers			➤ stop ALL containers
m stop_php				➤ stop only the PHP container
m stop_mysql				➤ stop only the MYSQL container
m stop_redis				➤ stop only the REDIS container
m stop_gotenberg			➤ stop only the GOTENBERG container
m stop_mailpit				➤ stop only the MAILPIT container

m rebuild_project			➤ rebuild all containers after the Dockerfile has changed
m rebuild_project_with_cleared_cache	➤ rebuild all containers without cache to fix caching errors
m fresh					➤ nuclear option: remove volumes, rebuild from scratch - WARNING: destroys all database data and Redis cache!

m show_containers			➤ show the status and health of ALL containers
m show_php				➤ show the PHP version
m show_Symfony				➤ show the SYMFONY version
m show_mySQL				➤ show the MYSQL version
m show_redis				➤ show the REDIS version
m show_gotenberg			➤ show the GOTENBERG version
m show_mailpit				➤ show the MAILPIT version
m show_XDEBUG				➤ show the XDEBUG version
m show_Docker				➤ show the DOCKER version
m show_Docker_compose			➤ show the DOCKER COMPOSE version
m show_WSL				➤ show the WSL version

m show_logs_all_containers		➤ show the logs of ALL containers
m show_logs_php				➤ show the logs of only the PHP container
m show_logs_database			➤ show the logs of only the MYSQL container
m show_logs_redis			➤ show the logs of only the REDIS container
m show_logs_gotenberg			➤ show the logs of only the GOTENBERG container
m show_logs_mailpit			➤ show the logs of only the MAILPIT container

m show_packages				➤ show a list of ALL installed packages/dependencies
m show_direct_packages			➤ show a list of only DIRECT installed packages/dependencies
m show_outdated_packages		➤ show a list of only OUTDATED installed packages/dependencies

m install <package name>		➤ install a package system wide
m install_for_dev <package name>	➤ install a package for dev system only

m update_dependencies			➤ update ALL packages to their latest version within their version constraints boundaries
m upgrade_dependencies			➤ upgrade ALL packages to their latest version (WARNING: upgrades to the latest major release!)

m update <package name>			➤ update only the given package to its latest version within their version constraints boundaries
m upgrade <package name>		➤ upgrade only the given package to its latest version (WARNING: upgrades to the latest major release!)

m remove <package name>			➤ remove/deinstall the given package

m install_Symfony			➤ install Symfony in the latest version

m convert_YAML_to_PHP_files_dry_run	➤ convert all package YAML config files to PHP config files without actually changing them (just see the preview)
m convert_YAML_to_PHP_files		➤ convert all package YAML config files to PHP config files

m format_PHP_files_dry_run		➤ let the autoformatter run over all PHP files and format them according to the rules specified in the config file (just preview)
m format_PHP_files			➤ let the autoformatter run over all PHP files and format them according to the rules specified in the config file

m run_console_command <command>		➤ run one specfic console command
m run_Symfony_command <command>		➤ run one specific Symfony command
m clear_cache				➤ clear the cache

m env_info				➤ show info about the currently loaded env
m config				➤ show current env config