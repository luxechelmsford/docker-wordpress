#!/bin/bash




#################################################################################################################
#                                                                                                               #
# Description:  Get port number for the passed site, subsite and service type combination                       #
# Parameters:                                                                                                   #
#     Para-1:   Site Id:      A numeric value between 0 and 90                                                  #
#     Para-2:   Subsite Id:   A numeric value between 0 and 9                                                   #
# Parameters:                                                                                                   #
# Return:                                                                                                       #
#    Success:   All four orts seperated by pipe:   <httpPort>|<httpsPort>|<ftpCmdPort>|<ftpPsvPorts>            #
#    Error:     Error string strating with 'Error:'                                                             #
#                                                                                                               #
##################################################################################################################
getPorts() {

  local siteNo=$1
  if [ "${siteNo}" == "" ]; then
    echo "Error: No site id passed. Faled to assign a port"
    return
  elif ! [[ ${siteNo} =~ ^[0-9]+$ ]]; then
    echo "Error: Site id [${siteNo}]] passed is not numeric. Failed to assign a port"
    return
  elif [ "${siteNo}" -lt "0" ] || [ "${siteNo}" -gt "90" ]; then
    echo "Error: Site id [${siteNo}]] passed must be bwteen 0 and 90. Failed to assign a port"
    return
  fi
  
  local subsiteNo=$2
  if [ "${subsiteNo}" == "" ]; then
    echo "Error: No subsite id passed. Faled to assign a port"
    return
  elif ! [[ ${subsiteNo} =~ ^[0-9]+$ ]]; then
    echo "Error: Subsite id [${subsiteNo}]] passed is not numeric. Failed to assign a port"
    return
  elif [ "${subsiteNo}" -lt "0" ] || [ "${subsiteNo}" -gt "9" ]; then
    echo "Error: Subsite id [${subsiteNo}]] passed must be bwteen 0 and 9. Failed to assign a port"
    return
  fi

  # 20100 - 20999 assigned to HTTP
  local httpPort=$((20100+10*siteNo+subsiteNo))

  # 30100 - 30999 assigned to HTTPS
  local httpsPort=$((30100+10*siteNo+subsiteNo))

  # 40100 - 48990 assigned to FTP
  local ftpCmdPort=$((40100+10*siteNo+1000*subsiteNo))

  # 40100 - 48990 assigned to FTP
  local minPort=$((40100+10*siteNo+1000*(subsiteNo+1)))
  local maxPort=$((40100+10*siteNo+1000*(subsiteNo+1)+10))
  local ftpPsvPorts="${minPort}-${maxPort}"

  echo "${httpPort}|${httpsPort}|${ftpCmdPort}|${ftpPsvPorts}"
}
