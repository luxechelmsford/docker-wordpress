#!/bin/bash

echo "*******************************************************************"
echo "[$(date +"%Y-%m-%d-%H%M%S")] Entered webdrive entrypoint script ..."


if [ -z "${WEBDRIVE_URL}" ];          then echo "Error: WEBDRIVE_URL not set";          echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WEBDRIVE_UID}" ];          then echo "Error: WEBDRIVE_UID not set";          echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WEBDRIVE_PWD}" ];          then echo "Error: WEBDRIVE_PWD not set";          echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WEBDRIVE_ROOT_DIR}" ];     then echo "Error: WEBDRIVE_ROOT_DIR not set";     echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WPBACKUP_ROOT_DIR}" ];     then echo "Error: WPBACKUP_ROOT_DIR not set";     echo "Finished: FAILURE"; exit 1; fi

# Copy webdrive secrets
DAVFS2_CREDENTIAL="${WEBDRIVE_URL} ${WEBDRIVE_UID} ${WEBDRIVE_PWD}"
if grep -qxF "${DAVFS2_CREDENTIAL}" "/etc/davfs2/secrets"
then
  echo "The webdrive credentials had been copied to davfs2 secrets file in the previous run"
else
  echo "Copying the webdrive credentials to davfs2 secrets file ..."
  if echo "${DAVFS2_CREDENTIAL}"  >> "/etc/davfs2/secrets"
  then
    echo "The webdrive credentials copied to davfs2 secrets file successfully"
  else
    echo "Failed to copy webdrive credentials to davfs2 secrets file"
  fi
fi


# Mount the drive
if ! grep -qxF "${DAVFS2_CREDENTIAL}" "/etc/davfs2/secrets"
then
  echo "Skipping the mounting of the web drive. Webdrive credentials not found in the secrets file"
else
  # Check if the webdrive is mounted
  DRIVE_TYPE=$(stat --file-system --format=%T "${WEBDRIVE_ROOT_DIR%/*}");
  if [ "${DRIVE_TYPE}" == "fuseblk" ]
  then
    echo "Webdrive has already been mounted"
  else
    # Mount the webdrive please note ${WEBDRIVE_ROOT_DIR%/*} would remove the top level subdir
    echo "Mounting the webdrive ..."
    echo "y" | mount -t davfs "$WEBDRIVE_URL" "${WEBDRIVE_ROOT_DIR%/*}" -o uid=0,gid=users,dir_mode=755,file_mode=755
    DRIVE_TYPE=$(stat --file-system --format=%T "${WEBDRIVE_ROOT_DIR%/*}");
    if [ "${DRIVE_TYPE}" == "fuseblk" ]
    then
      echo "Webdrive mounted successfully"
      # only create the remote sub folder once the wedrive is mounted
      # If it ceated in the local drive folder then it will be mounted as overlayfs
      # and never as overlayfs and then unison will throw the following error
      #     Fatal error: Error in canonizing path:
      # .   ${WEBDRIVE_ROOT_DIR}: No such file or directory
      if [ ! -d "${WEBDRIVE_ROOT_DIR}" ]
      then
        mkdir -p "${WEBDRIVE_ROOT_DIR}"
        echo "Remote directory [${WEBDRIVE_ROOT_DIR}] created successfully"  
      fi
    else
      echo "Failed to mount the webdrive"
    fi
  fi
fi

if [ ! -d "${WPBACKUP_ROOT_DIR}" ]
then
  mkdir -p "${WPBACKUP_ROOT_DIR}"
  echo "Remote directory [${WPBACKUP_ROOT_DIR}] created successfully"
fi


# Start the endless sync process
echo "Starting unison process ..."
unison "${WEBDRIVE_ROOT_DIR}" "${WPBACKUP_ROOT_DIR}"


echo "[$(date +"%Y-%m-%d-%H%M%S")] Exiting webdrive entrypoint script ..."
echo "*******************************************************************"