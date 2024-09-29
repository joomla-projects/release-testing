import getCompareSnapshotsPlugin from'cypress-image-diff-js/plugin';
import { generate } from 'cypress-image-diff-html-report';
import {readFileSync, existsSync, rename} from 'fs';
import onProxy from "cypress-on-fix";
import { beforeRunHook, afterRunHook } from 'cypress-mochawesome-reporter/lib/index.js';
import { dirname, join } from "path";
import { fileURLToPath } from 'url';
import neatCsv from 'neat-csv';
import { initPlugin as initVRDPlugin} from "@frsource/cypress-plugin-visual-regression-diff/plugins";

/**
 * Does the setup of the plugins.
 *
 * @param {*} on
 * @param {object} config The configuration
 *
 * @see https://docs.cypress.io/guides/references/configuration#setupNodeEvents
 */
export default async function setupPlugins(cypressOn, config) {
  const on = onProxy(cypressOn)
  // configure visual regression for open mode
  config.env.pluginVisualRegressionUpdateImages = false;
  config.env.pluginVisualRegressionDiffConfig = { threshold: 0.01 };
  config.env.preserveOriginalScreenshot = true;
  config.env.pluginVisualRegressionImagesPath = '../__image_snapshots__/{spec_path}';
  initVRDPlugin(on, config);
  getCompareSnapshotsPlugin(on, config);
  // let"s load the CSV file for the sitemap
  const __filename = fileURLToPath(import.meta.url);
  const __dirname = dirname(__filename);
  
  const filename = join(__dirname, '..', '..', '..', 'import', 'sitemap.csv');

  if (existsSync(filename)) {
    const text = readFileSync(filename, 'utf8')
    const csv = await neatCsv(text, { quote: '\'' })

    console.log('loaded the sitemap')

    // then set it inside the config object under the environment
    // which will make it available via Cypress.env("usersList")
    // before the start of the tests
    config.env.sitemapList = csv
  }

  on('before:browser:launch', (browser = {}, launchOptions) => {
    const REDUCE = 1;
    if (browser.family === 'firefox') {
      launchOptions.preferences['ui.prefersReducedMotion'] = REDUCE;
    }
    if (browser.family === 'chromium') {
      launchOptions.args.push('--force-prefers-reduced-motion');
    }
    return launchOptions;
  });
  // Mochoawesome reporter and cypress-image-diff-html-report
  on('after:run', async (results) => {
      console.log('override after:run for mochawesome-reporter');
      await afterRunHook();
      console.log('override after:run for cypress-image-diff-html-report');
      await generate({
        configFile: 'cypress-image-diff-html-report.config.mjs',
      })
      // rename generated report
      var d = new Date();
      var datestring =d.toJSON().slice(0,19).replace('T','-').split(':').join('');
      rename('../output/visual-regression-diff/cypress-image-diff-html-report/index.html', 
        `../output/visual-regression-diff/cypress-image-diff-html-report/index-${datestring}.html`, 
        function(err) {
        if ( err ) console.log('ERROR: ' + err);
      });
      console.log(`Report can be found at output/visual-regression-diff/cypress-image-diff-html-report/index-${datestring}.html`);
  });  
  on('before:run', async (details) => {
    console.log('override before:run for mochawesome-reporter');
    await beforeRunHook(details);
  });
}
