describe('Test in backend that', () => {
  beforeEach(() => {
    cy.skipWhenNot(Cypress.config('baseUrl').includes('web.local'))
    cy.task('queryDB', "DELETE FROM #__users WHERE username = 'test'")
  });
    
    it('can log in with a test user', () => {
        cy.db_createUser({
          name: 'automated test user',
          username: 'test',
          email: 'test@example.com',
          password: '098f6bcd4621d373cade4e832627b4f6',
        }).then(() => {
          cy.visit('/administrator');
          cy.get('#mod-login-username').type('test');
          cy.get('#mod-login-password').type('test');
          cy.get('#btn-login-submit').click();    
        });
    });
});
