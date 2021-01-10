#!/bin/bash
set -eu

echo Nginx service is staring ...

# Checking all variables
if [ -z "${WORDPRESS_ALL_SERVER_URLS}" ]; then  echo "WORDPRESS_ALL_SERVER_URLS is not set"; fi
if [ -z "${PHPMYADMIN_ALL_SERVER_URLS}" ]; then  echo "PHPMYADMIN_ALL_SERVER_URLS is not set"; fi
if [ -z "${LETSENCRYPT_ADMIN_EMAIL_FILE}" ]; then  echo "LETSENCRYPT_ADMIN_EMAIL_FILE is not set"; fi



# Check and create Nginx Conf, if not created in the previous run
if [ -n "${WORDPRESS_ALL_SERVER_URLS}" ] && [ -f "/etc/nginx/conf.d/wordpress.conf.template" ]
then
  # Do not change the single quotes around ${WORDPRESS_ALL_SERVER_URLS} below to double quotes
  # Otherwise the environment variables will not be expanded
  envsubst '${WORDPRESS_ALL_SERVER_URLS}' < /etc/nginx/conf.d/wordpress.conf.template > /etc/nginx/conf.d/wordpress.conf

  if [ -f "/etc/nginx/conf.d/wordpress.conf" ]
  then
    echo "The conf file [wordpress.conf] created successfully ..."
    echo "Now deleting the template file [wordpress.conf.template] ..."
    rm -f /etc/nginx/conf.d/wordpress.conf.template
    if [ ! -f "/etc/nginx/conf.d/wordpress.conf.template" ]
    then
      echo "The template files [wordpress.conf.template] deleted successfully ..."
    else
      echo "Failed to delete template files [wordpress.conf.template] ..."
    fi
  else
    echo "Failed to create wordpress.conf."
  fi
fi



# Check and create Nginx Conf, if not created in the previous run
if [ -n "${PHPMYADMIN_ALL_SERVER_URLS}" ] && [ -f "/etc/nginx/conf.d/phpmyadmin.conf.template" ]
then
  # Do not change the single quotes around ${PHPMYADMIN_ALL_SERVER_URLS} below to double quotes
  # Otherwise the environment variables will not be expanded
  envsubst '${PHPMYADMIN_ALL_SERVER_URLS}' < /etc/nginx/conf.d/phpmyadmin.conf.template > /etc/nginx/conf.d/phpmyadmin.conf

  if [ -f "/etc/nginx/conf.d/phpmyadmin.conf" ]
  then
    echo "The conf file [phpmyadmin.conf] created successfully ..."
    echo "Now deleting the template file [phpmyadmin.conf.template] ..."
    rm -f /etc/nginx/conf.d/phpmyadmin.conf.template
    if [ ! -f "/etc/nginx/conf.d/phpmyadmin.conf.template" ]
    then
      echo "The template files [phpmyadmin.conf.template] deleted successfully ..."
    else
      echo "Failed to delete template files [phpmyadmin.conf.template] ..."
    fi
  else
    echo "Failed to create phpmyadmin.conf."
  fi
fi



# Delete default.conf
if [ -f /etc/nginx/conf.d/default.conf ]
then
  echo "Deleting the default conf files [default.conf] ..."
  rm -f /etc/nginx/conf.d/default.conf
  echo "The default conf files [default.conf] deleted successfully ..."
fi



# Check if certificate exists
if [ -n "${WORDPRESS_ALL_SERVER_URLS}" ] && [ -n "${PHPMYADMIN_ALL_SERVER_URLS}" ]
then
  if [ ! -f etc/letsencrypt/live/thetek.co.uk/fullchain.pem ] ||  [ ! -f /etc/letsencrypt/live/thetek.co.uk/privkey.pem ]
  then
    echo "Installing SSL certificate for ${WORDPRESS_ALL_SERVER_URLS} ${PHPMYADMIN_ALL_SERVER_URLS} ... "
    if [ -z "${LETSENCRYPT_ADMIN_EMAIL_FILE}" ]
    then
      echo "Failed to install letsencrypt certificates - LETSENCRYPT_ADMIN_EMAIL_FILE environemnt variable not set";
    else
      ADMIN_EMAIL=$(<"${LETSENCRYPT_ADMIN_EMAIL_FILE}");
      DOMAIN_LIST=""
      IFS=', ' read -r -a array <<< "$WORDPRESS_ALL_SERVER_URLS"
      for element in "${array[@]}"
      do
         DOMAIN_LIST="${DOMAIN_LIST} -d ${element}";
      done      
      IFS=', ' read -r -a array <<< "$PHPMYADMIN_ALL_SERVER_URLS"
      for element in "${array[@]}"
      do
         DOMAIN_LIST="${DOMAIN_LIST} -d ${element}";
      done
echo $DOMAIN_LIST
      # Do not add any double quoetes on ${DOMAIN_LIST}, as there are multiple options together
      # if the var is enclsied in double quotes, it will be passed as one single domian - wonn't work 
      certbot --nginx --non-interactive --agree-tos --email "${ADMIN_EMAIL}" ${DOMAIN_LIST}
      if [ -f etc/letsencrypt/live/thetek.co.uk/fullchain.pem ] &&  [ -f /etc/letsencrypt/live/thetek.co.uk/privkey.pem ]
      then
        echo "Certificate installed successfully ... "
      fi
    fi
  else
    echo "SSL certificates already exist for wordpress and phpmyadmin"
  fi
fi



# Report if any of the conf is not found
if [ -f "/etc/nginx/conf.d/wordpress.conf" ]
then
  echo "Wordpress conf file found - starting wordpress nginx web service ..."
else
  echo "FATAL ERROR - the wordpress conf file not found - A reinstallation of the container may be required ..."
fi
if [ -f "/etc/nginx/conf.d/phpmyadmin.conf" ]
then
  echo "PHPMyAdmin conf file found - starting phpmyadmin nginx web service ..."
else
  echo "FATAL ERROR - the phpmyadmin conf file not found - A reinstallation of the container may be required ..."
fi



# Shedule cron task
/usr/sbin/crond -f -l 8

exec "$@"   