describe('Test in backend that the banners form', () => {
  beforeEach(() => {
    cy.cleanupBannerIfExist()
    cy.doAdministratorLogin();
    // Clear the filter
    cy.visit('/administrator/index.php?option=com_banners&filter=');
  });

  it('can create a banner', () => {
    cy.visit('/administrator/index.php?option=com_banners&task=banner.add');
    cy.get('#jform_name').clear().type('Test banner');
    cy.clickToolbarButton('Save & Close');

    cy.get('#system-message-container').contains('Banner saved.').should('exist');
    cy.contains('Test banner');
  });

  it('check redirection to list view', () => {
    cy.visit('/administrator/index.php?option=com_banners&task=banner.add');
    cy.intercept('index.php?option=com_banners&view=banners').as('listview');
    cy.clickToolbarButton('Cancel');

    cy.wait('@listview');
  });

  it('can edit a banner', () => {
    cy.createTestBanner().then((banner) => {
      cy.visit(`/administrator/index.php?option=com_banners&task=banner.edit&id=${banner.id}`);
      cy.get('#jform_name').clear().type('Test banner edited');
      cy.clickToolbarButton('Save & Close');

      cy.contains('Test banner edited');
    });
  });
});
