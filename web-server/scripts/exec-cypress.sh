#!/bin/bash

echo "Installing the assets (takes a while!)"
rm -rf "${ROOT}/node_modules"
cd "${ROOT}"
npm update

echo "Start creating cypress.config.js"
source  ${ROOT}/scripts/config-setup.sh

echo "Start Cypress"
cypress open --project ${ROOT}/tests --e2e

exit 1