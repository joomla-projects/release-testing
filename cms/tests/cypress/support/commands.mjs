/**
 * Imports commands fom files. The commands start with the folder name and an underscore as cypress doesn't support
 * namespaces for commands.
 *
 * https://github.com/cypress-io/cypress/issues/6575
 */

import { registerCommands } from 'joomla-cypress';

import './commands/api.mjs';
import './commands/config.mjs';
import './commands/db.mjs';

// Cleanup Data via API on remote Sites
import {cleanupBannerIfExist, createTestBanner} from './api/banners.mjs'

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

Cypress.Commands.add('skipWhen', function (expression) {
  // Skip the test if the expression is true
  if (expression) {
    this.skip()
  }
})

Cypress.Commands.add('skipWhenNot', function (expression) {
  // Skip the test if the expression is true
  if (!expression) {
    this.skip()
  }
})

// Cleanup Data via API on remote Sites
/**  Cleanup a test banner if it exists */
Cypress.Commands.add('cleanupBannerIfExist', () => {
  Cypress.log({ name: 'cleanupBannerIfExist' })

  if (Cypress.config('baseUrl').includes('web.local')) {
    return cy.task('queryDB', "DELETE FROM #__banners WHERE name = 'Test banner'")
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



