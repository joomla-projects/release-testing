describe('Test in backend that the categories list', () => {
  beforeEach(() => {
    cy.visit('/administrator/index.php');
    cy.get('#mod-login-username').type(`${Cypress.env('username')}`);
    cy.get('#mod-login-password').type(`${Cypress.env('password')}`);
    cy.get('#btn-login-submit').click();
    cy.visit('/administrator/index.php?option=com_categories&view=categories&extension=com_content');
  });

  it('has a title', () => {
    cy.contains('h1', 'Categories').should('exist');
  });

  it('the option to create a new aticle', () => {
    cy.get('.button-new').should('exist');
  });

  it('the option to search an article', () => {
    cy.get('#filter_search').should('exist');
  });
});