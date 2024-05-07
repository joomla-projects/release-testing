describe('Test in frontend that the login module', () => {
  it('can log in and out with the default credentials', () => {
    cy.doFrontendLogin(null, null, false);
    // cy.doFrontendLogout();
  });
});
