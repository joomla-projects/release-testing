/**
 * Imports commands fom files. The commands start with the folder name and an underscore as cypress doesn't support
 * namespaces for commands.
 *
 * https://github.com/cypress-io/cypress/issues/6575
 */

import './commands/api';
import './commands/config';
import './commands/db';

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
