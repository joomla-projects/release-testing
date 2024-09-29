#!/bin/bash
# @package    Joomla E2E Test Suite
# 
# @author     Charvi Mehra <https://github.com/charvimehradu>, Martina Scholz <https://github.com/LadySolveig>
#
# @copyright  (C) 2024 Open Source Matters, Inc. <http://www.joomla.org>
# @license    GNU General Public License version 2 or later; see LICENSE.txt

# Temporary file that is deleted when the script is terminated
TMP=/tmp/$(basename $0).$$
trap 'rm -rf $TMP' 0

# Setup root directory
root=$1
dbName=$2
site=$3
smtpHost=$4

dbHost='mysql'
dbDriver='mysqli'
secret=$(openssl rand -hex 8)

# Read database credentials from configuration.php
CONFIG_FILE="${root}/configuration.php"

# Change the working directory
cd $root
echo -e " > Doing setup on ${root}"

if [ -f $root/administrator/cache/autoload_psr4.php ]; then
	rm -f $root/administrator/cache/autoload_psr4.php
fi

# Install Joomla when no configuration file is available
if [[ ! -f $CONFIG_FILE ]]; then
	echo -e " > Set up site for testing not possible, no configuration.php available!"
    exit
fi

# Setup configuration file
cp $root/configuration.php $root/configuration.php.bak
cp $(dirname $(dirname $0))/config/configuration.php $root/configuration.php

DB_SITENAME_LINE=$(grep -oPi 'public \$sitename = ([^;]+);' $root/configuration.php.bak | cut --complement -c 1-20)
DB_PREFIX_LINE=$(grep -oPi 'public \$dbprefix = ([^;]+);' $root/configuration.php.bak | cut --complement -c 1-20)
DB_NAME_LINE=$(grep -oPi 'public \$db = ([^;]+);' $root/configuration.php.bak | cut --complement -c 1-14)

sitename=${DB_SITENAME_LINE:0:-2}
db_prefix=${DB_PREFIX_LINE:0:-2}
db_name=${DB_NAME_LINE:0:-2}

rm -f $root/configuration.php.bak

# Note: Don't use sed -i as Docker container image php-8.3, which uses Ubuntu 20.04.6 LTS, which uses GNU sed 4.7.
#       GNU sed 4.2 ... 4.7 incorrectly set umask on temporary files
#       sed: couldn't open temporary file: Permission denied
sed -e "s/{SITE}/${sitename:-$site}/g" \
    -e "s/{DBHOST}/$dbHost/g" \
    -e "s/{DBNAME}/${db_name:-$dbName}/g" \
    -e "s/{SMTPHOST}/$smtpHost/g" \
    -e "s/{PATH}/${root//\//\\/}/g" \
    -e "s/{SECRET}/$secret/g" \
    -e "s/{DBPREFIX}/${db_prefix:-'j__'}/g" \
	$root/configuration.php > $TMP && cp $TMP $root/configuration.php

if [[ -z $dbHost || $dbHost == 'mysql'* ]]; then
    echo -e " > Set DB driver to mysqli"
    # Note: Don't use sed -i as Docker container image php-8.3, which uses Ubuntu 20.04.6 LTS, which uses GNU sed 4.7.
    #       GNU sed 4.2 ... 4.7 incorrectly set umask on temporary files
    #       sed: couldn't open temporary file: Permission denied
	sed "s/{DBDRIVER}/mysqli/g" $root/configuration.php > $TMP && cp $TMP $root/configuration.php
	dbDriver='mysqli'

    if [[ -f $root/db_mysql_restore.sql ]]; then
        echo -e " > Restore MySQL database from dump"
        # Create joomla DB
	    mysql --defaults-extra-file=<(echo $'[client]\npassword='"root") -u root -h $dbHost -e "drop database if exists $db_name"
	    mysql --defaults-extra-file=<(echo $'[client]\npassword='"root") -u root -h $dbHost -e "create database $db_name"
        mysql --defaults-extra-file=<(echo $'[client]\npassword='"root") -u root -h $dbHost -D $db_name < $root/db_mysql_restore.sql
        rm -f $root/db_mysql_restore.sql
    fi
fi

if [[ $dbHost == 'postgres'* ]]; then
	echo -e " > Set DB driver to pgsql"
	# Note: Don't use sed -i as Docker container image php-8.3, which uses Ubuntu 20.04.6 LTS, which uses GNU sed 4.7.
    #       GNU sed 4.2 ... 4.7 incorrectly set umask on temporary files
    #       sed: couldn't open temporary file: Permission denied
	sed "s/{DBDRIVER}/pgsql/g" $root/configuration.php > $TMP && cp $TMP $root/configuration.php
	dbDriver='pgsql'
fi

# Add additional Super User

echo -e " > Add user Cy-Admin with --username cy-admin and --password admin12345678 via CLI"

php $root/cli/joomla.php user:add --username cy-admin --name Cy-Admin --password 'admin12345678' --email cy-admin@example.local --usergroup 'Super Users'

userId=$(mysql -u root -proot -h $dbHost -D $db_name -se "SELECT id FROM ${db_prefix:-'j__'}users where username='cy-admin'")

# Generate API tokenSeed and Bearer token
tokenSeed=$(openssl rand -base64 16)

php /usr/src/Projects/.tools/scripts/setup-api.php "$tokenSeed" "$secret" $userId "$site"

mysql --defaults-extra-file=<(echo $'[client]\npassword='\"root\") -u root -h $dbHost -D $db_name -e "INSERT INTO ${db_prefix:-'j__'}user_profiles (user_id, profile_key, profile_value) VALUES(${userId}, 'joomlatoken.token', '${tokenSeed}') ON DUPLICATE KEY UPDATE profile_value = '${tokenSeed}'"
mysql --defaults-extra-file=<(echo $'[client]\npassword='\"root\") -u root -h $dbHost -D $db_name -e "INSERT INTO ${db_prefix:-'j__'}user_profiles (user_id, profile_key, profile_value) VALUES(${userId}, 'joomlatoken.enabled', 1) ON DUPLICATE KEY UPDATE profile_value = 1"

echo "Configuration updated successfully!"
