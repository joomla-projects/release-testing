const { defineConfig } = require('cypress');
const setupPlugins = require('./System/plugins/index');

module.exports = defineConfig({
	fixturesFolder: 'System/fixtures',
	videosFolder: 'System/output/videos',
	screenshotsFolder: 'System/output/screenshots',
	viewportHeight: 1000,
	viewportWidth: 1200,
	e2e: {
		setupNodeEvents(on, config) {
			setupPlugins(on, config);
		},
		specPattern: [
			// 'System/integration/install/**/*.cy.{js,jsx,ts,tsx}',
			'System/integration/administrator/**/*.cy.{js,jsx,ts,tsx}',
			// 'System/integration/site/**/*.cy.{js,jsx,ts,tsx}',
			// 'System/integration/api/**/*.cy.{js,jsx,ts,tsx}',
			'System/integration/plugins/**/*.cy.{js,jsx,ts,tsx}',
		],
		baseUrl: "{BASE_URL}",
		supportFile: 'System/support/index.js',
		scrollBehavior: 'center',
		browser: 'firefox',
		screenshotOnRunFailure: true,
		video: false,
		experimentalRunAllSpecs: true,
		experimentalStudio: true,
		experimentalMemoryManagement: true,
		experimentalInteractiveRunEvents: true,
	},
	env: {
		sitename: '{SITENAME}',
		name: 'Admin',
		email: 'admin@example.local',
		username: '{JOOMLA_USERNAME}',
		password: '{JOOMLA_PASSWORD}',
		api_token: '{JOOMLA_TOKEN}',
		db_type: 'MySQLi',
		db_host: 'mysql',
		db_name: '{DB_NAME}',
		db_user: 'root',
		db_password: 'root',
		db_prefix: '{DB_PREFIX}',
		smtp_host: 'cypress',
		smtp_port: '1035',
		cmsPath: '{SITE_PATH}',
	},
	reporter: 'cypress-mochawesome-reporter',
	reporterOptions: {
		charts: true,
		reportPageTitle: 'Joomla-Tests',
		timestamp: 'yyyy-mm-dd_HH-MM',
		embeddedScreenshots: true,
		inlineAssets: true,
		saveAllAttempts: false,
		reportDir: 'System/output/reports',
		overwrite: false,
	}
});
