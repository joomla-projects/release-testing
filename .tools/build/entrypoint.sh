#!/bin/bash
# @package    Joomla E2E Test Suite
#
# @author     Charvi Mehra <https://github.com/charvimehradu>, Martina Scholz <https://github.com/LadySolveig>
#
# @copyright  (C) 2024 Open Source Matters, Inc. <http://www.joomla.org>
# @license    GNU General Public License version 2 or later; see LICENSE.txt

set -ex

WORKDIR="/e2e"
TOOLS_ROOT="/usr/src/Projects/.tools"

# Load environment variables from .env file
if [ -f $TOOLS_ROOT/.env ]; then
    # Load Environment Variables
    export $(cat $TOOLS_ROOT/.env | grep -v '#' | sed 's/\r$//' | awk '/=/ {print $1}' )
fi

# Load variables from .secret file
if [ -f $TOOLS_ROOT/.secret ]; then
    # Load Environment Variables - API-Token
    export $(cat $TOOLS_ROOT/.secret | grep -v '#' | sed 's/\r$//' | awk '/=/ {print $1}' )
fi

JOOMLA_LOCAL=${JOOMLA_LOCAL:-}

copyConfig() {
  cp -f $TOOLS_ROOT/config/cypress.config.dist.js $WORKDIR/tests/cypress.config.js
}

# Setup configuration file
# Backup the original file if a backup file not already exists and .env variable is not set to false/no/0
# Copy the configuration file to the working directory if .env variable is set to true/yes

if [ -f $WORKDIR/tests/cypress.config.js ]; then
  case $JC_OVERRIDE_BACKUP in
    false|no|n|0)
      break
      ;;
    *)
      if [ -f $WORKDIR/tests/cypress.config.js ] && [ ! -f $WORKDIR/tests/cypress.config.js.bak ] ; then
        cp -f $WORKDIR/tests/cypress.config.js $WORKDIR/tests/cypress.config.js.bak
      fi
      ;;
  esac
  case $JC_OVERRIDE in
    false|no|n|0)
      break
      ;;
    *)
      copyConfig
    ;;
  esac
else
  copyConfig
fi

# Set the correct permissions
chown node:node $WORKDIR/tests/cypress.config.js

case $JOOMLA_LOCAL in
  false|no|n|0)

    # Setup the configuration file for remote testing

    JOOMLA_USERNAME=${JOOMLA_USERNAME:-}
    JOOMLA_PASSWORD=${JOOMLA_PASSWORD:-}
    JOOMLA_API_TOKEN=${JOOMLA_API_TOKEN:-}
    JOOMLA_SITE=${JOOMLA_SITE:-}
    JOOMLA_PROJECT=${JOOMLA_PROJECT:-local}


    # Update Cypress configuration file with the provided values
    CYPRESS_BASE_URL_ESCAPED=$(printf '%s\n' "$CYPRESS_BASE_URL" | sed -e 's/[\/&]/\\&/g')
    sed -i "s/{BASE_URL}/$CYPRESS_BASE_URL_ESCAPED/g" $WORKDIR/tests/cypress.config.js
    sed -i "s/{JOOMLA_USERNAME}/$JOOMLA_USERNAME/g" $WORKDIR/tests/cypress.config.js
    sed -i "s/{JOOMLA_PASSWORD}/$JOOMLA_PASSWORD/g" $WORKDIR/tests/cypress.config.js
    sed -i "s/{JOOMLA_TOKEN}/${JOOMLA_API_TOKEN}/g" $WORKDIR/tests/cypress.config.js
    
    echo "Username and password updated in cypress.config.js"

    echo "Configuration updated successfully!"
    ;;

  *)
    # Setup the configuration file for local testing    
    JOOMLA_USERNAME=${JOOMLA_USERNAME:-"admin"}
    JOOMLA_PASSWORD=${JOOMLA_PASSWORD:-"admin12345678"}
    CYPRESS_BASE_URL="http://web.local/$JOOMLA_SITE"
    CYPRESS_BASE_URL_ESCAPED=$(printf '%s\n' "$CYPRESS_BASE_URL" | sed -e 's/[\/&]/\\&/g')

    # Read database credentials from configuration.php
    SITE_ROOT="/usr/src/Projects/data/sites/$JOOMLA_SITE"
    SITE_PATH="/var/www/html/$JOOMLA_SITE"
    SITE_PATH_SED=$(printf '%s\n' "$SITE_PATH" | sed -e 's/[\/&]/\\&/g')
    CONFIG_FILE="$SITE_ROOT/configuration.php"

    while  ! [ -f $CONFIG_FILE ]; do
      echo "$(date) - Waiting for Joomla configuration file - ${CONFIG_FILE}"
      sleep 10
    done

    SITENAME_LINE=$(grep -oPi 'public \$sitename = ([^;]+);' $CONFIG_FILE | cut --complement -c 1-20)
    EMAIL_LINE=$(grep -oPi 'public \$mailfrom = ([^;]+);' $CONFIG_FILE | cut --complement -c 1-20)
    DB_NAME_LINE=$(grep -oPi 'public \$db = ([^;]+);' $CONFIG_FILE | cut --complement -c 1-14)
    DB_PREFIX_LINE=$(grep -oPi 'public \$dbprefix = ([^;]+);' $CONFIG_FILE | cut --complement -c 1-20)

    SITENAME=${SITENAME_LINE:0:-2}
    EMAIL=${EMAIL_LINE:0:-2}
    DB_NAME=${DB_NAME_LINE:0:-2}
    DB_PREFIX=${DB_PREFIX_LINE:0:-2}
    LABEL=API_${JOOMLA_SITE}
    API_LABEL=$(printf "%s" ${LABEL} | tr '[:lower:]' '[:upper:]')

    # Define the site propperly
    sed -i "s/{SITENAME}/$SITENAME/g" $WORKDIR/tests/cypress.config.js
    sed -i "s/{DB_NAME}/$DB_NAME/g" $WORKDIR/tests/cypress.config.js
    sed -i "s/{DB_PREFIX}/$DB_PREFIX/g" $WORKDIR/tests/cypress.config.js
    sed -i "s/{SITE_PATH}/$SITE_PATH_SED/g" $WORKDIR/tests/cypress.config.js
    sed -i "s/{BASE_URL}/$CYPRESS_BASE_URL_ESCAPED/g" $WORKDIR/tests/cypress.config.js
    sed -i "s/{JOOMLA_USERNAME}/$JOOMLA_USERNAME/g" $WORKDIR/tests/cypress.config.js
    sed -i "s/{JOOMLA_PASSWORD}/$JOOMLA_PASSWORD/g" $WORKDIR/tests/cypress.config.js
    sed -i "s/{JOOMLA_TOKEN}/${!API_LABEL}/g" $WORKDIR/tests/cypress.config.js

    # Symlink test data into the site
    if [ ! -d $SITE_ROOT/tests/data ]; then
      if [ ! -d $SITE_ROOT/tests ]; then
        mkdir -p $SITE_ROOT/tests/System
      fi
      if [ -L $SITE_ROOT/tests/System/data ] ; then
        unlink $SITE_ROOT/tests/System/data
      fi
      ln -s $WORKDIR/tests/System/data $SITE_ROOT/tests/System/data
    fi

    ;;
esac

if [ ! -f $WORKDIR/tests/package.json ]; then
  echo "[ERROR] No package.json found in the tests folder. Skipping cypress container start."
  exit 0
fi

# Set the correct permissions
chown node:node $WORKDIR/tests/package.json $WORKDIR/tests/package-lock.json

# Install the assets
if [ -f $WORKDIR/tests/package.json ]; then
  echo "Cleaning the assets"
  rm -rf $WORKDIR/tests/node_modules
  echo -e " > Installing the assets (takes a while!)"
  cd $WORKDIR/tests/
  npm ci
fi

export DISPLAY=:0

# Start the VNC server, the noVNC web server and cypress and monitor with supervisord
exec supervisord -s -c /novnc/supervisord.conf
