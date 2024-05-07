describe('Test in backend that the article form', () => {
  beforeEach(() => {
    if (Cypress.isBrowser('firefox')) {
      cy.doAdministratorLogin(null, null, false);
    } else {
      cy.doAdministratorLogin();
    }
  });
  afterEach(() => {
    // cy.get('.js-stools-btn-clear').click({ force: true });
  });

  it('can create an article', () => {
    cy.visit('/administrator/index.php?option=com_content&task=article.add');

    cy.get('#jform_title').clear().type('Test article 001');
    cy.clickToolbarButton('Save & Close');

    cy.get('#system-message-container').contains('Article saved.').should('exist');
    cy.contains('Test article 001');
  });

  it('can archive an article', () => {
    cy.createArticle('test 987').then(() => {
      cy.visit('/administrator/index.php?option=com_content&filter=');

      cy.searchForItem('test 987');
      cy.checkAllResults();
      cy.clickToolbarButton('Action');
      cy.contains('Archive').click();

      cy.get('#system-message-container').contains('Article archived.').should('exist');
    });
  });

  it('can trash an article', () => {
    cy.visit('/administrator/index.php?option=com_content&view=articles');

    cy.searchForItem('Test article 001');
    cy.checkAllResults();
    cy.clickToolbarButton('Action');
    cy.get('.button-trash').click();

    cy.get('#system-message-container').contains('Article trashed.').should('exist');
  });

  it('can delete an article', () => {
    cy.visit('/administrator/index.php?option=com_content&filter=');
  
    cy.setFilter('published', 'Trashed');
    cy.searchForItem('Test article 001');
    cy.checkAllResults();
    cy.clickToolbarButton('empty trash');
    cy.get('.button-primary').click();

    cy.get('#system-message-container').contains('Article deleted.').should('exist');
  });
});