#!/bin/bash

# Initialize a new Node.js project
npm init -y

# Install Cypress as a development dependency
npm install cypress --save-dev

# Run all present Cypress tests
#npx cypress run

#Install all other dependencies
npm install mysql
npm install postgres
npm install smtp-tester

# Open Cypress
npx cypress open
