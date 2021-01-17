#!/bin/bash

# This script creates a compressed backup archive of the wordpress wp-content folder and nysql dmp

echo "[$(date +"%Y-%m-%d-%H%M%S")] Staritng backup task ..."

if [ -z "${WPBACKUP_WEBSITE}" ];       then echo "Error: WPBACKUP_WEBSITE not set";       echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WPBACKUP_DB_NAME}" ];       then echo "Error: WPBACKUP_DB_NAME not set";       echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WPBACKUP_DB_USER}" ];       then echo "Error: WPBACKUP_DB_USER not set";       echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WPBACKUP_WPCONTENT_DIR}" ]; then echo "Error: WPBACKUP_WPCONTENT_DIR not set"; echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WPBACKUP_BACKUP_DIR}" ];    then echo "Error: WPBACKUP_BACKUP_DIR not set";    echo "Finished: FAILURE"; exit 1; fi
if [ ! -f ~/.my.cnf  ];                then echo "Error: ~/.my.cnf does not exist";       echo "Finished: FAILURE"; exit 1; fi

# First find out the type of backup, ie. if user passes a value its adhoc
# else it is called from cron job and its its either monthly, weekly and daily
BACKUP_DESC="$1"; BACKUP_TYPE="daily";
if   [ -n "${BACKUP_DESC}"  ];  then BACKUP_TYPE="adhoc";
elif [ "$(date +%d)" == "1" ];  then BACKUP_TYPE="monthly";
elif [ "$(date +%u)" == "1" ];  then BACKUP_TYPE="weekly"; fi

TEMP_DIR="/tmp"

# Set the filenames of various backups
NOW="${NOW:-$(date +"%Y-%m-%d-%H%M")}"
if [ -n "${BACKUP_DESC}" ]; then BACKUP_DESC="-${BACKUP_DESC}"; fi
DB_FILENAME="${WPBACKUP_WEBSITE}-${BACKUP_TYPE}-${NOW}${BACKUP_DESC}.sql"
TR_FILENAME="${WPBACKUP_WEBSITE}-${BACKUP_TYPE}-${NOW}${BACKUP_DESC}.tar"

# Tar transformation for better archive structure.
# Make sure the name below matches with the backup.sh script
WP_TRANSFORM="s,^${WPBACKUP_WPCONTENT_DIR/\//},${WPBACKUP_WEBSITE}-backup/wp,"
DB_TRANSFORM="s,^${TEMP_DIR/\//},${WPBACKUP_WEBSITE}-backup/db,"

# Create the archive and the MySQL dump
# Password, host etc. supplied by ~/.my.cnf
tar -cvf "${TEMP_DIR}/${TR_FILENAME}" --transform "${WP_TRANSFORM}" "${WPBACKUP_WPCONTENT_DIR}"
mysqldump --add-drop-table --no-tablespaces --user="${WPBACKUP_DB_USER}" "${WPBACKUP_DB_NAME}"  > "${TEMP_DIR}/${DB_FILENAME}"

# Append the dump to the archive
# And compress the whole archive.
tar --append --file="${TEMP_DIR}/${TR_FILENAME}" --transform "${DB_TRANSFORM}" "${TEMP_DIR}/${DB_FILENAME}"
gzip -9 "${TEMP_DIR}/${TR_FILENAME}"
mv "${TEMP_DIR}/${TR_FILENAME}.gz" "${WPBACKUP_BACKUP_DIR}/"

# If we have a dropbox token passed in the fle
if [ -n "${WPBACKUP_DROPBOX_TOKEN_FILE}" ]; then WPBACKUP_DROPBOX_TOKEN=$(<"${WPBACKUP_DROPBOX_TOKEN_FILE}"); fi
if [ -n "${WPBACKUP_GPG_PASSWORD_FILE}" ];  then WPBACKUP_GPG_PASSWORD=$(<"${WPBACKUP_GPG_PASSWORD_FILE}"); fi
if [ -z "${WPBACKUP_DROPBOX_TOKEN}" ]
then
  echo "WPBACKUP_DROPBOX_TOKEN_FILE is not set - Skippng uploading the database file to dropbox";
else
  echo "Uploading the database file to Dropbox"
  if [ -z "${WPBACKUP_GPG_PASSWORD}" ]
  then
    echo "Error: WPBACKUP_GPG_PASSWORD_FILE not set";
    echo "File wll not be uploaded to dropbox";
  else
    # encrypting the sql file with gpg
    # to decrot the gpg file, download gpg tools and type
    # gpg --decrypt <filename.gpg>
    # then when prompted type the pass pharase set to encrypt the file
    gpg --batch --yes --passphrase "${WPBACKUP_GPG_PASSWORD}" --symmetric  "${TEMP_DIR}/${DB_FILENAME}"
    #
    # Upload the database file to dropbox
    echo "Uploading the excrypted SQL file to dropbox ..."
    curl -X POST https://content.dropboxapi.com/2/files/upload\
      --header "Authorization: Bearer ${WPBACKUP_DROPBOX_TOKEN}" \
      --header "Dropbox-API-Arg: {\"path\": \"/${WPBACKUP_WEBSITE}/${DB_FILENAME}.gpg\",\"mode\": \"add\",\"autorename\": false,\"mute\": false,\"strict_conflict\": false}" \
      --header "Content-Type: application/octet-stream" \
      --data-binary "@${TEMP_DIR}/${DB_FILENAME}.gpg"
    echo "The excrypted SQL file uploaded to dropbox successflly."
    #
    # delete the encrypted file
    rm "${TEMP_DIR}/${DB_FILENAME}.gpg"
  fi
fi

# Now delete the SQL files
rm "${TEMP_DIR}/${DB_FILENAME}"


# Clean older backup
if [ -n "${WP_CLEAN_DAILY_DAYS}" ]
then
  echo "Deleting daily backup files older than ${WP_CLEAN_DAILY_DAYS} days"
  find "${WPBACKUP_BACKUP_DIR}" -name "${WPBACKUP_WEBSITE}-daily*"  -type f -mtime "+${WP_CLEAN_DAILY_DAYS}" -delete
fi
if [ -n "${WP_CLEAN_WEEKLY_DAYS}" ]
then
  echo "Deleting weekly backup files older than ${WP_CLEAN_WEEKLY_DAYS} days"
  find "${WPBACKUP_BACKUP_DIR}" -name "${WPBACKUP_WEBSITE}-weekly*"  -type f -mtime "+${WP_CLEAN_WEEKLY_DAYS}" -delete
fi
if [ -n "${WP_CLEAN_MONTHLY_DAYS}" ]
then
  echo "Deleting monthly backup files older than ${WP_CLEAN_MONTHLY_DAYS} days"
  find "${WPBACKUP_BACKUP_DIR}" -name "${WPBACKUP_WEBSITE}-monthly*"  -type f -mtime "+${WP_CLEAN_MONTHLY_DAYS}" -delete
fi

echo "[$(date +"%Y-%m-%d-%H%M%S")] Finishing backup task ..."

exit 0;