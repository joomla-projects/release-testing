# Release Testing
**Release testing** plays a crucial role in the Joomla development cycle. It ensures that new versions of the CMS are stable, almost bug-free, and ready for public use. Minor updates of the Joomla CMS are released as minor updates every six (6) Tuesdays (although the schedule may vary) - [Joomla! Project Roadmap](https://developer.joomla.org/roadmap.html). \
One week before the official release, a Release Candidate (RC) version is made available for testing and **community participation is essential.**

> **The more people who test, the better the quality of the final release.**

However, manually testing every feature and step can be time-consuming and resource-intensive. That's why we've tried to  develop a **simple and intuitive solution** to streamline the testing process. Our goal is to make testing as easy and accessible as possible.

With our project, you can easily test either a brand-new Joomla site or your own existing site. Use the restore option to quickly create a local clone of your Joomla site or simply use the remote option, allowing for fast and efficient testing in a controlled environment. 

This repository takes care of all the dependencies for you, so there's no need to worry about configuring them manually. We've made the process straightforward, so you can focus on testing, not troubleshooting.

## Pre Requisites
* **Docker:** This application relies on Docker to create isolated environments and manage its components efficiently. Please install Docker by following [the official documentation](https://docs.docker.com/get-docker/).

* **WSL2 (Windows Subsystem for Linux 2):** If you're using Windows, WSL2 is essential for running Docker containers seamlessly. First you need to [install your preferred Distro into WSL2](https://learn.microsoft.com/en-us/windows/wsl/install). Then start the WSL Console where you find yourself in a full Linux terminal. 

Open a terminal or command prompt and run the following command to check if Docker is installed and running correctly:
```bash
Docker --version
```
## Installation

* Download or clone this repository:
```bash
git clone https://github.com/joomla-projects/release-testing.git
```
**Windows**
* Click on the `start.bat` file to start working in a WSL console.

## Testing

### Joomla E2E Test Suite Options

![grafik](https://github.com/user-attachments/assets/57ea9955-13c6-431d-8c5b-373d93109b0c)

<!-- TBD **1. With a zip-archive and a sql dump file of the site:**

Put a zip-archive (excluding the installation folder) and also a sql dump file of an existing site into the folder `local/joomla-backup`. 
Run this in the `start.exe` file:
```bash
./run.sh
```
It will set up your own site. Subsequently, it prompts you for your site **username and password** to run the tests. It may take some time to establish a database connection, so please be patient.

**2. On a back up Joomla site:**

To initiate the process, use the following command in the `start.exe` file:
```bash
./run.sh <your-website-domain>
```
For example: `./run.sh https://example.joom.ws/`

When you execute the command `./run.sh <website-domain>`, the system launches the web-server script. Subsequently, it prompts you for your **site username and password**. Once provided, it inserts environment variables into the Cypress configuration file and runs Cypress tests. **Notably, these tests work on your site's database.**

**3. Fresh Joomla installation:**

Make sure the `local/joomla-backup` folder is empty and then run this in the `start.exe` file:
```bash
./run.sh
```
If you do not provide a backup of an existing site it will install a new Joomla! site for you. The site is available on `localhost:3081` and you can login with\
username: admin \
password: admin12345678

The local mode also provides a phpmyadmin that you can reach under `localhost:3082` to see what is going on in the DB. It is also set up a mailcatcher container reachable under `localhost:3083` so you can test the system mail delivery from the site.

Afterwards the system automatically opens the tests. Press `ctrl + c` to stop all the containers. -->

The default credentials for a new installation are:
```
environment:
      JOOMLA_SITE_NAME: "${JOOMLA_SITE}"
      JOOMLA_ADMIN_USER: Cy-Admin
      JOOMLA_ADMIN_USERNAME: cy-admin
      JOOMLA_ADMIN_PASSOWRD: admin12345678
      JOOMLA_ADMIN_EMAIL: cy-admin@example.local
      JOOMLA_DB_HOST: mysql
      JOOMLA_DB_USER: root
      JOOMLA_DB_PASSWORD: root
      JOOMLA_DB_NAME: sites_${SITE}
      JOOMLA_INSTALLATION_DISABLE_LOCALHOST_CHECK: 1
```
> For detailed information and the complete documentation, please visit the [Wiki](https://github.com/joomla-projects/release-testing/wiki).
