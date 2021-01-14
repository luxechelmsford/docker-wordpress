#!/bin/bash
set -eu



#########################################################################################
#                                                                                       #
# Get the list of the domians that do not have a letsencrypt certificates installed     #
#                                                                                       #
# Parameters                                                                            #
#   The variable to hold the list of domain for certificates to be installed            #
#   If nothing passed, the value is returned via an echo                                #
#                                                                                       # 
# Retun Values:                                                                         #
#   If all domains have certificate installed then a black strung is returned           #
#   Else all domians are returned                                                       #
#                                                                                       #
#########################################################################################

getDomainList(){

  #local __resultvar=$1

  # Get the scertificate status and grep the line like this
  #    Domains: example.com www.example.com phpmyadmin.example.com
  local DOMAINS_WITH_CERTIFICATE
  DOMAINS_WITH_CERTIFICATE="$(certbot certificates 2>/dev/null | grep -i "domains:")"

  # Remove "Domains:" in the front and add the space at the end and front
  # So that each domains has spaces both at ends
  local DOMAINS_WITH_CERTIFICATE=" ${DOMAINS_WITH_CERTIFICATE#*:} "

  # Reset the variable that will contain list of domains not having a certificate
  local NEW_DOMAINS_FOUND=""
  local DOMAIN_LIST=""

  # combine all domains in a array list and iterate 
  IFS=', ' read -r -a array <<< "${WORDPRESS_ALL_SERVER_URLS} ${PHPMYADMIN_ALL_SERVER_URLS}"
  for element in "${array[@]}"
  do
    if [[ "${DOMAINS_WITH_CERTIFICATE}" != *"${element}"* ]]; then NEW_DOMAINS_FOUND="yes"; fi
    if [ -n "${DOMAIN_LIST}" ]; then DOMAIN_LIST="${DOMAIN_LIST}, "; fi
    DOMAIN_LIST="${DOMAIN_LIST}${element}";
  done

  #if [[ "$__resultvar" ]]; then
  #  eval $__resultvar="'${DOMAIN_LIST}'"
  #else
    if [ -n "${NEW_DOMAINS_FOUND}" ]
    then
      echo "${DOMAIN_LIST}"
    else
      echo ""
    fi
  #fi
}

#########################################################################################




echo ""
echo "[$(date +"%Y-%m-%d-%H%M%S")] Entered nginx entrypoint script ..."


# Copy wordpress.conf
if [ -z "${WORDPRESS_CONF_FILE}" ]
then
  echo "WORDPRESS_CONF_FILE must be defined"
elif [ ! -f "/etc/nginx/conf.d/${WORDPRESS_CONF_FILE##*/}" ]
then
  echo "Copying the wordpress conf file [wordpress.conf] ..."
  cp "${WORDPRESS_CONF_FILE}" "/etc/nginx/conf.d/"
  if [ -f "/etc/nginx/conf.d/${WORDPRESS_CONF_FILE##*/}" ]
  then
    echo "The wordpress conf files [wordpress.conf] copied successfully"
  else
    echo "Failed to copy wordpress conf files [wordpress.conf] to the conf.d folder"
  fi
fi


# Copy phpmyadmin.conf
if [ -z "${PHPMYADMIN_CONF_FILE}" ]
then
  echo "PHPMYADMIN_CONF_FILE must be defined"
elif [ ! -f "/etc/nginx/conf.d/${PHPMYADMIN_CONF_FILE##*/}" ]
then
  echo "Copying the phpmyadmin conf file [phpmyadmin.conf] ..."
  cp "${PHPMYADMIN_CONF_FILE}" "/etc/nginx/conf.d/"
  if [ -f "/etc/nginx/conf.d/${PHPMYADMIN_CONF_FILE##*/}" ]
  then
    echo "The phpmyadmin conf files [phpmyadmin.conf] copied successfully"
  else
    echo "Failed to copy phpmyadmin conf files [phpmyadmin.conf] to the conf.d folder"
  fi
fi


# Delete default.conf
if [ -f /etc/nginx/conf.d/default.conf ]
then
  echo "Deleting the default conf files [default.conf] ..."
  rm -f /etc/nginx/conf.d/default.conf
  if [ ! -f "/etc/nginx/conf.d/default.conf" ]
  then
    echo "The default conf files [default.conf] deleted successfully"
  else
    echo "Failed to delete default conf files [default.conf] from the conf.d folder"
  fi
fi

# Check if there are domians to be added
DOMAIN_LIST=$(getDomainList)
if [ -z "${DOMAIN_LIST}" ]
then
  echo "SSL certificates already exist for wordpress and phpmyadmin"
elif [ -z "${WORDPRESS_CONF_FILE}" ]  || [ ! -f "/etc/nginx/conf.d/${WORDPRESS_CONF_FILE##*/}" ]
then
  echo "Didn't attmept to install certificate as wordpress conf file is not found/created"
elif [ -z "${PHPMYADMIN_CONF_FILE}" ] || [ ! -f "/etc/nginx/conf.d/${PHPMYADMIN_CONF_FILE##*/}" ]
then
  echo "Didn't attmept to install certificate as phpmyadmin conf file is not found/created"
elif [ -f "/firstrun" ]
then
  echo "Already had a failed attempt. Won't run certboot any more. Please run certboot manually"
  if [ -n "${LETSENCRYPT_TEST_MODE}" ] && [ "${LETSENCRYPT_TEST_MODE}" == "yes" ]; then TF="--test-cert"; else TF=""; fi
  echo "    certbot --nginx --non-interactive --agree-tos --expand ${TF} --email ${LETSENCRYPT_ADMIN_EMAIL} -d ${DOMAIN_LIST}"
else
  touch "/firstrun"
  echo "Installing SSL certificate for ${WORDPRESS_ALL_SERVER_URLS} ${PHPMYADMIN_ALL_SERVER_URLS} ... "
  if [ -z "${LETSENCRYPT_ADMIN_EMAIL}" ]
  then
    echo "Failed to install letsencrypt certificates - LETSENCRYPT_ADMIN_EMAIL environemnt variable not set";
  elif [ -z "${WORDPRESS_ALL_SERVER_URLS}" ]
  then
    echo "Failed to install letsencrypt certificates - WORDPRESS_ALL_SERVER_URLS environemnt variable not set";
  elif [ -z "${PHPMYADMIN_ALL_SERVER_URLS}" ]
  then
    echo "Failed to install letsencrypt certificates - PHPMYADMIN_ALL_SERVER_URLS environemnt variable not set";
  else
    # Check and set TEST_MODE_FLAG
    TEST_FLAG=""
    if [ -n "${LETSENCRYPT_TEST_MODE}" ] && [ "${LETSENCRYPT_TEST_MODE}" == "yes" ]
    then
      # Install test certificate
      TEST_FLAG="--test-cert"
    fi
    # Install the certificate
    certbot --nginx --non-interactive --agree-tos --expand ${TEST_FLAG} --email "${LETSENCRYPT_ADMIN_EMAIL}" -d "${DOMAIN_LIST}"
    #
    # check if all certificates get installed
    NOT_INSTALLED_LIST=$(getDomainList)
    if [ -n "${NOT_INSTALLED_LIST}" ]
    then
      echo "Failed to installed Lets Encrypt certificate(s) for [${NOT_INSTALLED_LIST}]"
    else
      echo "Lets Encrypt TEST certificates for wordpress and phpmyadmin installed successfully"
    fi
  fi
fi


# check if all certificates get installed
echo "Scheduling cron job for certificate renewal ..."
if [ -f "/renewcertcron" ]
then
    echo "Cron job for cert renewal is already scheduled"
else
  echo "Cron job for cert renewal is not scheduled - No certificate installed."
  echo "Creating cron job for cert renewal"
  # Create a cron job file
  echo "Creating renew certificate cron job"
  crontab -l                                                         >   /renewcertcron
  echo "# The weekly cron task to renew lets encrypt certificates"   >>  /renewcertcron
  echo "0 0 * * * root certbot renew >> /var/log/certboot/renew.log" >>  /renewcertcron
  # Schedule the cron job
  crontab /renewcertcron
fi


# Shedule cron task
#/usr/sbin/crond -f -l 8

echo "Current crontab:"
crontab -l

exec "$@"