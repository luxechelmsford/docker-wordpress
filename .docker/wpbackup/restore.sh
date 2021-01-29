#!/bin/bash
set -e

echo "*******************************************************************"
echo "[$(date +"%Y-%m-%d-%H%M%S")] Entered wpbackup restore script ..."

if [ -z "${WPBACKUP_WEBSITE}" ];       then echo "Error: WPBACKUP_WEBSITE not set";                echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WPBACKUP_DB_NAME}" ];       then echo "Error: WPBACKUP_DB_NAME not set";                echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WPBACKUP_DB_USER}" ];       then echo "Error: WPBACKUP_DB_USER not set";                echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WPBACKUP_WPCONTENT_DIR}" ]; then echo "Error: WPBACKUP_WPCONTENT_DIR not set";          echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WPBACKUP_ROOT_DIR}" ];      then echo "Error: WPBACKUP_ROOT_DIR not set";               echo "Finished: FAILURE"; exit 1; fi
if [ -z "${MYSQL_USER_CNF_FILE}" ];    then echo "Error: MYSQL_USER_CNF_FILE not set";             echo "Finished: FAILURE"; exit 1; fi
if [ -z "${MYSQL_ROOT_CNF_FILE}" ];    then echo "Error: MYSQL_ROOT_CNF_FILE not set";             echo "Finished: FAILURE"; exit 1; fi
if [ !  "${MYSQL_USER_CNF_FILE}" ];    then echo "Error: [${MYSQL_USER_CNF_FILE}] does not exist"; echo "Finished: FAILURE"; exit 1; fi
if [ !  "${MYSQL_ROOT_CNF_FILE}" ];    then echo "Error: [${MYSQL_ROOT_CNF_FILE}] does not exist"; echo "Finished: FAILURE"; exit 1; fi


# Read the command line args. Expected parameters are:
# <$1>  Mandatory, the backup tar file to be restored from
# [$2]  Optional,  the wpcustom zip file to be copied on the deafult wordpress content
# [$3]  optional, -r to recreate the database, will require to be confirmed
RESTORE_FILE=$1
if [ -z "${RESTORE_FILE}" ]
then
  echo "Error: The backup file to restore from needs to be passed as first parameter"
  echo "Finished: FAILURE"
  exit 1
fi
#
if [ ! -f "${RESTORE_FILE}" ]
then
  echo "The restore file  [${RESTORE_FILE}] does not exist."
  echo "Finished: FAILURE"
  exit 1;
fi
#
RECREATE=""
if [ "$2" == "-r" ] || [ "$2" == "--recreate" ]
then
  RECREATE="Yes"
else
  WPCUSTOM_FILE=${2}
  if [ -n "${WPCUSTOM_FILE}" ]
  then
    if [ ! -f "${WPCUSTOM_FILE}" ]
    then
      echo "The restore file  [${WPCUSTOM_FILE}] does not exist."
      echo "Finished: FAILURE"
      exit 1;
    fi
  fi
  if [ "$3" == "-r" ] || [ "$3" == "--recreate" ]
  then
   RECREATE="Yes"
  fi
fi

echo "Restoring from a Wordpress backup with following options"
echo "    Restore File:  [${RESTORE_FILE}]"
echo "    Wpcustom File: [${WPCUSTOM_FILE:-"None"}]"
echo "    Recreate DB:   [${RECREATE:-"No"}]"

# Now check if the database is empty
# Host and password information is stored in config so there is no need to pass here
DB_TABLES=$(echo "show tables" | mysql "--defaults-extra-file=${MYSQL_USER_CNF_FILE}" "${WPBACKUP_DB_NAME}")
if  [ -n "${DB_TABLES}" ]
then
  if [ -n "${RECREATE}" ]
  then
    read -p "The existing databsae will be dropped before recreating? Are you sure (Y/N)? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      echo "Recreating mysql database ...";
      cat <<EOF > /tmp/recreatedb.sql
DROP DATABASE ${WPBACKUP_DB_NAME};
CREATE DATABASE ${WPBACKUP_DB_NAME};
GRANT ALL PRIVILEGES ON ${WPBACKUP_DB_NAME}.* TO '${WPBACKUP_DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

      mysql "--defaults-extra-file=${MYSQL_ROOT_CNF_FILE}" < /tmp/recreatedb.sql
      DB_TABLES=$(echo "show tables" | mysql "--defaults-extra-file=${MYSQL_USER_CNF_FILE}" "${WPBACKUP_DB_NAME}")
      if  [ -n "${DB_TABLES}" ]
      then
        echo "Failed to restore as database couldnt be recreated"
        echo "Finished: FAILURE";
        exit 1;
      else
        echo "Mysql config file created successfully.";
      fi
    else
      echo "Failed to restore - Cancelled by user"
      echo "Finished: FAILURE";
      exit 1;
    fi
  else 
    echo "Failed to restore as the database is NOT EMPTY."
    echo "If restore is required, pleas use -r option to drop the database and recreate"
    echo "Finished: FAILURE";
    exit 1;
  fi
fi

# Set temp dir
TEMP_DIR="/tmp"

# Make sure the name below matches with the backup.sh script
echo "Removing any previous restore folder ..."
rm -rf "${TEMP_DIR}/${WPBACKUP_WEBSITE}-backup"

echo "Uncompressing the backup tar ..."
sudo tar --same-owner -xpzf "${RESTORE_FILE}" --directory "${TEMP_DIR}/"

# Check we have the right folder structure
wpsrcDir=""; dbsrcDir="";
if [ -d "${TEMP_DIR}/${WPBACKUP_WEBSITE}-backup/wp" ]
then
  wpsrcDir="${TEMP_DIR}/${WPBACKUP_WEBSITE}-backup/wp"
  dbsrcDir="${TEMP_DIR}/${WPBACKUP_WEBSITE}-backup/db"
elif [ -d "${TEMP_DIR}/${WPBACKUP_WEBSITE%-*}-backup/wp" ]
then
  # We are restoring from a backup from live to test (i.e. demo to demo-test)
  wpsrcDir="${TEMP_DIR}/${WPBACKUP_WEBSITE%-*}-backup/wp"
	dbsrcDir="${TEMP_DIR}/${WPBACKUP_WEBSITE%-*}-backup/db"
elif [ -d "${TEMP_DIR}/${WPBACKUP_WEBSITE}-live-backup/wp" ]
then
  # We are restoring from a backup made with -live prefix
  wpsrcDir="${TEMP_DIR}/${WPBACKUP_WEBSITE}-live-backup/wp"
	dbsrcDir="${TEMP_DIR}/${WPBACKUP_WEBSITE}-live-backup/db"
elif [ -d "${TEMP_DIR}/${WPBACKUP_WEBSITE}-backup/www/wp-content" ]
then
	# its an achive from an older backup script
	wpsrcDir="${TEMP_DIR}/${WPBACKUP_WEBSITE}-backup/www/wp-content"
  dbsrcDir="${TEMP_DIR}/${WPBACKUP_WEBSITE}-backup/db"
else
  echo "Invalid archive. WP Folder [${TEMP_DIR}/${WPBACKUP_WEBSITE}-backup/wp] not found."
  echo "Finished: FAILURE";
  exit 1;
fi

if [ ! -d "${dbsrcDir}" ]
then
  echo "Invalid archive. DB Folder [${dbsrcDir}] not found."
  echo "Finished: FAILURE";
  exit 1;
fi

echo "Deleting existing wp-content directory ..."
rm -rf "${WPBACKUP_WPCONTENT_DIR}"

# Make sure the name below matches with the backup.sh script
echo "Copying the new wp-content folder ..."
mv -f "${wpsrcDir}" "${WPBACKUP_WPCONTENT_DIR}"

echo "Setting Wordpress specific file permissions ..."
echo "Setting ownership to www-data ..."
# Use 82 for gid/uid and not www-data, as they have uid/gid 33 in ubunti 20.04
# Hence use www-data will make wp-content in assisible to wordpress and nginx services which run of www-data
find "${WPBACKUP_WPCONTENT_DIR}" -exec chown 82:82 {} \;  
echo "Setting group to www-data ..."
find "${WPBACKUP_WPCONTENT_DIR}" -exec chgrp 82 {} \;
echo "Setting directory permission to 775 ..."
find "${WPBACKUP_WPCONTENT_DIR}" -type d -exec chmod 775 {} \;
echo "Setting file permission to 664 ..."
find "${WPBACKUP_WPCONTENT_DIR}" -type f -exec chmod 664 {} \;

# Copy any customised wordpress files, if passed via WPCUSTOM_FILE
if [ -n "${WPCUSTOM_FILE}" ]
then
  if [ -f "${WPCUSTOM_FILE}" ]
  then
    echo "Copying custom wordpress files ..."
    echo "From: [${WPCUSTOM_FILE}]"
    echo "To:   [${WPBACKUP_WPCONTENT_DIR%/*}]"
    unzip "${WPCUSTOM_FILE}" -d "${WPBACKUP_WPCONTENT_DIR%/*}" 
    #rm -vrf "${TEMP_DIR}/${WPBACKUP_WEBSITE}-custom"
    #sudo tar --same-owner xpvzf "${WPCUSTOM_FILE}" -C "${TEMP_DIR}}"
    ## move it to the parent folder of 
    #mv -vrf "${TEMP_DIR}/${WPBACKUP_WEBSITE}-custom" "${WPBACKUP_WPCONTENT_DIR%/*}"
  else
    echo "The cusotom zip file [${WPCUSTOM_FILE}] was not found."
    echo "No custom wordpress files were copied."
  fi
  echo "No custom zip file is specified. Skipping the customisation of wordpress installtation."
fi

# restore database
echo "Restoring data from mysql dump file ..."
# Host and password information is stored in config so there is no need to pass here
SQL_FILENAME="${RESTORE_FILE##*/}"     # remove directry from the path
SQL_FILENAME="${SQL_FILENAME%.*}"      # remove .gz from the filename
SQL_FILENAME="${SQL_FILENAME%.*}.sql"  # remove .tar from the filename and add .sql
mysql "--defaults-extra-file=${MYSQL_USER_CNF_FILE}" "${WPBACKUP_DB_NAME}" < "${dbsrcDir}/${SQL_FILENAME}"

echo "The WORDPRESS is restored SUCCESSFULLY"

echo "[$(date +"%Y-%m-%d-%H%M%S")] Exiting wpbackup restore script ..."
echo "*******************************************************************"

exit 0;
