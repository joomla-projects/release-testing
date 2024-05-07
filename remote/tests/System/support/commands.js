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

Cypress.Commands.overwrite('doFrontendLogin', (originalFn, username, password, useSnapshot = true) => {
  // Ensure there are valid credentials
  const user = username ?? Cypress.env('username');
  const pw = password ?? Cypress.env('password');

  // Do normal login when no snapshot should be used
  if (!useSnapshot) {
    // Clear the session data
    Cypress.session.clearAllSavedSessions();

    // Call the normal function
    return originalFn(user, pw);
  }

  // Do login through the session
  return cy.session([user, pw, 'front'], () => originalFn(user, pw), { cacheAcrossSpecs: true });
});

Cypress.Commands.overwrite('doFrontendLogout', (originalFn) => {
  // Call the login function
  originalFn();

  // Clear the session data
  Cypress.session.clearAllSavedSessions();
});

Cypress.Commands.overwrite('doAdministratorLogin', (originalFn, username, password, useSnapshot = true) => {
  // Ensure there are valid credentials
  const user = username ?? Cypress.env('username');
  const pw = password ?? Cypress.env('password');

  // Do normal login when no snapshot should be used
  if (!useSnapshot) {
    // Clear the session data
    Cypress.session.clearAllSavedSessions();

    // Call the normal function
    return originalFn(user, pw);
  }

  // Do login through the session
  return cy.session([user, pw, 'back'], () => originalFn(user, pw), { cacheAcrossSpecs: true });
});

Cypress.Commands.overwrite('doAdministratorLogout', (originalFn) => {
  // Call the login function
  originalFn();

  // Clear the session data
  Cypress.session.clearAllSavedSessions();
});

Cypress.Commands.add('createArticle', (article) => {
  cy.visit('/administrator/index.php?option=com_content&task=article.add');

  cy.get('#jform_title').clear().type(article);
  cy.clickToolbarButton('Save & Close');

  cy.get('#system-message-container').contains('Article saved.').should('exist');
  // cy.contains(article);
})

Cypress.Commands.add('trashArticle', (article) => {
  cy.visit('/administrator/index.php?option=com_content&view=articles');

  cy.searchForItem(article);
  cy.checkAllResults();
  cy.clickToolbarButton('Action');
  cy.get('.button-trash').click();

  //cy.get('#system-message-container').contains('Article trashed.').should('exist');
})

Cypress.Commands.add('deleteArticle', (article) => {
  cy.visit('/administrator/index.php?option=com_content&filter=');
  
  cy.setFilter('published', 'Trashed');
  cy.searchForItem(article);
  cy.checkAllResults();
  cy.clickToolbarButton('empty trash');
  cy.get('.button-primary').click();

  //cy.get('#system-message-container').contains('Article deleted.').should('exist');
})

Cypress.Commands.add('createUser', (name, username, password) => {
  cy.visit('/administrator/index.php?option=com_users&task=user.add');

    cy.get('#jform_name').clear().type(name);
    cy.get('#jform_username').clear().type(username);
    cy.get('#jform_email').clear().type('testuser@example.com');
    cy.get('#jform_password').clear().type(password);
    cy.get('#jform_password2').clear().type(password);
    cy.clickToolbarButton('Save & Close');

    cy.get('#system-message-container').contains('User saved').should('exist');
})

Cypress.Commands.add('deleteUser', (username) => {
  cy.visit('/administrator/index.php?option=com_users&view=users&filter=');

  cy.searchForItem(username);
  cy.checkAllResults();
  cy.clickToolbarButton('Action');
  cy.contains('Delete').click();
  cy.get('.button-primary').click();

  cy.get('#system-message-container').contains('User deleted.').should('exist');
})


Cypress.Commands.add('createSuperUser', (name, username, password) => {
  cy.visit('/administrator/index.php?option=com_users&task=user.add');

  cy.get('#jform_name').clear().type(name);
  cy.get('#jform_username').clear().type(username);
  cy.get('#jform_email').clear().type('testuser@example.com');
  cy.get('#jform_password').clear().type(password);
  cy.get('#jform_password2').clear().type(password);
  cy.clickToolbarButton('Save');

  // cy.get('#system-message-container').contains('User saved').should('exist');

  cy.contains('Assigned User Groups').click();
  cy.contains('Super Users').click();
  cy.clickToolbarButton('Save & Close');
})

Cypress.Commands.add('deleteSuperUser', (name) => {
  cy.doAdministratorLogin();
  cy.visit('/administrator/index.php?option=com_users&view=users&filter=');

  cy.searchForItem(name);
  cy.get('.name > a').click();
  cy.contains('Assigned User Groups').click();
  cy.contains('Super Users').click();
  cy.clickToolbarButton('Save & Close');

  cy.visit('/administrator/index.php?option=com_users&view=users&filter=');

  cy.searchForItem(name);
  cy.checkAllResults();
  cy.clickToolbarButton('Action');
  cy.contains('Delete').click();
  cy.get('.button-primary').click();

  cy.get('#system-message-container').contains('User deleted.').should('exist');
})
