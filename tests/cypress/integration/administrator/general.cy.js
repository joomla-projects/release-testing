describe('Test in backend that', () => {
  beforeEach(() => {
    cy.visit('/administrator/index.php');
    cy.get('#mod-login-username').type(`${Cypress.env('username')}`);
    cy.get('#mod-login-password').type(`${Cypress.env('password')}`);
    cy.get('#btn-login-submit').click();
  });

  it('it has a title', () => {
    cy.get('.page-title').should('contain.text', 'Home Dashboard');
  });

  it('it has a header', () => {
    cy.get('.header-inside').should('exist');
  });

  it('it has a sidebar', () => {
    cy.get('#sidebar-wrapper').should('exist');
  });

  it('it has the option to install blog sample data', () => {
    cy.get('.sampledata-blog').should('exist');
    cy.get('.sampledata-blog > .d-flex > .btn').should('exist');
  });
});