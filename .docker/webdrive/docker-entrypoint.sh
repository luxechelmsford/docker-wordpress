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
	
	# Create the remote restore folder, if it does not exists
	remoteRestorePath="${WEBDRIVE_ROOT_DIR}/restore" 
	if [ ! -d "${remoteRestorePath}" ]
	then
		mkdir -p "${remoteRestorePath}"
		echo "Remote restore folder [${remoteRestorePath}] created successfully"  
	fi

  # Create the remote backup folder, if it does not exists
	remoteBackupPath="${WEBDRIVE_ROOT_DIR}/backup" 
	if [ ! -d "${remoteBackupPath}" ]
	then
		mkdir -p "${remoteBackupPath}"
		echo "Remote backup folder [${remoteBackupPath}] created successfully"  
	fi

	# Create the local restore sub folder, if it does not exists
	localRestorePath="${WPBACKUP_ROOT_DIR}/restore" 
	if [ ! -d "${localRestorePath}" ]
	then
		mkdir -p "${localRestorePath}"
		echo "Local restore directory [${localRestorePath}] created successfully"
	fi

	# Create the local backup sub folder, if it does not exists
	localBackupPath="${WPBACKUP_ROOT_DIR}/backup" 
	if [ ! -d "${localBackupPath}" ]
	then
		mkdir -p "${localBackupPath}"
		echo "Local backup directory [${localBackupPath}] created successfully"
	fi

	# Copy restore webdrive mapping entry
	webdriveRemoteRestoreUrl="${WEBDRIVE_URL%/}/${WEBDRIVE_ROOT_DIR##*/}/${remoteRestorePath##*/}"
	fstabRestoreEntry="${webdriveRemoteRestoreUrl} ${remoteRestorePath} davfs _netdev,noauto,user,uid=0,gid=0, 0 0"
	if grep -qxF "${fstabRestoreEntry}" "/etc/fstab"
	then
		echo "The restore webdrive mapping entry had been copied to fstab file in the previous run"
	else
		echo "Copying the restore webdrive mapping entry to fstab file ..."
		if echo "${fstabRestoreEntry}"  >> "/etc/fstab"
		then
			echo "The restore webdrive mapping entry copied to fstab file successfully"
		else
			echo "Failed to copy restore webdrive mapping entry to fstab file"
		fi
	fi

	# Copy backup webdrive mapping entry
	webdriveRemoteBackupUrl="${WEBDRIVE_URL%/}/${WEBDRIVE_ROOT_DIR##*/}/${remoteBackupPath##*/}"
	fstabBackupEntry="${webdriveRemoteBackupUrl} ${remoteBackupPath} davfs _netdev,noauto,user,uid=0,gid=0, 0 0"
	if grep -qxF "${fstabBackupEntry}" "/etc/fstab"
	then
		echo "The backup webdrive mapping entry had been copied to fstab file in the previous run"
	else
		echo "Copying the backup webdrive mapping entry to fstab file ..."
		if echo "${fstabBackupEntry}"  >> "/etc/fstab"
		then
			echo "The backup webdrive mapping entry copied to fstab file successfully"
		else
			echo "Failed to copy backup webdrive mapping entry to fstab file"
		fi
	fi

  # Copy restore webdrive secrets
	davfs2RestoreCredential="${remoteRestorePath} ${WEBDRIVE_UID} ${WEBDRIVE_PWD}"
	if grep -qxF "${davfs2RestoreCredential}" "/etc/davfs2/secrets"
	then
		echo "The restore webdrive credentials had been copied to davfs2 secrets file in the previous run"
	else
		echo "Copying the restore webdrive credentials to davfs2 secrets file ..."
		if echo "${davfs2RestoreCredential}"  >> "/etc/davfs2/secrets"
		then
			echo "The restore webdrive credentials copied to davfs2 secrets file successfully"
		else
			echo "Failed to copy restore webdrive credentials to davfs2 secrets file"
		fi
	fi

  # Copy backup webdrive secrets
	davfs2BackupCredential="${remoteBackupPath} ${WEBDRIVE_UID} ${WEBDRIVE_PWD}"
	if grep -qxF "${davfs2BackupCredential}" "/etc/davfs2/secrets"
	then
		echo "The backup webdrive credentials had been copied to davfs2 secrets file in the previous run"
	else
		echo "Copying the backup webdrive credentials to davfs2 secrets file ..."
		if echo "${davfs2BackupCredential}"  >> "/etc/davfs2/secrets"
		then
			echo "The backup webdrive credentials copied to davfs2 secrets file successfully"
		else
			echo "Failed to copy backup webdrive credentials to davfs2 secrets file"
		fi
	fi

	# Mount the restore drive
	if ! grep -qxF "${fstabRestoreEntry}" "/etc/fstab"
	then
		echo "Skipping the mounting of the web drive. Webdrive mapping entry not found in the fstab file"
	elif ! grep -qxF "${davfs2RestoreCredential}" "/etc/davfs2/secrets"
	then
		echo "Skipping the mounting of the web drive. Webdrive credentials not found in the secrets file"
	else
		# Check if the webdrive is mounted
		driveType=$(stat --file-system --format=%T "${remoteRestorePath}");
		if [ "${driveType}" == "fuseblk" ]
		then
			echo "WEBDRIVE has ALREADY been mounted"
		else			  
			# Webdav on a reboot complain about unable to mount as found PID file /var/run/mount.davfs/mnt-webdrive.pid.
			# lets first delete this file
			webDriveRestorePidFile="${remoteRestorePath#/}"		# Remove the first slash
			webDriveRestorePidFile="${webDriveRestorePidFile//\//-}"	# Replace slashed with - to get the pid file name
			if [ -f "/var/run/mount.davfs/${webDriveRestorePidFile}.pid" ]
			then
			  echo "Removing the restore pid file created from previously running the container"
			  rm -f "/var/run/mount.davfs/${webDriveRestorePidFile}.pid";
			fi
			# Mount the webdrive
			echo "Mounting the restore webdrive ..."
			ret=$(echo "y" | mount "${remoteRestorePath}" |& grep '404 Not Found')
			if [ -n "${ret}" ]
			then
			  echo "FAILED to mount the drive!!"
				echo "Ensure the subfolder ${WEBDRIVE_ROOT_DIR##*/}/${remoteRestorePath##*/} exist as a share on the webdav server"
			else
				echo "" # Blank echo to over to the next line
				driveType=$(	stat --file-system --format=%T "${remoteRestorePath}");
				if [ "${driveType}" == "fuseblk" ]
				then
					echo "Restore WEBDRIVE mounted SUCCESSFULLY"
				else
					echo "FAILED to mount the Restore WEBDRIVE"
				fi
			fi
		fi
	fi

  # Mount the backup drive
	if ! grep -qxF "${fstabBackupEntry}" "/etc/fstab"
	then
		echo "Skipping the mounting of the web drive. Webdrive mapping entry not found in the fstab file"
	elif ! grep -qxF "${davfs2BackupCredential}" "/etc/davfs2/secrets"
	then
		echo "Skipping the mounting of the web drive. Webdrive credentials not found in the secrets file"
	else
		# Check if the webdrive is mounted
		driveType=$(stat --file-system --format=%T "${remoteBackupPath}");
		if [ "${driveType}" == "fuseblk" ]
		then
			echo "WEBDRIVE has ALREADY been mounted"
		else			  
			# Webdav on a reboot complain about unable to mount as found PID file /var/run/mount.davfs/mnt-webdrive.pid.
			# lets first delete this file
			webDriveBackupPidFile="${remoteBackupPath#/}"		# Remove the first slash
			webDriveBackupPidFile="${webDriveBackupPidFile//\//-}"	# Replace slashed with - to get the pid file name
			if [ -f "/var/run/mount.davfs/${webDriveBackupPidFile}.pid" ]
			then
			  echo "Removing the backup pid file created from previously running the container"
			  rm -f "/var/run/mount.davfs/${webDriveBackupPidFile}.pid";
			fi
			# Mount the webdrive
			echo "Mounting the backup webdrive ..."
			ret=$(echo "y" | mount "${remoteBackupPath}" |& grep '404 Not Found')
			if [ -n "${ret}" ]
			then
			  echo "FAILED to mount the drive!!"
				echo "Ensure the subfolder ${WEBDRIVE_ROOT_DIR##*/}/${remoteBackupPath##*/} exist as a share on the webdav server"
			else
				echo "" # Blank echo to over to the next line
				driveType=$(	stat --file-system --format=%T "${remoteBackupPath}");
				if [ "${driveType}" == "fuseblk" ]
				then
					echo "Backup WEBDRIVE mounted SUCCESSFULLY"
				else
					echo "FAILED to mount the Backup WEBDRIVE"
				fi
			fi
		fi
	fi

	driveRestoreType=$(stat --file-system --format=%T "${remoteRestorePath}");
	driveBackupType=$(stat --file-system --format=%T "${remoteBackupPath}");
	if [ "${driveRestoreType}" == "fuseblk" ] && [ "${driveBackupType}" == "fuseblk" ]
	then
		echo "Getting the restore directory listing for the webdrive ..."
		ls "${remoteRestorePath}"
		echo "Getting the restore directory listing for the webdrive ..."
		ls "${remoteBackupPath}"
		echo "Starting unison process ..."
		# Start the endless sync process
		while (true)
		do
			echo ""
		  # Oneway sync from local to remote
			echo "[$(date +"%Y-%m-%d-%H%M%S")] Syncing local backup -> remote backup"
  		unison "${localBackupPath}" "${remoteBackupPath}" -force "${localBackupPath}" -nodeletion "${remoteBackupPath}"
		  # Oneway sync from remote to local
			echo "[$(date +"%Y-%m-%d-%H%M%S")] Syncing local restore <- remote restore"
  		unison "${remoteRestorePath}" "${localRestorePath}" -force "${remoteRestorePath}"
			sleep 60
		done
	else
		echo "Skiping unison process and starting interctive shell ..."
    tail -f /dev/null
	fi
fi

echo "[$(date +"%Y-%m-%d-%H%M%S")] Exiting webdrive entrypoint script ..."
echo "*******************************************************************"
