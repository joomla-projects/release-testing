import { defineConfig } from 'cypress';
import setupPlugins from './cypress/plugins/index.mjs';

export default defineConfig({
	fixturesFolder: 'cypress/fixtures',
	videosFolder: '../output/videos/{TEST_PROJECT}',
	screenshotsFolder: '../output/screenshots/{TEST_PROJECT}',
	viewportHeight: 1000,
	viewportWidth: 1200,
	e2e: {
		setupNodeEvents(on, config) {
			setupPlugins(on, config);
			return config
		},
		specPattern: [
			'cypress/e2e/**/*.cy.{js,jsx,ts,tsx}',
		],
		baseUrl: "{BASE_URL}",
		supportFile: 'cypress/support/index.js',
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
		reportPageTitle: 'Joomla-Tests - {TEST_PROJECT}',
		timestamp: 'yyyy-mm-dd_HH-MM',
		embeddedScreenshots: true,
		// inlineAssets: true,
		saveAllAttempts: false,
		reportDir: './output/reports/{TEST_PROJECT}',
		overwrite: false,
	}
});
