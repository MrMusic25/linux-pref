#!/bin/bash
#
# INSTALL.sh - A script meant to automatically install and setup my personal favorite options
# Usage: ./INSTALL.sh [options] <install_option>
# Run with the -h|--help option to see full list of install options (or look at displayHelp())
#
# Changes:
# v2.1.0
# - Fixed a problem keeping skel installation from working in installBash()
# - Added backup function to installBash() for user, root, and skel
# - Made rmLink() to make removing links at the end of uninstall() easier
# - Finished writing uninstall()
# - Fixed issue with cut for -o|--only and -e|--except
#
# v2.0.3
# - More work on uninstall()
#
# v2.0.2
# - Got rid of adding cronjob in this script for gm; already has that implemented
# - Started work on uninstall()
#
# v2.0.1
# - Added all the installation functions, wrote them all (read: wrote one, then copy+pasted the rest)
# - Added folder check
# - All functions except grive ready for testing
# - Backup for crontab enabled
# - No need to backup .bashrc now because of new sourcing method
#
# v2.0.0
# - Started work on re-written, more efficient install script
# - Use 0b664c6 to get original script, most of it was erased after that commit
# - Wrote displayHelp and supporting variables/processArgs() fills
# - Added a monstorosity of a switch to decide which options to run
#
# TODO:
#
# v2.1.0, 10 Feb. 2018, 16:35 PST

### Variables

longName="INSTALL" #shortName and longName used for logging
shortName="iS" # installScript
specific="unset" # Used to tell if except/only mode is on
sudoCheck=0 # Tells script whether to ignore sudo warning
run=0 # Indicates whether or not scripts will be run by default
ask=0 # Whether or not user will be asked before running each script

### Functions

# Used to link commonFunctions.sh to /usr/share, in case it is not there already
# This version only used in the installer script, as it is usually the first thing run from the repo
function linkCF() {
	if [[ ! -f commonFunctions.sh ]]; then
		echo "ERROR: commonFunctions.sh is somehow not available, please correct and re-run!"
		echo "Please cd into the directoy containing $0 and commonFunctions.sh!"
		exit 1
	fi
	
	if [[ "$EUID" -ne 0 ]]; then
		echo "WARN: Linking to /usr/share requires root permissions, please login"
		sudo ln -s "$(pwd)"/commonFunctions.sh /usr/share/commonFunctions.sh
		sudo ln -s "$(pwd)"/packageManagerCF.sh /usr/share/packageManagerCF.sh
	else
		echo "INFO: Linking to commonFunctions.sh to /usr/share!"
		sudo ln -s "$(pwd)"/commonFunctions.sh /usr/share/commonFunctions.sh
		sudo ln -s "$(pwd)"/packageManagerCF.sh /usr/share/packageManagerCF.sh
	fi
}

if [[ -f /usr/share/commonFunctions.sh ]]; then
	source /usr/share/commonFunctions.sh
elif [[ -f commonFunctions.sh ]]; then
	source commonFunctions.sh
	linkCF
else
	echo "commonFunctions.sh could not be located!"
	echo "Script will now exit, please put file in same directory as script, or link to /usr/share!"
	exit 1
fi

function displayHelp() {
# The following will read all text between the words 'helpVar' into the variable $helpVar
# The echo at the end will output it, exactly as shown, to the user
read -d '' helpVar <<"endHelp"

INSTALL.sh - A script that sets up a new computer with other scripts and settings from mrmusic25/linux-pref

Usage: ./INSTALL.sh [options] <install_option>
       ./INSTALL.sh [options] -e <iOption>,[iOption]
       ./INSTALL.sh [options] -o <iOption>,[iOption]

Options:
  -h | --help                         : Display this help message and exit
  -v | --verbose                      : Prints verbose debug information. MUST be the first argument!
  -s | --sudo                         : Ignores sudo-check (use this option if root is only user being used on system)
  -n | --no-run                       : Only setup links, don't run any of the scripts
  -a | --ask                          : Ask before running each script
  -e | --except <iOption>,[iOption]   : Assumes install option 'all'. See note below for usage.
  -o | --only <iOption>,[iOption]     : Only installs selected options; similar to -e|--except

Install Options (iOptions):
  all                                 : Installs all the below options/scripts
  pm | packageManager                 : Universal package manager script
  programs                            : Installs programs from the local programLists folder
  gm | gitManager                     : Git management and update script
  bash                                : Installs .bashrc and .bash_aliases for selected users (will be asked)
  grive                               : Installs grive2, and the grive2 management script
  uninstall                           : Uninstalls all scripts, links, and files

For --except and --only options, specify programs you don't (or do) want installed in comma delimited format.
  e.g. ./INSTALL.sh -e pm,bash   <-- This command will install everything but pm and bash
       ./INSTALL.sh -o pm,bash   <-- This command will only install pm and bash, nothing else
If your package manager does not have grive2 by default, it will be installed from the repo vitalif/grive2

endHelp
echo "$helpVar"
}

function processArgs() {
	# displayHelp and exit if there is less than the required number of arguments
	# Remember to change this as your requirements change!
	if [[ $# -lt 1 ]]; then
		debug "l2" "ERROR: No arguments given! Please fix and re-run"
		displayHelp
		exit 1
	fi
	
	# This is an example of how most of my argument processors look
	# Psuedo-code: until condition is met, change values based on input; shift variable, then repeat
	while [[ $loopFlag -eq 0 ]]; do
		key="$1"
			
		case "$key" in
			-h|--help)
			displayHelp
			exit 0
			;;
			-v|--verbose)
			debugFlag=1
			debugLevel=2
			debug "l2" "WARN: Vebose mode enabled! In the future, however, please make -v|--verbose the first argument!"
			;;
			-s|--sudo)
			sudoCheck=1
			;;
			-n|--no-run)
			run=1
			debug "l1" "INFO: User has indicated not to run scripts"
			;;
			-a|--ask)
			ask=1
			debug "l1" "INFO: User will be asked before each script is run"
			;;
			-e|--except)
			if [[ -z $2 ]]; then
				debug "l2" "ERROR: No arguments given with $key, please fix and re-run!"
				exit 1
			fi
			specific="except"
			loopFlag=1 # Assume the rest is install options and continue
			;;
			-o|--only)
			if [[ -z $2 ]]; then
				debug "l2" "ERROR: No arguments given with $key, please fix and re-run!"
				exit 1
			fi
			specific="only"
			loopFlag=1
			;;
			#--dry-run)
			#dryRun="set" # Oh, a secret argument! When run, script will only output anticipated changes/debug messages without making changes
			#debug "l1" "WARN: Doing a dry-run, nothing will be changed!"
			#;;
			*)
			# If it is not an option, assume it is the run mode and continue
			loopFlag=1
			;;
		esac
		shift
	done
}

function installPM() {
	debug "l1" "INFO: Installing packageManager.sh and related functions!"
	
	# Make sure script is here
	if [[ ! -f packageManager.sh || ! -f packageManagerCF.sh ]]; then
		debug "l2" "FATAL: packageManager.sh or packageManagerCF.sh could not be found! Could not be successfully installed!"
		return 1
	fi
	
	dynamicLinker "$(pwd)/packageManager.sh" /usr/bin
	dynamicLinker "$(pwd)/packageManagerCF.sh" /usr/share
	
	# Verify links exist
	if [[ -e /usr/bin/pm && -e /usr/share/packageManager.sh ]]; then
		debug "l1" "INFO: pm.sh and pmCF.sh successfully installed! Moving on..."
	else
		debug "l2" "ERROR: Links not found, terminating packageManager installation..."
		return 1
	fi
	
	if [[ $run -ne 0 ]]; then
		debug "l1" "WARN: User indicated not to run scripts! Moving on..."
	elif [[ $ask -ne 0 ]]; then
		debug "l1" "WARN: User has chosen to be asked about running scripts, asking for confirmation..."
		getUserAnswer "pm.sh has been installed, would you like to update your computer now?"
		case $? in
			0) #true
			debug "l1" "INFO: User indicated to run pm.sh!"
			# continue with function
			;;
			1)
			debug "l1" "INFO: User chose not to run script, returning!"
			return 0 # technically a success
			;;
		esac
	fi
	
	# If you made it this far, script is meant to be run
	debug "l2" "WARN: Now running pm.sh and upgrading current system!"
	pm fu
	
	debug "l1" "INFO: Done installing and running pm.sh!"
	return 0
}

function installPrograms() {
	# Check to see if function should even be run
	if [[ $run -ne 0 || $ask -ne 0 ]]; then # Two birds, one stone
		debug "l2" "ERROR: User asked not to run scripts, but indicated to install programs!"
		getUserAnswer "n" "Would you like to install programs anyways?"
		case $? in
			0)
			true # debug message below, no need to duplicate it
			;;
			*)
			debug "l2" "INFO: User indicated not to install programs, returning..."
			return 0
			;;
		esac
	fi
	
	# Making it this far means user wants programs installed
	debug "l1" "INFO: Installing programs in programLists/ folder!"
	pm i programLists/
	
	debug "l1" "INFO: Done installing programs!"
}

function installGit() {
	debug "l1" "INFO: Installing gitManager.sh and related functions!"
	
	# Make sure script is here
	if [[ ! -f gitManager.sh ]]; then
		debug "l2" "FATAL: gitManager.sh could not be found! Could not be successfully installed!"
		return 1
	fi
	
	dynamicLinker "$(pwd)/gitManager.sh" /usr/bin
	
	# Verify link exists
	if [[ -e /usr/bin/gm ]]; then
		debug "l1" "INFO: gm.sh and pmCF.sh successfully installed! Moving on..."
	else
		debug "l2" "ERROR: Link not found, terminating gitManager installation..."
		return 1
	fi
	
	if [[ $run -ne 0 ]]; then
		debug "l1" "WARN: User indicated not to run scripts! Moving on..."
	elif [[ $ask -ne 0 ]]; then
		debug "l1" "WARN: User has chosen to be asked about running scripts, asking for confirmation..."
		getUserAnswer "gm.sh has been installed, would you like to update your computer now?"
		case $? in
			0) #true
			debug "l1" "INFO: User indicated to run gm.sh!"
			# continue with function
			;;
			1)
			debug "l1" "INFO: User chose not to run script, returning!"
			return 0 # technically a success
			;;
		esac
	fi
	
	# If you made it this far, script is meant to be run
	debug "l2" "WARN: Now running gm.sh in setup mode and adding repo to update list!"
	gm -i
	gm -d --add $(pwd)
	
	debug "l1" "INFO: Done installing and running gm.sh!"
	return 0
}

function installBash() {
	# No run not affected here, only check if ask is set
	if [[ $ask -ne 0 ]]; then
		debug "l2" "INFO: User indicated to be asked before running scripts, asking before installing bash"
		getUserAnswer "Would you like to install .bashrc and .bash_aliases?"
		case $? in
			0)
			debug "l1" "INFO: Installing .bashrc and .bash_aliases per user's choice (will confirm for root)"
			;;
			*)
			debug "l1" "INFO: User chose not to install bash"
			return 0
			;;
		esac
	fi
	
	# Proceed with installation
	# After making sure some stuff exists first
	if [[ ! -e $HOME/.bashrc ]]; then
		touch .bashrc
	fi
	
	touch "$HOME"/.lp # Got smart, this make it so link sent to .bashrc are no longer deleted upon uninstallation
	cp "$HOME"/.bashrc "$HOME"/.bashrc.bak # Gotta do those backups
	printf "# Locations of .bashrc and .bash_aliases as added by linux-pref on %s\nsource %s\nsource %s\n" "$(date)" "$(pwd)/.bashrc" "$(pwd)/.bash_aliases" >> "$HOME"/.lp
	
	printf "# Added by linux-pref to import .bashrc and .bash_aliases from git repo\nif [[ -f .lp ]]; then\n   source .lp\nfi\n" >> "$HOME"/.bashrc
	
	if [[ ! -d /etc/skel ]]; then
		debug "l1" "ERROR: skel directory not found! Unable to install bash for future users! Continuing..."
	else
		getUserAnswer "n" "Would you like to install bash for future users through the skel directory?"
		case $? in
			0)
			debug "l1" "INFO: Installing bash to skel directory as user indicated"
			debug "l2" "WARN: Installing bash to skel directory will require sudo premission!"
			sudo touch /etc/skel/.lp
			sudo cp /etc/skel/.bashrc /etc/skel/.bashrc.bak 2>/dev/null # Suppress warning if .bashrc doesn't exist, like on some systems
			printf "# Locations of .bashrc and .bash_aliases as added by linux-pref on %s\nsource %s\nsource %s\n" "$(date)" "$(pwd)/.bashrc" "$(pwd)/.bash_aliases" | sudo tee -a /etc/skel/.lp > /dev/null
			printf "# Added by linux-pref to import .bashrc and .bash_aliases from git repo\nif [[ -f .lp ]]; then\n   source .lp\nfi\n" | sudo tee -a /etc/skel/.bashrc > /dev/null
			;;
			*)
			debug "l1" "INFO: Skipping installation to skel directory..."
			;;
		esac
	fi
	
	if [[ $sudoCheck -eq 0 ]]; then
		debug "l1" "INFO: Asking to install bash for root user"
		getUserAnswer "Would you like to install .bashrc and aliases for root user?"
		case $? in
			0)
			debug "l1" "INFO: Installing .bashrc and .bash_aliases for root user"
			debug "l2" "WARN: Installing bash for root will require sudo premission!"
			sudo touch /root/.lp
			sudo cp /root/.bashrc.bak 2>/dev/null # Suppressed for same reason as skel
			printf "# Locations of .bashrc and .bash_aliases as added by linux-pref on %s\nsource %s\nsource %s\n" "$(date)" "$(pwd)/.bashrc" "$(pwd)/.bash_aliases" | sudo tee -a /root/.lp > /dev/null
			printf "# Added by linux-pref to import .bashrc and .bash_aliases from git repo\nif [[ -f .lp ]]; then\n   source .lp\nfi\n" | sudo tee -a /root/.bashrc > /dev/null
			;;
			*)
			debug "l1" "WARN: User indicated not to install bash for root user!"
			;;
		esac
	else
		debug "l1" "WARN: sudoCheck disabled, assuming root user has already been installed and continuing!"
	fi
	return 0
}

function installGrive() {
	debug "INFO: Installing grive"
	dynamicLinker grive.sh /usr/bin
	gs install
	if [[ "$?" -ne 0 ]]; then
		debug "l2" "ERROR: A problem occurred while installing grive 2! Might be already installed..."
		getUserAnswer "n" "Would you like to continue setting up grive despite error?"
		case $? in
			0)
			debug "INFO: Continuing grive setup at user request"
			;;
			*)
			debug "l2" "FATAL: Grive installation failed! Moving on..."
			return 1
			;;
		esac
	fi
	
	# Make grive folder and set it up
	installDir=$HOME/Grive
	announce "NOTE: By default, grive installs to \$HOME/Grive" "You may change this to a directory of your choosing instead"
	getUserAnswer "Would you like to use the default directory?" installDir "Pleaset enter full directory path now"
	case $? in
		0)
		debug "INFO: Using default directory for Grive"
		;;
		*)
		debug "WARN: Using user specified directory instead of default!"
		;;
	esac
	
	if [[ "$run" -ne 0 ]]; then
		debug "WARN: User chose not to run script, exiting after installation!"
		return 0
	fi
	
	if [[ -e "$installDir" ]]; then
		debug "l2" "FATAL: $installDir already exists! Aborting grive installation, please proceed manually!"
		return 1
	fi
	
	mkdir "$installDir"
	if [[ "$?" -ne 0 ]]; then
		debug "l2" "ERROR: Could not create grive directory! Does user have permission? Please fix manually!"
		return 1
	fi
	
	OOPWD="$(pwd)"
	cd "$installDir"
	announce "NOTE: This next step will take a while, depending on the size of your Google Drive" "Authenticating requires use of a web browser, the next step!"
	grive -a
	
	# Now, setup a cron job
	gUpdateTime=5
	getUserAnswer "Would you like to setup a cronjob to automatically update grive?" gUpdateTime "How often, in minutes, would you like to update? (Default is 5)"
	case $? in
		0)
		debug "INFO: Setting up cronjob for grive at user request"
		addCronJob "$gUpdateTime" min "/usr/bin/gs $HOME/Grive"
		;;
		*)
		debug "INFO: Not setting up cronjob for grive"
		;;
	esac
	
	debug "INFO: Done setting up grive!"
	return 0
}

function uninstall() {
	debug "l2" "WARN: Uninstalling linux-pref from the system!"
	announce "NOTE: EVERYTHING will be uninstalled after running this!" "If you only want a couple things installed, you will have to reinstall them manually" "Press CTRL+C now to stop uninstallation"
	
	# Restore crontab (and grive)
	if [[ ! -e "$HOME"/.crontab.bak ]]; then
		debug "l2" "ERROR: No crontab backup found! Please fix cron manually using `crontab -e`!"
	else
		debug "INFO: Attempting to restore crontab from backup..."
		announce "Be careful with this step! Cron jobs could be messed up!" "Script will attempt to restore original crontab" "If you have custom jobs, please fix manually"
		getUserAnswer "Would you like to edit cron manually? (Hint: No will restore backup)"
		if [[ $? -eq 0 ]]; then
			debug "INFO: User has decided to manually edit crontab"
			announce "As you wish, manually editing crontab!" "Remove all linux-pref scripts from the list, or comment them out!"
			crontab -e
		else
			debug "WARN: User has been warned, now attempting to restore original crontab"
			crontab "$HOME"/.crontab.bak
			val="$?"
			if [[ $val -ne 0 ]]; then
				debug "l2" "ERROR: Crontab restoration was not successful! Error code: $val"
			fi
		fi
	fi
	
	# Can't think of a good way to uninstall programs, so just warn the user and move on
	debug "l3" "WARN: Script will not uninstall programs from package manager, please do so manually"
	
	# Remove grive dir
	if [[ -f "$HOME"/Grive ]]; then
		debug "INFO: Grive found in default location, asking user to delete"
		getUserAnswer "Grive found in default location, would you like to remove folder?"
		if [[ $? -eq 0 ]]; then
			debug "WARN: Attempting to delete Grive at $HOME/Grive!"
			rm -rf "$HOME"/Grive
		else
			debug "INFO: User chose not to delete Grive folder, moving on!"
		fi
	else
		debug "WARN: Grive not found in default location!"
		announce "WARN: Grive not found in default directory, or is not installed!" "Please remove directory manually" "This message can be ignored if grive is not installed"
	fi
	
	# Ask to delete directories in .gitDirectoryList, if it exists
	if [[ -e "$HOME"/.gitDirectoryList ]]; then
		debug "INFO: .gitDirectoryList found, asking user if they would like to remove repos"
		getUserAnswer "Would you like to delete the repositories listed in .gitDirectoryList? (NOTE: Interactively)"
		if [[ $? -eq 0 ]]; then
			debug "WARN: Deleting git repos"
			while read dir; do
				getUserAnswer "Would you like to remove the repo at: $dir ?"
				if [[ $? -eq 0 ]]; then
					debug "WARN: Removing git repo $dir at user request"
					rm -v -rf "$dir"
					if [[ $? -ne 0 ]]; then
						debug "l2" "ERROR: Directory at $dir could not be removed, please do so manually!"
					fi
				fi
			done<"$HOME"/.gitDirectoryList
			debug "INFO: Now deleting .gitDirectoryList as well"
			rm -v "$HOME"/.gitDirectoryList
		else
			debug "WARN: Not deleting repos, just deleting directory list!"
			rm -v "$HOME"/.gitDirectoryList
		fi
	else
		debug "l2" "WARN: .gitDirectoryList not found, assuming it is not installed. Moving on..."
	fi
	
	# Ask to restore .bashrc.bak, if it exists
	if [[ -e "$HOME"/.bashrc.bak ]]; then
		debug "INFO: .bashrc.bak found, asking user to restore"
		announce ".bashrc.bak was found! Script will try to restore it!" "WARN: This could get rid of other aliases and custom functions!" "You can choose not to restore with no consequences or errors"
		getUserAnswer "Would you like script to restore .bashrc.bak?"
		if [[ $? -eq 0 ]]; then
			debug "WARN: User chose to restore .bashrc, attempting to do so!"
			rm -v "$HOME"/.bashrc
			mv -v "$HOME"/.bashrc.bak "$HOME"/.bashrc
		else
			debug "l2" "INFO: User chose not to restore .bashrc, deleting .bashrc.bak"
			rm -v "$HOME"/.bashrc.bak
		fi
	else
		debug "l2" "WARN: .bashrc backup not found! Cannot restore!"
	fi

	# Remove .lp ifpresent. no need to confirm with user
	debug "INFO: Removing .lp if it exists"
	rm "$HOME"/.lp 2>/dev/null # Didn't feel like writing an if statement for this
	
	# Restore /etc/skel
	debug "l2" "INFO: Attempting to restore bash for root and skel directory, requiring sudo permissions!"
	if [[ -e /etc/skel/.lp ]]; then
		debug "l2" "WARN: .lp found in skel directory, removing!"
		sudo rm -v /etc/skel/.lp
	fi
	if [[ -e /etc/skel/.bashrc.bak ]]; then
		debug "l2" "WARN: .bashrc backup found in /etc/skel, restoring..."
		sudo rm -v /etc/skel/.bashrc
		sudo mv -v /etc/skel/.bashrc.bak /etc/skel/.bashrc
	fi
	
	# Do the same for root. Little more complicated as it requires sudo
	if [[ ! -z $(sudo cat /root/.lp) ]]; then
		debug "l2" "WARN: .lp found in /root, attempting to uninstall"
		sudo rm -v /root/.lp
	fi
	if [[ ! -z $(sudo cat /root/.bashrc.bak) ]]; then
		debug "l2" "WARN: .bashrc backup found in /root, restoring..."
		sudo rm -v /root/.bashrc 2>/dev/null # No reason it shouldn't be there, but suppress error just in case
		sudo mv -v /root/.bashrc.bak /root/.bashrc
	else
		debug "l2" "ERROR: No backup found for root! Shouldn't cause any issues, but beware!"
	fi
	
	# Offer to remove .logs directories
	debug "INFO: Offering to remove logs directory"
	announce "Script will now offer to remove log directories" "NOTE: There will be no more logged debug statements until end of script!" "Only thing left to do is to remove symbolic links, anyways"
	getUserAnswer "Would you like to remove log directories for user and root?"
	if [[ $? -eq 0 ]]; then
		echo "INFO: Removing log directories!"
		rm -rf "$HOME"/.logs
		sudo rm -rf "$HOME"/.logs 2>/dev/null
	fi
	# I promised no more debug after that point, so no logging that the user chose not to remove directory
	
	# Finally, remove all symlinks
	if [[ ! -e "$HOME"/.linkList ]]; then
		echo "ERROR: .linkList not found, cannot unlink! Please do so manually with the following link:"
		echo "  https://unix.stackexchange.com/questions/34248/how-can-i-find-broken-symlinks"
		printf "\nSearch /usr/bin and /usr/share for broken links. Common install point.\n"
	else
		while read line; do
			rmLink "$line"
		done<"$HOME"/.linkList
		rm -v "$HOME"/.linkList
	fi
	echo "Done uninstalling everything, thanks for using my scripts! Hope to see you again soon!"
	exit 0
}

# Accepts input of a link. Returns 0 for success, 1 for error. No debug, since it runs at the end of uninstall()
function rmLink() {
	if [[ -z $1 ]]; then
		echo "ERROR: Incorrect call for rmLink()!"
		return 1
	fi
	
	if [[ ! -L "$1" ]]; then
		echo "ERROR: $1 is not a symbolic link! Not removing"
		return 1
	else
		echo "WARN: Removing symbolic link at $1"
		sudo rm -v "$1"
		return $?
	fi
	return 0 # Not necessary, but I like to be consistent
}

### Main Script

processArgs "$@"

# First, make sure user isn't sudo
if [[ $EUID -eq 0 ]]; then
	if [[ $sudoCheck -ne 0 ]]; then
		debug "l1" "WARN: Ignoring sudo check, continuing with script as root!"
	else
		announce "This script is meant to be run as a normal user, not root!" "Please run the script without sudo." "Or, if root is the only user, run with the -s|--sudo option!"
		debug "l1" "INFO: Warned user about using script as sudo, exiting..."
		exit 1
	fi
fi

# Check to make sure pwd is git directory
if [[ "$(pwd)" != *linux-pref ]]; then
	debug "l2" "FATAL: Current directory is incorrect! Please re-run script inside linux-pref folder! Exiting..."
	exit 1
fi

# Verify home dir
if [[ -z $HOME ]]; then
		HOME="$(echo ~/)"
fi

# Check if computer is Raspberry Pi
if [[ -e "/usr/bin/raspi-config" ]]; then
		announce "Raspberry Pi detected!" "If this is the first time being run, please make sure locale is correct!" "Also make sure SSH is enabled in advanced options!"
		getUserAnswer "Would you like to run raspi-config before running the rest of the script?"
		case $? in
			0)
			debug "l1" "INFO: User chose to run raspi-config"
			sudo raspi-config
			;;
			*)
			debug "l1" "INFO: User chose not to run raspi-config!"
			;;
		esac
fi

# Backup crontab, just in case it is used
if [[ ! -e "$HOME"/.crontab.bak ]]; then
	debug "l2" "INFO: Creating backup of current user's crontab at $HOME/crontab.bak"
	crontab -l > "$HOME"/.crontab.bak
else
	debug "l2" "ERROR: Backup of crontab already exists at $HOME/crontab.bak"
	getUserAnswer "n" "Would you like to overwrite the backup?"
	case $? in
		0)
		debug "l1" "WARN: Overwriting crontab backup at user's request"
		crontab -l > "$HOME"/.crontab.bak
		;;
		*)
		debug "l1" "INFO: Skipping crontab backup, as one already exists"
		;;
	esac
fi

# Now, time to decide what to run
# Scripts to install/run are decided by an array with the following values
# Program:    pm  programs  gm  bash  grive 
# Location:  [0]    [1]    [2]  [3]    [4]
declare -a iOptions
for i in {0..4}
do
	iOptions[$i]=0 # Initialize array, nothing by default
done

case $specific in
	except)
	for i in {0..4}
	do
		iOptions[$i]=1
	done
	commaCount="$(awk -F',' '{print NF-1}' <<< "$1")"
	((commaCount++)) # cut cannot start at zero, so increment
	for i in $(seq 1 1 $commaCount); # char count of commas in string; hopefully 0 doesn't cause it to fail
	do
		iOpt="$(echo "$1" | cut -d',' -f $i)" # By this point, $1 should be the only arg left
		case "$iOpt" in
			all)
			debug "l2" "FATAL: iOption all is not compatible with -e|--except! Please fix and re-run!"
			exit 1
			;;
			pm|pac*)
			iOptions[0]=0
			;;
			pr*)
			iOptions[1]=0
			;;
			gm|gi*)
			iOptions[2]=0
			;;
			ba*)
			iOptions[3]=0
			;;
			gr*)
			iOptions[4]=0
			;;
			uni*)
			debug "l2" "FATAL: iOption uninstall is not compatible with -e|--except! Please fix and re-run!"
			exit 1
			;;
			*)
			debug "l2" "ERROR: $iOpt is not a valid install option. Attempting to continue..."
			;;
		esac
	done
	;;
	only)
	commaCount="$(awk -F',' '{print NF-1}' <<< "$1")"
	((commaCount++))
	for i in $(seq 1 1 $commaCount); # char count of commas in string; hopefully 0 doesn't cause it to fail
	do
		iOpt="$(echo "$1" | cut -d',' -f $i)"
		case "$iOpt" in
			all)
			debug "l2" "FATAL: iOption all is not compatible with -o|--only! Please fix and re-run!"
			exit 1
			;;
			pm|pac*)
			iOptions[0]=1
			;;
			pr*)
			iOptions[1]=1
			;;
			gm|gi*)
			iOptions[2]=1
			;;
			ba*)
			iOptions[3]=1
			;;
			gr*)
			iOptions[4]=1
			;;
			uni*)
			debug "l2" "FATAL: iOption uninstall is not compatible with -o|--only! Please fix and re-run!"
			exit 1
			;;
			*)
			debug "l2" "ERROR: $iOpt is not a valid install option. Attempting to continue..."
			;;
		esac
	done
	;;
	*)
	case "$1" in
		all)
		for i in {0..4}
		do
			iOptions[$i]=1
		done
		;;
		pm|pac*)
		iOptions[0]=1
		;;
		pr*)
		iOptions[1]=1
		;;
		gm|gi*)
		iOptions[2]=1
		;;
		ba*)
		iOptions[3]=1
		;;
		gr*)
		iOptions[4]=1
		;;
		uni*)
		debug "l2" "FATAL: iOption uninstall is not compatible with -o|--only! Please fix and re-run!"
		exit 1
		;;
		*)
		debug "l2" "ERROR: $iOpt is not a valid install option. Attempting to continue..."
		;;
	esac
	;;
esac

# Now, run all the specified options
announce "Now installing selected options!" "You will be asked for permission to link to /usr/share and /usr/bin" "Please provide password when/if prompted!"
for i in {0..4}; # Remember to change this if more options are added
do
	if [[ ${iOptions[$i]} -ne 0 ]]; then
		case $i in
			0)
			installPM
			;;
			1)
			installPrograms
			;;
			2)
			installGit
			;;
			3)
			installBash
			;;
			4)
			installGrive
			;;
			*)
			debug "l2" "ERROR: Invalid sequence during installation! Attempting to continue..."
			;;
		esac
	fi
done

#EOF