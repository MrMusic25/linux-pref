#!/bin/bash
#
# gitManager.sh - Script that will pull from a git repo every X minutes
#
# Usage: ./gitCheck.sh [options] [git_directory]
#
# Recommended crontab entry:
#      */15 * * * * /home/$USER/linux-pref/gitCheck.sh --daemon &>/dev/null
# Syncs every 15 mins. Becareful which user script gets run as, should be owner of folder, or have read/write/execute access!
#
# Relies on the .git folder in the directory to be able to pull, therefore must be setup beforehand!
#
# Changes:
# v2.0.0
# - Starting work on an improved version of this script that can do more
# - Changed name of script from gitCheck.sh -> gitManager.sh
#
# v1.1.0
# - You can now download/install git repos with this script
# - Script will ask to setup cron job for new repo as well
#
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
# TODO:
# - Add a .gitDirectories folder to ~/ and sync with each directory every x minutes
# - Make an alias 'git clone'='gitcheck clone' and offer to add to directory list
#   ~ Only need one cron entry, easy to update all gits on computer!
#   ~ Ask if user wants to be notified of updates
# - git config --global core.editor nano
# - git config --global push.default [simple vs matching]
#   ~ Possibly make choice between the two if multiple branches detected
# - Output git status to log if push/pull unsuccessful
#   ~ Also output git diff to a tmp file (shortName_repo_date.txt)
# - https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository
#
# v2.0.0, 13 Jan. 2016 15:14 PST

### Variables

directory="NULL"

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

# Next, check to see if git credentials will be saved
# Realized halfway through writing this the script will not be pushing, only pulling. Still useful as I forget things like this
if [[ -e ~/.git-credentials || -e ~/.git-credential-cache ]]; then
	debug "l5" "Git has already been setup, moving to next step."
else
	announce "Git has not been setup yet!" "This script will now help configure git for ease of use."
	getUserAnswer "Would you like to setup your email and display name for git now?"
	if [[ $? -eq 0 ]]; then
		debug "Prompting for users info..."
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
