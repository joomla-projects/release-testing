#!/bin/bash
# @package    Joomla E2E Test Suite
#
# @author     Charvi Mehra <https://github.com/charvimehradu>, Martina Scholz <https://github.com/LadySolveig>
#
# @copyright  (C) 2023-2024 Open Source Matters, Inc. <http://www.joomla.org>
# @license    GNU General Public License version 2 or later; see LICENSE.txt


# Setup root directory
REAL_ROOT=$(realpath $(dirname $0))
REAL_TOOLS=$(realpath $REAL_ROOT/.tools)

BUILD=$REAL_TOOLS/build

# Load environment variables from .env file
. $REAL_TOOLS/.env

if [ -f $REAL_TOOLS/scripts/.colors ];
then
  . $REAL_TOOLS/scripts/.colors
fi

function localread() {
  L_LABEL=$1
  L_DEFAULT=$2
  L_VAR=$3
  L_ADDITIONAL=$4

  if [ -z "${!L_VAR}" ];
  then
	# Using workaround because OSX supports only bash 3.2 which doesn't support
	if [ "${BASH_VERSINFO:-0}" -ge 4 ];
	then
	  read "-${L_ADDITIONAL}rep" "${L_LABEL} " -i "${L_DEFAULT}" "${L_VAR}"
	else
	  # BASH 3.2 compatible code start
	  if [ ! -z "${L_DEFAULT}" ];
	  then
		L_LABEL="${L_LABEL} [${L_DEFAULT}]"
	  fi

	  if read "-${L_ADDITIONAL}rep" "${L_LABEL} " "${L_VAR}" && [[ ${L_VAR} ]]; then
		  return 0
	  else
		  printf -v "${L_VAR}" %s "${L_DEFAULT}"
	  fi
	fi
	# BASH 3.2 compatible code end
  fi
  # echo -e "\n"
}

# Function to start Cypress tests
# Usage: start-cypress
# This function starts the Cypress tests either on a remote site or locally.
# If the CYPRESS_OPTION is set to "remote", it prompts the user for the site URL, username, password, and project folder.
# It then checks if the site is reachable and if the project folder exists.
# If the CYPRESS_OPTION is set to "local", it prompts the user for the project folder and the local site to test.
# It lists all available local sites and allows the user to select one or create a new site.
# It then checks if the project folder exists and if the selected site exists and has a configuration file.
# After the necessary information is gathered, it starts the Cypress tests.
# The function provides options to run the tests in headless mode, restart the containers, restart in debug mode, or stop the container.
start-cypress () {

	cypress-stop

  check-image-build

  if [ $CYPRESS_OPTION == "remote" ]; then
    tmp_user=$JUSER
    tmp_domain=$JDOMAIN
    unset JUSER
    unset JPASSWORD
    unset JDOMAIN

    echo -e "${BG_BLUE}To start the cypress tests on remote site we need some info first${CLEAR_COLOR}"

    localread "Enter your site url (with http(s)://): " "$tmp_domain" JDOMAIN
    if [ -z $JDOMAIN ]; then
      echo -e "${FC_RED}No site url defined for testing with cypress${CLEAR_COLOR}"
      return 1
    fi

    wg_result=$(wget --max-redirect=0 --spider -S $JDOMAIN 2>&1 | grep "HTTP/" | awk '{print $2}')

    if [ -z $wg_result ] || [ $wg_result -lt 200 ] || [ $wg_result -ge 400 ] ; then
      echo -e "${FC_RED}Is your site up? Can't reach ${FC_BOLDU_INLINE}$JDOMAIN${CLEAR_COLOR_INLINE}${FC_RED_INLINE} for testing with cypress${CLEAR_COLOR}"
      return 1
    fi

    localread "Enter your site username: " "$tmp_user" JUSER
    if [ -z $JUSER ]; then
      echo -e "${FC_RED}No ${FC_BOLDU_INLINE}USER${CLEAR_COLOR_INLINE}${FC_RED_INLINE} defined for testing with cypress${CLEAR_COLOR}"
      return 1
    fi

    # Prompt user for password (-s for privacy)
    localread "Enter your site password: " "" JPASSWORD s
    if [ -z $JPASSWORD ]; then
      echo -e "${FC_RED}No ${FC_BOLDU_INLINE}PASSWORD${CLEAR_COLOR_INLINE}${FC_RED_INLINE} defined for testing with cypress${CLEAR_COLOR}"
      return 1
    fi

    # Prompt user for project
    tmp_project=${PROJECT:-"remote"}
    unset PROJECT

    echo -e "${FC_BLUE}Cypress needs a ${FC_BOLDU_INLINE}folder${CLEAR_COLOR_INLINE}${FC_BLUE_INLINE} as project where the tests are stored${CLEAR_COLOR}"
    echo -e "Defaul folder: ${FC_BOLDU_INLINE}remote${CLEAR_COLOR_INLINE}\n"

    localread "Enter your project: " "$tmp_project" PROJECT
    if [ -z $PROJECT ] || [ ! -d $REAL_ROOT/$PROJECT ]; then
      echo -e "${FC_RED}No ${FC_BOLDU_INLINE}project${CLEAR_COLOR_INLINE}${FC_RED} defined for testing with cypress${CLEAR_COLOR}"
      echo -e " > Please create a project ${FC_BOLDU_INLINE}folder${CLEAR_COLOR_INLINE}$ and try again\n"
      echo -e " > ${REAL_ROOT}/${PROJECT} - missing\n\n"
      return 1
    fi

  fi

  if [ $CYPRESS_OPTION == "local" ]; then

    check-web-image-build

    # Prompt user for project
    tmp_project=${PROJECT:-"local"}
    tmp_site=$SITE
    unset PROJECT
    unset SITE
    # Define default values for local testing
    JUSER="admin"
    JPASSWORD="admin12345678"

    echo -e "${BG_BLUE}To start the local cypress test we need some info first${CLEAR_COLOR}"

    echo -e "${FC_BLUE}Cypress needs a ${FC_BOLDU_INLINE}folder${CLEAR_COLOR_INLINE}${FC_BLUE_INLINE} as project where the tests are stored${CLEAR_COLOR}"
    echo -e "Defaul folder: ${FC_BOLDU_INLINE}local${CLEAR_COLOR_INLINE}\n"

    localread "Enter your project: " "$tmp_project" PROJECT
    if [ -z $PROJECT ] || [ ! -d $REAL_ROOT/$PROJECT ]; then
      echo -e "${FC_RED}No ${FC_BOLDU_INLINE}project${CLEAR_COLOR_INLINE}${FC_RED} defined for testing with cypress${CLEAR_COLOR}"
      echo -e " > Please create a project ${FC_BOLDU_INLINE}folder${CLEAR_COLOR_INLINE}$ and try again\n"
      echo -e " > ${REAL_ROOT}/${PROJECT} - missing\n\n"
      return 1
    fi

    # Prompt user for site
    # List all available sites
    readarray -t array < <(find $REAL_ROOT/data/sites/ -mindepth 1 -maxdepth 1 -type d -printf '%P\n')

    IFS=$'\n' arrSites=($(sort <<<"${array[*]}")); unset IFS

    echo -e "${FC_BLUE}Select a local site:${CLEAR_COLOR}"

    echo -e " > To create a new site please make sure to have a installable ${FC_BOLDU_INLINE}Joomla full package (zip)${CLEAR_COLOR_INLINE} in your ${FC_BOLDU_INLINE}/data/install${CLEAR_COLOR_INLINE} folder.\n"

    unset SITE

    select SITE in INSTALL-NEW ${arrSites[@]} quit; do
      case $SITE in
        quit)
          return 1
          ;;
        INSTALL-NEW)
          unset SITE
          setup-site
          if [ $? -eq 1 ]; then
            echo -e "${FC_RED}Site ${FC_BOLDU_INLINE}${SITE:-empty}${CLEAR_COLOR_INLINE}${FC_RED_INLINE} could not be created${CLEAR_COLOR}"
            continue
          fi
          break
          ;;
        *)
          if [ -z $SITE ] || ! [[ ${arrSites[@]} =~ "$SITE" ]];then
            echo -e "${FC_RED}No available site selected${CLEAR_COLOR}"
            continue
          fi
          if [ ! -d $REAL_ROOT/data/sites/$SITE ]; then
            echo -e "${FC_RED}Site does not exist data/sites/${SITE}${CLEAR_COLOR}"
            continue
          fi
          if [ ! -f $REAL_ROOT/data/sites/$SITE/configuration.php ]; then
            echo -e "${FC_RED}No Configuration File found for your Joomla site ${SITE}${CLEAR_COLOR}"
            echo -e " > data/sites/${SITE}/configuration.php - missing\n"
            echo -e " > Please install site ${SITE} first and try again\n\n"
            continue
          fi
          break
          ;;
      esac

    done
    
  fi

	cypress-start

	unset cy_options
	declare -a cy_options=("headless" "restart" "restart-debug" "stop")
	select cy_option in ${cy_options[@]}; do
		case $cy_option in
			headless)
        # cypress-stop
        check-image-build
        echo -e "${FC_BLUE}Running Cypress in headless mode${CLEAR_COLOR}"
        cypress-run
        echo -e "${BG_GREEN}Cypress tests done - reports can be found in folder System/output/reports${CLEAR_COLOR}"
			  continue
			  ;;
			restart)
			  cypress-stop
        check-image-build
			  cypress-start
			  ;;
			restart-debug)
			  cypress-stop
        check-image-build
			  cypress-debug
			  ;;
			stop)
			  cypress-stop
			  break
			  ;;
			*) 
	  		  echo "Invalid option $REPLY"
	  		  ;;
  		esac
	done

}

# Function to stop and clean up all running containers for the Joomla E2E Test Suite
cypress-stop () {

  echo -e "${FC_YELLOW}Cleaning up all running containers - Joomla E2E Test Suite${CLEAR_COLOR}"

  export-variables
  
  docker compose -f $REAL_TOOLS/docker-compose.yml down --remove-orphans
  docker compose -f $REAL_TOOLS/local/compose.yml -f $REAL_TOOLS/local/compose.local.yml down --remove-orphans

  return 0
	
}

# Function to start Cypress container
cypress-start () {

  export-variables

  # Check if Cypress option is set to "remote"
  if [ $CYPRESS_OPTION == "remote" ]; then
    docker compose -f $REAL_TOOLS/docker-compose.yml up -d --remove-orphans
    echo -e "${BG_BLUE}Open Cypress for site: $JDOMAIN${CLEAR_COLOR}"
    cypress-start-feedback
    return
  fi

  # Check if Cypress option is set to "local"
  if [ $CYPRESS_OPTION == "local" ]; then
    docker compose -f $REAL_TOOLS/local/compose.yml -f $REAL_TOOLS/local/compose.local.yml up -d --remove-orphans
    echo -e "${BG_BLUE}Open Cypress for site: $SITE and project: $PROJECT${CLEAR_COLOR}"
    cypress-start-feedback
    return
  fi

  # If no valid Cypress start option is provided
  echo -e "${BG_RED}No valid Cypress start option provided - Please try again${CLEAR_COLOR}"
}

# Function to provide feedback after starting Cypress container
cypress-start-feedback() {
  echo -e " > ... please wait ..."
  sleep 4
  echo -e "${BG_GREEN}http://localhost:8080/vnc.html?autoconnect=true${CLEAR_COLOR}"
}

# Function to start Cypress container in debug mode
cypress-debug () {

  export-variables

  if [ $CYPRESS_OPTION == "remote" ]; then
    echo -e "${BG_BLUE}Open Cypress for site: $JDOMAIN${CLEAR_COLOR}"
    cypress-start-feedback-debug
    docker compose -f $REAL_TOOLS/docker-compose.yml up --remove-orphans
    return
  fi

  if [ $CYPRESS_OPTION == "local" ]; then
    docker compose -f $REAL_TOOLS/local/compose.yml -f $REAL_TOOLS/local/compose.local.yml up --remove-orphans
    echo -e "${BG_BLUE}Open Cypress for site: $SITE and project: $PROJECT${CLEAR_COLOR}"
    cypress-start-feedback-debug
    return
  fi

  echo -e "${BG_RED}No valid Cypress start option provided - Please try again${CLEAR_COLOR}"
}

# Function to provide feedback after starting Cypress container in debug mode
cypress-start-feedback-debug() {
	echo -e "${BG_GREEN}access to cypress via http://localhost:8080/vnc.html?autoconnect=true after full startup ${CLEAR_COLOR}"

}

# Function to run Cypress tests in a container in headless mode
# Usage: cypress-run
# This function prompts the user to select a browser to run the tests in.
# It then asks for additional command parameters, if any, and runs the tests using the selected browser.
# If the user selects "quit", it stops the Cypress container.
cypress-run () {
  CONTAINER="cypress"
  COMPOSEFILES="$REAL_TOOLS/local/compose.yml"

  if [ $CYPRESS_OPTION == "remote" ]; then
    COMPOSEFILES="$REAL_TOOLS/docker-compose.yml"
  fi

  unset cy_browser
	declare -a cy_browsers=("firefox" "chromium" "edge" "chrome" "electron")
	select cy_browser in ${cy_browsers[@]} quit; do
		case $cy_browser in
      firefox|chromium|edge|chrome|electron)

        local tmp_cy_command_additional=${cy_command_additional:-""}
        unset cy_command_additional
        echo -e "${FC_BLUE}Enter additional command params (optional)${CLEAR_COLOR}"
        echo -e " > e.g. --spec 'System/integration/administrator/components/com_content/*'\n"

        localread "=> Command (optional): " "${tmp_cy_command_additional}" cy_command_additional

        run-command-container "cd /e2e/tests && cypress run --browser ${cy_browser} ${cy_command_additional}" true
        break
        ;;
			quit)
			  cypress-stop
			  break
			  ;;
			*) 
        echo "Invalid option $REPLY"
        ;;
  		esac
	done
}

# Function to check if the Docker image for Cypress is built and build it if necessary.
check-image-build () {
  is_build=$(docker image inspect ${IMAGE_NAME_TAG} > /dev/null 2>&1 && echo "true" || echo "")

  if [ -z ${is_build:-""} ]; then
    echo -e "${FC_BLUE}No image for cypress found - building one for you${CLEAR_COLOR}"
    # exit 1

    read -rp "Confirm (y/N): " USERCONFIRMBUILD
    if [[ $USERCONFIRMBUILD = "y" || $USERCONFIRMBUILD = "Y" ]]; then
      BUILD=$REAL_TOOLS/build
      source $REAL_TOOLS/build/build.sh
    else
      echo -e "${FC_YELLOW}Shutting down Joomla E2E Test Suite${CLEAR_COLOR}"
      exit 1
    fi

    echo -e "${FC_GREEN}Image for cypress build done${CLEAR_COLOR}"
  fi
}

# Function to check if the web image is built and build it if necessary.
check-web-image-build () {
  is_build=$(docker image inspect ${WEB_IMAGE_NAME_TAG} > /dev/null 2>&1 && echo "true" || echo "")
  if [ -z ${is_build:-""} ]; then
    echo -e "${FC_BLUE}No image for local webserver found - building one for you${CLEAR_COLOR}"

    unset USERCONFIRMBUILD
    localread "Confirm (y/N): " "" USERCONFIRMBUILD
    if [[ $USERCONFIRMBUILD = "y" || $USERCONFIRMBUILD = "Y" ]]; then
      BUILD=$REAL_TOOLS/build/web
      source $REAL_TOOLS/build/web/build.sh
    else
      echo -e "${FC_YELLOW}Shutting down Joomla E2E Test Suite${CLEAR_COLOR}"
      exit 1
    fi

    echo -e "${FC_GREEN}Image for local webserver build done${CLEAR_COLOR}"
  fi
}

# Function to check if a container is running
# Usage: check-containers-running
# Returns:
#   0 if the container is running
#   1 if the container is not running and an attempt to start it is made
check-containers-running() {  
  if [ ! "$(docker ps -q -f name=joomla_cypress_$CONTAINER)" ]; then
    export-variables
    echo -e "${FC_YELLOW}Container joomla_cypress_$CONTAINER is not running ... Trying to start now${CLEAR_COLOR}"
    docker compose -f $REAL_TOOLS/local/compose.yml up -d $CONTAINER
    return 1
  fi
  return 0
}

# Function to export repeatedly used variables
export-variables() {
  export JOOMLA_USERNAME=${JUSER:-"admin"} JOOMLA_PASSWORD=${JPASSWORD:-"admin12345678"} DOMAIN=${JDOMAIN:-"http:web.local/${SITE:-"test"}"} \
         JOOMLA_PROJECT=${PROJECT:-"local"} JOOMLA_SITE=${SITE:-"test"} ROOT=$REAL_ROOT
}

# Function to run the command in a container
# Usage: run-command-container $1
# $1: command to run
# $2: flag if run with -c
# $CONTAINER: container to run the command in
# $COMPOSEFILES: compose files to use
run-command-container() {

  export-variables

  if [ -z ${2+x} ]; then
    docker compose -f $COMPOSEFILES exec -it $CONTAINER /bin/bash $1
    return 0
  fi
  docker compose -f $COMPOSEFILES exec -it $CONTAINER /bin/bash -c "$1"
}

# Function to set up a new Joomla site installation locally in a container `web.local`
# This function checks if the necessary containers are running, prompts the user to select a zip file for installation,
# asks for a new site name, creates the site directory, unzips the Joomla installation files, creates a symbolic link,
# and installs Joomla on the specified site folder.
# Returns 0 on success, 1 on failure.
setup-site () {

  check-web-image-build
  CONTAINER="web.local"
  check-containers-running
  CONTAINER="mysql"
  check-containers-running
  CONTAINER="phpmyadmin"
  check-containers-running

  array=()
  for file in $REAL_ROOT/data/install/*zip; do
    array=(${array[@]} "$(basename -- "$file")")
  done

  IFS=$'\n' arrInstallZip=($(sort <<<"${array[*]}")); unset IFS

  echo -e "${BG_BLUE}Select a zip file for the installation:${CLEAR_COLOR}"

  select VERSION in ${arrInstallZip[@]} quit; do
    case $VERSION in
      quit)
        return 1
        ;;
      *)
        if [ -z $VERSION ] || ! [[ ${arrInstallZip[@]} =~ "$VERSION" ]];then
          echo -e "${FC_YELLOW}No package for installation selected - please choose one available.${CLEAR_COLOR}"
          continue
        fi

        tmp_site=$SITE
        unset SITE
        # Prompt user for site
        echo -e "\n"
        localread "Enter your new site name: " "$tmp_site" SITE
        if [ -z "$SITE" ]; then
          echo -e "${FC_RED}No ${FC_BOLDU_INLINE}Site${CLEAR_COLOR_INLINE}${FC_RED_INLINE} defined${CLEAR_COLOR}"
          return 1
        fi
        SITE=${SITE/' '/'_'}
        SITE=${SITE//[^[:alnum:]]/'_'}
        SITE=${SITE/-/_}
        SITE=${SITE//+(_)/_}
        SITE=${SITE/#-}
        SITE=${SITE/%-}
        SITE=$(echo "$SITE" | sed 's/.*/\L&/')
        if [ -d $REAL_ROOT/data/sites/$SITE ]; then
          echo -e "${FC_RED}Site already exists - ${FC_BOLDU_INLINE}data/sites/${SITE}${CLEAR_COLOR_INLINE}${FC_RED_INLINE}${CLEAR_COLOR}"
          return 1
        fi
    
        echo -e "${FC_BLUE}Create site ${FC_BOLDU_INLINE}${SITE}${CLEAR_COLOR_INLINE}${FC_BLUE_INLINE} with ${FC_BOLD_INLINE}${VERSION}${CLEAR_COLOR_INLINE}${FC_BLUE_INLINE}?${CLEAR_COLOR}"
        unset USERCONFIRMATION
        localread "Confirm (y/N): " "" USERCONFIRMATION
        if [[ $USERCONFIRMATION = "y" || $USERCONFIRMATION = "Y" ]]; then
          if [ ! -d $REAL_ROOT/data/sites/$SITE ]; then
            mkdir -p $REAL_ROOT/data/sites/$SITE

            echo -e "${FC_BLUE}Unzip Joomla ${FC_BOLD_INLINE}$VERSION${CLEAR_COLOR_INLINE}${FC_BLUE_INLINE} on Folder: ${FC_BOLDU_INLINE}$SITE${CLEAR_COLOR}"

            CONTAINER="web.local"
            COMPOSEFILES="$REAL_TOOLS/local/compose.yml"

            run-command-container "unzip -q /usr/src/Projects/data/install/$VERSION -d /usr/src/Projects/data/sites/$SITE" true

            run-command-container "ln -sfn /usr/src/Projects/data/sites/$SITE /var/www/html/$SITE" true
            
            echo -e "${BG_BLUE}Install Joomla $VERSION on Folder: $SITE${CLEAR_COLOR}"

            run-command-container "/usr/src/Projects/.tools/scripts/install-joomla.sh /var/www/html/$SITE sites_$SITE Joomla-$SITE mailcatcher r true"
            
            return 0
          fi
        else
          return 1
        fi
      ;;
    esac

  done

  return 0

}

# Function to remove a local installed Joomla site in container `web.local`
# This function removes a local site from the system, including its files, database, and API token `.secret` variable.
# It prompts the user to select a site from a list of available sites and confirms the removal before proceeding.
remove-site () {
  # Check if web image is built
  check-web-image-build

  # Check if containers are running
  CONTAINER="web.local"
  check-containers-running
  CONTAINER="mysql"
  check-containers-running
  CONTAINER="phpmyadmin"
  check-containers-running

  # Get a list of available sites
  readarray -t array < <(find $REAL_ROOT/data/sites/ -mindepth 1 -maxdepth 1 -type d -printf '%P\n')

  # Sort the list of sites
  IFS=$'\n' arrSites=($(sort <<<"${array[*]}")); unset IFS

  # Prompt the user to select a site to remove
  echo -e "${BG_BLUE}Select a local site to remove:${CLEAR_COLOR}"
  unset SITE
  select SITE in ${arrSites[@]} quit; do
    case $SITE in
      quit)
        break
        ;;
      *)
        # Check if a valid site is selected
        if [ -z $SITE ] || ! [[ ${arrSites[@]} =~ "$SITE" ]];then
          echo -e "${FC_RED}No available site selected${CLEAR_COLOR}"
          continue
        fi

        # Check if the site directory exists
        if [ ! -d $REAL_ROOT/data/sites/$SITE ]; then
          echo -e "${FC_RED}Site does not exist - ${REAL_ROOT}/data/sites/${SITE}${CLEAR_COLOR}"
          continue
        fi

        # Confirm the removal with the user
        echo -e "${BG_YELLOW}Remove Joomla $SITE on Folder: data/sites/${SITE}${CLEAR_COLOR}"
        echo -e "${FC_YELLOW}Are you sure?${CLEAR_COLOR}"
        read -rp "Confirm (y/N): " USERCONFIRMATION
        if [[ $USERCONFIRMATION = "y" || $USERCONFIRMATION = "Y" ]]; then

          # Remove files for the site
          CONTAINER="web.local"
          COMPOSEFILES="$REAL_TOOLS/local/compose.yml"
          echo -e "\n > Remove Files for Joomla $SITE on Folder: data/sites/${SITE}\n"
          run-command-container "rm -r /usr/src/Projects/data/sites/$SITE" true
          run-command-container "unlink /var/www/html/$SITE" true

          # Remove database for the site
          CONTAINER="mysql"
          COMPOSEFILES="$REAL_TOOLS/local/compose.yml"
          echo -e "\n > Remove Database for Joomla $SITE\n"
          run-command-container "export MYSQL_PWD=root && mysql -u root -e 'drop database if exists sites_$SITE'" true

          # Remove API token environment variable if exists in .secret
          LABEL="API_${SITE}="
          API_LABEL=$(printf "%s" ${LABEL} | tr '[:lower:]' '[:upper:]')
          echo -e "\n > Remove API-Token environment variable $API_LABEL if exists in .secret for Joomla $SITE\n"
          if [ -f $REAL_ROOT/.tools/.secret ]; then
            API_LINE=$(grep "^${API_LABEL}" $REAL_ROOT/.tools/.secret)
            sed -i "\:$API_LINE:d" $REAL_ROOT/.tools/.secret
          fi

          echo -e "${BG_GREEN}Site $SITE and Database removed from system${CLEAR_COLOR}"
        fi
        break
        ;;
    esac
  done

  return 0
}

# Welcome User and build container if not exists

echo -e "${BG_BLUE}Welcome to Joomla E2E Test Suite${CLEAR_COLOR}"

echo -e "\n > To run your ${FC_BOLDU_INLINE}remote${CLEAR_COLOR_INLINE} site (e.g. https://example.com) with cypress, use option 1 => remote\n"
echo -e " > To run a Joomla ${FC_BOLDU_INLINE}local${CLEAR_COLOR_INLINE} site locally with cypress, use option 2 => local\n"
echo -e " > To ${FC_BOLDU_INLINE}manage${CLEAR_COLOR_INLINE} your local Joomla sites (create and delete), use option 3 => manage\n"
echo -e " > If you encounter any problems, first try to ${FC_BOLDU_INLINE}shutdown${CLEAR_COLOR_INLINE} your container and start again 4 => shutdown"

echo -e "${FC_BLUE}Let's get started ... ${CLEAR_COLOR}"


# Check the build status of the cypress and php image.
check-image-build
check-web-image-build

selections=(remote local manage shutdown)

PS3="Choose an option: "

# If the selected option is "remote" or "local", the `start-cypress` function is called with the appropriate Cypress option.
# If the selected option is "manage", a sub-menu is displayed for managing local Joomla sites.
# The sub-menu allows the user to create a new local Joomla site, remove an existing site, or quit the sub-menu.
# If the selected option is "shutdown", the `cypress-stop` function is called and a message is displayed indicating that all containers are down and ready to restart.
# If the selected option is "quit", the `cypress-stop` function is called and the loop is exited, terminating the script.
# If an invalid option is selected, an error message is displayed.

select opt in ${selections[@]} quit; do
  case $opt in
    remote)
      CYPRESS_OPTION="remote"
      start-cypress
      ;;
    local)
      CYPRESS_OPTION="local"
      start-cypress
      ;;
    manage)
      echo -e "${BG_BLUE}Manage local Joomla sites${CLEAR_COLOR}"
      select siteopt in create remove quit; do
        case $siteopt in
          create)
            echo -e "${BG_BLUE}Setup new local Joomla site${CLEAR_COLOR}"
            setup-site
            break
            ;;
          remove)
            remove-site
            break
            ;;
          quit)
            break
            ;;
          *) 
            echo "Invalid option $REPLY"
            ;;
        esac
      done
      ;;
    shutdown)
      cypress-stop
      echo -e "${BG_BLUE}All containers down - ready to restart!${CLEAR_COLOR}"
      ;;
    quit)
      cypress-stop
      break
      ;;
    *) 
      echo "Invalid option $REPLY"
      ;;
  esac
done