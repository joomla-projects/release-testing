#!/bin/bash

cd "local"

backup_archive=( ./joomla-backup/*.zip )
backup_dbdump=( ./joomla-backup/*.sql )
backup_restore=false

if [ -f ${backup_archive[0]} ] && [ -f ${backup_dbdump[0]} ]; then
	echo "Restoring your backup site: ${backup_archive[0]} - ${backup_dbdump[0]}"
	backup_restore=true

	echo ""
	echo "We need some information from you to run cypress on your restored site."

	# Prompt user for username
	read -p "Enter your site username: " username

	# Prompt user for password (-s for privacy)
	read -p "Enter your site password: " password
fi

if [ "$backup_restore" = false ] && [ -f ${backup_archive[0]} ]; then
	echo "Backup archive found ${backup_archive[0]} but db-dump missing."
	echo "Please paste a .sql dump file into joomla-backup directory and restart."
	exit
fi

if [ "$backup_restore" = false ] && [ -f ${backup_dbdump[0]} ]; then
	echo "Backup sql dump found ${backup_dbdump[0]} but zip-archive missing."
	echo "Please paste a .zip archive into joomla-backup directory and restart."
	exit
fi

if [ "$backup_restore" = false ]; then
	username=""
	password=""
	echo "No backup archive or db-dump found in the joomla-backup directory."
	echo "Setting up new Joomla! site for testing."
fi

echo "Cleaning up the old containers"
ROOT=$ROOT USERNAME=$username PASSWORD=$password RESTORE=$backup_restore docker compose down --volumes

echo "Creating fresh containers and start"
ROOT=$ROOT USERNAME=$username PASSWORD=$password RESTORE=$backup_restore docker compose -f $(dirname $0)/docker-compose.yml up --force-recreate