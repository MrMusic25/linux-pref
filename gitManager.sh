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
# v2.0.1, 13 Jan. 2016 16:26 PST

### Variables

directoryList="~/.gitDirectoryList"

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
Meant to be run as a cronjob, but can be run as is also.
Run script once to complete setup!

Usage: ./gitManager.sh [options] [git_repository]

Options:
-h | --help                         : Display this help message and exit
-v | --verbose                      : Enable verbose debug messages. (Note: MUST be first argument!)
-c | --clone <git_URL> [folder]     : Clone a remote repository, and add it to the update list, then exit
-a | --add <git_folder>             : Add an existing git folder to the update list and exit
-d | --daemon                       : Run script in daemon mode, no interactive elements
-l | --list                         : Display locations and info of installed repositories and exit

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
		
		# In this example, if $key and $2 are a file and a directory, then processing arguments can end. Otherwise it will loop forever
		# This is also where you would include code for optional 3rd argument, otherwise it will never be processed
		if [[ -f "$key" && -d "$2" ]]; then
			inputFile="$key"
			outputDir="$2"
			
			if [[ -f "$3" ]]; then
				tmpDir="$3"
			fi
			loopFlag=1 # This will kill the loop, and the function. A 'return' statement would also work here.
		fi
			
		case "$key" in
			--output-only) # Long, unaliased names should always go first so they do not create errors. Try to avoid similar names!
			outputOnly="true"
			;;
			-h|--help)
			displayHelp
			exit 0
			;;
			-o|--option)
			option=1
			;;
			-i|--include)
			# Be careful with these, always check for file validity before moving on
			# Doing it this way makes it you can add as many files as you want, and then continuing
			until [[ "$2" == -* ]]; do # Keep looping until an option (starting with a - ) is found
				if [[ -f "$2" ]]; then
					# This adds the filename to the array includeFiles - make code later to perform an action on each file
					includeFiles+=("$2")
					shift
				else
					# displayHelp and exit if the file could not be found, safety measure
					debug "l2" "ERROR: Argument $2 is not a valid file or argument!"
					displayHelp
					exit 1
				fi
			done
			;;
			-a|--assume)
			if [[ "$2" == "Y" || "$2" == "y" || "$2" == "Yes" || "$2" == "yes" ]]; then
				assume="true"
				shift
			elif [[ "$2" == "N" || "$2" == "n" || "$2" == "No" || "$2" == "no" ]]; then
				assume="false" # If this is the default value, you can delete this line, used for example purposes
				shift
			else
				# Invalid value given with -a, report and exit!
				debug "l2" "ERROR: Invalid option $2 given with $key! Please fix and re-run"
				displayHelp
				exit 1
			fi
			;;
			*)
			# Anything here is undocumented or uncoded. Up to user whether or not to continue, but it is recommended to exit here if triggered
			debug "l2" "ERROR: Unknown option given: $key! Please fix and re-run"
			displayHelp
			exit 1
			;;
		esac
		shift
	done
}


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
