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
# v1.2.1, 16 Feb. 2017, 22:07 PST

### Variables

#logFile="$updatePrefix/logFile.log" # Saves it in the grive directory unless otherwise specified
griveDir="NULL"
longName="grive"

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

# Function that checks for conflicts, then notifies the user
conflictList="$( find *Conflict* 2>/dev/null )"
conflictCount="$( echo "$conflictList" | wc -l )" # Quotes are necessary for this to work
if [[ ! -z $conflictList ]]; then
	n=1 # cut does not work with numbers less than 1
	debug "Conflicting files found in Grive folder! Notifying user via mail..."
	echo "Grive has found conflicting files at $(date)! Please view $logFile for more info. Must be fixed manually." | mail -s "grive.sh" $USER
	until [[ $n -gt $conflictCount ]];
	do
		announce "Conflicting files found! Please fix manually!" "File: $(echo $conflictList | cut -d' ' -f $n )"
		debug "Conflicting filename: $(echo $conflictList | cut -d' ' -f $n )"
		((n++))
	done
fi

announce "Done syncronizing!" "Please check $logFile for more info!"

debug "Done with script!"
#EOF