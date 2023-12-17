describe('Test in backend that the tag form', () => {
  beforeEach(() => {
    cy.doAdministratorLogin();
  });
  afterEach(() => {
    cy.task('queryDB', "DELETE FROM #__tags WHERE title = 'Test tag'");
    cy.task('queryDB', "DELETE FROM #__content WHERE title = 'Test article'");
  });

  it('can create a tag', () => {
    cy.visit('/administrator/index.php?option=com_tags&task=tag.add');

    cy.get('#jform_title').clear().type('Test tag');
    cy.clickToolbarButton('Save & Close');

    cy.get('#system-message-container').contains('Tag saved').should('exist');
  });

  it('can assign tag to an article', () => {
    cy.db_createTag({ title: 'Test tag' }).then(() => {
      cy.db_createArticle({ title: 'Test article' }).then((article) => {
        cy.visit(`/administrator/index.php?option=com_content&task=article.edit&id=${article.id}`);

        cy.get('.choices__inner > .choices__input--cloned').click();
        cy.contains('Test tag').click();
        cy.clickToolbarButton('Save & Close');

        cy.get('.alert-message').should('contain.text', 'Article saved.')
      });
    });
  });

  it('can delete a tag', () => {
    cy.db_createTag({ title: 'Test tag', published: -2 }).then(() => {
      cy.visit('/administrator/index.php?option=com_tags&filter=');

      cy.setFilter('published', 'Trashed');
      cy.searchForItem('Test tag');
      cy.checkAllResults();
      cy.clickToolbarButton('empty trash');
      cy.get('.button-primary').click();

      cy.get('#system-message-container').contains('Tag deleted').should('exist');
    });
  });
});
