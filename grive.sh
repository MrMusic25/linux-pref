#!/bin/bash
#
# grive.sh - Script that will automatically sync grive
#
# Usage: ./grive.sh <grive_dir>
# Specifying a directory is optional, otherwise defaults to $HOME/Grive
#
# crontab line I use is as follows, syncs every 5 minutes and logs according to debug() in commonFunctions.sh
#	*/5 * * * * /home/kyle/grive.sh
#
# Changes:
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
# v1.1.4, 05 Aug. 2016 13:56 PST

### Variables

#logFile="$updatePrefix/logFile.log" # Saves it in the grive directory unless otherwise specified
griveDir="NULL"

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

### Main Script
#logFile="$debugPrefix/logFile.log"
#debug "Starting $0..." $logFile
announce "Preparing to sync with Google Drive using grive!"

# Determine runlevel for more debug
rl=$( runlevel | cut -d ' ' -f2 ) # Determine runlevel for additional info
case $rl in
	0)
	debug "Running script before shutdown!"
	;;
	6)
	debug "Running script before reboot!"
	;;
	*)
	debug "Normal operation mode, no reboot or shutdown detected."
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
	export debugFlag=1
	debug "Directory given does not exist, please fix and setup Grive for this directory!"
	exit 1
fi

# Check if grive is installed
if [[ -z $(which grive) ]]; then
	export debugFlag=1
	debug "Grive is not installed! Please install and setup, and re-run script!"
	exit 2
fi

# Quit early if there is no internet connection
ping -q -c 1 8.8.8.8 &>/dev/null # Redirects to null because I don't want ping info shown, should be headless!
if [[ $? != 0 ]]; then
	export debugFlag=1
	debug "No internet connection, cancelling sync!"
	exit 3
fi

# If checks pass, sync!
announce "Computer and servers ready, now syncronizing!"
cd $griveDir
grive sync &>> $logFile

if [[ $? != 0 ]]; then
	debug "An error occurred with grive, check log for more info!"
	echo "Grive encountered an error while attempting to sync at $(date)! Please view $logFile for more info." | mail -s "grive.sh" $USER
	exit 4
fi

announce "Done syncronizing!" "Please check $logFile for more info!"

debug "Done with script!"
#EOF