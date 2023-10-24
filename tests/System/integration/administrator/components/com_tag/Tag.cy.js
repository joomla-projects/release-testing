describe('Test in backend that the tag form', () => {
  beforeEach(() => {
    cy.doAdministratorLogin();
    // Clear the filter
    cy.visit('/administrator/index.php?option=com_tags&filter=');
  });
  afterEach(() => cy.task('queryDB', "DELETE FROM #__tags WHERE title = 'Test tag'"));

  it('can create a tag', () => {
    cy.visit('/administrator/index.php?option=com_tags&task=tag.add');
    cy.get('#jform_title').clear().type('Test tag');
    cy.clickToolbarButton('Save & Close');

    cy.get('#system-message-container').contains('Tag saved').should('exist');
    cy.contains('Test tag');
  });
});
