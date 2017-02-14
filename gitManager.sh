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
# v2.0.4
# - Added listRepos(), does nothing for now
# - Made the main bulk into pullRepo(), while loop to call it
#
# v2.0.3
# - Added the -i option to reintsall git options, instead of just "first run"
# - Added a failsafe to cloneRepo() in case folder could not be found
# - setupGit() created, and ready to go
# - Added the rest of the options from processArgs
#
# v2.0.2
# - Updated processArgs a bit with planned functions
# - Created functions cloneRepo() and addRepo()
# - cloneRepo() is ready for use! (untested, but ready)
#
# v2.0.1
# - Added displayHelp() and processArgs() from defaultScriptTemplate
# - Updated displayHelp with planned functions
#
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
# v2.0.4, 14 Jan. 2016 00:46 PST

### Variables

directoryList="~/.gitDirectoryList"
daemonMode=0

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


function displayHelp() {
# The following will read all text between the words 'helpVar' into the variable $helpVar
# The echo at the end will output it, exactly as shown, to the user
read -d '' helpVar <<"endHelp"

gitManager.sh - A script that will update and manage various git repositories
Meant to be run as a cronjob, but can be run standalone as well.
Run script once to complete setup!

Usage: ./gitManager.sh [options] [git_repository]

Options:
-h | --help                         : Display this help message and exit
-v | --verbose                      : Enable verbose debug messages. (Note: MUST be first argument!)
-c | --clone <git_URL> [folder]     : Clone a remote repository, and add it to the update list, then exit
-a | --add <git_folder>             : Add an existing git folder to the update list and exit
-d | --daemon                       : Run script in daemon mode, no interactive elements
-l | --list                         : Display locations and info of installed repositories and exit
-i | --install                      : Setup or re-setup the git parameters and exit

Information from "git pull" command is not shown by default; run the script with the verbose flag to see the data, or check the log!

endHelp
echo "$helpVar"
}

function processArgs() {
	# Runs standalone, so leave function if there are no arguments given
	if [[ $# -le 0 ]]; then
		debug "INFO: No arguments given, running script with default options!"
		return 0
	fi
	
	argCount=1
	args="$#"
	while [[ $loopFlag -eq 0 ]]; do
		key="$1"
		
		case "$key" in
			-h|--help)
			displayHelp
			exit 0
			;;
			-c|--clone)
			gitURL="$2"
			if [[ ! -z $3 ]]; then
				gitFolder="$3"
			else
				gitFolder="pwd"
			fi
			cloneRepo "$gitURL" "$gitFolder"
			exit 0 # Shouldn't get here, but just in case
			;;
			-d|--daemon)
			debug "INFO: Daemon mode enabled"
			daemonMode=1
			;;
			-i|--install)
			debug "INFO: Setting up git per user's request"
			setupGit
			exit 0
			;;
			-a|--add)
			debug "INFO: Attempting to add repo from $2"
			addRepo "$2"
			exit 0
			;;
			*)
			# Anything here is undocumented or uncoded
			debug "l2" "ERROR: Unknown option given: $key! Please fix and re-run"
			displayHelp
			exit 1
			;;
		esac
		
		((argCount++))
		if [[ $num -ge $args ]]; then
			loopFlag=1
		fi
		shift
	done
}

function addRepo() {
	# Check if git directory is valid
	if [[ ! -d "$1"/.git ]]; then
		debug "l2" "ERROR: $folder is not a valid git directory! Unable to add to list! Exiting..."
		exit 1
	fi
	
	# Valid directory at this point
	echo "$1" >>$directoryList
}

function cloneRepo() {
	# Clone into current directory (getting folder name from URL) if set to pwd mode. Else, clone into second argument
	if [[ "$2" == "pwd" ]]; then
		folder="$(echo "$1" | rev | cut -d'.' -f1 --complement | cut -d'/' -f1 | rev)"
		debug "INFO: Attemping to clone git repo $1 into current directory!"
		git clone "$1"
		value="$?"
	else
		folder="$2"
		debug "INFO: Attempting to clone git repo $1 into folder $2 !"
		git clone "$1" "$2"
		value="$?"
	fi
	
	# Warn user and exit if something goes wrong; continue otherwise
	if [[ $value -ne 0 ]]; then
		debug "l2" "ERROR: There was an error attemping to clone the repository! Exit code: $value"
		exit 1
	else
		if [[ ! -d "$folder" ]]; then
			debug "l2" "WARN: Repo was successfully cloned, but folder $folder could not be found! Please add to list manually!"
			exit 1
		fi
		addRepo "$folder"
		exit 0
	fi
}

function setupGit() {
	# Return if in daemon mode, no interactivity allowed!
	if [[ $daemonMode -ne 0 ]]; then
		return
	fi
	
	# Interactive part of the setup
	announce "Setting up Git for this system!" "Please follow the interactive prompts."
	read -p "Please enter the email you would like to use: " varEmail
	git config --global user.email "$varEmail"
	read -p "Please enter the display name you would like to use: " varUser
	git config --global user.name "$varUser"
	read -p "Please enter the default editor you wish to use (nano, vim, emacs, etc.): " varEditor
	git config --global core.editor "$varEditor"
	debug "INFO: Git set up as follows - Name: $varUser, Email: $varEmail, Editor: $varEditor"
	
	# Static config now
	git config --global credential.helper store
	debug "INFO: Git credential storage enabled"
	announce "Git credential storage has been enabled." "This means you will only have to login once to upload merges"
	git config --global push.default simple
	debug "INFO: Simple push behavior has been enabled"
	announce "Git has been configured to use simple push behavior (default since git v2.0+)" "This means that only the current working branch will be pushed, not all!"
}

function listRepos() {
	true
}

function pullRepo() {
	debug "INFO: Attempting to update repo $1 on currnt branch"
	cd "$1"
	git pull >.gitTmp
	value="$?"
	
	# Decide what to do with git output info
	if [[ $debugFlag -ne 0 && $daemonMode -ne 0 ]]; then
		cat .gitTmp
	fi
	cat .gitTmp >>$logFile
	rm .gitTmp
	
	# Warn user of any errors
	if [[ $value -ne 0 ]]; then
		debug "l2" "WARN: There was an error attempting to pull $1 - Exit code: $value"
	else
		debug "l5" "INFO: Repo $1 was updated successfully for current branch!"
	fi
}

### Main Script

processArgs "$@"

# Check to see if git has been setup. Run if not
if [[ -e ~/.git-credentials || -e ~/.git-credential-cache ]]; then
	debug "l5" "INFO: Git has already been setup, moving to next step."
else
	debug "l3" "WARN: Git has not been setup! Running first-time setup automatically"
	setupGit
fi

# Update all the installed repos
OPWD="$(pwd)"
while read -r directory;
do
	pullRepo "$directory"
done <"$directoryList"
cd "$OPWD"
if [[ $? -ne 0 ]]; then
	debug "There was an error, please check log for more info"
	echo "gitCheck.sh encountered an error, please check $logFile for more info!" | mail -s "gitCheck.sh" $USER
else
	echo "Success!"
fi

debug "l3" "Done with script!"

#EOF