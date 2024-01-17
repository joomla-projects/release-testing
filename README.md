# Release Testing
Release testing is an important practice of the Joomla development cycle. It helps ensure that new versions of the CMS are stable, bug-free, and ready for public release. Minor updates of Joomla are released every six (6) Tuesdays (schedule may change). One week prior to the release, the update is set for RC (Release Candidate) and available for testing. People are needed to conduct such tests. The more people that test, the better releases can be.

Don't want to waste time and resources clicking on every single item and testing them all? Here, we made an effort to offer a simple, one-step method for conducting the testing. Our objective was to provide a straightforward and understandable way to handle testing. With the help of our project, you can test a completely new Joomla site or even your own site by using the sql dump of the backed-up database and the backup zip archive for your Joomla site. This one repository handles all of the dependencies, so you don't have to worry about messing with them.

## Pre Requisites
* **Docker:** This application relies on Docker to create isolated environments and manage its components efficiently. Please install Docker by following [the official documentation](https://docs.docker.com/get-docker/)

* **WSL2 (Windows Subsystem for Linux 2):** If you're using Windows, WSL2 is essential for running Docker containers seamlessly. First you need to [install your preferred Distro into WSL2](https://learn.microsoft.com/en-us/windows/wsl/install). Then start the WSL Console where you find yourself in a full Linux terminal. 

Open a terminal or command prompt and run the following command to check if Docker is installed and running correctly:
```bash
Docker --version
```

## Structure
Our release tests are conducted with Cypress. The setup consists of a `tests` folder. The tests can be found in its `System/integration` folder. There are already some sample tests written that correspond to the names of the components in the [CMS release sheet](https://docs.google.com/spreadsheets/d/1ciTeoBmzcNJLvFkxIeOsjmUeZbKj1tHREZfQrm3X1-I/edit#gid=225816438). You can find a comprehensive guide on writing tests [here]().

To run these tests on your Joomla site, put a zip-archive (excluding the installation folder) and also a sql dump file of an existing site into the folder `local/joomla-backup`.

If you want to run these tests on a fresh joomla installation make sure the `local/joomla-backup` folder is empty.

## Installation
* Clone this repo (when on windows make sure to be working in wsl console):
```bash
git clone https://github.com/joomla-projects/release-testing.git
```

* Double click the `run.sh` file from the repo or run the following command **in a WSL console**.
```bash
./run.sh
```

## Testing
If you put a complete zip-archive and also a sql dump file from an existing site into the folder `local/joomla-backup` it will set up your own site. Subsequently, it prompts you for your site username and password to run the tests. It may take some time to establish a database connection, so please be patient.

If you do not provide a backup of an existing site it will install a new Joomla! site for you. The site is available on `localhost:3081` and you can login with\
username: admin \
password: admin12345678

The local mode also provides a phpmyadmin that you can reach under `localhost:3082` to see what is going on in the DB. It is also set up a mailcatcher container reachable under `localhost:3083` so you can test the system mail delivery from the site.

Afterwards the system automatically opens the tests. Press `ctrl + c` to stop all the containers.

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
