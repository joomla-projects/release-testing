describe('Test in backend that the user group form', () => {
  beforeEach(() => {
    if (Cypress.isBrowser('firefox')) {
      cy.doAdministratorLogin(null, null, false);
    } else {
      cy.doAdministratorLogin();
    }
  });
  afterEach(() => {
    // cy.get('.js-stools-btn-clear').click({ force: true })
  });

  it('can create a new user group', () => {
    cy.visit('/administrator/index.php?option=com_users&task=group.add');

    cy.get('#jform_title').clear().type('test group');
    cy.clickToolbarButton('Save & Close');

    cy.get('#system-message-container').contains('Group saved.').should('exist');
    cy.contains('test group');
  });

  it('can delete the test group', () => {
      cy.visit('/administrator/index.php?option=com_users&view=groups&filter=');

      cy.searchForItem('test group');
      cy.checkAllResults();
      cy.clickToolbarButton('Delete');
      cy.get('.button-primary').click();

      cy.get('#system-message-container').contains('User Group deleted.').should('exist');
  });
});
