#!/bin/bash
#
# grive.sh - Script that will automatically sync grive
#
# Usage: ./grive.sh <grive_dir> OR ./grive.sh install
# Specifying a directory is optional, otherwise defaults to $HOME/Grive
# install will attempt to install from source
#
# crontab line I use is as follows, syncs every 5 minutes and logs according to debug() in commonFunctions.sh
#	*/5 * * * * /home/kyle/grive.sh
#
# Changes:
# v1.3.0
# - Fixed debug messages
# - Added installation from source
# - Got rid of some stuff from my "bad practices" days (technically these will always change as my skills/knowledge increase)
#
# v1.2.1
# - Added $longName for logging purposes
#
# v1.2.0
# - Script will now check to see if there are Conflict files and notify user
# - Turned mailing back on since this script is run more often as a cron job. Check mail daily for cron notifications!
#
# v1.1.4
# - Made some small functional changes to make script more complaint with the others
#
# v1.1.3
# - Switched to dynamic logging
#
# v1.1.2
# - Fixed a silly typo preventing the script from running
# - Added some announce statements so the user knows if it's running or not
#
# v1.1.1
# - Changed where $logFile gets declared
# - Added a "done" debug statement
#
# v1.1.0
# - Script now uses commonFunctions.sh
# - Main location moved to github to be used with other scripts
# - Overhauled other parts of script to be 'self-friendly' (uses my own functions)
# - Also updated to use $updatePrefix
#
# TODO:
# - Add a "Windows mode"
#   - Remove the .grive folder and store it in $HOME
#   - Restore it before syncing
#   - Warn if folder cannot be found in either place
#   - Prevents Windows version from syncing folder with credentials
#
# v1.3.0, 10 Feb. 2018, 14:58 PST

### Variables

#logFile="$updatePrefix/logFile.log" # Saves it in the grive directory unless otherwise specified
griveDir="NULL"
longName="grive"
shortName="gs" # "Grive script"

### Functions

if [[ -f commonFunctions.sh ]]; then
	source commonFunctions.sh
elif [[ -f /usr/share/commonFunctions.sh ]]; then
	source /usr/share/commonFunctions.sh
else
	echo "commonFunctions.sh could not be located!"
	
	# Comment/uncomment below depending on if script actually uses common functions
	echo "Script will now exit, please put file in same directory as script, or link to /usr/share!"
	exit 1
fi

function installFromSource() {
	debug "INFO: Attempting to install grive2 from source after user confirmation!"
	getUserAnswer "Would you like to attempt to install grive2 from source?"
	case $? in
		0)
		debug "INFO: User confirmed, installing grive2!"
		;;
		*)
		debug "WARN: User chose not to install grive2!"
		return 1
		;;
	esac
	
	# Now, install required programs
	checkRequirements git cmake build-essential libgcrypt11-dev libyajl-dev libboost-all-dev libcurl4-openssl-dev libexpat1-dev libcppunit-dev binutils-dev debhelper zlib1g-dev dpkg-dev pkg-config
	valu=$?
	if [[ "$valu" -gt 4 ]]; then # Arbitrary number to cancel installation
		debug "l2" "FATAL: Too many errors to proceed, cannot install from source! Nuber of errors: $valu"
		exit "$valu"
	elif [[ "$valu" -ne 0 ]]; then
		debug "l2" "ERROR: Multiple errors detected, attempting to install from source anyways"
	else
		debug "l2" "INFO: Required packages installed, moving to compilation"
	fi
	
	# Clone source, compile, and install
	git clone https://github.com/vitalif/grive2.git
	OPWD="$(pwd)"
	cd grive2
	
	# Decide whether to build manually, or with dpkg
	if [[ ! -z $(which dpkg-buildpackage 2>/dev/null) ]]; then
		debug "INFO: Attempting to install with dpkg-buildpackage"
		sudo dpkg-buildpackage -j4
		va=$?
	else
		debug "INFO: Installing manually with cmake!"
		va=0
		
		mkdir build
		cd build
		
		cmake ..
		vaq=$?
		((va+=vaq))
		if [[ "$vaq" -ne 0 ]]; then
			debug "ERROR: cmake exited in error, cannot continue!"
			return "$vaq"
		fi
		
		make -j4
		vaq=$?
		((va+=vaq))
		if [[ "$vaq" -ne 0 ]]; then
			debug "ERROR: make could not compile grive 2!"
			return "$vaq"
		fi
		
		sudo make install
		vaq=$?
		((va+=vaq))
		if [[ "$vaq" -ne 0 ]]; then
			debug "ERROR: grive2 compiled, but could not be installed! Diagnose manually!"
			return "$vaq"
		fi
	fi
	cd "$OPWD"
	return "$va"
}

### Main Script

debug "l3" "INFO: Preparing to sync with Google Drive using grive!"

# Check to see if it's installed
checkRequirements "grive/grive2"
if [[ $? -ne 0 ]]; then
	debug "l2" "ERROR: grive2 not provided by package manager, attempting to install from source!"
	installFromSource
	if [[ "$?" -ne 0 ]]; then
		debug "l2" "FATAL: grive2 could not be installed from source, please fix manually!"
		exit 1
	fi
fi

# Make sure first arg isn't 'install'
if [[ "$1" == install ]]; then
	debug "WARN: User chose to install from source!"
	if [[ ! -z $(which grive 2>/dev/null) ]]; then
		debug "l2" "WARN: grive already installed from another source, exiting..."
		exit 0
	fi
	installFromSource
	exit "$?"
fi

# Determine runlevel for more debug
rl=$( runlevel | cut -d ' ' -f2 ) # Determine runlevel for additional info
case $rl in
	0)
	debug "INFO: Running script before shutdown!"
	;;
	6)
	debug "INFO: Running script before reboot!"
	;;
	*)
	debug "INFO: Normal operation mode, no reboot or shutdown detected."
	;;
esac

# Optionally set directory for grive to use

if [[ -z $1 ]]; then
	export griveDir="$HOME/Grive"
else
	export griveDir="$1"
fi

# Check if directory exists
if [[ ! -d $griveDir ]]; then
	#export debugFlag=1
	debug "l2" "FATAL: Directory given does not exist, please fix and setup Grive for this directory!"
	exit 1
fi

# Check if grive is installed
#if [[ -z $(which grive) ]]; then
#	export debugFlag=1
#	debug "Grive is not installed! Please install and setup, and re-run script!"
#	exit 2
#fi

# Quit early if there is no internet connection
ping -q -c 1 8.8.8.8 &>/dev/null # Redirects to null because I don't want ping info shown, should be headless!
if [[ $? != 0 ]]; then
	#export debugFlag=1
	debug "ERROR: No internet connection, cancelling sync!"
	exit 3
fi

# If checks pass, sync!
debug "INFO: Computer and servers ready, now syncronizing!"
OPWD="$(pwd)"
cd "$griveDir"
grive sync &>> "$logFile"
val=$?

if [[ $val != 0 ]]; then
	debug "ERROR: An error occurred with grive, check log for more info! Return value: $val"
	#echo "Grive encountered an error while attempting to sync at $(date)! Please view $logFile for more info." | mail -s "grive.sh" $USER
	exit "$val"
fi

# Function that checks for conflicts, then notifies the user
conflictList="$( find *Conflict* 2>/dev/null )"
conflictCount="$( echo "$conflictList" | wc -l )" # Quotes are necessary for this to work
if [[ ! -z $conflictList ]]; then
	n=1 # cut does not work with numbers less than 1
	debug "WARN: Conflicting files found in Grive folder! Notifying user via mail..."
	#echo "Grive has found conflicting files at $(date)! Please view $logFile for more info. Must be fixed manually." | mail -s "grive.sh" $USER
	until [[ $n -gt $conflictCount ]];
	do
		#announce "Conflicting files found! Please fix manually!" "File: $(echo $conflictList | cut -d' ' -f $n )"
		debug "l2" "ERROR: Conflicting file found: $(echo $conflictList | cut -d' ' -f $n )"
		((n++))
	done
fi

debug "l2" "INFO: Done syncing with grive!"

cd "$OPWD"
#debug "Done with script!"
#EOF