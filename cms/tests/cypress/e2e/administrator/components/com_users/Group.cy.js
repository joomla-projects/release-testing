describe('Test in backend that the user group form', () => {
  beforeEach(() => {
    cy.skipWhenNot(Cypress.config('baseUrl').includes('web.local'))
    cy.doAdministratorLogin()
  });
  afterEach(() => cy.task('queryDB', "DELETE FROM #__usergroups WHERE title = 'test group'"));

  it('can create a new group', () => {
    cy.visit('/administrator/index.php?option=com_users&task=group.add');

    cy.get('#jform_title').clear().type('test group');
    cy.clickToolbarButton('Save & Close');

    cy.get('#system-message-container').contains('Group saved.').should('exist');
    cy.contains('test group');
  });

  it('can edit a group', () => {
    cy.db_createUserGroup().then((group) => {
      cy.visit(`/administrator/index.php?option=com_users&task=group.edit&id=${group.id}`);

      cy.get('#jform_title').clear().type('test group edited');
      cy.clickToolbarButton('Save');

      cy.get('#system-message-container').contains('Group saved.').should('exist');
    });
  });

  it('check redirection to list view', () => {
    cy.visit('/administrator/index.php?option=com_users&task=group.add');
    cy.intercept('index.php?option=com_users&view=groups').as('listview');
    cy.clickToolbarButton('Cancel');

    cy.wait('@listview');
  });
});
