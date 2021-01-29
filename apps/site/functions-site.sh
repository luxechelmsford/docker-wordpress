#!/bin/bash



# Full path of the current script
this=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null||echo "$0")
# The directory where current script resides
dir=$(dirname "${this}")
# 'Dot' means 'source', i.e. 'include':
# shellcheck disable=SC1091
. "${dir}/functions-port.sh"
# shellcheck disable=SC1091
. "${dir}/functions-yml.sh"




##################################################################################################################
##                                                                                                               #
## Description:  Generate a new site and sub site number, if the site does not exists in thedata file            #
## Parameters:                                                                                                   #
##     Para-1:   dataFile:         The full or relative path of the site data file                               #
##     Para-2:   wesiteName:       A name uniquely idetifyining the website e.g. demo, demo-test etc.            #
## Return:                                                                                                       #
##    Success:   The site and subsite number, seperated by a colon                                               #
##    Error:     Error string strating with 'Error:'                                                             #
##                                                                                                               #
###################################################################################################################
#generateSiteNumber() {
#
#  local dataFile=$1
#  if [ -z "${dataFile}" ]
#  then
#    echo "Error: Failed to generate a site number: Must specify a data file.";
#    return;
#  fi
#
#  local websiteName=$2
#  if [ -z "${websiteName}" ]
#  then
#    echo "Error: Failed to generate a site number: Must specify a website name.";
#    return;
#  fi
#
#  # Split the site and subsite name which are sperated by a dash
#  # e.g. demo-live demo-test etc.
#  local site=${websiteName%-*};
#  local subsite=""
#  if [[ ${websiteName} == *"-"* ]]; then
#    subsite=${websiteName#*-}
#  fi
#  
#  local siteNo=""; local subsiteNo="";
#  # check if the file exists
#  if [ ! -f "${dataFile}" ]
#  then
#    if [ "${site}" == "demo" ]
#    then
#      siteNo=0 # Demo site has been given site id 0
#    else
#      siteNo=1 # This is the first sidte we are adding
#    fi
#    if [ -z "${subsite}" ]
#    then
#      subsiteNo=0 # This is the main site
#    else
#      subsiteNo=1 # This is the first subsite
#    fi
#    echo "${siteNo}:${subsiteNo}"
#    return;
#  fi
#
#  # check if the site is already added
#  if grep -q "^${websiteName}|" "${dataFile}"
#  then
#    echo "Error: Failed to generatea site number: Site already exists";
#    return;
#  fi
#
#  # Now locate the main site record
#  local siteRecord=""
#  siteRecord=$(grep -m 1 "^${site}|*" "${dataFile}")
#  if [ -z "${siteRecord}" ]; then
#    # Th main site does ot exist, locate the first subsite record
#    siteRecord=$(grep -m 1 "^${site}-*|*" "${dataFile}")
#  fi
#  
#  # Have we found a site/subsite record
#  if [ -n "${siteRecord}" ]
#  then
#    # Set site no
#    local siteData="${siteRecord#*|}" # Strip the wensite name from the record
#    siteNo="${siteData%%|*}"        # Now get the site number
#    # Now find the subsite number
#    if [ -z "${subsite}" ]; then    # If this is the main site
#      subsiteNo=0                   # This is the main site
#    else
#      # Find the max subsite number for this site
#      maxSubsiteNo=0
#      while IFS= read -r siteRecord; do
#        if [[ $siteRecord == "${site}-"* ]]; then
#          local siteData="${siteRecord#*|*|}"
#          if [ "${siteData%%|*}" -gt "$maxSubsiteNo" ];
#          then
#            maxSubsiteNo="${siteData%%|*}"
#          fi
#        fi
#      done < "${dataFile}"
#      subsiteNo=$((maxSubsiteNo+1))
#    fi
#    echo "${siteNo}:${subsiteNo}"
#    return
#  fi
#  
#  
#  # Reached here means we didn;t find a site/subsite record
#  #
#  if [ "${site}" == "demo" ]
#  then
#    siteNo=0                      # Demo sie is always zero
#  else
#    # Set the site number based on max site number found
#    maxSiteNo=0
#    while IFS= read -r siteRecord
#    do
#      local siteData="${siteRecord#*|}"
#      if [ "${siteData%%|*}" -gt "$maxSiteNo" ];
#      then
#        maxSiteNo="${siteData%%|*}"      
#      fi
#    done < "${dataFile}"
#    siteNo=$((maxSiteNo+1))
#  fi
#  
#  if [ -z "${subsite}" ]; then
#    subsiteNo=0    # This is the main site
#  else
#    subsiteNo=2    # This is the first subsite
#  fi
#  
#  echo "${siteNo}:${subsiteNo}"
#  return
#}



#################################################################################################################
#                                                                                                               #
# Description:  Add a site record to the passed data file, Return error if the site already exists              #
# Parameters:                                                                                                   #
#     Para-1:   ymlFolder:        The path of the folder where the Yml files are to be generated                #
#     Para-2:   scriptFolder:     The path of the this script file.                                             #
#     Para-3:   dataFile:         The full or relative path of the site data file                               #
#     Para-4:   wesiteName:       A name uniquely idetifyining the website e.g. demo, demo-test etc.            #
#     Para-5:   wesiteUrl:        The main url to served by the webserver e.g. www.example.com                  #
#     Para-6:   [additionalUrl]:  Optional. An additional url, which will be redireceted to the main url        #
#                                           This is typically the domian name e.g. example.com                  #
# Return:                                                                                                       #
# .  Success:   The site ias added and the site and subsite number, seperated by a colon returned               #
# .  Error:     Error string'                                                                                   #
#                                                                                                               #
##################################################################################################################
addSiteRecord() {

  # Yml path
  local ymlFolder=$1
  if [ -z "${ymlFolder}" ]; then
    echo "Failed to add the site record for [${websiteName}]. The yml folder must be specifcied"
    echo ""
    exit 1;
  fi

  # Script path
  local scriptFolder=$2
  if [ -z "${scriptFolder}" ]; then
    echo "Failed to add the site record for [${websiteName}]. The script folder must be specifcied"
    echo ""
    exit 1;
  fi

  local dataFile=$3
  if [ -z "${dataFile}" ]
  then
    echo "Failed to add the site record for [${websiteName}]. Must specify a data file.";
    echo ""
    exit 1;
  fi

  local websiteName=$4
  if [ -z "${websiteName}" ]
  then
    echo "Failed to add the site record for [${websiteName}]. Must specify a website name.";
    echo ""
    exit 1;
  fi

  local websiteUrl=$5
  if [ -z "${websiteUrl}" ]
  then
    echo "Failed to add the site record for [${websiteName}]Must specify a website url.";
    echo ""
    exit 1;
  fi

  local additionalUrl=$6
  if [ -z "${additionalUrl}" ]
  then
    additionalUrl="${websiteUrl}"
  fi

  # First check if this record was not added before
  if [ -f "${dataFile}" ]
  then
    # check if the site is already added
    if grep -q "^${websiteName}|" "${dataFile}";
    then
      echo "Failed to add the site record for [${websiteName}]. Site record already exists.";
      echo ""
      exit 1;
    fi
  fi

#  # Now generate the numbers
#  local returnVal
#  returnVal=$(generateSiteNumber "${dataFile}" "${websiteName}")
#  if [ "${returnVal}" == "Error*" ]
#  then
#    echo "Failed to add the site record for [${websiteName}]. Error in generating site number.";
#    echo ""
#    exit 1;
#  fi
#  
#  # Split site and subsite
#  siteNo="${returnVal%:*}"
#  subsiteNo="${returnVal#*:}"
#  
#  # Get all the ports
#  returnVal=$(getPorts "${siteNo}" "${subsiteNo}" )
#  if [ "${returnVal}" == "Error*" ]
#  then
#    echo "Failed to add the site record for [${websiteName}]. Error in assigning port number.";
#    echo ""
#    exit 1;
#  fi
#  
#  # Split the port values into an siteFields
#  local portArray=()
#  IFS='|' read -r -a portArray <<< "$returnVal"
#  if [ 4 != "${#portArray[@]}" ]; then
#    echo "Failed to add the site record for [${websiteName}]. Invalid port number asisgned.";
#    echo ""
#    exit 1;
#  fi
#
#  # Assign the port values to local variables
#  local httpPort="${portArray[0]}";
#  local httpsPort="${portArray[1]}";
#  local ftpCmdPort="${portArray[2]}";
#  local ftpPsvPorts="${portArray[3]}";
#  
#  # Add a new line, if the file does not end with it
#  if [ -n "$(tail -c 1 "${dataFile}")" ]; then echo "" >> "${dataFile}"; fi
#  echo "${websiteName}|${siteNo}|${subsiteNo}|${websiteUrl}|${additionalUrl:-websiteUrl}" >>"${dataFile}"
#
#  rebuildYml "${ymlFolder}" "${scriptFolder}" "${websiteName}" "${siteNo}" "${subsiteNo}" "${websiteUrl}" "${additionalUrl}"
#
#  echo "Site [${websiteName}] with Values:"
#  echo "    Site No:                ${siteNo}"
#  echo "    Subsite No:             ${subsiteNo}"
#  echo "    HTTP Port:              ${httpPort}"
#  echo "    HTTPS Port:             ${httpsPort}"
#  echo "    FTP Command Port:       ${ftpCmdPort}"
#  echo "    FTP Passive} Ports:     ${ftpPsvPorts}"
#  echo "    Main Server URL:        ${websiteUrl}"
#  echo "    Additional Server URL:  ${additionalUrl}"
#  echo "  added successfully ..."
#  echo ""
  
  # Add a new line, if the file does not end with it
  if [ -n "$(tail -c 1 "${dataFile}")" ]; then echo "" >> "${dataFile}"; fi
  echo "${websiteName}|${websiteUrl}|${additionalUrl:-websiteUrl}" >>"${dataFile}"

  rebuildYml "${ymlFolder}" "${scriptFolder}" "${websiteName}" "${websiteUrl}" "${additionalUrl}"

  echo "Site [${websiteName}] with Values:"
  echo "    Main Server URL:        ${websiteUrl}"
  echo "    Additional Server URL:  ${additionalUrl}"
  echo "  added successfully ..."
  echo ""

  return;
}



#################################################################################################################
#                                                                                                               #
# Description:  Edit the site record from the passed data file, Return error if the edit operation fails        #
# Parameters:                                                                                                   #
#     Para-1:   ymlFolder:                The path of the folder where the Yml files are to be generated        #
#     Para-2:   scriptFolder:             The path of the this script file.                                     #
#     Para-3:   dataFile:                 The full or relative path of the site data file                       #
#     Para-4:   wesiteName:               The unique name uniquely record to be editedeg. demo, demo-test etc.  #
#     Para-5:   wesiteUrl|additionalUrl:  The main and additional url to be edited, speperated by a pipe        #
#                                         On of the parametrer can be blanked but not both .                    #
# Return:                                                                                                       #
# .  Success:   The site is edited with the passed values .                                                     #
# .  Error:     Error string strating with 'Error:'                                                             #
#                                                                                                               #
##################################################################################################################
editSiteRecord() {

  # Yml path
  local ymlFolder=$1
  if [ -z "${ymlFolder}" ]; then
    echo "Failed to edit the site record for [${websiteName}]. The yml folder must be specifcied"
    echo ""
    exit 1;
  fi

  # Script path
  local scriptFolder=$2
  if [ -z "${scriptFolder}" ]; then
    echo "Failed to edit the site record for [${websiteName}]. The script folder must be specifcied"
    echo ""
    exit 1;
  fi

  local dataFile=$3
  if [ -z "${dataFile}" ]
  then
    echo "Failed to edit the site record for [${websiteName}]. Must specify a data file.";
    echo ""
    exit 1;
  fi

  local websiteName=$4
  if [ -z "${websiteName}" ]
  then
    echo "Failed to edit the site record for [${websiteName}]. A website name must be specifcy using <-n|--name=websiteName>"
    echo "Use [-h|--help] for detailed argument list"
    echo ""
    exit 1;
  fi
  
  # check if the file exists
  if [ ! -f "${dataFile}" ]
  then
    echo "Failed to edit the site record for [${websiteName}]. data file [${dataFile}] does not exist."
    echo ""
    exit 1;
  fi

  # Check if the sile exists
  local line
  line=$(grep -n "^${websiteName}|" "${dataFile}")
  if [ -z "${line}" ]; then
    echo "Failed to edit the site record for [${websiteName}]. The site [${websiteName}] does not exist"
    echo ""
    exit 1;
  fi

  local urls=$5
  local websiteUrl="${urls%|*}"
  local additionalUrl="${urls#*|}"
  if [ -z "${websiteUrl}" ] && [ -z "${additionalUrl}" ]; then
    echo "Failed to edit the site record for [${websiteName}]."
    echo "Atleast one of the followings must be specfied to edit a website configuration"
    echo "  [-w|--web-url=url] ......... The main website url, people will browse to"
    echo "  [-u|--add-url=url] ......... Any additional url, redireted to main url"
    echo "Use [-h|--help] for detailed argument list"
    echo ""
    exit 1;
  fi

  # Spit the line between line no and values
  lineNo=${line%%:*}
  siteRecord=${line#*:}

#  # Split the values int an siteFields
#  IFS='|' read -r -a siteFields <<< "$siteRecord"
#  if [ 5 != "${#siteFields[@]}" ]; then
#    echo "Failed to edit the site record for [${websiteName}]. Invalid site record [${siteRecord}]"
#    echo "Please fic the record and then try to add the site again"
#    echo ""
#    exit 1;
#  fi
#    
#  # Set the splitted fileds into the appropriate variables
#  local siteNo="${siteFields[1]}"
#  local subsiteNo="${siteFields[2]}"
#  if [ -z "$websiteUrl" ]; then websiteUrl=${siteFields[3]}; fi
#  if [ -z "$additionalUrl" ]; then additionalUrl=${siteFields[4]}; fi
#  if [ -z "$websiteUrl" ]; then websiteUrl=${siteFields[3]}; fi
#  if [ -z "$additionalUrl" ]; then additionalUrl=${siteFields[4]}; fi
#  
#  # Reset the addiitonal url if its the same as websiteUrl
#  if [ "${websiteUrl}" == "${additionalUrl}" ]; then
#    additionalUrl=""
#  fi
#    
#  # Get all the ports
#  returnVal=$(getPorts "${siteNo}" "${subsiteNo}" )
#  if [ "${returnVal}" == "Error*" ]
#  then
#    echo "Failed to edit the site record for [${websiteName}]. Error in assigning port number.";
#    echo ""
#    exit 1;
#  fi
#  
#  # Split the port values into an siteFields
#  local portArray=()
#  IFS='|' read -r -a portArray <<< "$returnVal"
#  if [ 4 != "${#portArray[@]}" ]; then
#    echo "Failed to edit the site record for [${websiteName}]. Invalid port number asisgned.";
#    echo ""
#    exit 1;
#  fi
#
#  # Assign the port values to local variables
#  local httpPort="${portArray[0]}";
#  local httpsPort="${portArray[1]}";
#  local ftpCmdPort="${portArray[2]}";
#  local ftpPsvPorts="${portArray[3]}";
#  
#  # Escape the Sed Char in the new line and replace it
#  newSiteRecord="${websiteName}|${siteNo}|${subsiteNo}|${websiteUrl}|${additionalUrl:-${websiteUrl}}"
#  escapedNewSiteRecord=$(printf '%s\n' "${newSiteRecord}" | sed -e 's/[\/&]/\\&/g')
#  sed "${lineNo}s/.*/${escapedNewSiteRecord}/" "${dataFile}" > "${dataFile}.tmp" && mv "${dataFile}.tmp" "${dataFile}"
#  
#  rebuildYml "${ymlFolder}" "${scriptFolder}" "${websiteName}" "${siteNo}" "${subsiteNo}" "${websiteUrl}" "${additionalUrl}"
#
#  echo "Site [${websiteName}] with Values:"
#  echo "    Site No:                ${siteNo}"
#  echo "    Subsite No:             ${subsiteNo}"
#  echo "    HTTP Port:              ${httpPort}"
#  echo "    HTTPS Port:             ${httpsPort}"
#  echo "    FTP Command Port:       ${ftpCmdPort}"
#  echo "    FTP Passive} Ports:     ${ftpPsvPorts}"
#  echo "    Main Server URL:        ${websiteUrl}"
#  echo "    Additional Server URL:  ${additionalUrl}"
#  echo "  edited successfully ..."
#  echo ""

  # Split the values int an siteFields
  IFS='|' read -r -a siteFields <<< "$siteRecord"
  if [ 3 != "${#siteFields[@]}" ]; then
    echo "Failed to edit the site record for [${websiteName}]. Invalid site record [${siteRecord}]"
    echo "Please fic the record and then try to add the site again"
    echo ""
    exit 1;
  fi

  # Set the splitted fileds into the appropriate variables
  if [ -z "$websiteUrl" ]; then websiteUrl=${siteFields[1]}; fi
  if [ -z "$additionalUrl" ]; then additionalUrl=${siteFields[2]}; fi
  
  # Reset the addiitonal url if its the same as websiteUrl
  if [ "${websiteUrl}" == "${additionalUrl}" ]; then
    additionalUrl=""
  fi
  
  # Escape the Sed Char in the new line and replace it
  newSiteRecord="${websiteName}|${websiteUrl}|${additionalUrl:-${websiteUrl}}"
  escapedNewSiteRecord=$(printf '%s\n' "${newSiteRecord}" | sed -e 's/[\/&]/\\&/g')
  sed "${lineNo}s/.*/${escapedNewSiteRecord}/" "${dataFile}" > "${dataFile}.tmp" && mv "${dataFile}.tmp" "${dataFile}"
  	
  rebuildYml "${ymlFolder}" "${scriptFolder}" "${websiteName}" "${websiteUrl}" "${additionalUrl}"

  echo "Site [${websiteName}] with Values:"
  echo "    Main Server URL:        ${websiteUrl}"
  echo "    Additional Server URL:  ${additionalUrl}"
  echo "  edited successfully ..."
  echo ""
  
  return;
}



#################################################################################################################
#                                                                                                               #
# Description:  View site records from the passed data file, Return error if the view operation fails           #
# Parameters:                                                                                                   #
#     Para-1:   ymlFolder:        The path of the folder where the Yml files are to be generated                #
#     Para-2:   scriptFolder:     The path of the this script file.                                             #
#     Para-3:   dataFile:         The full or relative path of the site data file                               #
#     Para-4:   [wesiteName]:     Optional. If none passed all records are dislayed                             #
# Return:                                                                                                       #
# .  Success:   The site records are displayed                                                                  #
# .  Error:     Error string strating with 'Error:'                                                             #
#                                                                                                               #
##################################################################################################################
viewSiteRecord() {

  # Yml path
  local ymlFolder=$1
  if [ -z "${ymlFolder}" ]; then
    echo "Failed to view the site record(s) for [${websiteName}]. The yml folder must be specifcied.";
    echo ""
    exit 1;
  fi

  # Script path
  local scriptFolder=$2
  if [ -z "${scriptFolder}" ]; then
    echo "Failed to view the site record(s) for [${websiteName}]. The script folder must be specifcied"
    echo ""
    exit 1;
  fi

  local dataFile=$3
  if [ -z "${dataFile}" ]
  then
    echo "Failed to view the site record(s) for [${websiteName}]. Must specify a data file.";
    echo ""
    exit 1;
  fi

  local websiteName=$4
  local searchString="^"
  if [ -n "${websiteName}" ]
  then
    siteRecord=$(grep "^${websiteName}|" "${dataFile}")
    if [ -z "${siteRecord}" ]; then
      echo "Failed to view the site record(s) for [${websiteName}]. The site [${websiteName}] does not exist"
      echo ""
      exit 1;
    fi
    searchString="^${websiteName}|"
  fi
  
#  colHeading1="SITE NAME     "
#  colHeading2="HTTP PORT "
#  colHeading3="HTTPS PORT "
#  colHeading4="FTP CMD PORT "
#  colHeading5="FTP PSV PORTS "
#  colHeading6="WEBSITE URL              "
#  colHeading7="ADDITIONAL URL "
#  echo ""
#  echo " ${colHeading1}| ${colHeading2}| ${colHeading3}| ${colHeading4}| ${colHeading5}| ${colHeading6}| ${colHeading7}"
#  echo "------------------------------------------------------------------------------------------------------------------------------"
#  grep "${searchString}" "${dataFile}" | while read -r siteRecord ; do
#    IFS='|' read -r -a siteFields <<< "${siteRecord}"
#    # Get all the ports
#    returnVal=$(getPorts "${siteFields[1]}" "${siteFields[2]}" )
#    # Split the port values into an siteFields
#    local portArray=()
#    IFS='|' read -r -a portArray <<< "$returnVal"
#  
#    # Reset the addiitonal url if its the same as websiteUrl
#    if [ "${siteFields[3]}" == "${siteFields[4]}" ]; then
#      siteFields[4]=""
#    fi
#
#    printf " %-${#colHeading1}s| %-${#colHeading2}s| %-${#colHeading3}s| %-${#colHeading4}s| %-${#colHeading5}s| %-${#colHeading6}s| %s\n" "${siteFields[0]}" "${portArray[0]}" "${portArray[1]}" "${portArray[2]}" "${portArray[3]}" "${siteFields[3]}" "${siteFields[4]}"
#  done  
#  echo "------------------------------------------------------------------------------------------------------------------------------"
#  echo ""

  colHeading1="SITE NAME     "
  colHeading2="WEBSITE URL              "
  colHeading3="ADDITIONAL URL "
  echo ""
  echo " ${colHeading1}| ${colHeading2}| ${colHeading3}"
  echo "------------------------------------------------------------------------------------------------------------------------------"
  grep "${searchString}" "${dataFile}" | while read -r siteRecord ; do
    IFS='|' read -r -a siteFields <<< "${siteRecord}"
  
    # Reset the addiitonal url if its the same as websiteUrl
    if [ "${siteFields[1]}" == "${siteFields[2]}" ]; then
      siteFields[2]=""
    fi

    printf " %-${#colHeading1}s| %-${#colHeading2}s| %s\n" "${siteFields[0]}" "${siteFields[1]}" "${siteFields[2]}"
  done  
  echo "------------------------------------------------------------------------------------------------------------------------------"
  echo ""
}





#################################################################################################################
#                                                                                                               #
# Description:  Delete site records from the passed data file, Return error if the view operation fails         #
# Parameters:                                                                                                   #
#     Para-1:   ymlFolder:        The path of the folder where the Yml files are to be generated                #
#     Para-2:   scriptFolder:     The path of the this script file.                                             #
#     Para-1:   dataFile:         The full or relative path of the site data file                               #
#     Para-2:   wesiteName:       The website name whose record is to be deleted .                              #
# Return:                                                                                                       #
# .  Success:   The site records are displayed                                                                  #
# .  Error:     Error string strating with 'Error:'                                                             #
#                                                                                                               #
##################################################################################################################
delSiteRecord() {

  echo "Deleting site [${websiteName}] ..."

  # Yml path
  local ymlFolder=$1
  if [ -z "${ymlFolder}" ]; then
    echo "Failed to delete the site record for [${websiteName}]. The yml folder must be specifcied"
    echo ""
    exit 1;
  fi

  # Script path
  local scriptFolder=$2
  if [ -z "${scriptFolder}" ]; then
    echo "Failed to delete the site record for [${websiteName}]. The script folder must be specifcied"
    echo ""
    exit 1;
  fi

  local dataFile=$3
  if [ -z "${dataFile}" ]
  then
    echo "Failed to delete the site record for [${websiteName}]. Must specify a data file.";
    echo ""
    exit 1;
  fi

  local websiteName=$4
  if [ -z "${websiteName}" ]
  then
    echo "Failed to delete the site record."
    echo "A website name must be specifcy using <-n|--name=websiteName>"
    echo "Use [-h|--help] for detailed argument list"
    echo ""
    exit 1;
  fi
  
  # If the site does not exist
  line=$(grep -n "^${websiteName}|" "${dataFile}")
  if [ -z "${line}" ]; then
    echo "Failed to delete the site record for [${websiteName}]. It does not exist"
    echo ""
    exit 1;
  fi

  # Spit the line between line no and site record
  lineNo=${line%%:*}
  siteRecord=${line#*:}

  # Split the values int an siteFields
  IFS='|' read -r -a siteFields <<< "$siteRecord"
  
#  # Get all the ports
#  returnVal=$(getPorts "${siteFields[1]}" "${siteFields[2]}" )
#  # Split the port values into an siteFields
#  local portArray=()
#  IFS='|' read -r -a portArray <<< "$returnVal"
#  
#  # delete the line in the file
#  sed "${lineNo}d" "${dataFile}" > "${dataFile}.tmp" && mv "${dataFile}.tmp" "${dataFile}" 
#  deleteYml "${ymlFolder}/docker-compose-${websiteName}.yml"
#
#  # Reset the addiitonal url if its the same as websiteUrl
#  if [ "${siteFields[3]}" == "${siteFields[4]}" ]; then
#    siteFields[4]=""
#  fi
# 
#  echo "Site [${websiteName}] with values:"
#  echo "    Site No:                ${siteFields[1]}"
#  echo "    Subsite No:             ${siteFields[2]}"
#  echo "    HTTP Port:              ${portArray[0]}"
#  echo "    HTTPS Port:             ${portArray[1]}"
#  echo "    FTP Command Port:       ${portArray[2]}"
#  echo "    FTP Passive} Ports:     ${portArray[3]}"
#  echo "    Main Server URL:        ${siteFields[3]}"
#  echo "    Additional Server URL:  ${siteFields[4]}"
#  echo "  deleted successfully ..."
#  echo ""
  
  # delete the line in the file
  sed "${lineNo}d" "${dataFile}" > "${dataFile}.tmp" && mv "${dataFile}.tmp" "${dataFile}" 
  deleteYml "${ymlFolder}/docker-compose-${websiteName}.yml"

  # Reset the addiitonal url if its the same as websiteUrl
  if [ "${siteFields[1]}" == "${siteFields[2]}" ]; then
    siteFields[2]=""
  fi
 
  echo "Site [${websiteName}] with values:"
  echo "    Main Server URL:        ${siteFields[1]}"
  echo "    Additional Server URL:  ${siteFields[2]}"
  echo "  deleted successfully ..."
  echo ""
}
