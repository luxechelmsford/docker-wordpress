#!/bin/bash
set -eu

echo Nginx server staring ...

if [ -f /etc/nginx/conf.d/default.conf ]
then

  echo First run detected ...

  if [ -z "${WORDPRESS_ALL_SERVER_URLS}" ]; then echo "Wordpress all server list is not set"; fi
  if [ -z "${PHPMYADMIN_ALL_SERVER_URLS}" ]; then  echo "PhpMyAdmin all server list is not set"; fi

  echo "Creatng wordpress.conf from the template"
  if [ -f "/etc/nginx/conf.d/wordpress.conf.template" ]
  then
    envsubst '${WORDPRESS_ALL_SERVER_URLS}' < /etc/nginx/conf.d/wordpress.conf.template > /etc/nginx/conf.d/wordpress.conf
    echo "The conf file [wordpress.conf] created successfully ..."
  elif [ -f "/etc/nginx/conf.d/wordpress.conf" ]
  then
    echo "The wordpress.conf has already been created."
  else
    echo "Failed to create wordpress.conf. The template file [/etc/nginx/conf.d/wordpress.conf.template] not found."
  fi

  echo "Creatng phpmyadmin.conf from the template"
  if [ -f "/etc/nginx/conf.d/phpmyadmin.conf.template" ]
  then
    envsubst '${PHPMYADMIN_ALL_SERVER_URLS}' < /etc/nginx/conf.d/phpmyadmin.conf.template > /etc/nginx/conf.d/phpmyadmin.conf
    echo "The conf file [phpmyadmin.conf] created successfully ..."
  elif [ -f "/etc/nginx/conf.d/phpmyadmin.conf" ]
  then
    echo "The phpmyadmin.con has already been created."
  else
    echo "Failed to create phpmyadmin.conf. The template file [/etc/nginx/conf.d/phpmyadmin.conf.template] not found."
  fi

  if [ -f "/etc/nginx/conf.d/wordpress.conf" ] && [ -f "/etc/nginx/conf.d/phpmyadmin.conf" ]
  then
    echo "Deleting the template files [wordpress.conf phpmyadmin.conf & default.conf] ..."
    rm -f /etc/nginx/conf.d/wordpress.conf.template && rm -f /etc/nginx/conf.d/phpmyadmin.conf.template && rm -f /etc/nginx/conf.d/default.conf;
    echo "The template files [wordpress.conf phpmyadmin.conf & default.conf] deleted successfully ..."
  fi
fi

exec "$@"