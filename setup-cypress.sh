#!/bin/bash

# Initialize a new Node.js project
npm init -y

# Install Cypress as a development dependency
npm install cypress --save-dev

# Run all present Cypress tests
#npx cypress run

# Open Cypress
npx cypress open
