#!/bin/bash

  # First read the password
if [ -n "${WPBACKUP_MYSQL_PASSWORD_FILE}" ]; then WPBACKUP_MYSQL_PASSWORD=$(<"${WPBACKUP_MYSQL_PASSWORD_FILE}"); fi
if [ -z "${WPBACKUP_MYSQL_PASSWORD}" ]; then  echo "WPBACKUP_MYSQL_PASSWORD_FILE is not set"; fi

# First creating the webdav mounts
if [ ! -f "/backup-cron" ] && [ -n "${WPBACKUP_MYSQL_PASSWORD}" ] ; then
  
  # Create a cron task file
  echo "Creating cron entry to start backup at: ${WPBACKUP_TIME}"
  echo "WPBACKUP_MYSQL_HOST=${WPBACKUP_MYSQL_HOST}"                      >  /backup-cron
  echo "WPBACKUP_MYSQL_PORT=${WPBACKUP_MYSQL_PORT}"                      >> /backup-cron
  echo "WPBACKUP_MYSQL_USERNAME=${WPBACKUP_MYSQL_USERNAME}"              >> /backup-cron
  echo "WPBACKUP_MYSQL_DATABASE=${WPBACKUP_MYSQL_DATABASE}"              >> /backup-cron
  echo "WPBACKUP_MYSQL_PASSWORD=${WPBACKUP_MYSQL_PASSWORD}"              >> /backup-cron
  echo "WPBACKUP_WEBSITE_NAME=${WPBACKUP_WEBSITE_NAME}"                  >> /backup-cron
  echo "NOW=\$(date +\"%Y-%m-%d-%H%M%S\")"                             >> /backup-cron
  if [[ $CLEANUP_OLDER_THAN ]]; then
    echo "CLEANUP_OLDER_THAN=\$CLEANUP_OLDER_THAN"                  >> /backup-cron
  fi
  echo " 0 ${WPBACKUP_TIME} * * *    backup.sh > /var/backups/logs/backup-\$NOW.log" >> /backup-cron
  crontab /backup-cron

  # to do restore from backup
  #
fi

echo "Current crontab:"
crontab -l

exec "$@"