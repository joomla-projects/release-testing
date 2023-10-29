#!/bin/bash

# Read database credentials from configuration.php
CONFIG_FILE="..\configuration.php"

DB_SITENAME_LINE=$(grep -oPi 'public \$sitename = ([^;]+);' $CONFIG_FILE | cut --complement -c 1-20)
DB_EMAIL_LINE=$(grep -oPi 'public \$mailfrom = ([^;]+);' $CONFIG_FILE | cut --complement -c 1-20)
DB_HOST_LINE=$(grep -oPi 'public \$host = ([^;]+);' $CONFIG_FILE | cut --complement -c 1-16)
DB_NAME_LINE=$(grep -oPi 'public \$db = ([^;]+);' $CONFIG_FILE | cut --complement -c 1-14)
DB_USER_LINE=$(grep -oPi 'public \$user = ([^;]+);' $CONFIG_FILE | cut --complement -c 1-16)
DB_PASS_LINE=$(grep -oPi 'public \$password = ([^;]+);' $CONFIG_FILE | cut --complement -c 1-20)
DB_PREFIX_LINE=$(grep -oPi 'public \$dbprefix = ([^;]+);' $CONFIG_FILE | cut --complement -c 1-20)

db_sitename=${DB_SITENAME_LINE:0:-2}
db_email=${DB_EMAIL_LINE:0:-2}
db_host=${DB_HOST_LINE:0:-2}
db_name=${DB_NAME_LINE:0:-2}
db_user=${DB_USER_LINE:0:-2}
db_password=${DB_PASS_LINE:0:-2}
db_prefix=${DB_PREFIX_LINE:0:-2}

# Path to your dummy config file
dummy_config="${PWD}\cypress.config.dist.js"

# Path to your real config file
real_config="${PWD}\cypress.config.js"

# Replace lines in the dummy config file with data from configuration.php
sed -i "s/sitename_replace/$db_sitename/g; s/email_replace/$db_email/g; s/db_host_replace/$db_host/g; s/db_name_replace/$db_name/g; s/password_replace/$db_password/g; s/user_replace/$db_user/g; s/db_prefix_replace/$db_prefix/g;" $dummy_config

# Copy the updated dummy config to the real config file
cp $dummy_config $real_config

echo "Configuration updated successfully!"