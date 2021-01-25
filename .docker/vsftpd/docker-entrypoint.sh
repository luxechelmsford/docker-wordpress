#!/bin/bash


echo "****************************************************************"
echo "[$(date +"%Y-%m-%d-%H%M%S")] Entered vsftpd entrypoint script ..."


if [ -z "${VSFTPD_ENABLED}" ] || [ "${VSFTPD_ENABLED}" != "yes" ]
then
  echo "Vsftpd is disabled. To ebable Vsftpd set the VSFTPD_ENABLED variable to yes"
else

  if [ -z "${VSFTPD_USERNAME}" ];      then echo "Error: VSFTPD_USERNAME not set";     echo "Finished: FAILURE"; exit; fi
  if [ -z "${VSFTPD_PASSWORD}" ];      then echo "Error: VSFTPD_PASSWORD not set";     echo "Finished: FAILURE"; exit; fi
  if [ -z "${VSFTPD_HOME_DIR}" ];      then echo "Error: VSFTPD_ROOT_DIR not set";     echo "Finished: FAILURE"; exit; fi
  if [ -z "${VSFTPD_SERVER_URL}" ];    then echo "Error: VSFTPD_SERVER_URL not set";   echo "Finished: FAILURE"; exit; fi

  echo "Checking if the user [${VSFTPD_USERNAME}] is included into the allowed user list ..."
  if [ -f "/etc/vsftpd/vsftpd.userlist" ]
  then
    echo "The ftp service has been configured in the previous run"
  else
    echo "Adding the user [${VSFTPD_USERNAME}] to the allowed user list [/etc/vsftpd/vsftpd.userlist] ..."
    echo ${VSFTPD_USERNAME} >"/etc/vsftpd/vsftpd.userlist"
  fi

  echo "Checking if the group [www-data:82] exists ..."
 if [ "$(getent group www-data)" ]; then
    echo "Group [www-data:82] already exists ..."
  else
    echo "Adding the group www-data:82 ..."
    addgroup -g 82 www-data
  fi

  echo "Checking if the user [${VSFTPD_USERNAME}] exists ..."
  if id "${VSFTPD_USERNAME}" &>/dev/null; then
    echo "User [${VSFTPD_USERNAME}] already exists ..."
  else
    echo "Adding the user [${VSFTPD_USERNAME}] ..."
    adduser -G www-data --gecos "" --disabled-password -h "${VSFTPD_HOME_DIR}" "${VSFTPD_USERNAME}"
    echo "Setting password ..."
    chpasswd <<<"${VSFTPD_USERNAME}:${VSFTPD_PASSWORD}"
  fi

  # Used to run custom commands inside container
  if [ -n "$1" ]; then
    echo "Executing passed commands ..."
    exec "$@"
  else
    echo "Running the ftp server ..."
    if [ -n "$VSFTPD_SERVER_URL" ]; then ADDR_OPT="-opasv_address=$VSFTPD_SERVER_URL"; fi
    exec /usr/sbin/vsftpd -opasv_min_port=21000 -opasv_max_port=21010 $ADDR_OPT -olocal_root=${VSFTPD_HOME_DIR} /etc/vsftpd/vsftpd.conf
  fi
fi

echo "[$(date +"%Y-%m-%d-%H%M%S")] Exiting vsftpd entrypoint script ..."
echo "*******************************************************************"