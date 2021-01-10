#!/bin/bash
set -eu

echo Nginx server staring ...

# Check and create Nginx Conf, if not created in the previous run
if [ -f "/etc/nginx/conf.d/wordpress.conf.template" ]
then
  echo "Creating conf file [wordpress.conf] from the template file [[wordpress.conf.template]."
  if [ -z "${WORDPRESS_ALL_SERVER_URLS}" ]
  then
    echo "Failed to create conf file [wordpress.conf] - WORDPRESS_ALL_SERVER_URLS environemnt variable not set";
    echo "Wordpress all server url list is not set";
  else   
    envsubst '${WORDPRESS_ALL_SERVER_URLS}' < /etc/nginx/conf.d/wordpress.conf.template > /etc/nginx/conf.d/wordpress.conf

    if [ ! -f "/etc/nginx/conf.d/wordpress.conf" ]
    then
      echo "Failed to create wordpress.conf."
    else
      echo "The conf file [wordpress.conf] created successfully ..."
      echo "Now deleteting the template file [wordpress.conf.template] ..."
      rm -f /etc/nginx/conf.d/wordpress.conf.template
 
      if [ -f "/etc/nginx/conf.d/wordpress.conf.template" ]
      then
        echo "Failed to delete template files [wordpress.conf.template] ..."
      else
        echo "The template files [wordpress.conf.template] deleted successfully ..."
      fi
    fi
  fi
  
fi

# Check and create PhpMyAdmin Conf, if not created in the previous run
if [ -f "/etc/nginx/conf.d/phpmyadmin.conf.template" ]
then
  echo "Creating conf file [phpmyadmin.conf] from the template file [[phpmyadmin.conf.template]."
  if [ -z "${PHPMYADMIN_ALL_SERVER_URLS}" ]
  then
    echo "Failed to create conf file [phpmyadmin.conf] - PHPMYADMIN_ALL_SERVER_URLS environemnt variable not set";
    echo "Wordpress all server url list is not set";
  else   
    envsubst '${PHPMYADMIN_ALL_SERVER_URLS}' < /etc/nginx/conf.d/phpmyadmin.conf.template > /etc/nginx/conf.d/phpmyadmin.conf

    if [ ! -f "/etc/nginx/conf.d/phpmyadmin.conf" ]
    then
      echo "Failed to create phpmyadmin.conf."
    else
      echo "The conf file [phpmyadmin.conf] created successfully ..."
      echo "Now deleteting the template file [phpmyadmin.conf.template] ..."
      rm -f /etc/nginx/conf.d/phpmyadmin.conf.template
 
      if [ -f "/etc/nginx/conf.d/phpmyadmin.conf.template" ]
      then
        echo "Failed to delete template files [phpmyadmin.conf.template] ..."
      else
        echo "The template files [phpmyadmin.conf.template] deleted successfully ..."
      fi
    fi
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


# Delete default.conf
if [ -f /etc/nginx/conf.d/default.conf ]
then
  echo "Deleting the default conf files [default.conf] ..."
  rm -f /etc/nginx/conf.d/default.conf
  echo "The default conf files [default.conf] deleted successfully ..."

  # Check if certificate exists
  if [ ! -f etc/letsencrypt/live/thetek.co.uk/fullchain.pem ] ||  [ ! -f /etc/letsencrypt/live/thetek.co.uk/privkey.pem]
  then
    echo "Installting SSL certificate for ${WORDPRESS_ALL_SERVER_URLS} ${PHPMYADMIN_ALL_SERVER_URLS} ... "
    if [ -z "${LETSENCRYPT_ADMIN_EMAIL_FILE}" ]
    then
      echo "Failed to install letsencrypt certificates - LETSENCRYPT_ADMIN_EMAIL_FILE environemnt variable not set";
    else
      ADMIN_EMAIL=$(<$LETSENCRYPT_ADMIN_EMAIL_FILE);  
      DOMAIN_LIST="-d ${WORDPRESS_ALL_SERVER_URLS/ / -d } -d ${PHPMYADMIN_ALL_SERVER_URLS/ / -d }"
      certbot --nginx --non-interactive --agree-tos --email ${ADMIN_EMAIL} ${DOMAIN_LIST}
      if [ -f etc/letsencrypt/live/thetek.co.uk/fullchain.pem ] &&  [ -f /etc/letsencrypt/live/thetek.co.uk/privkey.pem]
      then
        echo "Certificate installed successfully ... "
      fi
    fi
  fi
fi

# Shedule cron task
/usr/sbin/crond -f -l 8

exec "$@"