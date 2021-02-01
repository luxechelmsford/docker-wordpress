#!/bin/bash

echo "*******************************************************************"
echo "[$(date +"%Y-%m-%d-%H%M%S")] Entered webdrive entrypoint script ..."


if [ -z "${WEBDRIVE_ENABLED}" ] || [ "${WEBDRIVE_ENABLED}" != "yes" ]
then
  echo "Webdrive is disabled. To ebable webdrive set the WEBDRIVE_ENABLED variable to yes"
else

	if [ -z "${WEBDRIVE_URL}" ];          then echo "Error: WEBDRIVE_URL not set";          echo "Finished: FAILURE"; exit 1; fi
	if [ -z "${WEBDRIVE_UID}" ];          then echo "Error: WEBDRIVE_UID not set";          echo "Finished: FAILURE"; exit 1; fi
	if [ -z "${WEBDRIVE_PWD}" ];          then echo "Error: WEBDRIVE_PWD not set";          echo "Finished: FAILURE"; exit 1; fi
	if [ -z "${WEBDRIVE_ROOT_DIR}" ];     then echo "Error: WEBDRIVE_ROOT_DIR not set";     echo "Finished: FAILURE"; exit 1; fi
	if [ -z "${WPBACKUP_ROOT_DIR}" ];     then echo "Error: WPBACKUP_ROOT_DIR not set";     echo "Finished: FAILURE"; exit 1; fi
	
	# Create the remote sub folder, if it does not exists
	if [ ! -d "${WEBDRIVE_ROOT_DIR}" ]
	then
		mkdir -p "${WEBDRIVE_ROOT_DIR}"
		echo "Remote directory [${WEBDRIVE_ROOT_DIR}] created successfully"  
	fi

	# Create the local sub folder, if it does not exists
	if [ ! -d "${WPBACKUP_ROOT_DIR}" ]
	then
		mkdir -p "${WPBACKUP_ROOT_DIR}"
		echo "Local directory [${WPBACKUP_ROOT_DIR}] created successfully"
	fi

	# Copy webdrive mapping entry
	webdriveRemoteUrl="${WEBDRIVE_URL%/}/${WEBDRIVE_ROOT_DIR##*/}"
	fstabEntry="${webdriveRemoteUrl} ${WEBDRIVE_ROOT_DIR} davfs _netdev,noauto,user,uid=0,gid=0, 0 0"
	if grep -qxF "${fstabEntry}" "/etc/fstab"
	then
		echo "The webdrive mapping entry had been copied to fstab file in the previous run"
	else
		echo "Copying the webdrive mapping entry to fstab file ..."
		if echo "${fstabEntry}"  >> "/etc/fstab"
		then
			echo "The webdrive mapping entry copied to fstab file successfully"
		else
			echo "Failed to copy webdrive mapping entry to fstab file"
		fi
	fi

  # Copy webdrive secrets
	davfs2Credential="${WEBDRIVE_ROOT_DIR} ${WEBDRIVE_UID} ${WEBDRIVE_PWD}"
	if grep -qxF "${davfs2Credential}" "/etc/davfs2/secrets"
	then
		echo "The webdrive credentials had been copied to davfs2 secrets file in the previous run"
	else
		echo "Copying the webdrive credentials to davfs2 secrets file ..."
		if echo "${davfs2Credential}"  >> "/etc/davfs2/secrets"
		then
			echo "The webdrive credentials copied to davfs2 secrets file successfully"
		else
			echo "Failed to copy webdrive credentials to davfs2 secrets file"
		fi
	fi

	# Mount the drive
	if ! grep -qxF "${fstabEntry}" "/etc/fstab"
	then
		echo "Skipping the mounting of the web drive. Webdrive mapping entry not found in the fstab file"
	elif ! grep -qxF "${davfs2Credential}" "/etc/davfs2/secrets"
	then
		echo "Skipping the mounting of the web drive. Webdrive credentials not found in the secrets file"
	else
		# Check if the webdrive is mounted
		driveType=$(stat --file-system --format=%T "${WEBDRIVE_ROOT_DIR}");
		if [ "${driveType}" == "fuseblk" ]
		then
			echo "WEBDRIVE has ALREADY been mounted"
		else			  
			# Webdav on a reboot complain about unable to mount as found PID file /var/run/mount.davfs/mnt-webdrive.pid.
			# lets first delete this file
			webDrivePidFile="${WEBDRIVE_ROOT_DIR#/}"		# Remove the first slash
			webDrivePidFile="${webDrivePidFile//\//-}"	# Replace slashed with - to get the pid file name
			if [ -f "/var/run/mount.davfs/${webDrivePidFile}.pid" ]
			then
			  echo "Removing the pid file created from previously running the container"
			  rm -f "/var/run/mount.davfs/${webDrivePidFile}.pid";
			fi
			# Mount the webdrive
			echo "Mounting the webdrive ..."
			ret=$(echo "y" | mount "${WEBDRIVE_ROOT_DIR}" |& grep '404 Not Found')
			if [ -n "${ret}" ]
			then
			  echo "FAILED to mount the drive!!"
				echo "Ensure the subfolder ${WEBDRIVE_ROOT_DIR##*/} exist as a share on the webdav server"
			else
				echo "" # Blank echo to over to the next line
				driveType=$(	stat --file-system --format=%T "${WEBDRIVE_ROOT_DIR}");
				if [ "${driveType}" == "fuseblk" ]
				then
					echo "WEBDRIVE mounted SUCCESSFULLY"
				else
					echo "FAILED to mount the WEBDRIVE"
				fi
			fi
		fi
	fi

	driveType=$(stat --file-system --format=%T "${WEBDRIVE_ROOT_DIR}");
	if [ "${driveType}" == "fuseblk" ]
	then
		echo "Getting the directory listing of the webdrive ..."
		ls "${WEBDRIVE_ROOT_DIR}"
		echo "Starting unison process ..."
		# Start the endless sync process
		unison "${WEBDRIVE_ROOT_DIR}" "${WPBACKUP_ROOT_DIR}"
	else
		echo "Skiping unison process and starting interctive shell ..."
    tail -f /dev/null
	fi
fi

echo "[$(date +"%Y-%m-%d-%H%M%S")] Exiting webdrive entrypoint script ..."
echo "*******************************************************************"
