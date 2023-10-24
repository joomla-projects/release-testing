describe('Test in backend that the user form', () => {
  beforeEach(() => cy.doAdministratorLogin());
  afterEach(() => cy.task('queryDB', "DELETE FROM #__users WHERE username = 'test'"));

  it('can create a new user', () => {
    cy.visit('/administrator/index.php?option=com_users&task=user.add');

    cy.get('#jform_name').clear().type('test user');
    cy.get('#jform_username').clear().type('test');
    cy.get('#jform_email').clear().type('test@example.com');
    cy.get('#jform_password').clear().type('testtesttest');
    cy.get('#jform_password2').clear().type('testtesttest');
    cy.clickToolbarButton('Save & Close');

    cy.get('#system-message-container').contains('User saved').should('exist');
    cy.contains('test user');
  });

  it('can amend user details', () => {
    cy.db_createUser().then((id) => {
      cy.visit(`/administrator/index.php?option=com_users&task=user.edit&id=${id}`);

      cy.get('#jform_name').clear().type('test edited');
      cy.get('#jform_username').clear().type('testedited');
      cy.get('#jform_password').clear().type('testeditedtest');
      cy.get('#jform_password2').clear().type('testeditedtest');
      cy.get('#jform_email').clear().type('testedited@example.com');
      cy.clickToolbarButton('Save');

      cy.get('#system-message-container').contains('User saved.').should('exist');
    });
  });

  it('can delete a test user', () => {
    cy.db_createUser({ name: 'Test user', username: 'test' }).then(() => {
      cy.visit('/administrator/index.php?option=com_users&view=users&filter=');

      cy.searchForItem('Test user');
      cy.checkAllResults();
      cy.clickToolbarButton('Action');
      cy.contains('Delete').click();
      cy.get('.button-primary').click();

      cy.get('#system-message-container').contains('User deleted.').should('exist');
    });
  });
});
