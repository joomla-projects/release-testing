import('./commands.mjs');
import('joomla-cypress');
import('cypress-mochawesome-reporter/register');

before(() => {
  cy.task('startMailServer');
  Cypress.on('uncaught:exception', (err, runnable) => {
    console.log(`err :${err}`);
    console.log(`runnable :${runnable}`);
    return false;
  });
});

afterEach(() => {
  cy.checkForPhpNoticesOrWarnings();
  cy.task('cleanupDB');
});
