#!/bin/bash


echo "*******************************************************************"
echo "[$(date +"%Y-%m-%d-%H%M%S")] Entered mysql entrypoint script ..."

if [ -z "${MYSQL_ROOT_PASSWORD}" ];         then echo "Error: MYSQL_ROOT_PASSWORD not set";         echo "Finished: FAILURE"; exit 1; fi

# Create the conf file
# Do not include double quotes around ~/.my.cnf, it wont' expand 
if [ ! -s "/etc/mysql/conf.d/.mycnf" ]
then
  echo "Creating Mysql config file ...";
  cat <<EOF > "/etc/mysql/conf.d/my.cnf"
[mysql]
host=localhost
user=root
password=${MYSQL_ROOT_PASSWORD}
[mysqld]
collation-server=utf8mb4_unicode_ci
character-set-server=utf8mb4
[mysqldump]
host=localhost
user=root
password=${MYSQL_ROOT_PASSWORD}
EOF
    
  if [ -s "/etc/mysql/conf.d/.my.cnf" ]
  then
    echo "Mysql config file created successfully.";
  fi
fi


echo "[$(date +"%Y-%m-%d-%H%M%S")] Exiting mysql entrypoint script ..."
echo "*******************************************************************"
