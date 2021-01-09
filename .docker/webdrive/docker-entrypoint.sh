#!/bin/bash

if [ -n "${WEBDRIVE_URL_FILE}" ]; then WEBDRIVE_URL=$(<$WEBDRIVE_URL_FILE); fi
if [ -z "${WEBDRIVE_URL}" ]; then  echo "Webdrive url is not set"; fi

if [ -n "${WEBDRIVE_UID_FILE}" ]; then WEBDRIVE_UID=$(<$WEBDRIVE_UID_FILE); fi
if [ -z "${WEBDRIVE_UID}" ]; then  echo "Webdrive uid is not set"; fi

if [ -n "${WEBDRIVE_PWD_FILE}" ]; then WEBDRIVE_PWD=$(<$WEBDRIVE_PWD_FILE); fi
if [ -z "${WEBDRIVE_PWD}" ]; then echo "Webdrive pwd is not set"; fi


if [ -f /root/.unison/default.prf.template ]
then

  echo "First run detected ..."

  mkdir -p /mnt/webdrive/${WEBDRIVE_REMOTE_PATH}
  mkdir -p /var/backups/${WEBDRIVE_REMOTE_PATH}

  echo "Creatng default.prf from the template"
  if [ -f "/root/.unison/default.prf.template" ]
  then
    envsubst '${WEBDRIVE_REMOTE_PATH}' < /root/.unison/default.prf.template > /root/.unison/default.prf
    echo "The preference file [default.prf] created successfully."
  elif [ -f "/root/.unison/default.prf" ]
  then
    echo "The default.prf has already been created."
  else
    echo "Failed to create default.prf. The template file [/root/.unison/default.prf.template] not found."
  fi

  if [ -f "/root/.unison/default.prf" ]
  then
    echo "Deleating the preference template file [default.prf.template]."
    rm -f /root/.unison/default.prf.template;
    echo "The preference template [default.prf.template] deleated successfully."
  fi

  # save webdav drive credentials
  echo "$WEBDRIVE_URL $WEBDRIVE_UID $WEBDRIVE_PWD" >> /etc/davfs2/secrets

  # Create user
  #FOLDER_USER=${SYNC_USERID:-0}
  #if [ $FOLDER_USER -gt 0 ]; then
  #  useradd webdrive -u $FOLDER_USER -N -G users
  #fi
fi

# Mount the webdav drive 
mount -t davfs $WEBDRIVE_URL /mnt/webdrive -o uid=0,gid=users,dir_mode=755,file_mode=755
if [ ! -d /mnt/webdrive/${WEBDRIVE_REMOTE_PATH} ]; then
  mkdir -p /mnt/webdrive/${WEBDRIVE_REMOTE_PATH}
  echo "Remote directory [/mnt/webdrive/${WEBDRIVE_REMOTE_PATH}] created"
fi

# Start the endless sync process
unison