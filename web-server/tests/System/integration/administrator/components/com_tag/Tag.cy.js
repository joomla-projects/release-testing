describe('Test in backend that the tag form', () => {
  beforeEach(() => {
    cy.doAdministratorLogin();
  });

  it('can create a tag', () => {
    cy.visit('/administrator/index.php?option=com_tags&task=tag.add');

    cy.get('#jform_title').clear().type('Test tag #123');
    cy.clickToolbarButton('Save & Close');

    cy.get('#system-message-container').contains('Tag saved').should('exist');
  });

  it('can trash a tag', () => {
    cy.visit('/administrator/index.php?option=com_tags&view=tags');

    cy.searchForItem('Test tag #123');
    cy.checkAllResults();
    cy.clickToolbarButton('Action');
    cy.get('.button-trash').click();

    cy.get('#system-message-container').contains('Tag trashed.').should('exist');
  });

  it('can delete a tag', () => {
    cy.visit('/administrator/index.php?option=com_tags&filter=');

    cy.setFilter('published', 'Trashed');
    cy.searchForItem('Test tag #123');
    cy.checkAllResults();
    cy.clickToolbarButton('empty trash');
    cy.get('.button-primary').click();

    cy.get('#system-message-container').contains('Tag deleted').should('exist');
  });
});
