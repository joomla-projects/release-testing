describe('Install Joomla', () => {
  it('Install Joomla', () => {
    cy.exec('rm configuration.php', { failOnNonZeroExit: false });

    const config = {
      sitename: Cypress.env('sitename'),
      name: Cypress.env('name'),
      username: Cypress.env('username'),
      password: Cypress.env('password'),
      email: Cypress.env('email'),
      db_type: Cypress.env('db_type'),
      db_host: Cypress.env('db_host'),
      db_user: Cypress.env('db_user'),
      db_password: Cypress.env('db_password'),
      db_name: Cypress.env('db_name'),
      db_prefix: Cypress.env('db_prefix'),
    };

    cy.installJoomla(config);

    cy.doAdministratorLogin(config.username, config.password, false);
    cy.disableStatistics();
    cy.setErrorReportingToDevelopment();
    cy.doAdministratorLogout();

    // Update to the correct secret for the API tests because of the bearer token
    cy.config_setParameter('secret', 'tEstValue');

    // Setup mailing
    cy.config_setParameter('mailonline', true);
    cy.config_setParameter('mailer', 'smtp');
    cy.config_setParameter('smtphost', Cypress.env('smtp_host'));
    cy.config_setParameter('smtpport', Cypress.env('smtp_port'));
  });
});
