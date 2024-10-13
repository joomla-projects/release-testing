import { getMails, clearEmails, startMailServer } from './mail.mjs';
import { writeRelativeFile, deleteRelativePath } from './fs.mjs';
import { queryTestDB, deleteInsertedItems } from './db.mjs';
import { beforeRunHook, afterRunHook } from 'cypress-mochawesome-reporter/lib/index.js';
import onProxy from "cypress-on-fix";

/**
 * Does the setup of the plugins.
 *
 * @param {*} on
 * @param {object} config The configuration
 *
 * @see https://docs.cypress.io/guides/references/configuration#setupNodeEvents
 */
export default function setupPlugins(cypressOn, config) {
  const on = onProxy(cypressOn)
  on('task', {
    queryDB: (query) => queryTestDB(query, config),
    cleanupDB: () => deleteInsertedItems(config),
    writeRelativeFile: ({ path, content, mode }) => writeRelativeFile(path, content, config, mode),
    deleteRelativePath: (path) => deleteRelativePath(path, config),
    getMails: () => getMails(),
    clearEmails: () => clearEmails(),
    startMailServer: () => startMailServer(config),
  });
  // Mochoawesome reporter and cypress-image-diff-html-report
  on('after:run', async (results) => {
    console.log('override after:run for mochawesome-reporter');
    await afterRunHook();
  });  
  on('before:run', async (details) => {
    console.log('override before:run for mochawesome-reporter');
    await beforeRunHook(details);
  });
}