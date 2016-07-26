#!/bin/bash
#
# INSTALL.sh - A script meant to automatically install and setup my personal favorite options
# Usage: ./INSTALL.sh
#
# Note: This will change soon as functionality is added
#
# Changes:
# v0.2.0
# - Added installGit() and installUpdate()
# - Created a system to notify the user if the script will require their attention (so they know not to wander off)
#
# v0.1.0
# - Added linkCF() to check is commonFunctions.sh is linked to /usr/share
# - Also added two checks to make sure it is linked
# - Changed minor version because part of script actually functions now
# 
# v0.0.1
# - Initial commit - only displayHelp() and processArgs() working currently
#
# v0.1.0 12 July 2016 13:49 PST

### Variables

#sudoRequired=0 # Set to 0 by default - script will close if sudo is false and sudoRequired is true
installOnly=0 # Used by -n|--no-run, if 1 then files will be copied and verified, but not executed
programsFile="programs.txt"
kaliFile=".kaliPrograms.txt"
runMode="NULL" # Variable used to hold which install option will be run
pathCheck=0 # Used to tell other functions if path check as be run or not
pathLocation="/usr/bin"
interactiveFlag=0 # Tells the script whether or not to inform the user that the script will require their interaction

### Functions

# Used to link commonFunctions.sh to /usr/share, in case it is not there already
function linkCF() {
	if [[ ! -f commonFunctions.sh ]]; then
		echo "ERROR: commonFunctions.sh is somehow not available, please correct and re-run!"
		exit 1
	fi
	
	if [[ "$EUID" -ne 0 ]]; then
		echo "Linking to /usr/share requires root permissions, please login"
		sudo ln commonFunctions.sh /usr/share/
	else
		echo "Linking to commonFunctions.sh to /usr/share/ !"
		sudo ln commonFunctions.sh /usr/share/
	fi
}

if [[ -f /usr/share/commonFunctions.sh ]]; then
	source /usr/share/commonFunctions.sh
	export installLog="$debugPrefix/installer.log"
elif [[ -f commonFunctions.sh ]]; then
	source commonFunctions.sh
	linkCF
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
				if [[ -f $programsFile ]]; then
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
			elif [[ ! -f $2 ]]; then
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
				if [[ -f $kaliFile ]]; then
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
			elif [[ ! -f $2 ]]; then
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

function pathCheck() {
	echo $PATH | grep $pathLocation &>/dev/null # This shouldn't show anything, I hope
	if [[ $? -eq 0 ]]; then
		debug "$pathLocation is in the user's path!" $installLog
		export pathCheck=1
	else
		announce "WARNING: $pathLocation is not in the PATH for $USER!"
		answer="NULL"
		echo "Would you like to specify a different directory in your PATH? (y/n): "
		
		while [[ $answer != "y" && $answer != "n" && $answer != "yes" && $answer != "no" ]]; do
			read answer
			case $answer in
				n|no)
					debug "User chose not to specify new directory for PATH!" $installLog
					announce "Not updating path!" "Please add $pathLocation to your PATH manually!"
					exit 1
					;;
				y|yes)
					announce "Please choose one of the following directories when prompted:" "$(echo $PATH)"
					export pathLocation="NULL"
					
					echo "Which directory in your path would you like to use? "
					while [[ ! -d $pathLocation ]]; do
						read pathLocation
						echo $PATH | grep $pathLocation &>/dev/null
						
						if [[ -d $pathLocation && $? -eq 0 ]]; then
							echo "$pathLocation is valid, continuing with script!"
							export pathCheck=1
						else
							debug "ERROR: PATH given not valid!" $installLog
							echo " Path given not valid, please try again: "
						fi
					done
					;;
				*)
					echo "Please enter 'yes' or 'no': "
					;;
			esac
		done
	fi
}

function installUpdate() {
	announce "Now installing the update script!" "NOTE: This will require sudo permissions."
	if [[ $installOnly -ne 0 ]]; then
		debug "User indicated not to run scripts, only installing update script!" $installLog
	fi
	
	sudo ln update.sh /usr/bin/update
	
	if [[ $installOnly -eq 0 ]]; then
		sudo update
	fi
}

function installGit() {
	announce "Now installing the git auto-updating script!" "NOTE: This will require sudo premissions."
	if [[ $installOnly -ne 0 ]]; then
		debug "User indicated not to run scripts, so I will only install the script!" $installLog
	fi
	
	sudo ln gitCheck.sh /usr/bin/gitcheck
	
	announce "This script can be used for any git repository, read the documentation for more info!" "Make sure to add a cron job for any new directories!"
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

# This doesn't really need to be here now, but double-checking never hurts!
if [[ ! -f /usr/share/commonFunctions.sh ]]; then
	echo "commonFunctions.sh not linked to /usr/share, fixing now!"
	linkCF
fi

processArgs "$@"

pathCheck

# If you value your sanity, NEVER delete the following lines!
echo "fortune | cowsay | lolcat" >> ~/.bashrc
sudo echo "fortune | cowsay | lolcat" >> /root/.bashrc

echo "Done with script!"

#EOF