const { defineConfig } = require('cypress')

module.exports = defineConfig({
  fixturesFolder: 'tests/cypress/fixtures',
  videosFolder: 'tests/cypress/output/videos',
  screenshotsFolder: 'tests/cypress/output/screenshots',
  viewportHeight: 1000,
  viewportWidth: 1200,
  e2e: {
    setupNodeEvents(on, config) {},
    baseUrl: 'http://localhost/joomla-cms',
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
    sitename: 'Joomla CMS Test',
    name: 'admin',
    email: 'admin@example.com',
    username: 'admin',
    password: 'adminadminadmin',
    db_type: 'MySQLi',
    db_host: 'mysql',
    db_name: 'test_joomla',
    db_user: 'root',
    db_password: 'root',
    db_prefix: 'j4_',
  },
})
