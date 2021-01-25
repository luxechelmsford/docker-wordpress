#!/bin/bash

# Full path of the current script
this=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null||echo "$0")
# The directory where current script resides
dir=$(dirname "${this}")
# 'Dot' means 'source', i.e. 'include':
# shellcheck disable=SC1091
. "${dir}/functions-site.sh"


#################################################################################################################
#                                                                                                               #
# Description:  Displays help                                                                                   #
# Parameters:   None                                                                                            #
# Return:       None                                                                                            #
#                                                                                                               #
##################################################################################################################
help() {
  cat << EOF
Managing website(s) interface
  Usage: site [options]
    [-a|add] ....................   Add the configuration of a new website 
      <-n|--name=websiteName>         The secific website whose configration is to be added.
      <-w|--web-url=url>              The web url e.g. www.example.com.
                                      The wordpress site var is set to this
                                      So any other urls are eventually redireded to this uRL 
      [-u|--add-url=url]               The additional url, e.g. example.com
    [-e|--edit] .................   Edit the configuration of an existing website
      <-n|--name=websiteName>         The secific website whose configration is to be added.
      [-w|--web-url=url]              The web url e.g. www.example.com.
                                      The wordpress site var is set to this
                                      So any other urls are eventually redireded to this uRL 
      [-u|--add-url=url]              The additional url, e.g. example.com
    [-v|--view] .................   View all site details ot the specified one
      [-n|--name=websiteName]         The name of the site to be viewed. -n= will list all sites
    [-d|--del] ..................   Delete the specified site detials
      <-n|--name=websiteName>         The name of the site to be deleted
    [-b|--build] ..............     Rebuild all site yamls - should be used when template files are changed
      [-n|--name=websiteName]         The name of the site whose yaml to be rebuilt. -n= will rebuilt yaml for all sites
    [-r|--remcont] ..............   Remove containers for all services that are disabled in the config
      [-n|--name=websiteName]         The name of the site whose yaml to be rebuilt. -n= will rebuilt yaml for all sites
    [-h|--help] .................   Display this help menu

EOF
  exit 1
}


#################################################################################################################
#                                                                                                               #
# Description:  Check if a service is diabled and if so, stop and remove its corresponding container            #
# Parameters:                                                                                                   #
#     Para-1:   scriptFolder:     The path of the this script file.                                             #
# Return:       Stops and removes al disabled services .                                                        #
#                                                                                                               #
##################################################################################################################

function removeContainers() {
  
  # Script path
  local scriptFolder=$1
  if [ -z "${scriptFolder}" ]; then
    echo "Failed to remove containers. The script folder must be specifcied"
    echo ""
    exit 1;
  fi

  # Website name
  local websiteName=$2
  if [ -z "${websiteName}" ]; then
    echo "Failed to remove containers. Must specify a website name"
    echo ""
    exit 1;
  fi

  # stop containers not in use
	
  # First load the default environment variables
  if [ -f "${scriptFolder}/envs/default-env.sh" ]; then
    # shellcheck disable=SC1091
    . "${scriptFolder}/envs/default-env.sh";
  fi
  #if [ -f "./envs/default-env.sh" ]; then . "./apps/site/envs/default-env.sh"; fi

  # Then if a site specific file exist, override the values
  # shellcheck disable=SC1091
  if [ -f "${scriptFolder}/envs/${websiteName}-env.sh" ]; then
    # shellcheck disable=SC1090
    . "${scriptFolder}/envs/${websiteName}-env.sh";
  fi

  # Finally, check the env varables of various services and take appropriate actions
	#
  
  echo "Removing containers for disabled services ..."
	
  # Phpmyadmin service
  if [ -z "${PHPMYADMIN_ENABLED}" ] || [ "${PHPMYADMIN_ENABLED}" != "yes" ]; then
    docker stop "${websiteName}-phpmyadmin"
    docker rm   "${websiteName}-phpmyadmin"
  fi

  # Wpbackup service
  if [ -z "${WPBACKUP_ENABLED}" ] || [ "${WPBACKUP_ENABLED}" != "yes" ]; then
		docker stop "${websiteName}-wpbackup"
		docker rm   "${websiteName}-wpbackup"
  fi

  # Webdrive service
  local webdrive=""
  if [ -z "${WEBDRIVE_ENABLED}" ] || [ "${WEBDRIVE_ENABLED}" != "yes" ]; then
    docker stop "${websiteName}-webdrive"
    docker rm   "${websiteName}-webdrive"
  fi

  # Vsftpd service
	local vsftpd=""
  if [ -z "${VSFTPD_ENABLED}" ] || [ "${VSFTPD_ENABLED}" != "yes" ]; then
    docker stop "${websiteName}-vsftpd"
    docker rm "${websiteName}-vsftpd"
	fi

  echo "All containers for disabled services removed successfully."
}






#################################################################################################################
#                                                                                                               #
#   Main Processing Block                                                                                       #
#                                                                                                               #
##################################################################################################################

main() {
  # to do correct this to also work with linux
  local scriptFolder;
  scriptFolder=$(cd "$(dirname "$0")" || exit; pwd)
  local rootFolder=${scriptFolder%/*} # Go to parent folder
  local rootFolder=${rootFolder%/*}   # Now go to parent's parent folder
  local dataFile="${scriptFolder}/site.txt"

  # Iterate through all arguments and find the command to be executed
  local command=""
  local options=()
  for arg in "$@"; do 
    case $arg in
      -a|--add)
        command=addSite
        ;;
      -e|--edit)
        command=editSite
       ;;
      -v|--view)
        command=viewSite
        ;;
      -d|--del)
        command=delSite
        ;;
      -b|--build)
        command=rebuildYmls
        ;;
      -r|--remcont)
        command=removeContainers
        ;;
      -h|--help)
        command=help
        ;;
      *)
        # save as a potetial options to be iterated later
        options+=("${arg}")
    esac
  done

  if [ -z ${command} ]; then
    echo ""
    echo "One of the following options must be specified to manage site(s)."
    echo " [-a|--add] ..................   Add the configuration of a new website"
    echo " [-e|--edit] .................   Edit the configuration of an existing website"
    echo " [-v|--view] .................   View all site details ot the specified one's"
    echo " [-d|--del] ..................   Delete the specified site detials"
    echo " [-b|--build] ..............     Rebuild all site yamls - should be used when template files are changed"
    echo " [-r|--remcont] ..............   Remove containers for all services that are disabled in the config"
    echo " [-h|--help] .................   Display this help menu"
    echo ""
    echo ""
    exit 1;
  fi

  local cmdsOptionN=("addSite" "editSite" "viewSite"  "delSite" "rebuildYmls" "removeContainers")
  local cmdsOptionW=("addSite" "editSite")
  local cmdsOptionU=("addSite" "editSite")
  
  # set the environment variables from the argument
  # iterate all but the last

  local option=""
  local websiteName=""
  local websiteUrl=""
  local additionalUrl=""
  local unkownOption=""
  for option in "${options[@]}"; do
    case $option in
      -n=*|--name=*)
        #if [[ " ${cmdsOptionN[@]} " =~ " ${command} " ]]; then
        #  websiteName="${option#*=}"
        #  shift # past option=value
        #else
        #  unkownOption="${option}"
        #fi
        case "${cmdsOptionN[@]}" in 
          *"${command}"*)
            websiteName="${option#*=}"
            shift # past option=value
            ;;
          *)
            unkownOption="${option}"
            ;;
        esac
        ;;
      -w=*|--web-url=*)
        #if [[ " ${cmdsOptionW[@]} " =~ " ${command} " ]]; then
        #  websiteUrl="${option#*=}"
        #  shift # past option=value
        #else
        #  unkownOption="${option}"
        #fi
        case "${cmdsOptionW[@]}" in 
          *"${command}"*)
            websiteUrl="${option#*=}"
            shift # past option=value
            ;;
          *)
            unkownOption="${option}"
            ;;
        esac
        ;;
      -u=*|--add-url=*)
        #if [[ " ${cmdsOptionU[@]} " =~ " ${command} " ]]; then
        #  additionalUrl="${option#*=}"
        #  shift # past option=value
        #else
        #  unkownOption="${option}"
        #fi
        case "${cmdsOptionU[@]}" in 
          *"${command}"*)
            additionalUrl="${option#*=}"
            shift # past option=value
            ;;
          *)
            unkownOption="${option}"
            ;;
        esac
        ;;
      *)
        # Unknown option
        unkownOption="${option}"
        ;;
    esac
   
    if [ -n "${unkownOption}" ]; then
      echo "Unknown option [${unkownOption}] found for ${command} command"
      echo "Use [-h|--help] for detailed argument list"
      echo ""
      echo ""
      exit 1;
    fi
  done

  # Now handle any options not set for a specific command
  local cmdsMandatoryOptionN=("addSite" "editSite" "delSite" "removeContainers")
  local cmdsMandatoryOptionW=("addSite")
  local cmdsMandatoryOptionU=("")
 
  # Check the Site Name is set for all commnads that specifies it as a mandatory option
  case "${cmdsMandatoryOptionN[@]}" in  *"${command}"*)
    #if [[ " ${cmdsMandatoryOptionN[@]} " =~ " ${command} " ]] && [ -z "${websiteName}" ]; then
    if [ -z "${websiteName}" ]; then
      echo "A website name must be specified using <-n|--name=siteName> for [${command}] command"
      echo "Use [-h|--help] for detailed argument list"
      echo ""
      echo ""
      exit 1;
    fi
    ;;
  esac
 
  # Check the Web Server URL is set for all commnads that specifies it as a mandatory option
  case "${cmdsMandatoryOptionW[@]}" in  *"${command}"*)
    #if [[ " ${cmdsMandatoryOptionW[@]} " =~ " ${command} " ]] && [ -z "${websiteUrl}" ]; then
    if [ -z "${websiteUrl}" ]; then
      echo "A Web Server URL must be specified using <-w|--web=url> for [${command}] command"
      echo "Use [-h|--help] for detailed argument list"
      echo ""
      echo ""
      exit 1;
    fi
    ;;
  esac

  # Check the Additional Server URL is set for all commnads that specifies it as a mandatory option
  case "${cmdsMandatoryOptionU[@]}" in  *"${command}"*)
    #if [[ " ${cmdsMandatoryOptionU[@]} " =~ " ${command} " ]] && [ -z "${additionalUrl}" ]; then
    if [ -z "${additionalUrl}" ]; then
      echo "An Additional Server URL must be specified using <-u|--add-url=url> for [${command}] command"
      echo "Use [-h|--help] for detailed argument list"
      echo ""
      echo ""
      exit 1;
    fi
    ;;
  esac
  
  # Run the command
  case $command in
    addSite)
        addSiteRecord "${rootFolder}" "${scriptFolder}" "${dataFile}" "${websiteName}" "${websiteUrl}" "${additionalUrl}"
        ;;
    editSite)
        editSiteRecord "${rootFolder}" "${scriptFolder}" "${dataFile}" "${websiteName}" "${websiteUrl}|${additionalUrl}"
       ;;
    viewSite)
        viewSiteRecord "${rootFolder}" "${scriptFolder}" "${dataFile}" "${websiteName}"
        ;;
    delSite)
        delSiteRecord "${rootFolder}" "${scriptFolder}" "${dataFile}" "${websiteName}" ""
        ;;
    rebuildYmls)
        rebuildYmls "${rootFolder}" "${scriptFolder}" "${dataFile}"
        ;;
		removeContainers)
		    removeContainers "${scriptFolder}" "${websiteName}"
        ;;
    help)
        help
        ;;
    *)
        echo "Unknown command ${command} found"
        echo "Use [-h|--help] for detailed argument list"
        echo ""
        exit 1;
  esac
  echo ""
}

# call the main block
main "$@"
