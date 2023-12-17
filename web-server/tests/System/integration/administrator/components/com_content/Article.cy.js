describe('Test in backend that the article form', () => {
  beforeEach(() => {
    cy.doAdministratorLogin();
  });
  // afterEach(() => cy.deleteArticle())

  it('can create an article', () => {
    cy.visit('/administrator/index.php?option=com_content&task=article.add');

    cy.get('#jform_title').clear().type('Test article 123');
    cy.clickToolbarButton('Save & Close');

    cy.get('#system-message-container').contains('Article saved.').should('exist');
    cy.contains('Test article');
  });
  
  // it('can toggle featured status on article', () => {
  //   cy.createArticle('test012').then(() => {
  //     cy.visit('/administrator/index.php?option=com_content&task=article');
  //     cy.searchForItem('test012').click();

  //     cy.get('#jform_featured1').click();
  //     cy.clickToolbarButton('Save & Close');

  //     cy.get('#system-message-container').contains('Article saved.').should('exist');
  //     cy.contains('test012');
  //   });
  // });

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

  // it('can delete an article', () => {
  //   cy.db_createArticle({ title: 'Test article', state: -2 }).then(() => {
  //     cy.visit('/administrator/index.php?option=com_content&filter=');
  //     cy.setFilter('published', 'Trashed');
  //     cy.searchForItem('Test article');
  //     cy.checkAllResults();
  //     cy.clickToolbarButton('empty trash');
  //     cy.get('.button-primary').click();

  //     cy.get('#system-message-container').contains('Article deleted.').should('exist');
  //   });
  // });
});