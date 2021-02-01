#!/bin/bash




#################################################################################################################
#                                                                                                               #
# Description:  Displays help                                                                                   #
# Parameters:   None                                                                                            #
# Return:       None                                                                                            #
#                                                                                                               #
##################################################################################################################
help() {
  cat << EOF
Command line interface for the Docker-based web development environment wordpress.
  Format: wpcmd <command> [subcommand] [websiteName] [options=values]
  Available commands and their options:
    build ........................... Build all of the images or the specified one
      [-i|--image=imageName]            The secific image to be built. '-i=' will build all images
                                          Valid values for imageName are:
                                             mysql, nginx, wpbackup & webdrive
    logs ............................ Display and tail the logs of all containers or the specified one
      <websiteName>                     The secific website for which the logs are to be monitored.
      [-i|--image=imageName]            The secific image for which the log is to be monitored. '-i=' will monitor all logs
                                          Valid values for imageName are:
                                             mysql, wordpress, phpadmin, nginx, wpbackup & webdrive
    destroy ......................... Destroy the Docker environment of a website
      <websiteName>                     The secific website to be destroyed.
    up .............................. Build and start all the containers of a website
      <websiteName>                     The secific website to be built and started. 
    down ............................ Stop and destroy all containers of a website
      <websiteName>                     The secific website to be stopped and destoyed.
      [-v]                              Destroy the volumes as well
    start ........................... Start all the containers of a website
      <websiteName>                     The secific website for which the logs are to be monitored.
      <-n|--name=siteName>              The secific website to be built and started.
    stop ............................ Stop all the containers of sa website
      <websiteName>                     The secific website for which the logs are to be monitored.
      <-n|--name=siteName>              The secific website to be built and stopped.
    restart ......................... Restart all the containers of a website
      <websiteName>                     The secific website for which the logs are to be monitored.
      <-n|--name=siteName>              The secific website to be built and restarted.
    site ............................ Manage a website configuration
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
				                                    Not passing this parameter would mean YML files for all websites are to be built
      remcont .......................   Remove containers for all services that are disabled in the config
        [websiteName]                     The name of the site whose contaners are to be removed.
				                                    Not passing this parameter would mean dsabled containers of all websites are to be removed
    help ............................ Display this help menu

EOF
}



# Build all of the images, or the passed one


#################################################################################################################
#                                                                                                               #
# Description:  Build all of the images, or the passed one                                                      #
# Parameters:                                                                                                   #
#     Para-1:   [imageName]:      Optional. if nothing passed all are built.                                    #
#                                 valid values are <blank>, mysql, nginx, wpbackup and webdrive                 #
# Return:       None                                                                                            #
#                                                                                                               #
##################################################################################################################
build () {
  
  # Image name
  local imageName=$1
  if [ -n "$imageName" ]  && [ "$imageName" != "mysql" ]  && [ "$imageName" != "nginx" ]  \
     &&   [ "$imageName" != "wpbackup" ] && [ "$imageName" != "webdrive" ] && [ "$imageName" != "vsftpd" ]
  then
    echo "Invalid image name [$imageName] passed. Valid values are <blank>, mysql, nginx, wpbackup, webdrive and vsftpd"
    echo ""
    echo ""
    exit 1;
  fi
  
  # Build mysql
  if [ -z "$imageName" ] || [ "$imageName" == "mysql" ]; then
    echo "Building image [mysql] ..."
    docker build --no-cache --tag thetek/mysql:8.0.22 --label thetek_mysql:latest ./.docker/mysql
    docker image prune --force --filter='label=thetek_mysql:latest'
    echo ""
  fi
  
  # Build nginx
  if [ -z "$imageName" ] || [ "$imageName" == "nginx" ]; then
    echo "Building image [nginx] ..."
    docker build --no-cache --tag thetek/nginx:1.17-alpine --label thetek_nginx:latest ./.docker/nginx
    docker image prune --force --filter='label=thetek_nginx:latest'
    echo ""
  fi
  
  # Build wpbackup
  if [ -z "$imageName" ] || [ "$imageName" == "wpbackup" ]; then
    echo "Building image [wpbackup] ..."
    docker build --no-cache --tag thetek/wpbackup:1.0.0 --label thetek_wpbackup:latest ./.docker/wpbackup
    docker image prune --force --filter='label=thetek_wpbackup:latest'
    echo ""
  fi
  
  # Build webdrive
  if [ -z "$imageName" ] || [ "$imageName" == "webdrive" ]; then
    echo "Building image [webdrive] ..."
    docker build --no-cache --tag thetek/webdrive:1.0.0 --label thetek_webdrive:latest ./.docker/webdrive
    docker image prune --force --filter='label=thetek_webdrive:latest'
    echo ""
  fi
  
  # Only built vsftpd, if passed specifically
  if [ "$imageName" == "vsftpd" ]; then
    echo "Building image [vsftpd] ..."
    docker build --no-cache --tag thetek/vsftpd:1.0.0 --label thetek_vsftpd:latest ./.docker/vsftpd
    docker image prune --force --filter='label=thetek_vsftpd:latest'
    echo ""
  fi

  echo ""
}



#################################################################################################################
#                                                                                                               #
# Description:  Display and tail the logs of all containers or the specified one's                              #
# Parameters:                                                                                                   #
#     Para-1:   websiteName:      The name of the website whose log is to be tracked                            #
#     Para-2:   [imageName]:      Optional. if nothing passed all are built.                                    #
#                                 valid values are <blank>, mysql, nginx, wpbackup and webdrive                 #
# Return:       None                                                                                            #
#                                                                                                               #
##################################################################################################################
logs () {

  # Website name
  local websiteName=$1
  if [ -z "${websiteName}" ]; then
    echo "Could't find the YAML file [docker-compose-${websiteName}.yml]. Please add the site and try again"
    echo ""
    exit 1;
  fi

  # Image name
  local imageName=$2
  if [ -n "$imageName" ]  && [ "$imageName" != "mysql" ]  && [ "$imageName" != "nginx" ]  \
     &&   [ "$imageName" != "wpbackup" ] && [ "$imageName" != "webdrive" ] # && [ "$imageName" != "vsftpd" ]
  then
    echo "Invalid image name [$imageName] passed. Valid values are <blank>, mysql, nginx, wpbackup and webdrive"
    echo ""
    echo ""
    exit 1;
  fi

  # Display and ail the logs
  docker-compose -f docker-compose-${websiteName}.yml -p=${websiteName} logs -f "${imageName}"
}



#################################################################################################################
#                                                                                                               #
# Description:  Remove the entire Docker environment                                                            #
# Parameters:                                                                                                   #
#     Para-1:   websiteName:      The name of the website whose log is to be tracked                            #
#     Para-2:   [imageName]:      Optional. if nothing passed all are built.                                    #
#                                 valid values are <blank>, mysql, nginx, wpbackup and webdrive                 #
# Return:       None                                                                                            #
#                                                                                                               #
##################################################################################################################
destroy () {

  # Website name
  local websiteName=$1
  if [ -z "${websiteName}" ]; then
    echo "Could't find the YAML file [docker-compose-${websiteName}.yml]. Please add the site and try again"
    echo ""
    exit 1;
  fi

  # Image name
  local imageName=$2
  if [ -n "$imageName" ]  && [ "$imageName" != "mysql" ]  && [ "$imageName" != "nginx" ]  \
     &&   [ "$imageName" != "wpbackup" ] && [ "$imageName" != "webdrive" ] # && [ "$imageName" != "vsftpd" ]
  then
    echo "Invalid image name [$imageName] passed. Valid values are <blank>, mysql, nginx, wpbackup and webdrive"
    echo ""
    echo ""
    exit 1;
  fi

  read -p "This will delete containers, volumes and images for ${websiteName}. Are you sure? [y/N]: " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit; fi
	
	// Fibally distroy all containers of the passed website
  docker-compose -f docker-compose-${websiteName}.yml -p=${websiteName} down $destroyVolume --rmi all
}



#################################################################################################################
#                                                                                                               #
# Description:  Build & start the containers                                                                   #
# Parameters:                                                                                                   #
#     Para-1:   websiteName:      The name of the website whose log is to be tracked                            #
#     Para-2:   [imageName]:      Optional. if nothing passed all are built.                                    #
#                                 valid values are <blank>, mysql, nginx, wpbackup and webdrive                 #
# Return:       None                                                                                            #
#                                                                                                               #
##################################################################################################################
up () {

  # Website name
  local websiteName=$1
  if [ -z "${websiteName}" ]; then
    echo "Could't find the YAML file [docker-compose-${websiteName}.yml]. Please add the site and try again"
    echo ""
    exit 1;
  fi

  # Image name
  local imageName=$2
  if [ -n "$imageName" ]  && [ "$imageName" != "mysql" ]  && [ "$imageName" != "nginx" ]  \
     &&   [ "$imageName" != "wpbackup" ] && [ "$imageName" != "webdrive" ] # && [ "$imageName" != "vsftpd" ]
  then
    echo "Invalid image name [$imageName] passed. Valid values are <blank>, mysql, nginx, wpbackup and webdrive"
    echo ""
    echo ""
    exit 1;
  fi

  # Create and start the containers of the passed website
  docker-compose -f docker-compose-${websiteName}.yml -p=${websiteName} up -d

	# Stop and remove any containers whose services are disabled
	bash "${siteAppFilePath}" "remcont" "${websiteName}"
}



#################################################################################################################
#                                                                                                               #
# Description:  Stop and destroy the containers                                                                 #
# Parameters:                                                                                                   #
#     Para-1:   websiteName:      The name of the website whose log is to be tracked                            #
#     Para-2:   [imageName]:      Optional. if nothing passed all are built.                                    #
#                                 valid values are <blank>, mysql, nginx, wpbackup and webdrive                 #
# Return:       None                                                                                            #
#                                                                                                               #
##################################################################################################################
down () {

  # Website name
  local websiteName=$1
  if [ -z "${websiteName}" ]; then
    echo "Could't find the YAML file [docker-compose-${websiteName}.yml]. Please add the site and try again"
    echo ""
    exit 1;
  fi

  # Image name
  local imageName=$2
  if [ -n "$imageName" ]  && [ "$imageName" != "mysql" ]  && [ "$imageName" != "nginx" ]  \
     &&   [ "$imageName" != "wpbackup" ] && [ "$imageName" != "webdrive" ] # && [ "$imageName" != "vsftpd" ]
  then
    echo "Invalid image name [$imageName] passed. Valid values are <blank>, mysql, nginx, wpbackup and webdrive"
    echo ""
    echo ""
    exit 1;
  fi

  # Stop and remove the containers of the passed website
  docker-compose -f docker-compose-${websiteName}.yml -p=${websiteName} down
}




#################################################################################################################
#                                                                                                               #
# Description:  Start the containers                                                                            #
# Parameters:                                                                                                   #
#     Para-1:   websiteName:      The name of the website whose log is to be tracked                            #
#     Para-2:   [imageName]:      Optional. if nothing passed all are built.                                    #
#                                 valid values are <blank>, mysql, nginx, wpbackup and webdrive                 #
# Return:       None                                                                                            #
#                                                                                                               #
##################################################################################################################
start () {

  # Website name
  local websiteName=$1
  if [ -z "${websiteName}" ]; then
    echo "Could't find the YAML file [docker-compose-${websiteName}.yml]. Please add the site and try again"
    echo ""
    exit 1;
  fi

  # Image name
  local imageName=$2
  if [ -n "$imageName" ]  && [ "$imageName" != "mysql" ]  && [ "$imageName" != "nginx" ]  \
     &&   [ "$imageName" != "wpbackup" ] && [ "$imageName" != "webdrive" ] # && [ "$imageName" != "vsftpd" ]
  then
    echo "Invalid image name [$imageName] passed. Valid values are <blank>, mysql, nginx, wpbackup and webdrive"
    echo ""
    echo ""
    exit 1;
  fi

  # Start the containers of the passed website
  docker-compose -f docker-compose-${websiteName}.yml -p=${websiteName} start
}




#################################################################################################################
#                                                                                                               #
# Description:  Stop the containers                                                                             #
# Parameters:                                                                                                   #
#     Para-1:   websiteName:      The name of the website whose log is to be tracked                            #
#     Para-2:   [imageName]:      Optional. if nothing passed all are built.                                    #
#                                 valid values are <blank>, mysql, nginx, wpbackup and webdrive                 #
# Return:       None                                                                                            #
#                                                                                                               #
##################################################################################################################
stop () {

  # Website name
  local websiteName=$1
  if [ -z "${websiteName}" ]; then
    echo "Could't find the YAML file [docker-compose-${websiteName}.yml]. Please add the site and try again"
    echo ""
    exit 1;
  fi

  # Image name
  local imageName=$2
  if [ -n "$imageName" ]  && [ "$imageName" != "mysql" ]  && [ "$imageName" != "nginx" ]  \
     &&   [ "$imageName" != "wpbackup" ] && [ "$imageName" != "webdrive" ] # && [ "$imageName" != "vsftpd" ]
  then
    echo "Invalid image name [$imageName] passed. Valid values are <blank>, mysql, nginx, wpbackup and webdrive"
    echo ""
    echo ""
    exit 1;
  fi

  # Stop the containers of the passed website
  docker-compose -f docker-compose-${websiteName}.yml -p=.${websiteName} stop
}



#################################################################################################################
#                                                                                                               #
# Description:  Restart the containers                                                                          #
# Parameters:                                                                                                   #
#     Para-1:   websiteName:      The name of the website whose log is to be tracked                            #
#     Para-2:   [imageName]:      Optional. if nothing passed all are built.                                    #
#                                 valid values are <blank>, mysql, nginx, wpbackup and webdrive                 #
# Return:       None                                                                                            #
#                                                                                                               #
##################################################################################################################
restart () {

  # Website name
  local websiteName=$1
  if [ -z "${websiteName}" ]; then
    echo "Could't find the YAML file [docker-compose-${websiteName}.yml]. Please add the site and try again"
    echo ""
    exit 1;
  fi

  # Image name
  local imageName=$2
  if [ -n "$imageName" ]  && [ "$imageName" != "mysql" ]  && [ "$imageName" != "nginx" ]  \
     &&   [ "$imageName" != "wpbackup" ] && [ "$imageName" != "webdrive" ] # && [ "$imageName" != "vsftpd" ]
  then
    echo "Invalid image name [$imageName] passed. Valid values are <blank>, mysql, nginx, wpbackup and webdrive"
    echo ""
    echo ""
    exit 1;
  fi

  # Restart the containers of the passed website
  stop && start;
}



#################################################################################################################
#                                                                                                               #
#   Main Processing Block                                                                                       #
#                                                                                                               #
##################################################################################################################
main() {
	# to do correct this to also work with linux
	local scriptPath=$(cd "$(dirname "$0")"; pwd)
	local roorDir=${scriptPath%/*}
	local scriptFilePath="${scriptPath}/wpcmd" 
	local siteAppFilePath="${scriptPath}/apps/site/site.sh"

	local command=$1
	if [ -z "${command}" ]; then
		echo "A command must be specified."
		echo "Please type wpcmd help for a detailed list of commands available"
		echo ""
		echo ""
		exit 1;
	fi
	shift # past the command

	if [ "${command}" == "site" ]; then
		bash "${siteAppFilePath}" "$@"
		exit 1;
	fi

	if [ "${command}" == "help" ]; then
		help;
		echo ""
		exit 1;
	fi


	local websiteName=""
	if [  "${command}" != "build" ]
	then
	  websiteName="$1"
		if [ -z ${websiteName} ]
		then
			echo ""
			echo "Must sececify website name as 2nd parameter for commands logs, destroy, up, down, star, stop & restart."
			echo ""
			exit 1;
		fi
		shift # past the website name
	fi


	local cmdsOptionI=("build" "logs")
	local cmdsOptionV=("destroy")

  local imageName="";
  local unknownOption="";
	local destroyVolume="";
	for option in "$@"; do
		case $option in
			-i=*|--image=*)
				if [[ " ${cmdsOptionI[@]} " =~ " ${command} " ]]; then
					imageName="${option#*=}"
					shift # past option=value
				else
					unknownOption="${option}"
				fi
				;;
			-v|--volume)
				if [[ " ${cmdsOptionV[@]} " =~ " ${command} " ]]; then
					destroyVolume="-v"
					shift # past this optionoption
				else
					unknownOption="${option}"
				fi
				;;
			*)
				# unknown option
				unknownOption="${option}"
				;;
		esac

		if [ ! -z "${unknownOption}" ]; then
			echo "Unknown option [${unknownOption}] found for ${command} command"
			echo "Use [-h|--help] for detailed argument list"
			echo ""
			echo ""
			exit 1;
		fi
	done


	# Finally run the command
	case $command in
		build)
			build "${imageName}"
			;;
		logs)
			logs "${websiteName}" "${imageName}"
			;;
		destroy)
			destroy "${websiteName}" "${destroyVolume}"
			;;
		up)
			up "${websiteName}" "${imageName}"
			;;
		down)
			down "${websiteName}" "${imageName}"
			;;
		start)
			start "${websiteName}" "${imageName}"
			;;
		stop)
			stop "${websiteName}" "${imageName}"
			;;
		restart)
			restart "${websiteName}" "${imageName}"
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

