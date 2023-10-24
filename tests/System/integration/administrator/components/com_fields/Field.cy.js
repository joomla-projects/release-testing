describe('Test in backend that the field form', () => {
  beforeEach(() => {
    cy.doAdministratorLogin();
    // Clear the filter
    cy.visit('/administrator/index.php?option=com_fields&filter=');
  });
  afterEach(() => cy.task('queryDB', "DELETE FROM #__fields WHERE title = 'Test field'"));

  it('can create a field', () => {
    cy.visit('/administrator/index.php?option=com_fields&task=field.add&context=com_content.article');
    cy.get('#jform_title').clear().type('Test field');
    cy.clickToolbarButton('Save & Close');

    cy.get('#system-message-container').contains('Field saved').should('exist');
    cy.contains('Test field');
  });

  it('can delete the test field', () => {
    cy.db_createField({ title: 'Test field', state: -2 }).then(() => {
      cy.reload();
      cy.setFilter('state', 'Trashed');
      cy.searchForItem('Test field');
      cy.checkAllResults();
      cy.clickToolbarButton('empty trash');
      cy.get('.button-primary').click();
      cy.get('#system-message-container').contains('Field deleted').should('exist');
    });
  });
});
