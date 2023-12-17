#!/bin/bash
echo "Running web.sh"

cd "web-server"

echo ${cypress_base_url}

domain=${cypress_base_url}

real_config="tests/cypress.config.js"

# Prompt user for username
read -p "Enter your site username: " username

# Prompt user for password (-s for privacy)
read -p "Enter your site password: " password

# Update Cypress configuration file with the provided values
sed -i "s|url_replace|$domain|g; s/username_replace/$username/g; s/password_replace/$password/g" $real_config

echo "Username and password updated in cypress.config.js"

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