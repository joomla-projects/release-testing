#!/bin/bash

# Initialize a new Node.js project
npm init -y

# Install Cypress as a development dependency
npm install cypress --save-dev

#Install all other dependencies
npm install mysql
npm install postgres
npm install smtp-tester

# Run all present Cypress tests
npx cypress run

# Open Cypress
npx cypress open
