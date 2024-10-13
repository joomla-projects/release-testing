describe('Test in backend that the user access level form', () => {
  beforeEach(() => {
    cy.skipWhenNot(Cypress.config('baseUrl').includes('web.local'))
    cy.doAdministratorLogin()
  });
  afterEach(() => cy.task('queryDB', "DELETE FROM #__viewlevels WHERE title = 'test level'"));

  it('can create a new access level', () => {
    cy.visit('/administrator/index.php?option=com_users&task=level.add');

    cy.get('#jform_title').clear().type('test level');
    cy.clickToolbarButton('Save & Close');

    cy.get('#system-message-container').contains('Access level saved.').should('exist');
    cy.contains('test level');
  });

  it('can edit an access level', () => {
    cy.db_createUserLevel().then((level) => {
      cy.visit(`/administrator/index.php?option=com_users&task=level.edit&id=${level.id}`);

      cy.get('#jform_title').clear().type('test level edited');
      cy.clickToolbarButton('Save');

      cy.get('#system-message-container').contains('Access level saved.').should('exist');
    });
  });

  it('check redirection to list view', () => {
    cy.visit('/administrator/index.php?option=com_users&task=level.add');
    cy.intercept('index.php?option=com_users&view=levels').as('listview');
    cy.clickToolbarButton('Cancel');

    cy.wait('@listview');
  });
});
