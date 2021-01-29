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
Managing a website configuration Interface
  Format:
	  site <command> [websiteName] [options=values]

  Available commands and related options:
    add ...........................   Add the configuration of a new website 
			<websiteName>                     The secific website whose configration is to be added.
			<-w|--web-url=url>                The web url e.g. www.example.com.
																				The wordpress site var is set to this
																				So any other urls are eventually redireded to this uRL 
			[-u|--add-url=url]                The additional url, e.g. example.com
		edit ..........................   Edit the configuration of an existing website
			<websiteName>                     The secific website whose configration is to be edited.
			[-w|--web-url=url]                The web url e.g. www.example.com.
																				The wordpress site var is set to this
																				So any other urls are eventually redireded to this uRL 
			[-u|--add-url=url]                The additional url, e.g. example.com
		view ..........................   View all site details ot the specified one
			[websiteName]                     The secific website whose configration is to be displayed.
																					Not passing this parameter would mean the configurations of all websites are to be displayed
		del ...........................   Delete the specified site detials
			<websiteName>                     The secific website whose configration is to deleted.
		rebuild ......,................   Rebuild all site yamls - should be used when template files are changed
			[websiteName]                     The secific website whose YML file is to be rebuilt.
																					Not passing this parameter would mean YML files for all websites are to be rebuilt
		remcont .......................   Remove containers for all services that are disabled in the config
			[websiteName]                     The name of the site whose contaners are to be removed.
																					Not passing this parameter would mean dsabled containers of all websites are to be removed
    help ............................ Display this help menu

  Example Usage
	  Add configuration of a live website for domain example.com
		  site add examp -w=www.example.com -u=example.com
	  Add configuration of a test website for domain test.example.com
			site add examp-test -w=test.example.com
	  Edit the website url of the live site to www2.example.com
		  site edit examp -w=www2.example.com
	  Unset the domain url of the live site by setting the domian url to same as website url
		  site edit examp -u=www2.example.com
	  View the details of example.com and all website
		  site view examp
	  View the details of all websites
		  site view
	  Delete the test website examp-test
		  site del examp-test
	  Rebuild the yml file for examp-test
		  site rebuild examp-test
	  Rebuild the yml files for all websites
		  site rebuild
	  Display this help menu
		  site help

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

  ## Vsftpd service
	#local vsftpd=""
  #if [ -z "${VSFTPD_ENABLED}" ] || [ "${VSFTPD_ENABLED}" != "yes" ]; then
  #  docker stop "${websiteName}-vsftpd"
  #  docker rm "${websiteName}-vsftpd"
	#fi

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
		
	local command=$1
  if [ -z "${command}" ]; then
    echo ""
    echo "One of the following command must be passed as 1st param to manage site(s)."
    echo " add ..................   Add the configuration of a new website"
    echo " edit .................   Edit the configuration of an existing website"
    echo " view .................   View all site details ot the specified one's"
    echo " del ..................   Delete the specified site detials"
    echo " rebuild ..............   Rebuild all site yamls - should be used when template files are changed"
    echo " remcont ..............   Remove containers for all services that are disabled in the config"
    echo " help] .................  Display this help menu"
    echo ""
    echo ""
    exit 1;
  fi
  shift # past the command

	local websiteName=$1
  if [ -z ${websiteName} ]; then
	  if [ "${websiteName}" == "add" ] || [ "${websiteName}" == "edit" ] || [ "${websiteName}" == "del" ]
		then
      echo ""
      echo "Must sececify website name as 2nd parameter for commands add, edit anf del."
      echo ""
      exit 1;
		fi
  fi
  shift # past the sitename

  local cmdsOptionW=("add" "edit")
  local cmdsOptionU=("add" "edit")
  
  # set the environment variables from the argument
  # iterate all but the last

  local option=""
  local websiteUrl=""
  local additionalUrl=""
  local unkownOption=""
  for option in "$@"; do
    case $option in
      -w=*|--web-url=*)
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
      echo ""
      echo "Unknown option [${unkownOption}] found for ${command} command"
      echo "Use [-h|--help] for detailed argument list"
      echo ""
      echo ""
      exit 1;
    fi
  done

  # Now handle any options not set for a specific command
  local cmdsMandatoryOptionW=("add")
  local cmdsMandatoryOptionU=("")
 
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
    add)
        addSiteRecord "${rootFolder}" "${scriptFolder}" "${dataFile}" "${websiteName}" "${websiteUrl}" "${additionalUrl}"
        ;;
    edit)
        editSiteRecord "${rootFolder}" "${scriptFolder}" "${dataFile}" "${websiteName}" "${websiteUrl}|${additionalUrl}"
       ;;
    view)
        viewSiteRecord "${rootFolder}" "${scriptFolder}" "${dataFile}" "${websiteName}"
        ;;
    del)
        delSiteRecord "${rootFolder}" "${scriptFolder}" "${dataFile}" "${websiteName}" ""
        ;;
    rebuild)
        rebuildYmls "${rootFolder}" "${scriptFolder}" "${dataFile}"
        ;;
		remcont)
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
