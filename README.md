# release-testing

Temporary Readme for Joomla 5.0 RC Setup

The setup comprises two folders— one for web servers and another for local mode and a run.sh script. To initiate the process, use the command `./run.sh` or `./run.sh <your-website-domain>`.
For example: `./run.sh https://example.joom.ws/`

When you execute the command `./run.sh <website-domain>`, the system launches the web-server script. Subsequently, it prompts you for your site username and password. The script then downloads necessary dependencies, and checks for the presence of the configuration.php file in the joomla-backup folder. If the file is not found, the system waits for you to paste the configuration file. Once provided, it inserts environment variables into the Cypress configuration file and runs Cypress tests. Notably, these tests are independent and do not rely on a database.

Alternatively, if you run `./run.sh` without providing any input, the system operates in a local mode. It sets up a database, downloads necessary dependencies, and waits for the configuration file on localhost:2005.  Afterwards, you can enter default credentials for installation, and the system automatically executes the tests. The default credentials are:
```
environment:
      JOOMLA_SITE_NAME: "Joomla Test Site"
      JOOMLA_ADMIN_USER: admin
      JOOMLA_ADMIN_USERNAME: admin
      JOOMLA_ADMIN_PASSOWRD: admin12345678
      JOOMLA_ADMIN_EMAIL: admin@example.com
      JOOMLA_DB_HOST: mysql
      JOOMLA_DB_USER: root
      JOOMLA_DB_PASSWORD: example12345678
      JOOMLA_DB_NAME: joomla
      JOOMLA_INSTALLATION_DISABLE_LOCALHOST_CHECK: 1
```

- Use the following command to run all tests:
`npx cypress run`

- Use the following command to run tests in a specific folder:
`npx cypress run --spec "tests/cypress/integration/<folder-name>/*.cy.js"`
For example: `npx cypress run --spec "tests/cypress/integration/administrator/*.cy.js"` runs tets in the administrator folder.
