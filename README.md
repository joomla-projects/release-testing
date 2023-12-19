# release-testing

Temporary Readme for Joomla 5.0 RC Setup

The setup comprises two folders— one for web servers and another for local mode and a run.sh script. To initiate the process, use the command `./run.sh` or `./run.sh <your-website-domain>`.
For example: `./run.sh https://example.joom.ws/`

When you execute the command `./run.sh <website-domain>`, the system launches the web-server script. Subsequently, it prompts you for your site username and password. The script then downloads necessary dependencies, and checks for the presence of the configuration.php file in the joomla-backup folder. If the file is not found, the system waits for you to paste the configuration file. Once provided, it inserts environment variables into the Cypress configuration file and runs Cypress tests. Notably, these tests are independent and do not rely on a database.

Alternatively, if you run `./run.sh` without providing any input, the system operates in a local mode. It sets up a database, downloads necessary dependencies, and waits for the configuration file on localhost:3081.

If you do not provide a backup of an existing site it will install a new Joomla! site for you.

The site is available on `localhost:3081` and you can login with \
username: admin \
password: admin12345678

If you put a complete zip-archive and also a sql dump file from an existing site into the folder `local/joomla-backup` it will set up your own site and ask for your credentials on start.

The local mode also provides a phpmyadmin that you can reach under `localhost:3082` to see what is going on in the DB.

It is also set up a mailcatcher container reachable under `localhost:3083` so you can test the system mail delivery from the site. 

Afterwards the system automatically executes the tests. 

The default credentials for a new installation are:
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
