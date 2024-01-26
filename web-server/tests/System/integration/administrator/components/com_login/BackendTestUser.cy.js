describe('Test in backend that', () => {
  beforeEach(() => cy.doAdministratorLogin());
    
  it('can log in with a test user', () => {
    cy.createSuperUser('test 010', 'test#123', 'testtesttest#123').then(() => {
      cy.doAdministratorLogout();
      cy.visit('/administrator');
      cy.get('#mod-login-username').type('test#123');
      cy.get('#mod-login-password').type('testtesttest#123');
      cy.get('#btn-login-submit').click();    
    });

    cy.deleteSuperUser('test 010');
  });
});
