import {createCustomErrorMessage} from '../../plugins/errorMessage.mjs'
// we can access the Cypress.env() object outside the test
const csvSitemap = Cypress.env('sitemapList')
const sizeViewport = [1024, 768]
const sizeName = 'laptop [1024x768]'
const timeoutPerImage = 2500
const timeoutDefault = 4000

describe('Visual Regression Tests', () => {
    beforeEach(() => {
        Cypress.config('defaultCommandTimeout', timeoutDefault);
        cy.step(`Set default timeout to ${Cypress.config('defaultCommandTimeout', timeoutDefault)}`);
    });

    context(`Device: ${sizeName}`, () => {
        csvSitemap.forEach((row) => {
            it(`${row['Name']} should not contain any changes on ${sizeViewport} screen`, () => {
                
                if (Cypress._.isArray(sizeViewport)) {
                    cy.viewport(sizeViewport[0], sizeViewport[1])
                } else {
                    cy.viewport(sizeViewport)
                }

                cy.visit(`${row['Adresse']}`)

                // synchronously query from body
                cy.get('body')
                .then(($body) => {

                    // specific for yootheme theme pages
                    cy.step(`Check for scrollspy elements on page ${row["Name"]}`);
                    if ($body.find('[uk-scrollspy]').length) {
                        cy.get('[uk-scrollspy]').each(($scrollSpyTarget) => {
                            cy.wrap($scrollSpyTarget).scrollIntoView();
                        });
                    }
                    cy.step(`Check for slider elements on page ${row["Name"]} and deactivate autoplay`);
                    if ($body.find('[uk-slider]').length) {
                        cy.get('[uk-slider]')
                            .invoke('attr', 'uk-slider', 'autoplay: 0');
                    }

                    // check if img tags are present
                    cy.step(`Check if images are are present on page ${row["Name"]} and set timeout accordingly`);
                    if ($body.find('img').length ) {
                        cy.get('img').then($elements => {
                            let imageListLength = $elements.length;
                            let timeoutLazyImg = imageListLength * timeoutPerImage;
                            timeoutLazyImg = timeoutLazyImg < timeoutDefault ? timeoutDefault : timeoutLazyImg;
                            Cypress.config('defaultCommandTimeout', timeoutLazyImg);
                            cy.step(`Timeout is set to ${Cypress.config('defaultCommandTimeout')} after image check`);
                        });

                        // check if img tags with loading="lazy" are present
                        cy.step(`Check if lazy loading images are loaded ${row["Name"]}`);
                        if ($body.find('img[loading="lazy"]').length) {
                            cy.get('img[loading="lazy"]').each((img) => {
                                cy.step(`Scroll image into view - ${img.attr('src')}`);
                                cy.wrap(img)
                                    .scrollIntoView()

                                cy.step(`Wait for image to load - ${img.attr('src')}`);
                                cy.wait(1000); // Wait for the image to load

                                cy.step(`Set visualRegressionImgParentVisible to true - ${img.attr('src')}`);
                                Cypress.env('visualRegressionImgParentVisible', 'true'); // Set the default value as environment variable

                                cy.step(`Wrap image element - ${img.attr('src')}`);
                                cy.wrap(img).then($el => {
                                    cy.step(`Check if parent elements are visible for image ${img.attr('src')}`)
                                    $el.parentsUntil('body').each((index, $parent) => {
                                        if (Cypress.dom.isElement($parent) && !Cypress.dom.isVisible($parent)) {
                                            cy.step(`Set visualRegressionImgParentVisible to false - ${img.attr('src')} - parent: ${$parent}`);
                                            Cypress.env('visualRegressionImgParentVisible', 'false'); // Set the variable to false if parent is not visible
                                            return false; // breaks
                                        }
                                    })

                                    if (Cypress.env('visualRegressionImgParentVisible') === 'true') {
                                        cy.step(`Check if image is visible - ${img.attr('src')}`)
                                        const src = img.attr('src')
                                        const alt = img.attr('alt')
                                        const info = `${src ? src : ''}${alt ? ' ' + alt : ''}`
                                        const errorMessage = createCustomErrorMessage(
                                            new Error(`Expected element to be visible: ${info}`),
                                            Cypress.env('step') ?? [],
                                            Cypress.currentTest,
                                            Cypress.spec
                                        )

                                        // Fail if the image is not loaded
                                        cy.step(`Check naturalWidth of image - ${img.attr('src')} and throw error if not loaded`)
                                        expect($el[0].naturalWidth).to.be.greaterThan(0, errorMessage)
                                    }
                                })
                            })
                        }
                    } else {
                        Cypress.config('defaultCommandTimeout', 20000);
                    }
                });

                cy.step(`Compare snapshot of ${row['Name']} on ${sizeViewport} screen`);
                if (Cypress.config('isTextTerminal')) {
                    cy.compareSnapshot({
                        name: `${row['Name']}-${sizeName}-${Cypress.browser.displayName}`,
                        exactName: true,
                        cypressScreenshotOptions: {
                          scale: false,
                        },
                      })
                  } else {
                    cy.matchImage({
                        title: `${row['Name']}-${sizeName}-${Cypress.browser.displayName}`
                    });
                  }
            });
        })
    });
});