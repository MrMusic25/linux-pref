#!/bin/bash
#
# INSTALL.sh - A script meant to automatically install and setup my personal favorite options
# Usage: ./INSTALL.sh
#
# Note: This will change soon as functionality is added
# 
# v0.1 05 July 2016 13:06 PST

### Variables

sudoRequired=0 # Set to 0 by default - script will close if sudo is false and sudoRequired is true
installOnly=0 # Used by -n|--no-run, if 1 then files will be copied and verified, but not executed
inFile="NULL" # Multi-use input file variable
runMode="NULL" # Variable used to hold which install option will be run

### Functions

if [[ -f commonFunctions.sh ]]; then
	source commonFunctions.sh
elif [[ -f /usr/share/commonFunctions.sh ]]; then
	source /usr/share/commonFunctions.sh
else
	echo "commonFunctions.sh could not be located!"
	
	# Comment/uncomment below depending on if script actually uses common functions
	#echo "Script will now exit, please put file in same directory as script, or link to /usr/share!"
	#exit 1
fi

function processArgs() {
	while [[ $# > 0 ]]; then
	do
		key="$1"
		
		case $key in
			-h|--help)
			displayHelp
			exit 0
			;;
			-s|--sudo)
			checkPrivilege "exit" # This is why we make functions
			;;
			-e|--except)
			if [[ $2 == "all" ]]; then
				export debugFlag=1
				debug "ERROR: -e | --except option cannot be used with install option 'all' !"
				displayHelp
				exit 1
			elif [[ ! -z $2 || $2 == "update" || $2 == "programs" || $2 == "kali" || $2 == "git" ]]; then
				export except="$2"
			else
				export debugFlag=1
				debug "ERROR: -e | --except must have an option following it! Please fix and re-run script!"
				exit 1
			fi
			;;
			-n|--no-run)
			export installOnly=1
			;;
			all)
			export runMode="all"
			continue
			;;
			update)
			export runMode="update"
			continue
			;;
		esac
		shift
	done
}

function displayHelp() {
	# Don't use announce() in here in case script fails from beng unable to source comonFunctions.sh
	echo " "
	echo " Usage: $0 [options] <install_option>"
	echo " "
	echo " Install Options:"
	echo " NOTE: Running any install option will check if /usr/share/commonFunctions.sh exists. If not, sudo permission will be requested to install."
	echo "       Each script will be run after it is installed as well, to verify it is working properly."
	echo "    all                 - Installs all the scripts below"
	echo "    update              - Installs update script"
	echo "    programs [file]     - Installs programs using programInstaller.sh, or provided text-based tab-delimited file"
	echo "    kali [file]         - Same as 'programs', but installs from .kaliPrograms.txt by default. Also accepts file input."
	echo "    git                 - Installs git monitoring script and sets up cron job to run at boot"
	echo " "
	echo " Options:"
	echo "    -h | --help                        : Displays this help message"
	echo "    -s | --sudo                        : Makes script check for root privileges before running anything"
	echo "    -e | --except <install_option>     : Installs everything except option specified. e.g './INSTALL.sh -e kali' "
	echo "    -n | --no-run                      : Only installs scripts to be used, does not execute scripts"
}

### Main Script

# DELETE THIS WHEN READY
displayHelp
exit 5

processArgs "$@"

#EOF