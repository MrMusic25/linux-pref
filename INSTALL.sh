#!/bin/bash
#
# INSTALL.sh - A script meant to automatically install and setup my personal favorite options
# Usage: ./INSTALL.sh
#
# Note: This will change soon as functionality is added
#
# Changes:
# v1.2.0
# - Script now installs everything using symbolic links, as hard links don't update anymore
# - Created a function to uninstall the changes this script makes
# - installBash() now creates a backup (.bashrc.bak) in case the user tries to uninstall later
# - Script now backs up the user's crontab, and can now restore said crontab
#
# v1.1.2
# - Changed te way installBash() works - sources instead of linking now
#
# v1.1.1
# - Minor text fixes :3
#
# v1.1.0
# - Added a function to install and setup grive
# - Other small functionality changes
#
# v1.0.3
# - installUpdate() now installs the newly created installPackages.sh as well
# - Putting a lot of faith in shellcheck, fixed every error it gave me for this script (untested for now because a commit is necessary to test on RPi)
#
# v1.0.2
# - Fixed multiple issues I found when trying to install yesterday
# - Added a check to tell user not to run script as root
#
# v1.0.1
# - 30 mins of debugging, and shellcheck found the error seconds. Amazing program.
# - Script fully functional, just need to test on system now
#
# v1.0.0
# - Finally ready for a release version! Theoretically, everything should work and install properly
#
# v0.2.1
# - Changed to dynamic logging
#
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
# v1.2.0 15 Aug 2016 15:47 PST

### Variables

#sudoRequired=0 # Set to 0 by default - script will close if sudo is false and sudoRequired is true
installOnly=0 # Used by -n|--no-run, if 1 then files will be copied and verified, but not executed
programsFile="programLists/"
#kaliFile=".kaliPrograms.txt"
runMode="NULL" # Variable used to hold which install option will be run
pathCheck=0 # Used to tell other functions if path check has be run or not
pathLocation="/usr/bin"
#interactiveFlag=0 # Tells the script whether or not to inform the user that the script will require their interaction

### Functions

# Used to link commonFunctions.sh to /usr/share, in case it is not there already
function linkCF() {
	if [[ ! -f commonFunctions.sh ]]; then
		echo "ERROR: commonFunctions.sh is somehow not available, please correct and re-run!"
		echo "Please cd into the directoy containing $0 and commonFunctions.sh!"
		exit 1
	fi
	
	if [[ "$EUID" -ne 0 ]]; then
		echo "Linking to /usr/share requires root permissions, please login"
		sudo ln -s commonFunctions.sh /usr/share/
	else
		echo "Linking to commonFunctions.sh to /usr/share/ !"
		sudo ln -s commonFunctions.sh /usr/share/
	fi
}

if [[ -f /usr/share/commonFunctions.sh ]]; then
	source /usr/share/commonFunctions.sh
	#export installLog="$debugPrefix/installer.log"
elif [[ -f commonFunctions.sh ]]; then
	source commonFunctions.sh
	linkCF
	#export installLog="$debugPrefix/installer.log"
else
	echo "commonFunctions.sh could not be located!"
	
	# Comment/uncomment below depending on if script actually uses common functions
	echo "Script will now exit, please put file in same directory as script, or link to /usr/share!"
	exit 1
fi

function processArgs() {
	if [[ $# -eq 0 ]]; then
		export debugFlag=1
		debug "ERROR: Script must be run with at least one argument!"
		displayHelp
		exit 1
	fi
	loopFlag=0
	
	debug "Processing arguments..."
	while [[ $loopFlag -eq 0 ]];
	do
		key="$1"
		
		case $key in
			-h|--help)
			debug "Displaying help then exiting!"
			displayHelp
			exit 0
			;;
			-s|--sudo)
			debug "Checking for root privileges"
			checkPrivilege "exit" # This is why we make functions
			;;
			-e|--except)
			if [[ $2 == "all" ]]; then
				export debugFlag=1
				debug "ERROR: -e | --except option cannot be used with install option 'all' !"
				displayHelp
				exit 1
			elif [[ $2 == "uninstall" ]]; then
				echo "The except option is not compatible with uninstall! Please run $0 uninstall instead!"
				displayHelp
				exit 1
			elif [[ ! -z $2 || $2 == "update" || $2 == "programs" || $2 == "git" || $2 == "bash" || $2 == "grive" ]]; then
				export except="$2"
				export loopFlag=1
			else
				export debugFlag=1
				debug "ERROR: -e | --except must have an option following it! Please fix and re-run script!"
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
			grive)
			export runMode="grive"
			export loopFlag=1
			;;
			programs)
			if [[ -z $2 ]]; then
				debug "No argument provided for 'programs' applet, assuming default file location"
				if [[ -f $programsFile ]]; then
					debug "Default location of programs file is working, using for script..."
					export runMode="programs"
					export loopFlag=1	
				else
					debug "Default location not valid, quitting script!"
					export debugFlag=1
					debug "ERROR: Default file ($programsFile) not found, please locate or specify"
					displayHelp
					exit 1
				fi
			elif [[ ! -z $2 ]]; then
				export programsFile="$2"
				export runMode="programs"
				export loopFlag=1
				debug "Running in programs mode, using file/directory $programsFile"
			#else
			#	export runMode="programs"
			#	debug "Programs mode set, file provided is valid!"
			#	export programsFile="$2"
			#	export loopFlag=1
			fi
			;;
			#kali)
			#if [[ -z $2 ]]; then
			#	debug "No argument provided for 'kali' applet, assuming default file location"
			#	if [[ -f $kaliFile ]]; then
			#		debug "Default location of kali file is working, using for script..."
			#		export runMode="kali"
			#		export loopFlag=1	
			#	else
			#		debug "Default location not valid, quitting script!"
			#		export debugFlag=1
			#		debug "ERROR: Default file ($kaliFile) not found, please locate or specify"
			#		displayHelp
			#		exit 1
			#	fi
			#elif [[ ! -f $2 ]]; then
			#	export debugFlag=1
			#	debug "ERROR: File provided for kali is invalid, or does not exist! Please fix and re-run script!"
			#	displayHelp
			#	exit 1
			#else
			#	export runMode="kali"
			#	debug "Kali mode set, file provided is valid!"
			#	export programsFile="$2"
			#	export loopFlag=1
			#fi
			#;;
			git)
			export runMode="git"
			export loopFlag=1
			;;
			bash)
			export runMode="bash"
			export loopFlag=1
			;;
			uninstall)
			export runMode="uninstall"
			export loopFlag=1
			;;
			*)
			export debugFlag=1
			debug "ERROR: Unknown option '$1' "
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
	echo "$PATH" | grep "$pathLocation" &>/dev/null # This shouldn't show anything, I hope
	if [[ $? -eq 0 ]]; then
		debug "$pathLocation is in the user's path!"
		export pathCheck=1
	else
		announce "WARNING: $pathLocation is not in the PATH for $USER!"
		answer="NULL"
		echo "Would you like to specify a different directory in your PATH? (y/n): "
		
		while [[ $answer != "y" && $answer != "n" && $answer != "yes" && $answer != "no" ]]; do
			read -r answer
			case $answer in
				n|no)
					debug "User chose not to specify new directory for PATH!"
					announce "Not updating path!" "Please add $pathLocation to your PATH manually!"
					exit 1
					;;
				y|yes)
					announce "Please choose one of the following directories when prompted:" "$PATH"
					export pathLocation="NULL"
					
					echo "Which directory in your path would you like to use? "
					while [[ ! -d $pathLocation ]]; do
						read pathLocation
						echo "$PATH" | grep "$pathLocation" &>/dev/null
						
						if [[ -d $pathLocation && $? -eq 0 ]]; then
							echo "$pathLocation is valid, continuing with script!"
							export pathCheck=1
						else
							debug "ERROR: PATH given not valid!"
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
	announce "Now installing the update and installer scripts!" "NOTE: This will require sudo permissions."
	if [[ $installOnly -ne 0 ]]; then
		debug "User indicated not to run scripts, only installing update script!"
	fi
	
	sudo ln -s update.sh /usr/bin/update
	announce "You can now update your system anywhere by running the command: sudo update" "You can also install packages by running: sudo update <packages_to_install>"
	
	sudo ln -s installPackages.sh /usr/bin/installPackages
	announce "If all you want to do is install packages, you can run: installPackages <packages_to_install>"
	sleep 5 # Give the user time to read before more script runs
	
	if [[ $installOnly -eq 0 ]]; then
		sudo update
	fi
}

function installGit() {
	announce "Now installing the git auto-updating script!" "NOTE: This will require sudo premissions."
	if [[ $installOnly -ne 0 ]]; then
		debug "User indicated not to run scripts, so I will only install the script!"
	fi
	
	sudo ln -s gitCheck.sh /usr/bin/gitcheck
	
	announce "This script can be used for any git repository, read the documentation for more info!" "Make sure to add a cron job for any new directories!"
	
	getUserAnswer "Would you like to periodically update this directory?" gitTime "How many minutes would you like between updates? (0-60)"
	if [[ $? -eq 0 ]]; then
		addCronJob "$gitTime" min "/usr/bin/gitcheck $(pwd)" # Added as current user
		debug "Cron job added, will check every $gitTime minutes."
	fi
}

function installPrograms() {
	# If no-run enabled, ask user if they want to continue
	if [[ $installOnly -eq 1 ]]; then
		#export debugFlag=1
		debug "ERROR: User indicated not to run scripts, then tried to install programs! Asking for verification..."
		getUserAnswer "You indicated not to run scripts! Do you still want to install programs?"
		if [[ $? -eq 1 ]]; then
			debug "Not installing programs, returning..."
			return
		fi
	fi
	
	announce "Installing programs using programInstaller.sh!" "Script is interactive, so pay attention!" "Look at the programLists folder to see what will be installed!"
	sudo ./programInstaller.sh "$programsFile"
}

function displayHelp() {
	# Don't use announce() in here in case script fails from beng unable to source comonFunctions.sh
	echo " "
	echo " Usage: $0 [options] <install_option>"
	echo " "
	#echo " NOTE: Running any install option will check if /usr/share/commonFunctions.sh exists. If not, sudo permission will be requested to install."
	#echo "       Each script will be run after it is installed as well, to verify it is working properly."
	#echo " "
	echo " Install Options:"
	echo "    all                                : Installs all the scripts below"
	echo "    update                             : Installs update script"
	echo "    programs [file]                    : Installs programs using default locations, or provided text-based tab-delimited file"
	#echo "    kali [file]                        : Same as 'programs', but installs from .kaliPrograms.txt by default. Also accepts file input."
	echo "    git                                : Installs git monitoring script and sets up cron job to run at boot"
	echo "    bash                               : Links or sources the .bashrc and .bash_aliases from the git repo"
	echo "    grive                              : Helps create and sync Google Drive using grive2"
	echo "    uninstall                          : Uninstalls any file or settings that may have been installed, highly interactive"
	echo " "
	echo " Options:"
	echo "    -h | --help                        : Displays this help message"
	echo "    -s | --sudo                        : Makes script check for root privileges before running anything"
	echo "    -e | --except <install_option>     : Installs everything except option specified. e.g './INSTALL.sh -e git' "
	echo "                                       : NOTE: Make sure to put -e <install_option> last!" 
	echo "    -n | --no-run                      : Only installs scripts to be used, does not execute scripts"
	echo "    -v | --verbose                     : Displays additional debug info, also found in logfile"
}

function installBash() {
	# Install .bashrc and .bash_aliases for current user
	announce "Installing .bashrc and aliases from the repo for current user!"
	if [[ -e ~/.bashrc ]]; then
		debug ".bashrc present for $USER, backing up and adding source arguments"
		cp ~/.bashrc ~/.bashrc.bak # Creates a backup in case it is needed later
		printf "\n# Added by %s at %s, gets .bashrc from linux-pref git\nsource %s\n" "$0" "$(date)" "$(readlink -f "$(basename .bashrc)")" >>~/.bashrc
	else
		debug "No .bashrc was would, creating one for user!"
		touch ~/.bashrc
		printf "\n# Added by %s at %s, gets .bashrc from linux-pref git\nsource %s\n" "$0" "$(date)" "$(readlink -f "$(basename .bashrc)")" >>~/.bashrc
		#ln -s .bashrc ~/
	fi
	
	# Script will now only source .bash_aliases, that way user can add their own ~/.bash_aliases if desired
	printf "\n# Added by %s at %s, gets aliases from linux-pref git\nsource %s\n" "$0" "$(date)" "$(readlink -f "$(basename .bash_aliases)")" >>~/.bashrc
	
	# Now ask if they want it installed for root
	checkPrivilege
	if [[ $? -ne 0 ]]; then
		getUserAnswer "Installed for current user, would you like to install .bashrc for root as well?"
		case $? in
			0)
			announce "Installing .bashrc from the repo for root user!"
			# If either of these if statements fail, chmod the root directory to 744
			if sudo test -e /root/.bashrc; then
				debug "/root/.bashrc present, backing up and adding source arguments"
				sudo cp /root/.bashrc /root/.bashrc.bak
				printf "\n# Added by %s at %s, gets .bashrc from linux-pref git\nsource %s\n" "$0" "$(date)" "$(readlink -f "$(basename .bashrc)")" | sudo tee -a /root/.bashrc > /dev/null
			else
				#sudo ln -s .bashrc /root/
				debug "/root/.bashrc not found, creating now!"
				sudo touch /root/.bashrc
				printf "\n# Added by %s at %s, gets .bashrc from linux-pref git\nsource %s\n" "$0" "$(date)" "$(readlink -f "$(basename .bashrc)")" | sudo tee -a /root/.bashrc > /dev/null
			fi
			
			# Script will now only source .bash_aliases, that way user can add their own .bash_aliases if desired
			printf "\n# Added by %s at %s, gets aliases from linux-pref git\nsource %s\n" "$0" "$(date)" "$(readlink -f "$(basename .bash_aliases)")" | sudo tee -a /root/.bashrc > /dev/null
			;;
			1)
			debug "Not installing .bashrc for root user..."
			;;
			*)
			debug "Something went wrong in the universe! Please call The Doctor and diagnose!"
			exit 1
			;;
		esac
	else
		debug "User is root, no other installation is needed!"
		announce "NOTE: If you ran script this as root, you will need to run it again as normal user!" "To save time, run: $0 bash!"
	fi
}

function installGrive() {
	if [[ $installOnly -eq 1 ]]; then
		announce "You indicated not to run scripts, but are trying to install grive." "Would you like to run grive as well or just install?"
		getUserAnswer "Answer yes if you want to run grive.sh: "
		if [[ $? -eq 1 ]]; then
			debug "User cose not to run grive"
			#sudo ln -s grive.sh /usr/bin/grive.sh
			return
		fi
	fi
	debug "Installing and setting up Grive..."
	
	# Ask user which directory they would like to use
	export griveSetupDir="$HOME/Grive"
	getUserAnswer "Would you like to change grive directory from: $griveSetupDir ?" griveSetupDir "Please enter the location you would like to use: "
	
	# Check to see if directory exists, mkdir if not
	if [[ -d $griveSetupDir ]]; then
		debug "Directory already exists, moving on!"
	else
		debug "Directory does not exist, creating now!"
		mkdir "$griveSetupDir"
	fi
	
	# Tell user what to do then install grive
	announce "Changing into directory and setting up grive." "Follow instructions given. Once installed, it may take some time to sync all your files."
	cd "$griveSetupDir"
	grive -a
	
	# Finally, setup a cronjob to sync grive every 5 mins
	debug "Creating a cronjob for current user to update grive"
	export griveSync=5
	#sudo ln -s grive.sh /usr/bin/grive.sh
	getUserAnswer "Grive will sync every $griveSync minutes, would you like to change this? " griveSync "Please enter how many mintues between updates you would like: "
	addCronJob $griveSync min "$(pwd)/grive.sh $griveSetupDir"
	
	debug "Grive has been installed!"
}

function uninstallScript() {
	# Remove all the links created
	links=( "/usr/share/commonFunctions.sh" "/usr/bin/update" "/usr/bin/grive.sh" "/usr/bin/gitcheck" "/usr/bin/installPackages" )
	
	debug "Running uninstaller function."
	getUserAnswer "Would you like to uninstall all the program links that have been made?"
	case $? in
		1)
		debug "Not destroying links as per user choice."
		# Don't return, see if they want to uninstall other options
		;;
		0)
		debug "Destroying links."
		announce "Uninstalling links, this will require sudo permission!"
		for link in "${links[@]}"; do
			if sudo test -e "$link" && sudo test -h "$link"; then
				debug "Deleting link located at $link"
				sudo rm "$link"
			else
				debug "$link was either not found, or is not a link. Skipping..."
			fi
		done
		;;
		*)
		debug "Unknown option received"
		exit 1
		;;
	esac
	
	# Offer to fix bash settings
	getUserAnswer "Would you like to restore the backup .bashrc for current user?"
	case $? in
		1)
		debug "Not restoring .bashrc backup - user decision"
		;;
		0)
		debug "Restoring .bashrc from backup"
		rm ~/.bashrc
		cp ~/.bachrc.bak ~/.bashrc # ALWAYS keep the backup
		;;
		*)
		debug "Unknown option received!"
		exit 1
		;;
	esac
	
	# Do the same, but for root
	if ! "$EUID" -eq 0 && test -e /root/.bashrc.bak; then # Only run this if user is NOT root AND backup exists
		getUserAnswer "Would you like to restore .bashrc backup for root user as well?"
		case $? in
			1)
			debug "Not restoring root's .bashrc"
			;;
			0)
			debug "Restoring .bashrc for root user!"
			sudo rm /root/.bashrc
			sudo cp /root/.bashrc.bak /root/.bashrc
			;;
			*)
			debug "Unknown option received!"
			exit 1
			;;
		esac
	fi
	
	# Restore the user's crontab
	getUserAnswer "Would you like to restore the original crontab?"
	case $? in
		1)
		debug "Keeping the current crontab, be careful as links may have been destroyed!"
		;;
		0)
		debug "Restoring the original crontab from backup"
		cp ~/.crontab.bak ~/.crontab.txt # Once again, always keep the backup
		crontab ~/.crontab.txt
		;;
		*)
		debug "Unknown option received!"
		exit 1
		;;
	esac
	
	# Too dangerous to try uninstalling Grive from script
	announce "If you installed Grive, please uninstall manually by deleting folder and crontab entry" "Use rm -rf <Directory> to delete, but use extreme caution!"
}

### Main Script

# This doesn't really need to be here now, but double-checking never hurts!
if [[ ! -f /usr/share/commonFunctions.sh ]]; then
	echo "commonFunctions.sh not linked to /usr/share, fixing now!"
	linkCF
fi

debug "Processing arguments passed to script"
processArgs "$@"

announce "Please stay by your computer, there are interactive parts of this script!" "It moves fast though, so no need to worry about standing by for 20 mins!"

if [[ "$EUID" -eq 0 ]]; then
	announce "This script is meant to be run as local user, not root!" "Script will continue, but CTRL+C now if you want changes to effect current user!"
fi

pathCheck # Checks if /usr/bin is in the user's path, since scripts rely on it

# Backup the crontab, used for uninstallation
crontab -l > ~/.crontab.bak

# Now, run the install mode!
case $runMode in
	update)
	installUpdate
	;;
	programs)
	installPrograms
	;;
	git)
	installGit
	;;
	bash)
	installBash
	;;
	grive)
	installGrive
	;;
	uninstall)
	uninstallScript
	;;
	all)
	installUpdate
	installPrograms
	installGit
	installBash
	installGrive
	;;
	except)
	case $except in
		programs)
		installGit
		installUpdate
		installBash
		installGrive
		;;
		git)
		installPrograms
		installUpdate
		installBash
		installGrive
		;;
		update)
		installPrograms
		installGit
		installBash
		installGrive
		;;
		bash)
		installPrograms
		installGit
		installUpdate
		installGrive
		;;
		grive)
		installPrograms
		installGit
		installUpdate
		installBash
		;;
		*)
		debug "Script has encountered a fatal error! Except has created an exception!"
		exit 1
		;;
	esac
	;;
	*)
	echo "Command not found, please re-run script!"
	;;
esac

# Now install all my necessary and fun commands to user and root .bashrc
if [[ $installOnly -eq 0 ]]; then
	debug "Running setupCommands.sh!"
	./setupCommands.sh
else
	debug "Not running setupCommands.sh because user specified not to"
fi

announce "The following commands cannot be scripted." "Manually install each command as they are given"
while read -r lined;
do
	[[ $lined = \#* || -z $lined ]] && continue
	echo "$lined"
	sleep 5
done < "nonScriptCommands.txt"

debug "Done with script!"

#EOF