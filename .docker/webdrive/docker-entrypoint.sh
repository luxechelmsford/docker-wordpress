#!/bin/bash

echo "*******************************************************************"
echo "[$(date +"%Y-%m-%d-%H%M%S")] Entered webdrive entrypoint script ..."


if [ -z "${WEBDRIVE_URL}" ];          then echo "Error: WEBDRIVE_URL not set";          echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WEBDRIVE_REMOTE_PATH}" ];  then echo "Error: WEBDRIVE_REMOTE_PATH not set";  echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WEBDRIVE_SECRETS_FILE}" ]; then echo "Error: WEBDRIVE_SECRETS_FILE not set"; echo "Finished: FAILURE"; exit 1; fi
 
# Copy webdrive secrets
DAVFS_FILE_MARKER="# Webdrive credential for ${WEBDRIVE_URL}"
if grep -qxF "${DAVFS_FILE_MARKER}" "/etc/davfs2/secrets"
then
  echo "The webdrive credentials had been copied to davfs2 secrets file in the peious run"
else
  echo "Copying the webdrive credentials to davfs2 secrets file ..."
  if echo "${DAVFS_FILE_MARKER}"  >> "/etc/davfs2/secrets" && cat "${WEBDRIVE_SECRETS_FILE}" >> "/etc/davfs2/secrets"
  #echo "${DAVFS_FILE_MARKER}"; cat "${WEBDRIVE_SECRETS_FILE}" >> "/etc/davfs2/secrets"
  then
    echo "The webdrive credentials copied to davfs2 secrets file successfully"
  else
    echo "Failed to copy webdrive credentials to davfs2 secrets file"
  fi
fi


# Mount the drive
if ! grep -qxF "${DAVFS_FILE_MARKER}" "/etc/davfs2/secrets"
then
  echo "Skipping the mounting of the web drive. Webdrive credentials not found in the secrets file"
else
  # Check if the webdrive is mounted
  DRIVE_TYPE=$(stat --file-system --format=%T /mnt/webdrive);
  if [ "${DRIVE_TYPE}" == "fuseblk" ]
  then
    echo "Webdrive has already been mounted"
  else
    # Mount the webdrive
    echo "Mounting the webdrive ..."
    mount -t davfs "$WEBDRIVE_URL" "/mnt/webdrive" -o uid=0,gid=users,dir_mode=755,file_mode=755
    DRIVE_TYPE=$(stat --file-system --format=%T /mnt/webdrive);
    if [ "${DRIVE_TYPE}" == "fuseblk" ]
    then
      echo "Webdrive mounted successfully"
      # only create the remote sub folder once the wedrive is mounted
      # If it ceated in the local drive folder then it will be mounted as overlayfs
      # and never as overlayfs and then unison will throw the following error
      #     Fatal error: Error in canonizing path:
      # .   /mnt/webdrive/website-dir: No such file or directory
      if [ ! -d "/mnt/webdrive/${WEBDRIVE_REMOTE_PATH}" ]
      then
        mkdir -p "/mnt/webdrive/${WEBDRIVE_REMOTE_PATH}"
        echo "Remote directory [/mnt/webdrive/${WEBDRIVE_REMOTE_PATH}] created successfully"  
      fi
      if [ ! -d "/var/backups/${WEBDRIVE_REMOTE_PATH}" ]
      then
        mkdir -p "/var/backups/${WEBDRIVE_REMOTE_PATH}"
        echo "Remote directory [/var/backups/${WEBDRIVE_REMOTE_PATH}] created successfully"
      fi
    else
      echo "Failed to mount the webdrive"
    fi
  fi
fi

# Start the endless sync process
echo "Starting unison process ..."
unison


echo "[$(date +"%Y-%m-%d-%H%M%S")] Exiting webdrive entrypoint script ..."
echo "*******************************************************************"