describe('Test in backend that the user form', () => {
  beforeEach(() => cy.doAdministratorLogin());
  // after(() => {
  //   cy.task('queryDB', "DELETE FROM #__menu_types WHERE menutype = 'test'");
  // })

  it('can create a new menu', () => {
    cy.visit('/administrator/index.php?option=com_menus&task=menu.add');

    cy.get('#jform_title').clear().type('test menu');
    cy.get('#jform_menutype').clear().type('test#1209');
    cy.get('#jform_menudescription').clear().type('test description');
    cy.clickToolbarButton('Save & Close');

    cy.get('#system-message-container').contains('Menu saved').should('exist');
    cy.contains('test menu');
  });

  it('can delete a new menu', () => {
    cy.visit('/administrator/index.php?option=com_menus&view=menus');

    cy.searchForItem('test menu');
    cy.checkAllResults();
    cy.clickToolbarButton('Delete');
    cy.get('.button-primary').click();

    cy.get('#system-message-container').contains('Menu deleted').should('exist');
  });
});
