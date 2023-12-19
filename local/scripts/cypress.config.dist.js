const { defineConfig } = require('cypress');
const setupPlugins = require('./System/plugins/index');

module.exports = defineConfig({
  fixturesFolder: 'System/fixtures',
  videosFolder: 'System/output/videos',
  screenshotsFolder: 'System/output/screenshots',
  viewportHeight: 1000,
  viewportWidth: 1200,
  e2e: {
    setupNodeEvents(on, config) {
      setupPlugins(on, config);
    },
    specPattern: [
      'System/integration/install/**/*.cy.{js,jsx,ts,tsx}',
      'System/integration/administrator/**/*.cy.{js,jsx,ts,tsx}',
      'System/integration/site/**/*.cy.{js,jsx,ts,tsx}',
      'System/integration/api/**/*.cy.{js,jsx,ts,tsx}',
      'System/integration/plugins/**/*.cy.{js,jsx,ts,tsx}',
    ],
    baseUrl: "url_replace",
    supportFile: 'System/support/index.js',
    scrollBehavior: 'center',
    browser: 'firefox',
    screenshotOnRunFailure: true,
    video: false,
  },
  env: {
    sitename: 'sitename_replace',
    name: "Admin Tester",
    // email: "admin@example.com",
    username: "username_replace",
    password: "password_replace",
    // automatically created from configuration.php
    email: 'email_replace',
    db_host: 'db_host_replace',
    db_name: 'db_name_replace',
    db_user: 'db_user_replace',
    db_password: 'db_password_replace',
    db_prefix: 'db_prefix_replace',
    cmsPath: '../../var/www/html',
  },
});
