Cypress.Commands.add('api_responseContains', (response, attribute, value) => {
  const items = response.body.data.map((item) => ({ attribute: item.attributes[attribute] }));
  cy.wrap(items).should('deep.include', { attribute: value });
});

Cypress.Commands.add('api_get', (path) => cy.api_getBearerToken().then((token) => cy.request({ method: 'GET', url: `/api/index.php/v1${path}`, headers: { Authorization: `Bearer ${token}` } })));

Cypress.Commands.add('api_post', (path, body) => cy.api_getBearerToken().then((token) => cy.request({
  method: 'POST', url: `/api/index.php/v1${path}`, body, headers: { Authorization: `Bearer ${token}` }, json: true,
})));

Cypress.Commands.add('api_patch', (path, body) => cy.api_getBearerToken().then((token) => cy.request({
  method: 'PATCH', url: `/api/index.php/v1${path}`, body, headers: { Authorization: `Bearer ${token}` }, json: true,
})));

Cypress.Commands.add('api_delete', (path) => cy.api_getBearerToken().then((token) => cy.request({ method: 'DELETE', url: `/api/index.php/v1${path}`, headers: { Authorization: `Bearer ${token}` } })));

Cypress.Commands.add('api_getBearerToken', () => {
  return Cypress.env('api_token');
});
