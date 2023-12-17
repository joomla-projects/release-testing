#!/bin/bash
cd "local"

echo "Cleaning up the old containers"
docker compose down --volumes

# if [ ! -d "./www" ]; then
	# echo "Creating Joomla folder"
	# mkdir -p "./www"
# fi

# echo "permissions to write in Joomla folder"
# chmod 777 ./www
# echo "Remove Joomla folder"
# rm -rf "./www/*"

# echo "Start creating cypress.config.js from Joomla configuration.php"
# source  /dev_joomla/scripts/config-setup.sh

echo "Creating fresh containers and start"
docker compose up --force-recreate