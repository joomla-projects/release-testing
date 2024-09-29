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

# Function for reading user input if the variable is empty.
# Arguments:
#   $1 – prompt – The input prompt.
#   $2 – default_value – The given default value, to be taken on empty return.
#   $3 – variable – The global variable to be set.
#   $4 – additional – Additional read options, e.g. 's' for silent mode (input chars are not echoed)
#
# This implementation is compatible with using bash 3.2 in macOS without:
#   -e option (use readline e.g. for filename completion) and
#   -i option (text to be placed into the buffer).
#
function localread() {
  local prompt="$1"
  local default_value="$2"
  local variable="$3"
  local additional="$4"

  # Is the variable not set and an input is required?
  if [ -z "${!variable}" ] ; then
      # Is a default value given?
      if [ -n "${default_value}" ] ; then
        prompt="${prompt} [${default_value}]"
      fi
      # Separate prompt from input
      prompt="${prompt}: "
      # [-s] silent
      # -r do not use backslash \ as an escape char
      # -p next argument is the prompt
      read "-${additional}rp" "${prompt}" "${variable}"
      # Input is empty and default is set?
      if [ -z "${!variable}" -a -n "${default_value}" ]; then
        # Use the default value.
        printf -v "${variable}" "%s" "${default_value}"
      fi
  fi
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
    unset JAPITOKEN

    printf "%s\n\n" "$(bg::yellow "[Caution!] - Never perform tests on an active live site!")"

    echo -e " > Please make sure that you are working on a ${FC_BOLDU_INLINE}COPY${CLEAR_COLOR_INLINE} of your site ${FC_BOLDU_INLINE}AND${CLEAR_COLOR_INLINE} database that you can delete afterwards.\n"

    unset USERCONFIRMATION
    localread "Confirm (y/N)" "" USERCONFIRMATION
    if [[ $USERCONFIRMATION != "y" && $USERCONFIRMATION != "Y" ]]; then
      return 1
    fi
    
    printf "%s\n\n" "$(bg::blue "To start the cypress tests on a remote site we need some info first")"

    localread "Enter your site url (with http(s)://)" "$tmp_domain" JDOMAIN
    if [ -z $JDOMAIN ]; then
      printf "%s\n\n" "$(bg::red "No site url defined for testing with cypress")"
      return 1
    fi


    localread "Enter your site username" "$tmp_user" JUSER
    if [ -z $JUSER ]; then
      printf "%s\n\n" "$(bg::red "No USER defined for testing with cypress")"
      return 1
    fi

    # Prompt user for password (-s for privacy)
    localread "Enter your site password" "" JPASSWORD s
    if [ -z $JPASSWORD ]; then
      printf "%s\n\n" "$(bg::red "No PASSWORD defined for testing with cypress")"
      return 1
    fi

    # Prompt user for API-TOKEN (-s for privacy)
    localread "Enter your site API-TOKEN" "" JAPITOKEN s
    if [ -z $JAPITOKEN ]; then
      printf "%s\n\n" "$(bg::red "No API-Token defined for testing with cypress")"
      return 1
    fi

    # Prompt user for project
    tmp_project=${PROJECT:-"cms"}
    unset PROJECT

    echo -e "${FC_BLUE}Cypress needs a ${FC_BOLDU_INLINE}folder${CLEAR_COLOR_INLINE}${FC_BLUE_INLINE} as project where the tests are stored${CLEAR_COLOR}"
    echo -e "Defaul folder: ${FC_BOLDU_INLINE}cms${CLEAR_COLOR_INLINE}\n"

    localread "Enter your project" "$tmp_project" PROJECT
    if [ -z $PROJECT ] || [ ! -d $REAL_ROOT/$PROJECT ]; then
      printf "%s\n\n" "$(bg::red "No project defined for testing with cypress")"
      echo -e " > Please create a project ${FC_BOLDU_INLINE}folder${CLEAR_COLOR_INLINE} and try again\n"
      echo -e " > ${REAL_ROOT}/${PROJECT} - ${FC_RED_INLINE}missing${CLEAR_COLOR}"
      return 1
    fi

  fi

  if [ $CYPRESS_OPTION == "local" ]; then

    check-image-build

    # Prompt user for project
    tmp_project=${PROJECT:-"cms"}
    tmp_site=$SITE
    unset PROJECT
    unset SITE
    # Define default values for local testing
    JUSER="admin"
    JPASSWORD="admin12345678"

    printf "%s\n\n" "$(bg::blue "To start the local cypress test we need some info first")"

    echo -e "${FC_BLUE}Cypress needs a ${FC_BOLDU_INLINE}folder${CLEAR_COLOR_INLINE}${FC_BLUE_INLINE} as project where the tests are stored${CLEAR_COLOR}"
    echo -e "Defaul folder: ${FC_BOLDU_INLINE}cms${CLEAR_COLOR_INLINE}\n"

    localread "Enter your project" "$tmp_project" PROJECT
    if [ -z $PROJECT ] || [ ! -d $REAL_ROOT/$PROJECT ]; then
      printf "%s\n\n" "$(bg::red "No project defined for testing with cypress")"
      echo -e " > Please create a project ${FC_BOLDU_INLINE}folder${CLEAR_COLOR_INLINE} and try again\n"
      echo -e " > ${REAL_ROOT}/${PROJECT} - ${FC_RED_INLINE}missing${CLEAR_COLOR}"
      return 1
    fi

    # Prompt user for site
    # List all available sites
    IFS=$'\n'
      array=($(find $REAL_ROOT/data/sites/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))
    unset IFS

    IFS=$'\n' arrSites=($(sort <<<"${array[*]}")); unset IFS

    while true; do
    echo -e "${FC_BLUE}Select a local site:${CLEAR_COLOR}"
    echo -e " > To create a new site please make sure to have a installable ${FC_BOLDU_INLINE}Joomla full package (zip)${CLEAR_COLOR_INLINE} in your ${FC_BOLDU_INLINE}/data/install${CLEAR_COLOR_INLINE} folder.\n"
    unset SITE
      select SITE in INSTALL-NEW RESTORE-BACKUP ${arrSites[@]} quit; do
        case $SITE in
          quit)
            return 1
            ;;
          INSTALL-NEW)
            unset SITE
            setup-site
            if [ $? -eq 1 ]; then
              echo -e "${FC_RED}Site ${FC_BOLDU_INLINE}${SITE:-empty}${CLEAR_COLOR_INLINE}${FC_RED_INLINE} could not be created.${CLEAR_COLOR}"
              break
            fi
            break 2
            ;;
          RESTORE-BACKUP)
            unset SITE
            restore-site
            if [ $? -eq 1 ]; then
              echo -e "${FC_RED}Site ${FC_BOLDU_INLINE}${SITE:-empty}${CLEAR_COLOR_INLINE}${FC_RED_INLINE} could not be restored from backup.${CLEAR_COLOR}"
              break
            fi
            break 2
            ;;
          *)
            if [ -z $SITE ] || ! [[ ${arrSites[@]} =~ "$SITE" ]];then
              echo -e "${FC_RED}No available site selected${CLEAR_COLOR}"
              break
            fi
            if [ ! -d $REAL_ROOT/data/sites/$SITE ]; then
              echo -e "${FC_RED}Site does not exist data/sites/${SITE}${CLEAR_COLOR}"
              break
            fi
            if [ ! -f $REAL_ROOT/data/sites/$SITE/configuration.php ]; then
              printf "%s\n\n" "$(bg::red "No Configuration File found for your Joomla site ${SITE}")"
              echo -e " > Please install site ${SITE} first and try again\n"
              echo -e " > ${FC_RED}data/sites/${SITE}/configuration.php - ${FC_RED_INLINE}missing${CLEAR_COLOR}"              
              break
            fi
            break 2
            ;;
        esac
      done
    done
    
  fi

	cypress-start

  while true; do
    unset cy_options
    # declare -a cy_options=("headless" "restart" "restart-debug" "reopen-cypress" "stop")
    declare -a cy_options=("headless" "restart" "restart-debug" "stop")
    select cy_option in ${cy_options[@]}; do
      case $cy_option in
        headless)
          # cypress-stop
          check-image-build
          echo -e "${FC_BLUE}Running Cypress in headless mode${CLEAR_COLOR}"
          cypress-run
          printf "%s\n\n" "$(bg::green "Cypress tests done - reports can be found in folder output/reports")"
          break
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
        reopen-cypress)
          # cypress-open
          # break
          ;;
        stop)
          cypress-stop
          break 2
          ;;
        *) 
          echo -e "\n${FC_RED}Invalid option $REPLY${CLEAR_COLOR}"
          break
          ;;
        esac
    done
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
    printf "%s\n\n" "$(bg::blue "Open Cypress for site: $JDOMAIN")"
    cypress-start-feedback
    return
  fi

  # Check if Cypress option is set to "local"
  if [ $CYPRESS_OPTION == "local" ]; then
    docker compose -f $REAL_TOOLS/local/compose.yml -f $REAL_TOOLS/local/compose.local.yml up -d --remove-orphans
    printf "%s\n\n" "$(bg::blue "Open Cypress for site: $SITE and project: $PROJECT")"
    cypress-start-feedback
    if [ $? -eq 1 ]; then
      cypress-stop
      printf "%s\n\n" "$(bg::yellow "Startup process was canceled - please try a restart or restart in debugging mode")"
    fi
    return
  fi

  # If no valid Cypress start option is provided
  printf "%s\n\n" "$(bg::red "No valid Cypress start option provided - Please try again")"
}

# Function to provide feedback after starting Cypress container
cypress-start-feedback() {
  echo -en " > ... please wait - Cypress is starting ."
  CONTAINER="joomla_cypress"
  breakout=0
  unset key
  if [ ! "$(docker ps -q -f name=$CONTAINER)" ]; then
    echo -e "\n${FC_RED}Cypress container could not be started${CLEAR_COLOR}"
    return 1
  fi

  while [ "`docker inspect -f '{{.State.Running}}' $CONTAINER`" != "true" ] || [ "`docker inspect -f {{.State.Health.Status}} $CONTAINER`" != "healthy" ]; do
      echo -n "."
      sleep 2;
      if [ "`docker inspect -f '{{.State.Running}}' $CONTAINER`" != "true" ] || [ "`docker inspect -f {{.State.Health.Status}} $CONTAINER`" != "healthy" ]; then
        breakout=$(($breakout+1))
        if [ $breakout -gt 1 ] && [ $(($breakout % 60)) == 0 ]; then
            echo -e "\n${FC_YELLOW} Starting Cypress takes a bit longer than expected, giving it a chance and wait?${CLEAR_COLOR}"
            unset USERCONFIRMATION
            localread "Confirm (y/N)" "y" USERCONFIRMATION
            if [[ $USERCONFIRMATION = "n" || $USERCONFIRMATION = "N" ]]; then
              unset USERCONFIRMATION
              echo -e "\n${FC_YELLOW} Restart Cypress Container in detached mode for debugging?${CLEAR_COLOR}"
              localread "Confirm (y/N)" "" USERCONFIRMATION
              if [[ $USERCONFIRMATION = "y" || $USERCONFIRMATION = "y" ]]; then
                echo -e '\n > Restart cypress container in detached mode for debugging'
                cypress-debug
                break
              fi
              echo -e "\n${FC_RED}Cypress container could not be started${CLEAR_COLOR}"
              return 1
            fi
            echo -en ' > ... please wait - we are still trying to start cypress .'
        fi
      fi
  done
  if [ ! "$(docker ps -q -f name=$CONTAINER)" ] || [ "`docker inspect -f '{{.State.Running}}' $CONTAINER`" != "true" ]; then
    echo -e "\n${FC_RED}Cypress container could not be started${CLEAR_COLOR}"
    return 1
  fi
  echo -e "\n"
  printf "%s\n\n" "$(bg::green "http://localhost:5800/vnc.html?autoconnect=true")"
  return 0
}

# Function to start Cypress container in debug mode
cypress-debug () {

  export-variables

  if [ $CYPRESS_OPTION == "remote" ]; then
    printf "%s\n\n" "$(bg::blue "Open Cypress for site: $JDOMAIN")"
    cypress-start-feedback-debug
    docker compose -f $REAL_TOOLS/docker-compose.yml up --remove-orphans
    return
  fi

  if [ $CYPRESS_OPTION == "local" ]; then
    docker compose -f $REAL_TOOLS/local/compose.yml -f $REAL_TOOLS/local/compose.local.yml up --remove-orphans
    printf "%s\n\n" "$(bg::blue "Open Cypress for site: $SITE and project: $PROJECT")"
    cypress-start-feedback-debug
    return
  fi

  printf "%s\n\n" "$(bg::red "No valid Cypress start option provided - Please try again")"
}

# Function to provide feedback after starting Cypress container in debug mode
cypress-start-feedback-debug() {
	printf "%s\n\n" "$(bg::green "access to cypress via http://localhost:5800/vnc.html?autoconnect=true after full startup")"
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
  
  while true; do
    unset cy_browser
	  declare -a cy_browsers=("firefox" "chrome" "electron")
    select cy_browser in ${cy_browsers[@]} quit; do
      case $cy_browser in
        firefox|chrome|electron)

          local tmp_cy_command_additional=${cy_command_additional:-""}
          unset cy_command_additional
          echo -e "${FC_BLUE}Enter additional command params (optional)${CLEAR_COLOR}"
          echo -e " > e.g. --spec 'cypress/e2e/administrator/components/com_content/*'\n"

          localread "=> Command (optional)" "${tmp_cy_command_additional}" cy_command_additional

          run-command-container "cd /e2e/tests && cypress run --browser ${cy_browser} ${cy_command_additional}" true
          break 2
          ;;
        quit)
          cypress-stop
          break 2
          ;;
        *) 
          echo -e "\n${FC_RED}Invalid option $REPLY${CLEAR_COLOR}"
          break
          ;;
        esac
    done
	done
}

# Function to open Cypress interactive with or without debug mode enabled
# cypress-open () {
  # CONTAINER="cypress"
  # COMPOSEFILES="$REAL_TOOLS/local/compose.yml"

  # if [ $CYPRESS_OPTION == "remote" ]; then
    # COMPOSEFILES="$REAL_TOOLS/docker-compose.yml"
  # fi

  # run-command-container "cd /e2e/tests && cypress open --project '/e2e/tests' " true
# }

# Function to check if the Docker image for Cypress is built and build it if necessary.
check-image-build () {
  is_build=$(docker image inspect ${IMAGE_NAME_TAG} > /dev/null 2>&1 && echo "true" || echo "")
  is_build_web=$(docker image inspect ${WEB_IMAGE_NAME_TAG} > /dev/null 2>&1 && echo "true" || echo "")

  if [ -z ${is_build:-""} ] && [ -z ${is_build_web:-""} ]; then
    echo -e "${FC_BLUE}No images found - build them for you for you?!!${CLEAR_COLOR}"

    confirm-build-image

    # Build the cypress image
    BUILD=$REAL_TOOLS/build
    source $REAL_TOOLS/build/build.sh

    # Build the web.local image
    BUILD=$REAL_TOOLS/build/web
    source $REAL_TOOLS/build/web/build.sh

    echo -e "${FC_GREEN}Build for cypress and web.local images done${CLEAR_COLOR}"
    return 0

  fi

  if [ -z ${is_build:-""} ]; then
    echo -e "${FC_BLUE}No docker image for cypress found - building one for you${CLEAR_COLOR}"
    
    confirm-build-image

    # Build the cypress image
    BUILD=$REAL_TOOLS/build
    source $REAL_TOOLS/build/build.sh

    echo -e "${FC_GREEN}Image for cypress build done${CLEAR_COLOR}"
    return 0
  fi

  if [ -z ${is_build_web:-""} ]; then
    echo -e "${FC_BLUE}No docker image for local webserver found - building one for you${CLEAR_COLOR}"

    confirm-build-image

    # Build the web.local image
    BUILD=$REAL_TOOLS/build/web
    source $REAL_TOOLS/build/web/build.sh

    echo -e "${FC_GREEN}Image for local webserver build done${CLEAR_COLOR}"
    return 0
  fi
}

confirm-build-image () {
  unset USERCONFIRMBUILD
  localread "Confirm (y/N): " "y" USERCONFIRMBUILD
  if [[ $USERCONFIRMBUILD = "y" || $USERCONFIRMBUILD = "Y" ]]; then
    return 0
  else
    echo -e "${FC_YELLOW}Shutting down Joomla E2E Test Suite${CLEAR_COLOR}"
    exit 1
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

check-local-containers-running() {
  check-image-build
  CONTAINER="web.local"
  check-containers-running
  CONTAINER="mysql"
  check-containers-running
  CONTAINER="phpmyadmin"
  check-containers-running
}

# Function to export repeatedly used variables
export-variables() {
  export JOOMLA_USERNAME=${JUSER:-"cy-admin"} JOOMLA_PASSWORD=${JPASSWORD:-"admin12345678"} DOMAIN=${JDOMAIN:-"http:web.local/${SITE:-"test"}"} \
         JOOMLA_PROJECT=${PROJECT:-"cms"} JOOMLA_SITE=${SITE:-"test"} ROOT=$REAL_ROOT WEB_LOCAL_PORT=${WEB_LOCAL_PORT:-"8080"} \
         WEB_LOCAL_PORT_SSL=${WEB_LOCAL_PORT_SSL:-"4433"} JOOMLA_API_TOKEN=${JAPITOKEN:-}
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

  check-local-containers-running

  array=()
  for file in $REAL_ROOT/data/install/*zip; do
    if [ -f "$file" ]; then
      array=(${array[@]} "$(basename -- "$file")")
    fi
  done

  if [[ ! ${array[@]} ]]; then
    printf "%s\n\n" "$(bg::red "Installation unfortunately not possible!")"
    echo -e " > No ${FC_BOLDU_INLINE}Joomla full package (zip)${CLEAR_COLOR_INLINE} found in your ${FC_BOLDU_INLINE}/data/install${CLEAR_COLOR_INLINE} folder.\n"
    echo -e "${FC_BLUE}Please download a Joomla full package (zip) and try again${CLEAR_COLOR}"
    return 1
  else
    IFS=$'\n' arrInstallZip=($(sort <<<"${array[@]}")); unset IFS  

    while true; do
      printf "%s\n\n" "$(bg::blue "Select a zip file for the installation:")"
      select VERSION in ${arrInstallZip[@]} quit; do
        case $VERSION in
          quit)
            return 1
            ;;
          *)
            if [ -z $VERSION ] || ! [[ ${arrInstallZip[@]} =~ "$VERSION" ]];then
              echo -e "${FC_YELLOW}No package for installation selected - please choose one available.${CLEAR_COLOR}"
              break
            fi

            prepare-new-site

            if [ $? -eq 1 ]; then
              return 1
            fi

            echo -e "${FC_BLUE}Create site ${FC_BOLDU_INLINE}${SITE}${CLEAR_COLOR_INLINE}${FC_BLUE_INLINE} with ${FC_BOLD_INLINE}${VERSION}${CLEAR_COLOR_INLINE}${FC_BLUE_INLINE}?${CLEAR_COLOR}"
            unset USERCONFIRMATION
            localread "Confirm (y/N)" "" USERCONFIRMATION
            if [[ $USERCONFIRMATION = "y" || $USERCONFIRMATION = "Y" ]]; then
              if [ ! -d $REAL_ROOT/data/sites/$SITE ]; then
                mkdir -p $REAL_ROOT/data/sites/$SITE

                echo -e "${FC_BLUE}Unzip Joomla ${FC_BOLD_INLINE}$VERSION${CLEAR_COLOR_INLINE}${FC_BLUE_INLINE} on Folder: ${FC_BOLDU_INLINE}$SITE${CLEAR_COLOR}"

                CONTAINER="web.local"
                COMPOSEFILES="$REAL_TOOLS/local/compose.yml"

                run-command-container "unzip \"/usr/src/Projects/data/install/$VERSION\" -d /usr/src/Projects/data/sites/$SITE | pv -l -s \$(unzip -Z -1 \"/usr/src/Projects/data/install/$VERSION\" | wc -l) > \/dev\/null" true

                run-command-container "ln -sfn /usr/src/Projects/data/sites/$SITE /var/www/html/$SITE" true
                
                printf "%s\n\n" "$(bg::blue "Install Joomla $VERSION on Folder: $SITE")"

                run-command-container "/usr/src/Projects/.tools/scripts/install-joomla.sh /var/www/html/$SITE sites_$SITE Joomla-$SITE mailcatcher r true"
                
                return 0
              fi
            else
              return 1
            fi
          ;;
        esac
      done
    done

    return 0
    
  fi

  return 1

}

restore-site () {
  check-local-containers-running

  echo -e "${FC_BLUE}Restore site with your ${FC_BLUE_INLINE}${FC_BOLD_INLINE}backup files${CLEAR_COLOR_INLINE}${FC_BLUE_INLINE}?${CLEAR_COLOR}"

  unset USERCONFIRMATION
  localread "Confirm (y/N)" "y" USERCONFIRMATION
  if [[ $USERCONFIRMATION != "y" && $USERCONFIRMATION != "Y" ]]; then
    return 1
  fi

  prepare-new-site

  if [ $? -eq 1 ]; then
    return 1
  fi

  if [ ! -d $REAL_ROOT/data/sites/$SITE ]; then
      mkdir -p $REAL_ROOT/data/sites/$SITE
  else
      printf "%s\n\n" "$(bg::red "Site already exists - check: data/sites/${SITE}")"
      return 1
  fi

  # TODO - copy akeeba backup + kickstart.php to /data/sites/$SITE
  # TODO - alternative copy zip and db_dump.sql to /data/sites/$SITE

  printf "\n%s\n\n" "$(bg::blue "Let's start to restore your site locally to ${SITE}")"

  echo -e " > We have tried to open the folder for you into which you can copy your backup files."
  echo -e " > If for some reason this did not work, please copy your backup to the following folder: ${FC_BOLDU_INLINE}data/sites/${SITE}${CLEAR_COLOR_INLINE}.\n"

  
  echo -e " > To restore from a copy via direct FTP(s) download and database dump, please copy ${FC_BOLDU_INLINE}all files${CLEAR_COLOR_INLINE} into the folder and confirm."
  echo -e " > You can also download your page files as a complete ${FC_BOLDU_INLINE}zip archive${CLEAR_COLOR_INLINE} and copy it in the folder. Please store your ${FC_BOLDU_INLINE}database dump${CLEAR_COLOR_INLINE} file next to it.\n"
  echo -e " > To restore with an ${FC_BOLDU_INLINE}Akeeba backup (.jpa, jps)${CLEAR_COLOR_INLINE} please copy the backup file(s) and an ${FC_BOLDU_INLINE}up-to-date kickstart.php${CLEAR_COLOR_INLINE} into the folder."
  echo -e " > We will then provide you with all the information you need to restore your Akeeba backup in the next steps.\n\n"
  
  open "${REAL_ROOT}/data/sites/$SITE"
  
  unset USERCONFIRMATION
  localread "All prepared for restoring your site? (y/N)" "y" USERCONFIRMATION
  if [[ $USERCONFIRMATION = "y" || $USERCONFIRMATION = "Y" ]]; then

      unset ak_backup
      unset ak_kickstart
      unset zip_archive
      unset config_file
      unset db_dump

      CONTAINER="web.local"
      COMPOSEFILES="$REAL_TOOLS/local/compose.yml"

      # Link site folder to web.local www folder
      run-command-container "ln -sfn /usr/src/Projects/data/sites/$SITE /var/www/html/$SITE" true

      # Get Akeeba backup files
      ak_backup=($(find $REAL_ROOT/data/sites/$SITE -mindepth 1 -maxdepth 1 -type f \( -iname "*.jpa" -o -iname "*.jps" \) -exec basename {} \;));

      if [[ ${ak_backup[@]} ]]; then
        # Check if kickstart.php is present
        ak_kickstart=($(find $REAL_ROOT/data/sites/$SITE -mindepth 1 -maxdepth 1 -type f -iname "kickstart.php" -exec basename {} \;));

        echo -e "\nAkeeba backup ${FC_BOLDU_INLINE}${ak_backup[*]}${CLEAR_COLOR_INLINE} found for site ${SITE}"

        if [[ ! ${ak_kickstart[@]} ]]; then
          printf "%s\n" "$(bg::yellow "No kickstart.php found in your /data/sites/${SITE} folder.\n   For restoring your site with an Akeeba backup you will need the kickstart.php present.")"
        fi

        CONTAINER="mysql"

        # Create DB to restore
        # TODO postgresql
        run-command-container "/usr/bin/mysql --defaults-extra-file=<(echo $'[client]\npassword='\"root\") -u root -e \"drop database if exists sites_$SITE\"" true
        run-command-container "/usr/bin/mysql --defaults-extra-file=<(echo $'[client]\npassword='\"root\") -u root -e \"create database sites_$SITE\"" true

        # Print information that is needed for Akeeba restore locally
        echo -e "${FC_BLUE}To restore your site with Akeeba backup and kickstart.php, please follow the steps below:${CLEAR_COLOR}"

        echo -e " > Open your browser and navigate to ${FC_BOLDU_INLINE}http://localhost:${WEB_LOCAL_PORT}/${SITE}/kickstart.php${CLEAR_COLOR_INLINE}\n"

        echo -e " > Follow the instructions on the screen:\n"
        echo -e " > Start >> Run the Installer >> Next - (nothing to do here)\n"
        echo -e " > Provide the following information for ${FC_BOLDU_INLINE}Database Restoration${CLEAR_COLOR_INLINE}\n"
        echo -e " > Database server host name: ${FC_BOLD_INLINE}mysql${CLEAR_COLOR_INLINE}"
        echo -e " > User name: ${FC_BOLD_INLINE}root${CLEAR_COLOR_INLINE}"
        echo -e " > Password: ${FC_BOLD_INLINE}root${CLEAR_COLOR_INLINE}"
        echo -e " > Database name: ${FC_BOLD_INLINE}sites_${SITE}${CLEAR_COLOR_INLINE}"
        echo -e " > Database table name prefix: ${FC_BOLD_INLINE}j_${CLEAR_COLOR_INLINE}\n"
        echo -e " > Click on Next and change ${FC_BOLD_INLINE}.htaccess Handling${CLEAR_COLOR_INLINE} to ${FC_BOLD_INLINE}Use default${CLEAR_COLOR_INLINE}.\n"
        echo -e " > Click on Next and finish the restoration process.\n"

        echo -e "${FC_BLUE}Is your site up? Can we start the configuration for cypress?${CLEAR_COLOR}"

        unset USERCONFIRMATION
        localread "Confirm (y/N)" "" USERCONFIRMATION
        if [[ $USERCONFIRMATION = "y" || $USERCONFIRMATION = "Y" ]]; then
          # Start setup cypress configuration
          CONTAINER="web.local"
          run-command-container "/usr/src/Projects/.tools/scripts/restore-backup.sh /var/www/html/$SITE sites_$SITE Joomla-$SITE mailcatcher r true"
          return 0
        else
          echo -e "${FC_YELLOW}Please restore your site with Akeeba backup and kickstart.php first and try again.${CLEAR_COLOR}"
          return 1
        fi
      else
        # Get config_file
        zip_archive=($(find $REAL_ROOT/data/sites/$SITE -mindepth 1 -maxdepth 1 -type f -iname "*.zip" -exec basename {} \;));

        # Get config_file
        config_file=($(find $REAL_ROOT/data/sites/$SITE -mindepth 1 -maxdepth 1 -type f -iname "configuration.php" -exec basename {} \;));

        if [[ ! ${zip_archive[@]} ]] && [[ ! ${config_file[@]} ]]; then
          printf "%s\n\n" "$(bg::red "Restoration unfortunately not possible!")"
          echo -e " > No ${FC_BOLDU_INLINE}Akeeba backup${CLEAR_COLOR_INLINE}, ${FC_BOLDU_INLINE}zip archive${CLEAR_COLOR_INLINE} or ${FC_BOLDU_INLINE}configuration.php${CLEAR_COLOR_INLINE} found in your ${FC_BOLDU_INLINE}/data/sites/${SITE}${CLEAR_COLOR_INLINE} folder.\n"
          echo -e " > ${FC_BOLD_INLINE}Please remove site $SITE, restart the process and provide the files from your backup${CLEAR_COLOR}"
          return 1
        fi

        # Get db_dump file
        db_dump=($(find $REAL_ROOT/data/sites/$SITE -mindepth 1 -maxdepth 1 -type f -iname "*.sql" -exec basename {} \;));

        if [[ ! ${db_dump[@]} ]]; then
          printf "%s\n\n" "$(bg::red "Restoration unfortunately not possible!")"
          echo -e " > No ${FC_BOLDU_INLINE}database dump${CLEAR_COLOR_INLINE} found in your ${FC_BOLDU_INLINE}/data/sites/${SITE}${CLEAR_COLOR_INLINE} folder.\n"
          echo -e " > ${FC_BOLD_INLINE}Please remove site $SITE, restart the process and provide the files from your backup${CLEAR_COLOR}"
          return 1
        fi

        if [[ ${zip_archive[@]} ]]; then
          echo -e "\n > Zip archive ${zip_archive[0]} found for site ${SITE}"
          run-command-container "unzip \"/usr/src/Projects/data/sites/$SITE/${zip_archive[0]}\" -d /usr/src/Projects/data/sites/$SITE | pv -l -s \$(unzip -Z -1 \"/usr/src/Projects/data/sites/$SITE/${zip_archive[0]}\" | wc -l) > \/dev\/null" true
          rm -rf $REAL_ROOT/data/sites/$SITE/${zip_archive[0]}
          # Get config_file
          config_file=($(find $REAL_ROOT/data/sites/$SITE -mindepth 1 -maxdepth 1 -type f -iname "configuration.php" -exec basename {} \;));
          if [[ ! ${config_file[@]} ]]; then
            printf "%s\n\n" "$(bg::red "Restoration unfortunately not possible!")"
            echo -e " > No ${FC_BOLDU_INLINE}configuration.php${CLEAR_COLOR_INLINE} file found after extraction of your zip archive for ${SITE}.${CLEAR_COLOR}"
            echo -e " > ${FC_BOLD_INLINE}Please remove site $SITE, check the files from your backup and restart the process${CLEAR_COLOR}"
            return 1
          fi
        fi

        if [[ ${config_file[@]} ]]; then
          echo -e "\n > Configuration file ${FC_BOLDU_INLINE}${config_file[0]}${CLEAR_COLOR_INLINE} found for site ${FC_BOLDU_INLINE}${SITE}${CLEAR_COLOR_INLINE}"
        else 
          printf "%s\n\n" "$(bg::red "Restoration unfortunately not possible!")"
          echo -e " > No ${FC_BOLDU_INLINE}configuration.php${CLEAR_COLOR_INLINE} file found for ${SITE}."
          echo -e " > ${FC_BOLD_INLINE}Please remove site $SITE, check the files from your backup and restart the process${CLEAR_COLOR}"
          return 1
        fi

        echo -e "\n > Database dump ${FC_BOLDU_INLINE}${db_dump[0]}${CLEAR_COLOR_INLINE} found for site ${FC_BOLDU_INLINE}${SITE}${CLEAR_COLOR_INLINE}."

        CONTAINER="web.local"
        
        # TODO postgresql
        run-command-container "mv '/usr/src/Projects/data/sites/$SITE/${db_dump[0]}' /usr/src/Projects/data/sites/$SITE/db_mysql_restore.sql" true
        run-command-container "/usr/src/Projects/.tools/scripts/restore-backup.sh /var/www/html/$SITE sites_$SITE Joomla-$SITE mailcatcher r true"

        printf "%s\n\n" "$(bg::green "Successfully restored Joomla Site on Folder: $SITE")"
        echo -e "\n > Open your browser and navigate to ${FC_BOLDU_INLINE}http://localhost:${WEB_LOCAL_PORT}/${SITE}${CLEAR_COLOR_INLINE}\n"

        return 0
      fi

      printf "%s\n\n" "$(bg::red "Restoration unfortunately not possible!")"
      echo -e " > No ${FC_BOLDU_INLINE}Akeeba backup${CLEAR_COLOR_INLINE}, ${FC_BOLDU_INLINE}zip archive${CLEAR_COLOR_INLINE} or ${FC_BOLDU_INLINE}configuration.php${CLEAR_COLOR_INLINE} found in your ${FC_BOLDU_INLINE}/data/sites/${SITE}${CLEAR_COLOR_INLINE} folder.\n"
      echo -e " > ${FC_BOLD_INLINE}Please remove site $SITE, restart the process and provide the files from your backup${CLEAR_COLOR}"
      
      return 1
  else
    return 1
  fi
}

prepare-new-site() {
  tmp_site=$SITE
  unset SITE
  # Prompt user for site
  echo -e "\n"
  localread "Enter your new site name" "$tmp_site" SITE
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
    printf "%s\n\n" "$(bg::red "Site already exists - check: data/sites/${SITE}")"
    return 1
  fi
}

# Function to remove a local installed Joomla site in container `web.local`
# This function removes a local site from the system, including its files, database, and API token `.secret` variable.
# It prompts the user to select a site from a list of available sites and confirms the removal before proceeding.
remove-site () {
  # Check if web image is built
  check-image-build

  # Check if containers are running
  CONTAINER="web.local"
  check-containers-running
  CONTAINER="mysql"
  check-containers-running
  CONTAINER="phpmyadmin"
  check-containers-running

  # Get a list of available sites
  IFS=$'\n'
    array=($(find $REAL_ROOT/data/sites/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))
  unset IFS
  # Sort the list of sites
  IFS=$'\n' arrSites=($(sort <<<"${array[*]}")); unset IFS

  # Prompt the user to select a site to remove
  while true; do
    printf "%s\n\n" "$(bg::blue "Select a local site to remove:")"
    unset SITE
    select SITE in ${arrSites[@]} quit; do
      case $SITE in
        quit)
          break 2
          ;;
        *)
          # Check if a valid site is selected
          if [ -z $SITE ] || ! [[ ${arrSites[@]} =~ "$SITE" ]];then
            echo -e "${FC_RED}No available site selected${CLEAR_COLOR}"
            break
          fi

          # Check if the site directory exists
          if [ ! -d $REAL_ROOT/data/sites/$SITE ]; then
            echo -e "${FC_RED}Site does not exist - ${REAL_ROOT}/data/sites/${SITE}${CLEAR_COLOR}"
            break
          fi

          # Confirm the removal with the user
          printf "%s\n\n" "$(bg::yellow "Remove Joomla $SITE on Folder: data/sites/${SITE}")"
          echo -e "${FC_YELLOW}Are you sure?${CLEAR_COLOR}"
          read -rp "Confirm (y/N): " USERCONFIRMATION
          if [[ $USERCONFIRMATION = "y" || $USERCONFIRMATION = "Y" ]]; then

            # Remove files for the site
            CONTAINER="web.local"
            COMPOSEFILES="$REAL_TOOLS/local/compose.yml"
            echo -e "\n > Remove Files for Joomla $SITE on Folder: data/sites/${SITE}\n"
            run-command-container "rm -rv /usr/src/Projects/data/sites/$SITE | pv -l -s \$(du -a /usr/src/Projects/data/sites/$SITE 2> >(grep -v '^du: cannot \(access\|read\)' >&2) | wc -l) > \/dev\/null" true
            run-command-container "unlink /var/www/html/$SITE 2> >(grep -v '^unlink: cannot unlink' >&2)" true

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
              if [ ! -z $API_LINE ]; then
                echo -e " > Remove API-Token Test ${API_LINE} from .secret"
                # Note: Don't use sed -i as Docker container image php-8.3, which uses Ubuntu 20.04.6 LTS, which uses GNU sed 4.7.
                #       GNU sed 4.2 ... 4.7 incorrectly set umask on temporary files
                #       sed: couldn't open temporary file: Permission denied
                sed "\:$API_LINE:d" $REAL_ROOT/.tools/.secret >$TMP 2>/dev/null && cp $TMP $REAL_ROOT/.tools/.secret
              fi
            fi

            printf "%s\n\n" "$(bg::green "Site $SITE and Database removed from system")"
          fi
          break 2
          ;;
      esac
    done
  done

  return 0
}

# Welcome User and build container if not exists

printf "%s\n\n" "$(bg::blue "Welcome to Joomla E2E Test Suite")"


echo -e " > To run your ${FC_BOLDU_INLINE}remote${CLEAR_COLOR_INLINE} site (e.g. https://example.com) with cypress, use option 1 => remote\n"
echo -e " > To run a Joomla ${FC_BOLDU_INLINE}local${CLEAR_COLOR_INLINE} site locally with cypress, use option 2 => local\n"
echo -e " > To ${FC_BOLDU_INLINE}manage${CLEAR_COLOR_INLINE} your local Joomla sites (create, restore-backup and delete), use option 3 => manage\n"
echo -e " > If you encounter any problems, first try to ${FC_BOLDU_INLINE}shutdown${CLEAR_COLOR_INLINE} your container and start again 4 => shutdown"

echo -e "${FC_BLUE}Let's get started ... ${CLEAR_COLOR}"


# Check the build status of the cypress and php image.
check-image-build

selections=(remote local manage shutdown)

PS3="Choose an option: "

# If the selected option is "remote" or "local", the `start-cypress` function is called with the appropriate Cypress option.
# If the selected option is "manage", a sub-menu is displayed for managing local Joomla sites.
# The sub-menu allows the user to create a new local Joomla site, remove an existing site, or quit the sub-menu.
# If the selected option is "shutdown", the `cypress-stop` function is called and a message is displayed indicating that all containers are down and ready to restart.
# If the selected option is "quit", the `cypress-stop` function is called and the loop is exited, terminating the script.
# If an invalid option is selected, an error message is displayed.
while true; do
  if [ -z ${FIRST_LOOP:-""} ]; then
    FIRST_LOOP="false"
  else
    printf "%s\n\n" "$(bg::blue "Joomla E2E Test Suite")"
    echo -e " > To run your ${FC_BOLDU_INLINE}remote${CLEAR_COLOR_INLINE} site (e.g. https://example.com) with cypress, use option 1 => remote\n"
    echo -e " > To run a Joomla ${FC_BOLDU_INLINE}local${CLEAR_COLOR_INLINE} site locally with cypress, use option 2 => local\n"
    echo -e " > To ${FC_BOLDU_INLINE}manage${CLEAR_COLOR_INLINE} your local Joomla sites (create, restore-backup and delete), use option 3 => manage\n"
    echo -e " > If you encounter any problems, first try to ${FC_BOLDU_INLINE}shutdown${CLEAR_COLOR_INLINE} your container and start again 4 => shutdown\n"
  fi
  select opt in ${selections[@]} quit; do
    case $opt in
      remote)
        CYPRESS_OPTION="remote"
        start-cypress
        break
        ;;
      local)
        CYPRESS_OPTION="local"
        start-cypress
        break
        ;;
      manage)
        while true; do
          printf "%s\n\n" "$(bg::blue "Manage local Joomla sites")"
          select siteopt in create restore-backup remove quit; do
            case $siteopt in
              create)
                printf "%s\n\n" "$(bg::blue "Setup new local Joomla site")"
                setup-site
                if [ $? -eq 1 ]; then
                  break
                fi
                break 3
                ;;
              restore-backup)
                printf "%s\n\n" "$(bg::blue "Setup new local Joomla site from a previews backup")"
                restore-site
                if [ $? -eq 1 ]; then
                  break 
                fi
                break 3
                ;;
              remove)
                remove-site
                break
                ;;
              quit)
                break 3
                ;;
              *) 
                echo -e "\n${FC_RED}Invalid option $REPLY${CLEAR_COLOR}"
                break
                ;;
            esac
          done
        done
        ;;
      shutdown)
        cypress-stop
        printf "%s\n\n" "$(bg::blue "All containers down - ready to restart!")"
        break
        ;;
      quit)
        cypress-stop
        break 2
        ;;
      *) 
        echo -e "\n${FC_RED}Invalid option $REPLY${CLEAR_COLOR}"
        break
        ;;
    esac
  done
done
