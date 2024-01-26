#!/bin/bash
echo "Running web.sh"

cd "web-server"

echo ${cypress_base_url}

domain=${cypress_base_url}

real_config="tests/cypress.config.js"

# Prompt user for username
read -p "Enter your site username: " username

# Prompt user for password (-s for privacy)
read -s -p "Enter your site password: " password

echo ""
echo "Cleaning up the old containers"
docker compose down --volumes

echo "Creating fresh containers and start"
ROOT=$ROOT USERNAME=$username PASSWORD=$password DOMAIN=$domain docker compose -f $(dirname $0)/docker-compose.yml up --force-recreate