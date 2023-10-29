const { defineConfig } = require('cypress');
const setupPlugins = require('./tests/System/plugins/index');

module.exports = defineConfig({
  fixturesFolder: 'tests/System/fixtures',
  videosFolder: 'tests/System/output/videos',
  screenshotsFolder: 'tests/System/output/screenshots',
  viewportHeight: 1000,
  viewportWidth: 1200,
  e2e: {
    setupNodeEvents(on, config) {
      setupPlugins(on, config);
    },
    baseUrl: 'http://localhost/',
    specPattern: [
      'tests/System/integration/install/**/*.cy.{js,jsx,ts,tsx}',
      'tests/System/integration/administrator/**/*.cy.{js,jsx,ts,tsx}',
      'tests/System/integration/site/**/*.cy.{js,jsx,ts,tsx}',
      'tests/System/integration/api/**/*.cy.{js,jsx,ts,tsx}',
      'tests/System/integration/plugins/**/*.cy.{js,jsx,ts,tsx}',
    ],
    supportFile: 'tests/System/support/index.js',
    scrollBehavior: 'center',
    browser: 'firefox',
    screenshotOnRunFailure: true,
    video: false,
  },
  env: {
    sitename: 'sitename_replace',
    // name: 'name_replace',
    email: 'email_replace',
    // username: 'db_username_replace',
    // password: 'db_pass_replace',
    // db_type: 'MySQLi',
    db_host: 'db_host_replace',
    // db_port: '',
    db_name: 'db_name_replace',
    db_user: 'user_replace',
    db_password: 'password_replace',
    db_prefix: 'db_prefix_replace',
    // smtp_host: 'localhost',
    // smtp_port: '1025',
    cmsPath: '.',
  },
});
