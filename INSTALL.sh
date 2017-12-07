#!/bin/bash
#
# INSTALL.sh - A script meant to automatically install and setup my personal favorite options
# Usage: ./INSTALL.sh [options] <install_option>
# Run with the -h|--help option to see full list of install options (or look at displayHelp())
#
# Changes:
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
# v2.0.1, 06 Dec. 2017, 22:50 PST

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
  uninstall                           : Uninstalls all scripts and changes listed in ~/.lpChanges.conf

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
	pm i programLists
	
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
	
	# Finally, ask if user wants to setup a cron job to update repos
	getUserAnswer "Would you like to periodically update all Git directories?" gitTime "How many minutes would you like between updates? (0-60)"
	if [[ $? -eq 0 ]]; then
		addCronJob "$gitTime" min "/usr/bin/gm --daemon" # Added as current user
		debug "l1" "INFO: Cron job added, will check every $gitTime minutes."
	else
		debug "l2" "WARN: Not installing cron job! Please run manually periodically, or setup your own cron job!"
	fi
	
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
	printf "# Locations of .bashrc and .bash_aliases as added by linux-pref on %s\nsource %s\nsource %s\n" "$(date)" "$(pwd)/.bashrc" "$(pwd)/.bash_aliases" >> "$HOME"/.lp
	
	printf "# Added by linux-pref to import .bashrc and .bash_aliases from git repo\nif [[ -f .lp ]]; then\n   source .lp\nfi\n" >> "$HOME"/.bashrc
	
	if [[ -d /etc/skel ]]; then
		debug "l1" "ERROR: skel directory not found! Unable to install bash for future users! Continuing..."
	else
		getUserAnswer "n" "Would you like to install bash for future users through the skel directory?"
		case $? in
			0)
			debug "l1" "INFO: Installing bash to skel directory as user indicated"
			debug "l2" "WARN: Installing bash to skel directory will require sudo premission!"
			sudo touch /etc/skel/.lp
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
	debug "l3" "ERROR: Grive2 installation not ready yet, check back for updates!"
	return 0
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
	for i in $(seq 0 1 $commaCount); # char count of commas in string; hopefully 0 doesn't cause it to fail
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
	for i in $(seq 0 1 $commaCount); # char count of commas in string; hopefully 0 doesn't cause it to fail
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