#!/bin/bash
#
# gitCheck.sh - Script that will pull from a git repo every X minutes
#
# Usage: ./gitCheck.sh <working_git_directory>
#
# Recommended crontab entry:
#      */15 * * * * /home/$USER/linux-pref/gitCheck.sh /home/$USER/linux-pref/
#                                                       `---> This can be replaced with any git directory to be synced
# Syncs every 15 mins. Becareful which user script gets run as, should be owner of folder, or have read/write/execute access!
#
# Relies on the .git folder in the directory to be able to pull, therefore must be setup beforehand!
#
# Changes:
# v1.0.5
# - Script now does more auto-configuration
#
# v1.0.4
# - Got rid of extra statements for debug in case it breaks script like grive.sh. Seems to be working now.
#
# v1.0.3
# - Switched to dynamic logging
#
# v1.0.2
# - Changed where $logFile is declared
# - Added end debug statement
#
# v1.0.1
# - Script now uses $debugPrefix
#
# v1.0.5, 05 Aug. 2016 13:36 PST

### Variables

sleepTime=900 # Time in seconds to wait until going through loop again. 900 seconds (15 minutes) by default
directory="NULL"
#logFile="$debugPrefix/logFile.log"

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
debug "Starting $0 ..."
# I was reminded why comments are important when I looked upon this codebock the next day and did not understand it...
# Anyways lol, this block is used to determine if directory is valid and git-ready
if [[ -d "$1" ]]; then
	if [[ -d "$1/.git" ]]; then
		export directory="$1"
	else
		export debugFlag=1
		debug "Directory exists, but has not been initilized by git, please fix and re-run!"
		exit 1
	fi
elif [[ -z $1 ]]; then
	debug "Script was run, but no arguments given. Need at least one directory argument."
	announce "ERROR: No directory given!" "Please give a directory as an argument and re-run!" "e.g. $0 /home/user/git-directory/ "
	exit 1
else
	export debugFlag=1
	debug "Path given is invalid, please fix and re-run!"
	exit 1
fi

announce "Preparing to sync with git directory $directory !"

# Next, check to see if git credentials will be saved
# Realized halfway through writing this the script will not be pushing, only pulling. Still useful as I forget things like this
if [[ -e ~/.git-credentials || -e ~/.git-credential-cache ]]; then
	debug "Git has already been setup, moving to next step."
else
	announce "Git has not been setup yet!" "This script will now help configure git for ease of use."
	getUserAnswer "Would you like to setup your email and display name for git now?"
	if [[ $? -eq 0 ]]; then
		debug "Prompting for user's info..."
		read -p "Please enter the email you would like to use: " varEmail
		git config --global user.email "$varEmail"
		read -p "Please enter the display name you would like to use: " varUser
		git config --global user.name "$varUser"
		debug "Git has been configured for user $varUser with email $varEmail"
	fi
		
	git config --global credential.helper store
	debug "Credential storage has been enabled"
fi

# Note: Script itself will not loop, just in case there are bugs. Instead, set a cronjob to run it

cd $directory
git pull >>$logFile

if [[ $? -ne 0 ]]; then
	debug "There was an error, please check log for more info"
	echo "gitCheck.sh encountered an error, please check $logFile for more info!" | mail -s "gitCheck.sh" $USER
else
	echo "Success!"
fi

debug "Done with script!"

#EOF
