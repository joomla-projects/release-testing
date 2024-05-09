/**
 * Imports commands fom files. The commands start with the folder name and an underscore as cypress doesn't support
 * namespaces for commands.
 *
 * https://github.com/cypress-io/cypress/issues/6575
 */

import './commands/api';
import './commands/config';
import './commands/db';

// Cleanup Data via API on remote Sites
import {cleanupBannerIfExist, createTestBanner} from './api/banners'

const { registerCommands } = require('../../node_modules/joomla-cypress/src/index.js');

registerCommands();

// Click Joomla Dialog Confirm, isOkay: true = push "ok" button, false = push "cancel" button
Cypress.Commands.add('clickDialogConfirm', (isOkay) => {
  let selector = '.joomla-dialog-confirm';
  if (isOkay) {
    selector += ' button[data-button-ok]';
  } else {
    selector += ' button[data-button-cancel]';
  }
  return cy.get(selector, { timeout: 1000 }).click();
});

Cypress.Commands.overwrite('doAdministratorLogin', (originalFn, username, password, useSnapshot = true) => {

  if (Cypress.isBrowser('firefox')) {
    // Clear the session data - Fix for Firefox >= 115
    Cypress.session.clearAllSavedSessions();
  }

  return originalFn(username, password, useSnapshot);
});

Cypress.Commands.overwrite('doFrontendLogin', (originalFn, username, password, useSnapshot = true) => {

  if (Cypress.isBrowser('firefox')) {
    // Clear the session data - Fix for Firefox >= 115
    Cypress.session.clearAllSavedSessions();
  }

  return originalFn(username, password, useSnapshot);
});

Cypress.Commands.add('skipWhen', function (expression) {
  // Skip the test if the expression is true
  if (expression) {
    this.skip()
  }
})

// Cleanup Data via API on remote Sites
/**  Cleanup a test banner if it exists */
Cypress.Commands.add('cleanupBannerIfExist', () => {
  Cypress.log({ name: 'cleanupBannerIfExist' })

  if (Cypress.config('baseUrl').includes('web.local')) {
    cy.task('queryDB', "DELETE FROM #__banners WHERE name = 'Test banner'")
    return true
  } else {
    return cleanupBannerIfExist()
  }
})

/**  Create a test banner */
Cypress.Commands.add('createTestBanner', () => {
  Cypress.log({ name: 'createTestBanner' })

  if (Cypress.config('baseUrl').includes('web.local')) {
    return cy.db_createBanner({ name: 'Test Banner' })
  } else {
    return createTestBanner()
  }  
})



