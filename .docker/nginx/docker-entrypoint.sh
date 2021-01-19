#!/bin/bash
set -eu



#########################################################################################
#                                                                                       #
# Get the list of the domians that do not have a letsencrypt certificates installed     #
#                                                                                       #
# Parameters                                                                            #
#   None                                                                                #
#                                                                                       # 
# Retun Values:                                                                         #
#   If all domains have certificate installed then a black string is returned           #
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

  if [ -n "${NEW_DOMAINS_FOUND}" ]
  then
    echo "${DOMAIN_LIST}"
  else
    echo ""
  fi
}

#########################################################################################



echo "****************************************************************"
echo "[$(date +"%Y-%m-%d-%H%M%S")] Entered nginx entrypoint script ..."


if [ -z "${LETSENCRYPT_ADMIN_EMAIL}" ];    then echo "Error: LETSENCRYPT_ADMIN_EMAIL not set";    echo "Finished: FAILURE"; exit 1; fi
if [ -z "${LETSENCRYPT_MODE}" ];           then echo "Error: LETSENCRYPT_MODE not set";           echo "Finished: FAILURE"; exit 1; fi
if [ -z "${LETSENCRYPT_LOG_DIR}" ];        then echo "Error: LETSENCRYPT_LOG_DIR not set";        echo "Finished: FAILURE"; exit 1; fi
if [ -z "${NGINX_LOG_DIR}" ];              then echo "Error: NGINX_LOG_DIR not set";              echo "Finished: FAILURE"; exit 1; fi
if [ -z "${WORDPRESS_ALL_SERVER_URLS}" ];  then echo "Error: WORDPRESS_ALL_SERVER_URLS not set";  echo "Finished: FAILURE"; exit 1; fi
if [ -z "${PHPMYADMIN_ALL_SERVER_URLS}" ]; then echo "Error: PHPMYADMIN_ALL_SERVER_URLS not set"; echo "Finished: FAILURE"; exit 1; fi

mkdir -p "${LETSENCRYPT_LOG_DIR}"
mkdir -p "${NGINX_LOG_DIR}"



# Copy wordpress.conf
if [ ! -f "/etc/nginx/conf.d/wordpress.conf" ]
then
  echo "Copying the wordpress conf file [wordpress.conf] ..."
  # Do not replace the single quote below '${WORDPRESS_ALL_SERVER_URLS}'
  # Otherwise the envsubst does not expand the variables
  envsubst '${WORDPRESS_ALL_SERVER_URLS}' < /etc/nginx/templates/wordpress.conf.template > /etc/nginx/conf.d/wordpress.conf
  if [ -f "/etc/nginx/conf.d/wordpress.conf" ]
  then
    echo "The wordpress conf file [wordpress.conf] copied successfully."
  else
    echo "Failed to copy wordpress conf file [wordpress.conf]."
  fi
fi


# Copy phpmyadmin.conf
if [ ! -f "/etc/nginx/conf.d/phpmyadmin.conf" ]
then
  echo "Copying the phpmyadmin conf file [phpmyadmin.conf] ..."
  # Do not replace the single quote below '${WORDPRESS_ALL_SERVER_URLS}'
  # Otherwise the envsubst does not expand the variables
  envsubst '${PHPMYADMIN_ALL_SERVER_URLS}' < /etc/nginx/templates/phpmyadmin.conf.template > /etc/nginx/conf.d/phpmyadmin.conf
  if [ -f "/etc/nginx/conf.d/phpmyadmin.conf" ]
  then
    echo "The phpmyadmin conf file [phpmyadmin.conf] copied successfully."
  else
    echo "Failed to copy phpmyadmin conf file [phpmyadmin.conf]."
  fi
fi



# Check if there are domians to be added
# If atleast one domain is to be added,
#   getDomains() returns the comma seperated list of all the domains
DOMAIN_LIST=$(getDomainList)
if [ "${LETSENCRYPT_MODE}" == "disabled" ]
then
  echo "SSL certificate installation is skipped as the LETSENCRYPT_MODE is set to [${LETSENCRYPT_MODE}]"
  echo "To enable SSL certificate, set the LETSENCRYPT_MODE env var in Nginx service block to staging or live"
elif [ -z "${DOMAIN_LIST}" ]
then
  echo "SSL certificates already exist for wordpress and phpmyadmin"
elif [ -f "/etc/nginx/conf.d/default.conf" ]
then
  echo "Already had a failed attempt. Won't run certboot any more. Please run certboot manually"
  if [ "${LETSENCRYPT_MODE}" == "staging" ]; then TMF="--test-cert"; else TMF=""; fi
  echo "    certbot --nginx --non-interactive --agree-tos --expand ${TMF} --email ${LETSENCRYPT_ADMIN_EMAIL} -d ${DOMAIN_LIST}"
else
  echo "Installing SSL certificate for ${WORDPRESS_ALL_SERVER_URLS} ${PHPMYADMIN_ALL_SERVER_URLS} ... "
  # Check and set TEST_MODE_FLAG (TMF)
  if [ "${LETSENCRYPT_MODE}" == "staging" ]; then TMF="--test-cert"; else TMF=""; fi
  # Build the cerboot command line options and parameters and install certificates
  #certbot --nginx --non-interactive --agree-tos --expand ${TMF} --email "${LETSENCRYPT_ADMIN_EMAIL}" -d "${DOMAIN_LIST}"
  # check if all certificates get installed
  #NOT_INSTALLED_LIST=$(getDomainList)
  #if [ -z "${NOT_INSTALLED_LIST}" ]
  CERBOOT_PARAMS="--nginx --non-interactive --agree-tos --expand ${TMF} --email ${LETSENCRYPT_ADMIN_EMAIL} -d ${DOMAIN_LIST}" 
  if cetboot "${CERBOOT_PARAMS}"
  then
    echo "Lets Encrypt TEST certificates for wordpress and phpmyadmin installed successfully"
      
    # Create a log directory, if not there
    if [ -z "${LETSENCRYPT_LOG_DIR}" ]; then LETSENCRYPT_LOG_DIR="/var/log/letsencrypt"; fi
    mkdir -p "${LETSENCRYPT_LOG_DIR}"
      
    # Now schedule a cron job for renewal of certificates
    echo "Creating cron job for cert renewal"
    crontab -l;                                                         \
    echo "# The weekly cron task to renew lets encrypt certificates";   \
    echo "0 0 * * * root certbot renew >> ${LETSENCRYPT_LOG_DIR}/renew.log"  >  /etc/renewcert-cron
    # Schedule the cron job
    crontab /etc/renewcert-cron
  else
    echo "Failed to installed Lets Encrypt certificate(s) for [${NOT_INSTALLED_LIST}]"
    echo "please install it manullay by running the following commnad"
    echo "    cetboot ${CERBOOT_PARAMS}"
  fi
  #
  # Lets delete the default.conf, so we dont run this clode any further
  # And risk reaching the LetsEnrypt's limits
  # If we failed, we will have to add certificates tbis manually
  echo "Deleting the default conf files [default.conf] ..."
  if rm -f /etc/nginx/conf.d/default.conf
  #if [ ! -f "/etc/nginx/conf.d/default.conf" ]
  then
    echo "The default conf files [default.conf] deleted successfully"
  else
    echo "Failed to delete default conf files [default.conf] from the conf.d folder"
  fi
fi

echo "Current crontab:"
crontab -l

exec "$@"


echo "[$(date +"%Y-%m-%d-%H%M%S")] Exiting nginx entrypoint script ..."
echo "*******************************************************************"