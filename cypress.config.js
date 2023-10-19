const { defineConfig } = require('cypress')

module.exports = defineConfig({
  fixturesFolder: 'tests/cypress/fixtures',
  videosFolder: 'tests/cypress/output/videos',
  screenshotsFolder: 'tests/cypress/output/screenshots',
  viewportHeight: 1000,
  viewportWidth: 1200,
  e2e: {
    setupNodeEvents(on, config) {},
    baseUrl: 'http://localhost/release-testing',
    specPattern: [
      'tests/cypress/integration/install/*.cy.{js,jsx,ts,tsx}',
      'tests/cypress/integration/administrator/**/*.cy.{js,jsx,ts,tsx}',
      'tests/cypress/integration/module/**/*.cy.{js,jsx,ts,tsx}',
      'tests/cypress/integration/site/**/*.cy.{js,jsx,ts,tsx}'
    ],
    supportFile: 'tests/cypress/support/index.js',
    scrollBehavior: 'center',
    browser: 'firefox',
    screenshotOnRunFailure: true,
    video: false
  },
  env: {
    sitename: 'Joomla5.0',
    name: 'charvi',
    email: 'charvimehradu@gmail.com',
    username: 'root',
    password: 'charvimehradu',
    db_type: 'MySQLi',
    db_host: 'mysql',
    db_name: 'joomla_db',
    db_user: 'root',
    db_password: 'root',
    db_prefix: 'cgmku_',
  },
})
