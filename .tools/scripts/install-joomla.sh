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
db_prefix='j__'

# Change the working directory
cd $root
echo -e " > Doing setup on ${root}"

if [ -f $root/administrator/cache/autoload_psr4.php ]; then
	rm -f $root/administrator/cache/autoload_psr4.php
fi

if [ -f $root/composer.json ]; then
	if [[ ! -d $root/libraries/vendor ]]; then
		echo -e " > Installing PHP dependencies"
		rm -rf $root/libraries/vendor
		composer install
	fi
fi

# Run npm
if [ -f $root/package.json ]; then
	echo "Cleaning the assets"
	rm -rf $root/node_modules
	rm -rf $root/administrator/components/com_media/node_modules
	rm -rf $root/media
	if [ ! -d $root/media/vendor ]; then
		echo -e " > Installing the assets (takes a while!)"
		mkdir -p $root/media/vendor
		npm ci
	fi
fi

# Install Joomla when no configuration file is available
if [[ -f $root/configuration.php ]]; then
	exit
fi

echo -e " > Setting up Joomla"

if [ ! -f $root/.htaccess ]; then
	cp $root/htaccess.txt $root/.htaccess
fi

# Setup configuration file
cp $(dirname $(dirname $0))/config/configuration.php $root/configuration.php
# Note: Don't use sed -i as Docker container image php-8.3, which uses Ubuntu 20.04.6 LTS, which uses GNU sed 4.7.
#       GNU sed 4.2 ... 4.7 incorrectly set umask on temporary files
#       sed: couldn't open temporary file: Permission denied
sed -e "s/{SITE}/$site/g" \
    -e "s/{DBHOST}/$dbHost/g" \
    -e "s/{DBNAME}/$dbName/g" \
	-e "s/{DBPREFIX}/$db_prefix/g" \
    -e "s/{SMTPHOST}/$smtpHost/g" \
    -e "s/{PATH}/${root//\//\\/}/g" \
    -e "s/{SECRET}/$secret/g" \
	$root/configuration.php > $TMP && cp $TMP $root/configuration.php

# Define install folder
installFolder=$root/installation
if [ ! -d $installFolder ]; then
	installFolder=$root/_installation
fi

# Install Joomla with cli

if [[ -z $dbHost || $dbHost == 'mysql'* ]]; then
	echo -e " > Create Joomla DB with mysql"

    # Note: Don't use sed -i as Docker container image php-8.3, which uses Ubuntu 20.04.6 LTS, which uses GNU sed 4.7.
    #       GNU sed 4.2 ... 4.7 incorrectly set umask on temporary files
    #       sed: couldn't open temporary file: Permission denied
	sed "s/{DBDRIVER}/mysqli/g" $root/configuration.php > $TMP && cp $TMP $root/configuration.php
	dbDriver='mysqli'

	echo -e " > Waiting for database server"
	while ! mysqladmin ping -u root -proot -h $dbHost --silent  > /dev/null; do
		sleep 4
	done

	echo -e " > Executing install scripts"

	# Create joomla DB
	mysql -u root -proot -h $dbHost -e "drop database if exists $dbName"
	mysql -u root -proot -h $dbHost -e "create database $dbName"
fi

if [[ $dbHost == 'postgres'* ]]; then
	echo -e " > Create Joomla DB with postgres"
	# Note: Don't use sed -i as Docker container image php-8.3, which uses Ubuntu 20.04.6 LTS, which uses GNU sed 4.7.
    #       GNU sed 4.2 ... 4.7 incorrectly set umask on temporary files
    #       sed: couldn't open temporary file: Permission denied
	sed "s/{DBDRIVER}/pgsql/g" $root/configuration.php > $TMP && cp $TMP $root/configuration.php
	dbDriver='pgsql'
	export PGPASSWORD=root

	# Clear existing connections
	psql -U root -h $dbHost -c "REVOKE CONNECT ON DATABASE $dbName FROM public" > /dev/null 2>&1
	psql -U root -h $dbHost -c "SELECT pid, pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$dbName' AND pid <> pg_backend_pid()" > /dev/null

	# Create joomla DB
	psql -U root -h $dbHost -c "drop database if exists $dbName" > /dev/null
	psql -U root -h $dbHost -c "create database $dbName" > /dev/null
fi

mv $root/configuration.php $root/configuration.bak

cp -r $root/installation $root/_installation

echo -e " > Installing Joomla via CLI"

php $root/installation/joomla.php install --site-name "${site}" --admin-user cy-admin --admin-password 'admin12345678' --admin-username Cy-Admin --admin-email cy-admin@example.local --db-type $dbDriver --db-host $dbHost --db-user root --db-pass root --db-name $dbName --db-prefix j_ --no-interaction -vvv

userId=$(mysql -u root -proot -h $dbHost -D $dbName -se "SELECT id FROM j_users where username='cy-admin'")

# Generate API tokenSeed and Bearer token
tokenSeed=$(openssl rand -base64 16)

php /usr/src/Projects/.tools/scripts/setup-api.php "$tokenSeed" "$secret" $userId "$site"

mysql -u root -proot -h $dbHost -D $dbName -e "INSERT INTO j_user_profiles (user_id, profile_key, profile_value) VALUES(${userId}, 'joomlatoken.token', '${tokenSeed}')"
mysql -u root -proot -h $dbHost -D $dbName -e "INSERT INTO j_user_profiles (user_id, profile_key, profile_value) VALUES(${userId}, 'joomlatoken.enabled', 1)"

mv $root/configuration.bak $root/configuration.php

# Add additional User

echo -e " > Add user Manager with --username manager and --password manager1234567 via CLI"

php $root/cli/joomla.php user:add --username manager --name Manager --password 'manager1234567' --email manager@example.local --usergroup Manager

echo -e " > Add user User with --username user and --password user1234567 via CLI"

php $root/cli/joomla.php user:add --username user --name User --password 'user1234567' --email user@example.local --usergroup Registered
