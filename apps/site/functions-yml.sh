#!/bin/bash


#################################################################################################################
#                                                                                                               #
# Description:  Expands environment variablesin a file                                                          #
# Parameters:                                                                                                   #
#     Para-1:   Input File: The file in which the variables are to eb expanded                                  #
# Parameters:                                                                                                   #
# Return:       None. The expnaded file is written back in the input file                                       #
#                                                                                                               #
##################################################################################################################
apply_shell_expansion() {
    declare file="$1"
    declare data
    data=$(< "$file")
    declare delimiter="__apply_shell_expansion_delimiter__"
    declare command="cat <<$delimiter"$'\n'"$data"$'\n'"$delimiter"
    eval "$command"
}



#################################################################################################################
#                                                                                                               #
# Description:  Deletes a Yml file                                                                              #
# Parameters:                                                                                                   #
#     Para-1:   ymlPath:          The full path of the yml file to be deleted                                   #
# Return:       Deletes the ym file, if it exists                                                               #
#                                                                                                               #
##################################################################################################################
deleteYml() {
  local ymlFile=$1
  if [ -n "${ymlFile}" ] && [ -f "${ymlFile}" ]
  then
    rm -rf "${ymlFile}"
  fi
}



#################################################################################################################
#                                                                                                               #
# Description:  generate Yml                                                                                    #
# Parameters:                                                                                                   #
#     Para-1:   ymlFolder:        The path of the folder where the Yml files are to be generated                #
#     Para-2:   scriptFolder:     The path of the this script file.                                             #
#     Para-3:   Wesite name:      A name uniquely idetifyining the website e.g. demo, demo-test etc.            #
#     Para-6:   Main Web Url:     e.g. www.example.com, test.example.com                                        #
#     Para-7:   [Additional Url]: Optional, ypically the domian name, e.g. example.com                          #
# Return:       Generates the yml file with name 'docker-compose-<websiteName>.yml'                             #
#                                                                                                               #
##################################################################################################################
rebuildYml() {

  # Script path
  local ymlFolder=$1
  if [ -z "${ymlFolder}" ]; then
    echo "Failed to rebuild Yml. The yam folder must be specifcied"
    echo ""
    exit 1;
  fi

  # Script path
  local scriptFolder=$2
  if [ -z "${scriptFolder}" ]; then
    echo "Failed to rebuild Yml. The script folder must be specifcied"
    echo ""
    exit 1;
  fi

  # Website name
  local websiteName=$3
  if [ -z "${websiteName}" ]; then
    echo "Failed to rebuild Yml. Must specify a website name"
    echo ""
    exit 1;
  fi

#  # Site No
#  local siteNo=$4
#  if [ -z "${siteNo}" ]; then
#    echo "Failed to rebuild Yml. The site numer is not defined."
#    echo ""
#    exit 1;
#  fi
#
#  # Subsite No
#  local subsiteNo=$5
#  if [ -z "${subsiteNo}" ]; then
#    echo "Failed to rebuild Yml. The subsite numer is not defined."
#    echo ""
#    exit 1;
#  fi
#
#  # Website Url
#  local websiteUrl=$6
#  if [ -z "${websiteUrl}" ]; then
#    echo "Failed to rebuild Yml. The website url must be specified"
#    echo "Use [-h|--help] for detailed argument list"
#    echo ""
#    exit 1;
#  fi
#
#  # Additional Url
#  local additionalUrl=$7
#  # Reset the addiitonal url if its the same as websiteUrl
#  if [ "${websiteUrl}" == "${additionalUrl}" ]; then
#    additionalUrl=""
#  fi

  # Website Url
  local websiteUrl=$4
  if [ -z "${websiteUrl}" ]; then
    echo "Failed to rebuild Yml. The website url must be specified"
    echo "Use [-h|--help] for detailed argument list"
    echo ""
    exit 1;
  fi

  # Additional Url
  local additionalUrl=$5
  # Reset the addiitonal url if its the same as websiteUrl
  if [ "${websiteUrl}" == "${additionalUrl}" ]; then
    additionalUrl=""
  fi


#  ###########################################################################################################
#  # Reteieve and set various port variables                                                                 #
#  ###########################################################################################################
#
#  # Get all the ports
#  returnVal=$(getPorts "${siteNo}" "${subsiteNo}" )
#  if [ "${returnVal}" == "Error*" ]
#  then
#    echo "Failed to generate Yml. Error in assigning port number. "
#    echo "${returnVal}"
#    echo ""
#    exit 1;
#  fi
#  
#  # Split the port values into an array
#  local portArray=""
#  IFS='|' read -r -a portArray <<< "$returnVal"
#  if [ 4 != "${#portArray[@]}" ]
#  then
#    echo "Failed to generate Yml. Invalid port numbers assigned"
#    echo ""
#    exit 1;
#  fi
#
#  # Assign the port values to local variables
#  local httpPort="${portArray[0]}";
#  local httpsPort="${portArray[1]}";
#  local ftpcmdPort="${portArray[2]}";
#  local ftppsvPorts="${portArray[3]}";
  
  
  ###########################################################################################################
  # Prepare intermediatory variables .                                                                      #
  ###########################################################################################################

  # database name/ username is derived from website name replacing '-' with '_'
  local dbName=${websiteName//-/_}

  # Construcr wwordpress urls to be ued in the nginx server block
  local wordpressUrls="${websiteUrl}"
  if [ -n "${additionalUrl}" ]; then wordpressUrls="${wordpressUrls} ${additionalUrl}"; fi

  # Construct phpmyadmin and ftp urls to be used in the nginx server block
  # If the additional url is a substing of main url e.g. main url is www.example.com and additional url
  # is example.com our phpmyadmin/ftp url will be sql/ftp.example.com
  # else we will just prepand phymyadmin infront of the main url
  local phpMyadminUrls="sql.${websiteUrl}"
  local ftpServerUrl="ftp.${websiteUrl}"
  if [ -n "${additionalUrl}" ] && [ "${websiteUrl}" != "${additionalUrl}" ] && [[ ${websiteUrl} == *"${additionalUrl}"* ]]
  then
    phpMyadminUrls="sql.${additionalUrl}"
    ftpServerUrl="ftp.${additionalUrl}"
  fi


  ###########################################################################################################
  # Environment variables to be used in the YML template                                                    #
  ###########################################################################################################

  # Set common environment variables
  #
  # shellcheck disable=SC2034
  local WEBSITE_NAME="${websiteName}"
  
  # Set the mysql environment variables
  #
  # shellcheck disable=SC2034
  local MYSQL_PORT=3306
  # shellcheck disable=SC2034
  local MYSQL_HOST=mysql
  # shellcheck disable=SC2034
  local MYSQL_DATABASE=${dbName}
  # shellcheck disable=SC2034
  local MYSQL_USER=${dbName}
  # shellcheck disable=SC2034
  local WORDPRESS_TABLE_PREFIX="wp_"
  # shellcheck disable=SC2034
  local MYSQL_CNF_FILENAME="my.cnf"

  # Set the wordpress environment variables
  #
  # shellcheck disable=SC2034
  local WORDPRESS_ROOT_DIR="/var/www/html"
  # shellcheck disable=SC2034
  local WORDPRESS_MAIN_SERVER_URLS="${websiteUrl}"
  # shellcheck disable=SC2034
  local PHPMYADMIN_ROOT_DIR="/var/www/phpmyadmin"
  # shellcheck disable=SC2034
  local VSFTPD_USERNAME=${dbName}
#  # shellcheck disable=SC2034
#  local VSFTPD_CMD_PORT=${ftpcmdPort}
#  # shellcheck disable=SC2034
#  local VSFTPD_PSV_PORTS=${ftppsvPorts}
#  # shellcheck disable=SC2034
#  local VSFTPD_SERVER_URL="${ftpServerUrl}"  
  
  # Set the nginx environment variables
  #
  # shellcheck disable=SC2034
  local WORDPRESS_ALL_SERVER_URLS="${wordpressUrls}"
  # shellcheck disable=SC2034
  local PHPMYADMIN_ALL_SERVER_URLS="${phpMyadminUrls}"
#  # shellcheck disable=SC2034
#  local WEB_HTTP_PORT="${httpPort}"
#  # shellcheck disable=SC2034
#  local WEB_HTTPS_PORT="${httpsPort}"
#  # shellcheck disable=SC2034

  # Set the wpbackup environment variables
  #
  # shellcheck disable=SC2034
  local WPBACKUP_TIME=0
  # shellcheck disable=SC2034
  local WPBACKUP_ROOT_DIR="/var/backups/${websiteName}"

  # Set the webdrive environment variables
  #
  # shellcheck disable=SC2034
  local WEBDRIVE_ROOT_DIR="/mnt/webdrive/${websiteName}"
  # shellcheck disable=SC2034
  local WEBDRIVE_REMOTE_PATH="${websiteName}"


  ###########################################################################################################
  # Load all-site and this site specific environment variable files                                         #
  ###########################################################################################################
  
  if [ ! -f "${scriptFolder}/envs/default-env.sh" ] && [ ! -f "${scriptFolder}/envs/${websiteName}-env.sh" ]
  then
    echo "At least one of the following environment variable files must exists"
    echo "    [${scriptFolder}/envs/default-env.sh]"
    echo "    [${scriptFolder}/envs/${websiteName}-env.sh]"
    Exit 1;
  fi
  
  # First load the default environment variables
  if [ -f "${scriptFolder}/envs/default-env.sh" ]
  then
    # shellcheck disable=SC1091
    . "${scriptFolder}/envs/default-env.sh"
  fi

  # Finally if a site specific file exist, override the values
  if [ -f "${scriptFolder}/envs/${websiteName}-env.sh" ]
  then
    # shellcheck disable=SC1090
    . "${scriptFolder}/envs/${websiteName}-env.sh"
  fi

  ###########################################################################################################
  # Finally generate the template                                                                           #
  ###########################################################################################################
  
  # Now set the site and home url based on if we are going for ssl
  local webProtocol=""
  if [ "${LETSENCRYPT_MODE}" == "disabled" ]; then webProtocol="http"; else webProtocol="https"; fi;
  # shellcheck disable=SC2034
  local WORDPRESS_HOME="${webProtocol}://${websiteUrl}"
  # shellcheck disable=SC2034
  local WORDPRESS_SITEURL="${webProtocol}://${websiteUrl}"

  # Finally generate docker-compose file
  printf "%s\n" "$(apply_shell_expansion "${scriptFolder}/docker-compose-template.yml")" > "${ymlFolder}/docker-compose-${websiteName}.yml"
}




#################################################################################################################
#                                                                                                               #
# Description:  Rebuild Yml file for all sites in the data file                                                 #
# Parameters:                                                                                                   #
#     Para-1:   ymlFolder:        The path of the folder where the Yml files are to be generated                #
#     Para-2:   scriptFolder:     The path of the this script file.                                             #
#     Para-1:   dataFile:         The full or relative path of the site data file                               #
# Return:       Generates all yml file with name 'docker-compose-<websiteName>.yml'                             #
#                                                                                                               #
##################################################################################################################
rebuildYmls() { 

  # Yml path
  local ymlFolder=$1
  if [ -z "${ymlFolder}" ]; then
    echo "Failed to rebuild Yml files. The yml folder must be specifcied"
    echo ""
    exit 1;
  fi

  # Script path
  local scriptFolder=$2
  if [ -z "${scriptFolder}" ]; then
    echo "Failed to rebuild Yml files. The script folder must be specifcied"
    echo ""
    exit 1;
  fi

  local dataFile=$3
  if [ -z "${dataFile}" ]
  then
    echo "Failed to rebuild Yml files. The data file must be specifed.";
    echo ""
    exit 1;
  fi

  #rm -rf ${ROOT_DIR}/docker-compose-*.yml
  
  searchString="^.*\S.*"
  
  if [ -n "${websiteName}" ]; then
    LINE=$(grep "^${websiteName}|" "dataFile")
    if [ -z "${LINE}" ]; then
      echo "Failed to rebuild Yml files. The site [${websiteName}] does not exist"
      echo ""
      exit 1;
    fi
    searchString="^${websiteName}|"
  fi

  grep "${searchString}" "${dataFile}" | while read -r siteRecord ; do
    IFS='|' read -r -a siteFields <<< "$siteRecord"

#    if [ 5 != "${#siteFields[@]}" ]; then
#      echo "Failed to rebuild Yml files. Invalid site record [${siteRecord}]"
#      echo "Please fix the site record and try again"
#      echo ""
#      exit 1;
#    fi
#
#    # Get all the ports
#    returnVal=$(getPorts "${siteFields[1]}" "${siteFields[2]}" )
#    # Split the port values into an siteFields
#    local portArray=()
#    IFS='|' read -r -a portArray <<< "$returnVal"
#
#
#    echo "  Building ${siteFields[0]}: ${siteFields[1]}, ${siteFields[2]}, ${portArray[0]},  ${portArray[1]},  ${portArray[2]},  ${portArray[3]}, ${siteFields[3]}, ${siteFields[4]}"
#    rebuildYml "${ymlFolder}" "${scriptFolder}" "${siteFields[0]}" "${siteFields[1]}" "${siteFields[2]}" "${siteFields[3]}" "${siteFields[4]}"

    if [ 3 != "${#siteFields[@]}" ]; then
      echo "Failed to rebuild Yml files. Invalid site record [${siteRecord}]"
      echo "Please fix the site record and try again"
      echo ""
      exit 1;
    fi

    echo "  Building ${siteFields[0]}: ${siteFields[1]}, ${siteFields[2]}"
    rebuildYml "${ymlFolder}" "${scriptFolder}" "${siteFields[0]}" "${siteFields[1]}" "${siteFields[2]}"

  done  

  echo "All sites built successfully ..."
  echo ""
}
