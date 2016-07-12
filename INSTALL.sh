#!/bin/bash
#
# INSTALL.sh - A script meant to automatically install and setup my personal favorite options
# Usage: ./INSTALL.sh
#
# Note: This will change soon as functionality is added
# 
# v0.1 12 July 2016 13:32 PST

### Variables

sudoRequired=0 # Set to 0 by default - script will close if sudo is false and sudoRequired is true
installOnly=0 # Used by -n|--no-run, if 1 then files will be copied and verified, but not executed
programsFile="programs.txt"
kaliFile=".kaliPrograms.txt"
runMode="NULL" # Variable used to hold which install option will be run

### Functions

if [[ -f commonFunctions.sh ]]; then
	source commonFunctions.sh
	export installLog="$debugPrefix/installer.log"
elif [[ -f /usr/share/commonFunctions.sh ]]; then
	source /usr/share/commonFunctions.sh
	export installLog="$debugPrefix/installer.log"
else
	echo "commonFunctions.sh could not be located!"
	
	# Comment/uncomment below depending on if script actually uses common functions
	echo "Script will now exit, please put file in same directory as script, or link to /usr/share!"
	exit 1
fi

function processArgs() {
	if [[ $# -eq 0 ]]; then
		export debugFlag=1
		debug "ERROR: Script must be run with at least one argument!" $installLog
		displayHelp
		exit 1
	fi
	loopFlag=0
	
	while [[ $loopFlag -eq 0 ]];
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
				debug "ERROR: -e | --except option cannot be used with install option 'all' !" $installLog
				displayHelp
				exit 1
			elif [[ ! -z $2 || $2 == "update" || $2 == "programs" || $2 == "kali" || $2 == "git" ]]; then
				export except="$2"
			else
				export debugFlag=1
				debug "ERROR: -e | --except must have an option following it! Please fix and re-run script!" $installLog
				displayHelp
				exit 1
			fi
			;;
			-n|--no-run)
			export installOnly=1
			;;
			-v|--verbose)
			export debugFlag=1 # Again, this is why we like shared functions
			;;
			all)
			export runMode="all"
			export loopFlag=1
			;;
			update)
			export runMode="update"
			export loopFlag=1
			;;
			programs)
			if [[ -z $2 ]]; then
				debug "No argument provided for 'programs' applet, assuming default file location" $installLog
				if [[ -e $programsFile ]]; then
					debug "Default location of programs file is working, using for script..." $installLog
					export runMode="programs"
					export loopFlag=1	
				else
					debug "Default location not valid, quitting script!" $installLog
					export debugFlag=1
					debug "ERROR: Default file ($programsFile) not found, please locate or specify" $installLog
					displayHelp
					exit 1
				fi
			elif [[ ! -e $2 ]]; then
				export debugFlag=1
				debug "ERROR: File provided for programs is invalid, or does not exist! Please fix and re-run script!" $installLog
				displayHelp
				exit 1
			else
				export runMode="programs"
				debug "Programs mode set, file provided is valid!" $installLog
				export programsFile="$2"
				export loopFlag=1
			fi
			;;
			kali)
			if [[ -z $2 ]]; then
				debug "No argument provided for 'kali' applet, assuming default file location" $installLog
				if [[ -e $kaliFile ]]; then
					debug "Default location of kali file is working, using for script..." $installLog
					export runMode="kali"
					export loopFlag=1	
				else
					debug "Default location not valid, quitting script!" $installLog
					export debugFlag=1
					debug "ERROR: Default file ($kaliFile) not found, please locate or specify" $installLog
					displayHelp
					exit 1
				fi
			elif [[ ! -e $2 ]]; then
				export debugFlag=1
				debug "ERROR: File provided for kali is invalid, or does not exist! Please fix and re-run script!" $installLog
				displayHelp
				exit 1
			else
				export runMode="kali"
				debug "Kali mode set, file provided is valid!" $installLog
				export programsFile="$2"
				export loopFlag=1
			fi
			;;
			git)
			export runMode="git"
			export loopFlag=1
			;;
			*)
			export debugFlag=1
			debug "ERROR: Unknown option '$1' " $installLog
			displayHelp
			exit 1
		esac
		shift
	done
	
	if [[ $runMode == "NULL" ]]; then
		export debugFlag=1
		debug "ERROR: Please provide a run mode and re-run script!"
		displayHelp
		exit 1
	fi
}

function displayHelp() {
	# Don't use announce() in here in case script fails from beng unable to source comonFunctions.sh
	echo " "
	echo " Usage: $0 [options] <install_option>"
	echo " "
	echo " NOTE: Running any install option will check if /usr/share/commonFunctions.sh exists. If not, sudo permission will be requested to install."
	echo "       Each script will be run after it is installed as well, to verify it is working properly."
	echo " "
	echo " Install Options:"
	echo "    all                                : Installs all the scripts below"
	echo "    update                             : Installs update script"
	echo "    programs [file]                    : Installs programs using programInstaller.sh, or provided text-based tab-delimited file"
	echo "    kali [file]                        : Same as 'programs', but installs from .kaliPrograms.txt by default. Also accepts file input."
	echo "    git                                : Installs git monitoring script and sets up cron job to run at boot"
	echo " "
	echo " Options:"
	echo "    -h | --help                        : Displays this help message"
	echo "    -s | --sudo                        : Makes script check for root privileges before running anything"
	echo "    -e | --except <install_option>     : Installs everything except option specified. e.g './INSTALL.sh -e kali' "
	echo "    -n | --no-run                      : Only installs scripts to be used, does not execute scripts"
	echo "    -v | --verbose                     : Displays additional debug info, also found in logfile"
}

### Main Script

# DELETE THIS WHEN READY
#displayHelp
#exit 5

processArgs "$@"

echo "Done with script!"

#EOF