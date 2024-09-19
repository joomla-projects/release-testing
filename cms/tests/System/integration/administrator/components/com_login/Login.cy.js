describe('Test in backend that the login component', () => {
  it('can log in and out', () => {
    cy.skipWhenNot(Cypress.config('baseUrl').includes('web.local'))
    cy.doAdministratorLogin(null, null, false);
    cy.doAdministratorLogout();
  });
});
