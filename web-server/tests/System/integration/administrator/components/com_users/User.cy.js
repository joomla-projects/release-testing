describe('Test in backend that the user form', () => {
  beforeEach(() => cy.doAdministratorLogin());
  afterEach(() => {
    cy.get('.js-stools-btn-clear').click({ force: true })
  });

  it('can create a new user', () => {
    cy.visit('/administrator/index.php?option=com_users&task=user.add');

    cy.get('#jform_name').clear().type('test user 112');
    cy.get('#jform_username').clear().type('test');
    cy.get('#jform_email').clear().type('test@example.com');
    cy.get('#jform_password').clear().type('testtesttest');
    cy.get('#jform_password2').clear().type('testtesttest');
    cy.clickToolbarButton('Save & Close');

    cy.get('#system-message-container').contains('User saved').should('exist');
    cy.contains('test user 112');

    cy.deleteUser('test user 112');
  });

  it('can delete a test user', () => {
    cy.createUser('Test user 012', 'test', 'testtesttest').then(() => {
      cy.visit('/administrator/index.php?option=com_users&view=users&filter=');

      cy.searchForItem('Test user 012');
      cy.checkAllResults();
      cy.clickToolbarButton('Action');
      cy.contains('Delete').click();
      cy.get('.button-primary').click();

      cy.get('#system-message-container').contains('User deleted.').should('exist');
    });
  });
});
