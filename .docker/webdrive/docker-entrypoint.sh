#!/bin/bash

echo "Entered webdrive entrypoint script ..."


# Copy webdrive secrets
if [ -z "${WEBDRIVE_SECRETS_FILE}" ]
then
  echo "WORDPRESS_CONF_FILE must be defined"
# /etc/davfs2/secrets was removed in the image (DockerFile)
# Hence we can check if we have copied our secrets file here
elif [ ! -f "/etc/davfs2/secrets" ] 
then
  echo "Copying the webdrive secrets conf file ..."
  cp "${WEBDRIVE_SECRETS_FILE}" "/etc/davfs2/secrets"
  if [ -f "/etc/davfs2/secrets" ]
  then
    echo "The davfs2 secerts files copied successfully"
  else
    echo "Failed to davfs2 secerts files to the davfs2 folder"
  fi
fi


if [ -z "${WEBDRIVE_URL}" ]
then
  echo "WEBDRIVE_URL is not set";
elif [ -z "${WEBDRIVE_REMOTE_PATH}" ]
then
  echo "WEBDRIVE_REMOTE_PATH is not set";
elif [ -f "/etc/davfs2/secrets" ]
then
  # Check if the webdrive is mounted
  DRIVE_TYPE=$(stat --file-system --format=%T /mnt/webdrive);
  if [ "${DRIVE_TYPE}" != "fuseblk" ]
  then
    # Mount the webdav drive
    echo "Mounting the web drive ..."
    mount -t davfs "$WEBDRIVE_URL" "/mnt/webdrive" -o uid=0,gid=users,dir_mode=755,file_mode=755
    DRIVE_TYPE=$(stat --file-system --format=%T /mnt/webdrive);
    if [ "${DRIVE_TYPE}" == "fuseblk" ]
    then
      echo "Webdrive mounted successfully"
      # only create the remote sub folder once the wedrive is mounted
      # If it ceated in the local drive folder then it will be mounted as overlayfs
      # and never as overlayfs and then unison will throw the following error
      #     Fatal error: Error in canonizing path: No such file or directory
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
  else
    echo "Webdrive has already been mounted"
  fi
fi


# Start the endless sync process
echo "Starting unison process ..."
unison