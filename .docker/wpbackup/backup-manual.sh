#!/bin/bash

WPBACKUP_WEBSITE="abs-live"
WPBACKUP_WPCONTENT_DIR="/root/wordpress/artbysweta2.com/wp-content"
WPBACKUP_DB_DUMP_DIR="/root/wordpress/artbysweta2.com"
EXISTING_SQL_FILENAME="admin_artbysweta.mysql.sql"


WPBACKUP_DB_NAME="${WEBSITE_NAME//-/_}"
WPBACKUP_DB_USER=$WPBACKUP_DB_NAME
WPBACKUP_ROOT_DIR="."


# First find out the type of backup, ie. if user passes a value its adhoc
# else it is called from cron job and its its either monthly, weekly and daily
BACKUP_DESC="imported-from-previous-website"
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
DB_TRANSFORM="s,^${WPBACKUP_DB_DUMP_DIR/\//},${WPBACKUP_WEBSITE}-backup/db,"


# Create the archive and the MySQL dump
# Password, host etc. supplied by ~/.my.cnf
echo Creating tar
rm -f "./${TR_FILENAME}"
tar -cvf "./${TR_FILENAME}" --transform "${WP_TRANSFORM}" "${WPBACKUP_WPCONTENT_DIR}"
#mysqldump --add-drop-table --no-tablespaces --user="${WPBACKUP_DB_USER}" "${WPBACKUP_DB_NAME}"  > "${TEMP_DIR}/${DB_FILENAME}"


# Append the dump to the archive
# And compress the whole archive.
echo Adding sql to tar
cp "${WPBACKUP_DB_DUMP_DIR}/${EXISTING_SQL_FILENAME}" "${WPBACKUP_DB_DUMP_DIR}/${DB_FILENAME}"
tar --append --file="./${TR_FILENAME}" --transform "${DB_TRANSFORM}" "${WPBACKUP_DB_DUMP_DIR}/${DB_FILENAME}"
gzip -9 "./${TR_FILENAME}"
rm -f "${WPBACKUP_DB_DUMP_DIR}/${EXISTING_SQL_FILENAME}"
