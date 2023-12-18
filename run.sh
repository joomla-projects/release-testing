#!/bin/bash

# Setup root directory
ROOT="/dev_joomla"

# Check the number of arguments provided
if [ $# -eq 0 ]; then
  # No input provided, run the local script
  echo "No domain provided, running local script..."
  source local/local.sh
else
  # One input provided, assume it's the domain
  domain="$1"
  echo "Domain provided: ${domain}"

  # Save the domain in a variable for Cypress configuration
  cypress_base_url="${domain}"
  
  source web-server/web.sh
fi
