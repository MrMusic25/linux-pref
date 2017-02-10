#!/bin/bash
#
# gitCheck.sh - Script that will pull from a git repo every X minutes
#
# Usage: ./gitCheck.sh <working_git_directory> OR ./gitCheck.sh install <git_URL> [directory]
#
# Recommended crontab entry:
#      */15 * * * * /home/$USER/linux-pref/gitCheck.sh /home/$USER/linux-pref/
#                                                       `---> This can be replaced with any git directory to be synced
# Syncs every 15 mins. Becareful which user script gets run as, should be owner of folder, or have read/write/execute access!
#
# Relies on the .git folder in the directory to be able to pull, therefore must be setup beforehand!
#
# Changes:
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
# - Output git status to log if push/pull unsuccessful
#   ~ Also output git diff to a tmp file (shortName_repo_date.txt)
# - https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository
#
# v1.1.0, 23 Aug. 2016 15:34 PST

### Variables

#sleepTime=900 # Time in seconds to wait until going through loop again. 900 seconds (15 minutes) by default
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

# I was reminded why comments are important when I looked upon this codebock the next day and did not understand it...
# Anyways lol, this block is used to determine if directory is valid and git-ready
if [[ ! -z "$1" ]]; then
	if [[ "$1" == "install" ]]; then
		if [[ ! -z "$2" ]]; then 
			gitURL="$2"
			debug "Installing git repo from $gitURL"
			announce "Installing repo from the following URL!" "$gitURL" "Note: This may take time depending on connection speed and repo size"
			
			# Decide which directory to clone into
			if [[ ! -z "$3" && -d "$3" ]]; then
				debug "User specified $3 as directory to be used."
				directory="$3"
			else
				debug "Cloning into current directory"
				directory='' # Must be null or it will create errors
			fi
			
			# Now, do the clone!
			git clone "$gitURL" "$directory" &>.tmp
			
			if [[ -z "$directory" ]]; then
				directory=$( head -n 1 .tmp | awk -F\' '{print $2,$4}' ) # This gets the name of the directory
				rm .tmp
				
				# Check to make directory exists
				if [[ ! -d "$directory" ]]; then
					debug "Something went wrong while cloning, or directory somehow was not found. Clone manually and add cron job."
					announce "Something went wrong!" "Please clone and setup cron job manually!"
					exit 1
				fi
			else
				rm .tmp
			fi
			
			debug "Successfully cloned directory"
			
			# Next, setup the cron job for the user
			addCronJob "30" "min" "/usr/bin/gitcheck $directory"
			if [[ "$?" -ne 0 ]]; then
				debug "There was an issue setting up the cronjob! Please setup manually!"
				tmpVar="Cron job could not be setup! Please run crontab -e and set it up manually!"
			else
				debug "Cron job setup!"
				tmpVar="Cron job was successfully setup for the git repo!"
			fi
			
			# Clever way I came up with to notify if cron was successful or not lol
			announce "Git repo was successfully cloned!" "$tmpVar" "Now moving on to the rest of the script..."
		else
			debug "Install mode selected, but no URL given! Exiting..."
			displayHelp
			exit 1
		fi
	elif [[ -d "$1" ]]; then
		if [[ -d "$1/.git" ]]; then
			export directory="$1"
		else
			export debugFlag=1
			debug "Directory exists, but has not been initilized by git, please fix and re-run!"
			exit 1
		fi
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
