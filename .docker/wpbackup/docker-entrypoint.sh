#!/bin/bash


echo "*******************************************************************"
echo "[$(date +"%Y-%m-%d-%H%M%S")] Entered wpbackup entrypoint script ..."


if [ -z "${WPBACKUP_ENABLED}" ] || [ "${WPBACKUP_ENABLED}" != "yes" ]
then
  echo "Wpbackup is disabled. To ebable Wpbackup set the WPBACKUP_ENABLED variable to yes"
else

	if [ -z "${WPBACKUP_WEBSITE}" ];          then echo "Error: WPBACKUP_WEBSITE not set";          echo "Finished: FAILURE"; exit 1; fi
	if [ -z "${WPBACKUP_DB_HOST}" ];          then echo "Error: WPBACKUP_DB_HOST not set";          echo "Finished: FAILURE"; exit 1; fi
	if [ -z "${WPBACKUP_DB_NAME}" ];          then echo "Error: WPBACKUP_DB_NAME not set";          echo "Finished: FAILURE"; exit 1; fi
	if [ -z "${WPBACKUP_DB_USER}" ];          then echo "Error: WPBACKUP_DB_USER not set";          echo "Finished: FAILURE"; exit 1; fi
	if [ -z "${WPBACKUP_DB_PASSWORD}" ];      then echo "Error: WPBACKUP_DB_PASSWORD not set";      echo "Finished: FAILURE"; exit 1; fi
	if [ -z "${WPBACKUP_ROOT_DB_PASSWORD}" ]; then echo "Error: WPBACKUP_ROOT_DB_PASSWORD not set"; echo "Finished: FAILURE"; exit 1; fi
	if [ -z "${WPBACKUP_WPCONTENT_DIR}" ];    then echo "Error: WPBACKUP_WPCONTENT_DIR not set";    echo "Finished: FAILURE"; exit 1; fi
	if [ -z "${WPBACKUP_ROOT_DIR}" ];         then echo "Error: WPBACKUP_ROOT_DIR not set";         echo "Finished: FAILURE"; exit 1; fi
	if [ -z "${WPBACKUP_LOG_DIR}" ];          then echo "Error: WPBACKUP_LOG_DIR not set";          echo "Finished: FAILURE"; exit 1; fi
	if [ -z "${MYSQL_USER_CNF_FILE}" ];       then echo "Error: MYSQL_USER_CNF_FILE not set";       echo "Finished: FAILURE"; exit 1; fi
	if [ -z "${MYSQL_ROOT_CNF_FILE}" ];       then echo "Error: MYSQL_ROOT_CNF_FILE not set";       echo "Finished: FAILURE"; exit 1; fi

	if [ ! -d "${WPBACKUP_ROOT_DIR}" ]; then mkdir -p "${WPBACKUP_ROOT_DIR}"; fi
	if [ ! -d "${WPBACKUP_LOG_DIR}" ]; then mkdir -p "${WPBACKUP_LOG_DIR}"; fi

	# Create the restore sub folder, if it does not exists
	restorePath="${WPBACKUP_ROOT_DIR}/restore" 
	if [ ! -d "${restorePath}" ]
	then
		mkdir -p "${restorePath}"
		echo "Restore directory [${restorePath}] created successfully"
	fi

	# Create the backup sub folder, if it does not exists
	backupPath="${WPBACKUP_ROOT_DIR}/backup" 
	if [ ! -d "${backupPath}" ]
	then
		mkdir -p "${backupPath}"
		echo "Backup directory [${backupPath}] created successfully"
	fi


	# First create the cron job
	WPBACKUP_ENABLED="${WPBACKUP_ENABLED:-"yes"}"
	if [ ! -f "/etc/wpbackup-cron" ]
	then
		if  [ "${WPBACKUP_ENABLED}" == "yes" ]
		then
			# Schedule the cron task
			echo "Creating backup/restore cron jobs ..."

			# Now create the cron job that
			#   Loads the docker-envs, sets the current date and time in a env var
			#   Executes the backup script and then finall unsets the current date & time env var
			echo "0 ${WPBACKUP_TIME:-0} * * * . /etc/docker_envs; export NOW=\$(date +\"\%Y-\%m-\%d-\%H\%M\"); /bin/backup.sh > ${WPBACKUP_LOG_DIR}/backup-\${NOW}.log; unset NOW;" > /etc/wpbackup-cron

			# Schedule the backup cron job
			crontab "/etc/wpbackup-cron"
		else
			echo "No cron job scheduled as WPBACKUP_ENABLED is not set to \"yes\""
			echo "Removing any previusly scheduled cron job ..."
			echo "" > /etc/wpbackup-cron
			crontab "/etc/wpbackup-cron"
			echo "Removing [/etc/wpbackup-cron] file ..."
			if  rm -rf "/etc/wpbackup-cron"
			then
				echo "Removed [/etc/wpbackup-cron] file successfully"
			else
				echo "Failed to remove [/etc/wpbackup-cron] file"
			fi
		fi
	fi

	echo "Current crontab:"
	crontab -l
	

	# Now create the conf file for backup job to pick up database username password
	# Do not include double quotes around ~/.my.cnf, it wont' expand 
	if [ ! -f "${MYSQL_USER_CNF_FILE}" ]
	then
		echo "Creating Mysql user config file ...";
		cat <<EOF > "${MYSQL_USER_CNF_FILE}"
[mysql]
host=${WPBACKUP_DB_HOST}
user=${WPBACKUP_DB_USER}
password=${WPBACKUP_DB_PASSWORD}
[mysqld]
collation-server=utf8mb4_unicode_ci
character-set-server=utf8mb4
[mysqldump]
host=${WPBACKUP_DB_HOST}
user=${WPBACKUP_DB_USER}
password=${WPBACKUP_DB_PASSWORD}
EOF

		chmod 644 "${MYSQL_USER_CNF_FILE}"
		echo "Mysql user config file created successfullly";
		echo "Creating Mysql root config file ...";
		cat <<EOF > "${MYSQL_ROOT_CNF_FILE}"
[mysql]
host=${WPBACKUP_DB_HOST}
user=root
password=${WPBACKUP_ROOT_DB_PASSWORD}
EOF

		chmod 644 "${MYSQL_ROOT_CNF_FILE}"
		echo "Mysql root config file created successfully.";
	fi

	# load the environment and check if restore is required
	# export environment variables in a file
	printenv | sed 's/^\(.*\)$/export \1/g' >  /etc/wpbackup-envs

	# Check if we need to restore from a restore file
	# First we check if the mysql service si up and running
	while ! mysql "--defaults-extra-file=${MYSQL_USER_CNF_FILE}" "${WPBACKUP_DB_NAME}" -e ";" ; do
		echo "Unable to connect to mysql database. It may not have been staretd as yet"
		echo "Lets try again in some time ..."
		sleep 60 # sleep for 60 seconds
	done

  # Lets get into a loop until
	#   1. Database is not empty, or
	#   2. WPBACKUP_RESTORE_KEY env variable is not set, or
	#   3. Restore Key file does not point to any file, or
	#   4. Restore file is defined and it exists 
	echo "Checking if we need to restore from a previous backup ..."
	while true
	do
		# First check if the database is empty
  	# We can only restore on an empty database lets check that
	  # Host and password information is stored in config so there is no need to pass here
  	dbTables=$(echo "show tables" | mysql "--defaults-extra-file=${MYSQL_USER_CNF_FILE}" "${WPBACKUP_DB_NAME}")
	  if  [ -n "${dbTables}" ]
	  then
  		echo "Database is not empty - restore will be skipped"
	  	echo "If restore is required, please delete the database"
			break;
		fi

    # Now check if the restore key env var is deifned and the file actually exists
		# If the env var is not defined, we will exit
		if [ -z "${WPBACKUP_RESTORE_KEY}" ]
		then
			echo "WPBACKUP_RESTORE_KEY is not defined - Restore will be skipped"
			break;
		fi

    # Check if the restore key is deifned and the file actually exists
		restoreKeyFile="${restorePath}/${WPBACKUP_RESTORE_KEY}"
		if [ ! -f "${restoreKeyFile}" ]
		then
  		echo "Restore key file does not exist as yet."
	  	echo "May be it is yet to be synchronised with remote mount, lets wait ...";
  		sleep 60 # sleep for 60 seconds
		  continue;
		fi

		# Read the name of the restore file from the key
		# And if the restore filename is empty, break the loop
		restoreFilename="$(<"${restoreKeyFile}")";
		if [ -z "${restoreFilename}" ]
		then
			echo "Restore key file [${restoreFilename}] does not point to any restore file"
			echo "Restore will be skipped"
			break;
		fi

		# Check the existenece of the restore file
    restoreFile="${restorePath}/${restoreFilename}"
		if [ ! -f "${restoreFile}" ]
		then
			echo "The restore file [${restoreFile}] does not exist as yet."
			echo "May be it is yet to be synchronised with remote mount, lets wait ...";
			sleep 60   # Sleep for 60 seconds
			continue;  # This is an infinit loop
		fi

    echo "Restore file [${restoreFile}] found."
		# Lets check the wpcustom file
		wpbackupKeyFile="${restorePath}/${WPBACKUP_WPCUSTOM_KEY}"
		if [ -n "${WPBACKUP_WPCUSTOM_KEY}" ] && [ -f "${wpbackupKeyFile}" ]
		then
			wpcustomFilename="$(<"${wpbackupKeyFile}")"
			wpcustomFile="${restorePath}/${wpcustomFilename}"
			if [ -n "${wpcustomFilename}" ] && [ -f "${wpcustomFile}" ]
			then
				echo "wpcustom file [${wpcustomFile}] found."
			else
				wpcustomFile=""
			fi
		fi

    echo "Restore will start shortly"
		break;
	done

	if [ -n "${restoreKeyFile}" ] && [ -f "${restoreKeyFile}" ]
	then
		if [ -n "${restoreFile}" ] && [ -f "${restoreFile}" ]
		then
			# lets run the restore script 
			echo "Restoring the wordpress site ..."
			echo "Restore file:  [${restoreFile}]"
			if [ -n "${wpcustomFile}" ]; then
				echo "Wpcustom file: [${wpcustomFile}]"
			fi
			export NOW; NOW="$(date "+%Y-%m-%d-%H%M")"
			if bash /bin/restore.sh "${restoreFile}" "${wpcustomFile}" > "${WPBACKUP_LOG_DIR}/restore-${NOW}.log"
			then
				echo "WORDPRESS is restored SUCCESSFULLY"
				echo "Please check the logs at [${WPBACKUP_LOG_DIR}/restore-${NOW}.log]"
#				# Delete the restore file, as we are done with it
#				# Otherwise it will try and restore this again, when this container is recreated
#				echo "Deleting restore key file [${restoreKeyFile}]."
#				if rm -f "${restoreKeyFile}"
#				then
#					echo "Restore key file [${restoreKeyFile}] deleted successfully."
#				else
#					echo "Failed to delete restore file [${restoreKeyFile}]."
#				fi
			else
				echo "Failed to restore wordpress from:"
				echo "Backup file:   [${restoreFile}]"
				if [ -n "${wpcustomFile}" ]; then
					echo "Wpcustom file: [${wpcustomFile}]"
				fi
				echo "Please check the logs at [${WPBACKUP_LOG_DIR}/restore-${NOW}.log]"
			fi
			unset NOW
#		else
#			# Delete the restore file, as we are done with it
#			# Otherwise it will try and restore this again, when this container is recreated
#			echo "Deleting restore key file [${restoreKeyFile}]."
#			if rm -f "${restoreKeyFile}"
#			then
#				echo "Restore key file [${restoreKeyFile}] deleted successfully."
#			else
#				echo "Failed to delete restore file [${restoreKeyFile}]."
#			fi
		fi
	fi
fi

exec "$@"

echo "[$(date +"%Y-%m-%d-%H%M%S")] Exiting wpbackup entrypoint script ..."
echo "*******************************************************************"
