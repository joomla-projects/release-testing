# release-testing

Temporary Readme for Joomla 5.0 RC Setup

1. Start with a Fresh Joomla Installation: For starting testing, it's essential to begin with a fresh installation of [Joomla 5.0 Release Candidate](https://github.com/joomla/joomla-cms/releases/tag/5.0.0-rc).

2. Unzip the Folder: Unzip the contents of this folder into your Joomla 5.0 RC directory.

3. Running the Cypress Installation: Inside the unzipped folder, you'll find a file named [setup-cypress.sh](https://github.com/joomla-projects/release-testing/blob/main/setup-cypress.sh). Double clickon it to run the tests. This file is designed to automate the setup process. Currently, it executes three commands:

- npm init: Initializes the project.
- npm install cypress: Installs Cypress.
- npx cypress open: Opens Cypress Test Runner.

This should succesfully lead you to the following page:

![image](https://github.com/joomla-projects/release-testing/assets/121369234/860596ee-5d9d-441c-93f0-ceee805cf8be)
