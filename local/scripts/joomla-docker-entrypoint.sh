#!/bin/bash
set -e

uid="$(id -u)"
gid="$(id -g)"
if [ "$uid" = '0' ]; then
        case "$1" in
        apache2*)
                user="${APACHE_RUN_USER:-www-data}"
                group="${APACHE_RUN_GROUP:-www-data}"

                # strip off any '#' symbol ('#1000' is valid syntax for Apache)
                pound='#'
                user="${user#$pound}"
                group="${group#$pound}"

                # set user if not exist
                if ! id "$user" &>/dev/null; then
                        # get the user name
                        : "${USER_NAME:=www-data}"
                        # change the user name
                        [[ "$USER_NAME" != "www-data" ]] &&
                                usermod -l "$USER_NAME" www-data &&
                                groupmod -n "$USER_NAME" www-data
                        # update the user ID
                        groupmod -o -g "$user" "$USER_NAME"
                        # update the user-group ID
                        usermod -o -u "$group" "$USER_NAME"
                fi
                ;;
        *) # php-fpm
                user='www-data'
                group='www-data'
                ;;
        esac
else
        user="$uid"
        group="$gid"
fi

if [ -n "$MYSQL_PORT_3306_TCP" ]; then
        if [ -z "$JOOMLA_DB_HOST" ]; then
                JOOMLA_DB_HOST='mysql'
        else
                echo >&2 "warning: both JOOMLA_DB_HOST and MYSQL_PORT_3306_TCP found"
                echo >&2 "  Connecting to JOOMLA_DB_HOST ($JOOMLA_DB_HOST)"
                echo >&2 "  instead of the linked mysql container"
        fi
fi

if [ -z "$JOOMLA_DB_HOST" ]; then
        echo >&2 "error: missing JOOMLA_DB_HOST and MYSQL_PORT_3306_TCP environment variables"
        echo >&2 "  Did you forget to --link some_mysql_container:mysql or set an external db"
        echo >&2 "  with -e JOOMLA_DB_HOST=hostname:port?"
        exit 1
fi

# If the DB user is 'root' then use the MySQL root password env var
: "${JOOMLA_DB_USER:=root}"
if [ "$JOOMLA_DB_USER" = 'root' ]; then
        : ${JOOMLA_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi
: "${JOOMLA_DB_NAME:=joomla}"

if [ -z "$JOOMLA_DB_PASSWORD" ] && [ "$JOOMLA_DB_PASSWORD_ALLOW_EMPTY" != 'yes' ]; then
        echo >&2 "error: missing required JOOMLA_DB_PASSWORD environment variable"
        echo >&2 "  Did you forget to -e JOOMLA_DB_PASSWORD=... ?"
        echo >&2
        echo >&2 "  (Also of interest might be JOOMLA_DB_USER and JOOMLA_DB_NAME.)"
        exit 1
fi

if [ ! -e index.php ] && [ ! -e libraries/src/Version.php ] && [ "$RESTORE" = true ]; then
         echo >&2 "Joomla not found in $PWD - searching for a backup archive (zip)..."
        
       shopt -s nullglob

        files=( joomla-backup/*.zip )

        if [ ! -z ${files[0]} ]; then
          echo >&2 "${files[0]}"
          FOUNDBACKUP=true
          unzip ${files[0]} -d ./jbak
          mv ./jbak/*/* .
          rm -r ./jbak

          CONFIG_FILE="configuration.php"

          DB_SITENAME_LINE=$(grep -oPi 'public \$sitename = ([^;]+);' $CONFIG_FILE | cut --complement -c 1-20)
          DB_NAME_LINE=$(grep -oPi 'public \$db = ([^;]+);' $CONFIG_FILE | cut --complement -c 1-14)
          DB_PREFIX_LINE=$(grep -oPi 'public \$dbprefix = ([^;]+);' $CONFIG_FILE | cut --complement -c 1-20)

          db_sitename=${DB_SITENAME_LINE:0:-2}
          db_name=${DB_NAME_LINE:0:-2}
          db_prefix=${DB_PREFIX_LINE:0:-2}

          mv configuration.php configuration.php.bak

          cp ${ROOT}/scripts/configuration.php configuration.php

          # Replace lines in the real config file with data from configuration.php
          sed -i "s/{SITE}/$db_sitename/g; s/{DBNAME}/$db_name/g; s/{DBPREFIX}/$db_prefix/g;" $CONFIG_FILE

          if [ -f .htaccess ]; then
                mv .htaccess .htaccess.bak
          fi
          mv htaccess.txt .htaccess

          cp configuration.php ./joomla-backup/configuration.php
        fi

        # if the directory exists and Joomla doesn't appear to be installed change permissions
        chown -R www-data:www-data .
        chown -R '1000:1000' ./joomla-backup
fi
        

if [ ! -e index.php ] && [ ! -e libraries/src/Version.php ]; then

        echo >&2 "Joomla not found in $PWD - copying now..."
        if [ "$(ls -A)" ]; then
                echo >&2 "WARNING: $PWD is not empty - press Ctrl+C now if this is an error!"
                (
                        set -x
                        ls -A
                        sleep 10
                )
        fi
        # use full commands
        # for clearer intent
        sourceTarArgs=(
                --create
                --file -
                --directory /usr/src/joomla
                --one-file-system
                --owner "$user" --group "$group"
        )
        targetTarArgs=(
                --extract
                --file -
        )
        if [ "$uid" != '0' ]; then
                # avoid "tar: .: Cannot utime: Operation not permitted" and "tar: .: Cannot change mode to rwxr-xr-x: Operation not permitted"
                targetTarArgs+=(--no-overwrite-dir)
        fi

        tar "${sourceTarArgs[@]}" . | tar "${targetTarArgs[@]}"

        if [ ! -e .htaccess ]; then
                # NOTE: The "Indexes" option is disabled in the php:apache base image so remove it as we enable .htaccess
                sed -r 's/^(Options -Indexes.*)$/#\1/' htaccess.txt >.htaccess
                chown "$user":"$group" .htaccess
        fi

        if [ -e configuration.php ] ; then
                echo >&2 "configuration file found $PWD"
                sed -i 's/^.*\$user.*$/    public \$user = '${JOOMLA_DB_USER}'/' configuration.php
                sed -i 's/^.*\$password.*$/    public \$password = '${JOOMLA_DB_PASSWORD}'/' configuration.php
                sed -i 's/^.*\$dbprefix.*$/    public \$dbprefix = '${JOOMLA_DB_PREFIX}'/' configuration.php
        fi

        # if the directory exists and Joomla doesn't appear to be installed change permissions
        chown -R www-data:www-data .

        echo >&2 "Complete! Joomla has been successfully copied to $PWD"
fi

# Ensure the MySQL Database is created
php ${ROOT}/scripts/makedb.php "$JOOMLA_DB_HOST" "$JOOMLA_DB_USER" "$JOOMLA_DB_PASSWORD" "$JOOMLA_DB_NAME" "${JOOMLA_DB_TYPE:-mysqli}"

# Basic email regex for validation
email_regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

# Function to validate environment variables
validate_vars() {
        echo >&2 "DB - Vars Validation!"
        # Check if JOOMLA_SITE_NAME is longer than 2 characters
        if [[ "${#JOOMLA_SITE_NAME}" -le 2 ]]; then
                echo >&2 "Error: JOOMLA_SITE_NAME must be longer than 2 characters!"
                return 1
        fi

        # Check if JOOMLA_ADMIN_USER is longer than 2 characters
        if [[ "${#JOOMLA_ADMIN_USER}" -le 2 ]]; then
                echo >&2 "Error: JOOMLA_ADMIN_USER must be longer than 2 characters!"
                return 1
        fi

        # Check if JOOMLA_ADMIN_USERNAME has no spaces, and is only alphabetical
        if [[ "${JOOMLA_ADMIN_USERNAME}" =~ [^a-zA-Z] ]]; then
                echo >&2 "Error: JOOMLA_ADMIN_USERNAME must contain no spaces and be only alphabetical!"
                return 1
        fi

        # Check if JOOMLA_ADMIN_PASSWORD is longer than 12 characters
        if [[ "${#JOOMLA_ADMIN_PASSWORD}" -le 12 ]]; then
                echo >&2 "Error: JOOMLA_ADMIN_PASSWORD must be longer than 12 characters!"
                return 1
        fi

        # Check if JOOMLA_ADMIN_EMAIL is a valid email
        if [[ ! "${JOOMLA_ADMIN_EMAIL}" =~ $email_regex ]]; then
                echo >&2 "Error: JOOMLA_ADMIN_EMAIL must be a valid email address!"
                return 1
        fi

        # If all checks passed, return 0
        return 0
}

# Function to check that auto deploy can be done
can_auto_deploy() {
        echo >&2 "Start can autodeploy check"
        # Check if all NEEDED variables exist
        if [[ -n "${JOOMLA_SITE_NAME}" && -n "${JOOMLA_ADMIN_USER}" &&
                -n "${JOOMLA_ADMIN_USERNAME}" && -n "${JOOMLA_ADMIN_PASSWORD}" &&
                -n "${JOOMLA_ADMIN_EMAIL}" ]]; then

                # All variables exist. Now validate them.
                if validate_vars; then
                        # If all checks passed, return 0
                        return 0
                fi
        fi

        # If any needed variables does not exist fail, return 1
        echo >&2 "No autodeploy possible"
        echo >&2 "Sitename: ${JOOMLA_SITE_NAME}"
        echo >&2 "JOOMLA_ADMIN_USER: ${JOOMLA_ADMIN_USER}"
        echo >&2 "JOOMLA_ADMIN_USERNAME: ${JOOMLA_ADMIN_USERNAME}"
        echo >&2 "JOOMLA_ADMIN_PASSWORD: ${JOOMLA_ADMIN_PASSWORD}"
        echo >&2 "JOOMLA_ADMIN_EMAIL: ${JOOMLA_ADMIN_EMAIL}"
        return 1
}

# if the directory exists and we can auto deploy
if [ -d installation ] && [ -e installation/joomla.php ] && can_auto_deploy; then
        echo >&2 "Directory exists and installation is present"
        # use full commands
        # for clearer intent
        installJoomlaArgs=(
                --site-name="${JOOMLA_SITE_NAME}"
                --admin-email="${JOOMLA_ADMIN_EMAIL}"
                --admin-username="${JOOMLA_ADMIN_USERNAME}"
                --admin-user="${JOOMLA_ADMIN_USER}"
                --admin-password="${JOOMLA_ADMIN_PASSWORD}"
                --db-type="${JOOMLA_DB_TYPE:-mysqli}"
                --db-host="${JOOMLA_DB_HOST}"
                --db-name="${JOOMLA_DB_NAME}"
                --db-pass="${JOOMLA_DB_PASSWORD}"
                --db-user="${JOOMLA_DB_USER}"
                --db-prefix="${JOOMLA_DB_PREFIX:-joom_}"
                --db-encryption=0
        )

        php installation/joomla.php install "${installJoomlaArgs[@]}"

        # Check the exit status of the PHP command
        if [ $? -eq 0 ]; then
                # The PHP command succeeded (so we remove the installation folder)
                rm -rf installation

                echo >&2 "========================================================================"
                echo >&2
                echo >&2 "This server is now configured to run Joomla!"
                echo >&2
                echo >&2 "========================================================================"

                cp configuration.php ./joomla-backup/configuration.php
        else
                echo >&2 "========================================================================"
                echo >&2
                echo >&2 "This server is now configured to run Joomla!"
                echo >&2
                echo >&2 "NOTE: You will need your database server address, database name,"
                echo >&2 "and database user credentials to install Joomla."
                echo >&2
                echo >&2 "========================================================================"
        fi
else
        echo >&2 "========================================================================"
        echo >&2
        echo >&2 "This server is now configured to run Joomla!"
        echo >&2
        echo >&2 "NOTE: You will need your database server address, database name,"
        echo >&2 "and database user credentials to install Joomla."
        echo >&2
        echo >&2 "========================================================================"
fi

exec "$@"