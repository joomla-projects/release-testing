/**
 * Imports commands fom files. The commands start with the folder name and an underscore as cypress doesn't support
 * namespaces for commands.
 *
 * https://github.com/cypress-io/cypress/issues/6575
 */

import compareSnapshotCommand from 'cypress-image-diff-js/command';

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

Cypress.Commands.add("logToConsole", (message) => {
  if (Cypress.browser.isHeadless) {
    return cy.task("log", message);
  } else {
    return cy.log(message);
  }
});


Cypress.Commands.add('step', description => {
  const MAX_ITEMS_IN_STACK = 5
  /**
   * Retrieves the 'step' environment variable from Cypress command and assigns it to the constant `arr`.
   * If the 'step' environment variable is not defined, `arr` will be an empty array.
   *
   * @constant {Array} arr - The array containing the 'step' environment variable or an empty array if not defined.
   */
  const arr = Cypress.env('step') || []
  arr.push(description)
  if (arr.length > MAX_ITEMS_IN_STACK) {
    arr.shift()
  }
  Cypress.env('step', arr)
})

if (Cypress.config('isTextTerminal')) {
  compareSnapshotCommand();
}



