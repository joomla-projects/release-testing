describe('Test in backend that the application configuration', () => {
  beforeEach(() => {
    cy.skipWhenNot(Cypress.config('baseUrl').includes('web.local'))
    cy.maildevDeleteAllMessages();
    cy.doAdministratorLogin();
    cy.visit('/administrator/index.php?option=com_config');
  });

  it('has a title', () => {
    cy.contains('h1', 'Global Configuration').should('exist');
  });

  it('can display the configuration', () => {
    cy.contains('label', 'Site Name').should('exist');
  });

  it('can send a test mail', () => {
    cy.get('#configTabs div[role="tablist"] button[aria-controls="page-server"]').click();
    cy.get('#jform_mailer').select('smtp');
    cy.get('#jform_smtphost').clear().type(Cypress.env('smtp_host'));
    cy.get('#jform_smtpport').clear().type(Cypress.env('smtp_port'));
    cy.get('#jform_smtpsecure').select('none');
    cy.get('#sendtestmail').click();

    cy.get('#system-message-container').should('contain.text', 'The email was sent to');

    cy.maildevGetAllMessages().then((emails) => {
      expect(emails.length).to.equal(1);
    });

    cy.maildevGetLastMessage().then((email) => {
      expect(email.from[0].address).to.equal(Cypress.env('email'));
      expect(email.to[0].address).to.equal(Cypress.env('email'));
      expect(email.text).to.contain('This is a test mail sent using');
      // cy.wrap(email.text).should("have.string", "This is a test mail sent using");
      // HTML
      // cy.maildevVisitMessageById(email.id);
      // cy.get("body h1").should("have.string", "This is a test mail sent using");
    });
  });
});
