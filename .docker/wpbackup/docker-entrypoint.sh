#!/bin/bash

  # First read the password
# First creating the webdav mounts
if [ -z "${WPBACKUP_CRON_FILE}" ]
then
  echo "WEBDRIVE_BACKUP_CRON_FILE is not set";
elif [ ! -f "/backupcron" ]
then
  # Schedule the cron task
  echo "Creating backupup cron job"
  crontab -l                    >   /backupcron
  cat "${WPBACKUP_CRON_FILE}"   >>  /backupcron

   crontab /backupcron
  # to do restore from backup
  #
fi

echo "Current crontab:"
crontab -l

exec "$@"