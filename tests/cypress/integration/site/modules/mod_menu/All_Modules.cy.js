describe('Test in frontend that the menu module', () => {
  it('can display the All Modules menu item', () => {
    cy.visit('/');
    cy.contains('All Modules');
    cy.get('.container-sidebar-left > :nth-child(1) > .card-body');
  });
});