#!/bin/bash

echo "Entered webdrive entrypoint script ..."

if [ -z "${WEBDRIVE_CER_FILE}" ]; then  echo "WEBDRIVE_CER_FILE is not set"; fi

if [ -n "${WEBDRIVE_URL_FILE}" ]; then WEBDRIVE_URL=$(<"${WEBDRIVE_URL_FILE}"); fi
if [ -z "${WEBDRIVE_URL}" ]; then  echo "WEBDRIVE_URL_FILE is not set"; fi

if [ -n "${WEBDRIVE_UID_FILE}" ]; then WEBDRIVE_UID=$(<"${WEBDRIVE_UID_FILE}"); fi
if [ -z "${WEBDRIVE_UID}" ]; then  echo "WEBDRIVE_UID_FILE is not set"; fi

if [ -n "${WEBDRIVE_PWD_FILE}" ]; then WEBDRIVE_PWD=$(<"${WEBDRIVE_PWD_FILE}"); fi
if [ -z "${WEBDRIVE_PWD}" ]; then echo "WEBDRIVE_PWD_FILE is not set"; fi

if [ -z "${WEBDRIVE_REMOTE_PATH}" ]; then echo "WEBDRIVE_REMOTE_PATH is not set"; fi



if [ -n "${WEBDRIVE_CER_FILE}" ] &&  [ ! -f "/etc/davfs2/certs/${WEBDRIVE_CER_FILE##*/}" ]
then
  echo "Copying Webdrive public certificiate file ..."
  cp "${WEBDRIVE_CER_FILE}" "/etc/davfs2/certs/"
  if [ -f "/etc/davfs2/certs/${WEBDRIVE_CER_FILE##*/}" ]
  then
    echo "Webdrive public certificiate file copied successfully ..."
  else
    echo "Failed to copy Webdrive public certificiate file ..."
  fi
fi



if [ -n "${WEBDRIVE_URL}" ] && [ -n "${WEBDRIVE_UID}" ] &&          \
   [ -n "${WEBDRIVE_PWD}" ] && [ -n "${WEBDRIVE_REMOTE_PATH}" ] &&  \
   [ ! -f "/root/.unison/default.prf" ]
then

  echo "Setting up webdrive mount configuration ..."
  echo "Creatng default.prf from the template"
  if [ -f "/root/.unison/default.prf.template" ]
  then
    # Do not change the single quotes around ${WEBDRIVE_REMOTE_PATH} below to double quotes
    # Otherwise the environment variables will not be expanded
    envsubst '${WEBDRIVE_REMOTE_PATH}' < /root/.unison/default.prf.template > /root/.unison/default.prf
    if  [ -f "/root/.unison/default.prf" ]
    then
      echo "The preference file [default.prf] created successfully."
      echo "Deleating the preference template file [default.prf.template]."
      rm -f "/root/.unison/default.prf.template"

      if [ ! -f "/root/.unison/default.prf.template" ]
      then
        echo "The preference template [default.prf.template] deleated successfully."

        # save webdav drive credentials
        echo "Saving the webrive credentials in /etc/davfs2/secrets"
        echo "${WEBDRIVE_URL} ${WEBDRIVE_UID} ${WEBDRIVE_PWD}" >> /etc/davfs2/secrets
     else
        echo "Failed to delete the preference template [default.prf.template]."
      fi
    else
      echo "Failed to create preference file [default.prf]."
    fi
  else
    echo "Failed to create preference file default.prf. The template file [/root/.unison/default.prf.template] not found."
  fi

  # Create user
  #FOLDER_USER=${SYNC_USERID:-0}
  #if [ $FOLDER_USER -gt 0 ]; then
  #  useradd webdrive -u $FOLDER_USER -N -G users
  #fi
fi

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
  echo "Webdrive was already mounted"
fi

# Start the endless sync process
echo "Starting unison process ..."
unison