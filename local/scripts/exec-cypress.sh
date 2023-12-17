#!/bin/bash

echo "Installing the assets (takes a while!)"
rm -rf "/dev_joomla/node_modules"
cd "/dev_joomla"
npm update

echo "Start creating cypress.config.js from Joomla configuration.php"
source  /dev_joomla/scripts/config-setup.sh

echo "Start Cypress"
cypress open --project /dev_joomla/tests --e2e

exit 1