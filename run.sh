#!/bin/bash

# Setup root directory
ROOT="/dev_joomla"

# Check the number of arguments provided
if [ $# -eq 0 ]; then
  # No input provided, run the local script
  echo "Running local script..."
  source local/local.sh
fi
