describe('Test in frontend that the articles categories module', () => {
  it('can display the "Older Posts" menu item', () => {
    cy.visit('/');
    cy.contains('Older Posts');
    cy.get('.sidebar-left > .card-body');
  });
});