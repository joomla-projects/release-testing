// support/api/banners.mjs

import '../commands/api.mjs';

const getBanners = () => cy.api_get('/banners')

const deleteBanner = ({ bannerId } = {}) => cy.api_delete(`/banners/${bannerId}`)

const cleanupBannerIfExist = () => {
    getBanners().then((response) => {
        if (response.body.data.length > 0) {
            response.body.data.forEach((banner) => {
                if (banner.attributes.name === 'Test banner' || banner.attributes.name === 'Test Banner' 
                    || banner.attributes.name === 'Test banner edited') {
                    const matchedBanner = banner.attributes
                    // Remove if found
                    if (matchedBanner) {
                        // If the banner is not already trashed, trash it
                        if (matchedBanner.state !== -2) {
                            cy.api_patch(`/banners/${matchedBanner.id}`, { state: -2 })
                        }
                        deleteBanner({ bannerId: matchedBanner.id })
                    }
                    return
                }
            })
        }
    })
}

/**
 * Create a test banner 
 * @param {integer} categoryId The category id
 *
 * @returns integer
 */
const createTestBanner = () => {
    // TODO Create categorie only if not exits - TODO add delete categorie onBeforeEach - API Bug Joomla
    return cy.api_post('/banners/categories', { title: 'test banner category', description: 'test banner category description' })
    .then((response) => {
        return cy.api_post('/banners', {
            name: 'Test Banner',
            alias: 'test-banner',
            catid: response.body.data.id,
            state: 1,
            language: '*',
            description: '',
            custombannercode: '',
            params: {
            imageurl: '', width: '', height: '', alt: '',
            },
        });
    });
}

export default {cleanupBannerIfExist, createTestBanner}