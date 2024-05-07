describe('Test in backend that', () => {
  beforeEach(() => {
    if (Cypress.isBrowser('firefox')) {
      cy.doAdministratorLogin(null, null, false);
    } else {
      cy.doAdministratorLogin();
    }
  });
    
  it('can log in with a test user', () => {
    cy.createSuperUser('test 010', 'test#123', 'TestReleaseTesting123!!').then(() => {
      cy.doAdministratorLogout();
      cy.visit('/administrator');
      cy.get('#mod-login-username').type('test#123');
      cy.get('#mod-login-password').type('TestReleaseTesting123!!');
      cy.get('#btn-login-submit').click();    
    });

    cy.deleteSuperUser('test 010');
  });
});
