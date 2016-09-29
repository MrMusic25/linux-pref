#!/bin/bash
#
# commonFunctions.sh - A collection of functions to be used in this project
#
# Note: this script whould not be run by itself, as it only contains functions and variables
#
# Changes:
# v1.7.3
# - Didn't want to change major version since I was working on it today
# - Added function editTextFile() that was originally built for improved programInstaller.sh
#
# v1.7.2
# - Don't use pipes to separate variables... Changed to slashes, and this time I tested before uploading
# - Small change to determinePM() to prevent pacman errors
# - After testing, reverted the change to determinePM and moved it to universalInstaller()
#
# v1.7.1
# - Fixed checkRequirements() so it accepts "program|installer" as an argument
#
# v1.7.0
# - Added checkRequirements()
#
# v1.6.7
# - Added a very tiny function that pauses the script (can't believe it took me this long to do something so simple...)
# - Fixed a few issues found with shellcheck
#
# v1.6.6
# - Changed the way updating and installing with pacman works
#
# v1.6.5
# - Fixed determinePM() so 'which' is not so noisy
# - Added some more debug statements
# - Changed the way determinePrivilege() works due to a bug I discovered
# - BIG (yet humble) CHANGE: debug() now redirects message to stderr instead of stdout if verbose is on
#
# v1.6.4
# - Found a huge error in debug(), fixed now
# - Fixed all errors from shellcheck (minus the ones that don't need fixing (SC2034) and ones that would break the functions)
# - So many small changes I forgot to list
#
# v1.6.3
# - checkPrivilege() now returns 0 if you are root and 777 if not
# - Quick fix to universalInstaller() for apt-get, assumes yes for installation
#
# v1.6.2
# - Added small 'function' that allows any script to have -v|--verbose as $1 to enable debugging
# - Change to the way addCronJob() works, since it was non-functional before
#
# v1.6.1
# - Finally got around to testing getUserAnswer, and it only half worked. Now works 97%.
# - Other small changes I forgot to document and forgot hours later
#
# v1.6.0
# - Big update - now, all scripts have a dynamically assigned logFile based on the script name!
# - All scripts have been updated to reflect this, they can still be found in '$HOME/.logs'
# - MAJOR update to announce(), now looks much cleaner!
# - announce() now checks to make sure an argument is given as well
#
# v1.5.1
# - Turned off ctrl_c() trap because it doesn't work properly, will fix later
# - Added slackpkg to universalInstaller() and determinePM()
#
# v1.5.0
# - Retroactively employed the better looking numbering scheme
# - Added the addCronJob() function. Have yet to test it, however
#
# v1.4.0
# - Added a re-run as sudo option to update.sh, then decided to make is common as part of checkPrivilege()
# - ctrl_c now kill hung process first, then asks to exit. Safety measure
#
# v1.3.1
# - ctrl_c() now send a SIGINT to kill process
#
# v1.3.0
# - Added the ctrl_c() function, and corresponding trap for INT request
#
# v1.2.3
# - First actual 'bugfix' - accidentally made it touch $debugPrefix instead of mkdir
#
# v1.2.2
# - Added variable for a log directory prefix; small line, big impact
# - debug() will also make sure directory exists before writing to it
#
# v1.2.1
# - Added an initilizer to debug() so that time log was started is shown at beginning of log
#
# v1.2.0
# - Added checkPrivilege(). Checks if user is root, and exits with code 777 if not
#
# v1.1.3
# - Added a 'sleep 2' statement to the end of announce() since I keep doing it anyways
#
# v1.1.2
# - Added 'dnf' to determinePM() and universalInstaller() after reading about it on DistroWatch. Similar changes made in programInstaller.sh
#
# v1.1.1
# - debug() now touches logfile so script doesn't have to!
# - Slightly changed the output of announce() to look more symmetrical
#
# v1.1.0
# - Added announce() and debug() functions
#
# TODO:
# - Add hello()/bye() OR script(start/stop) function to initialize scripts
#   ~ Start debugger, log the start time, source files that are needed according to script
#     ~ Each script has "sourceVar" which is an array of required scripts to source before running. Quit if can't be found.
#   ~ Put exit debug message, "Script completed in x.yz seconds", announce "Done with script!" or "Script exited successfully!"
#     ~ Exit with included code, don't print success message if code > 0
# - debug()
#   ~ MAYBE start doing log levels (1 log only, 2 stderr+log, 3 stdout+stderr+log)
#   ~ If $1 == "echo", send debug message to stdout as well
#     ~ Eliminates need for "export debugFlag=1" statements for exiting, cleaner execution
# - announce()
#   ~ If announce() reaches $MAX_CHAR_LIMIT, output extra data to second line
#   ~ Disable stars and printf statements when -v|--verbose is on, makes debugging cleaner
#
# v1.7.3 22 Sep. 2016 23:43 PST

### Variables

program="NULL" # This should be the start point for most scripts
debugFlag=0
privilege=0 # 0 if root, 777 if not
debugInit=0
debugPrefix="$HOME/.logs" # Use: scriptLog="$debugPrefix/scriptLog.log", then include $scriptLog in debug() statements
logFile=$debugPrefix/$( basename "$0" | cut -d '.' -f 1 ).log # Now every script has a unique yet dynamic log name!

cFlag=0 # Used with the ctrl_c function
#trap ctrl_c INT # This will run the function ctrl_c() when it captures the key press

### Functions

## determinePM()
# Function: Determine package manager (PM) and export for script use
# PreReq: None
#
# Call: determinePM
#
# Input: No input necessary; ignored
#
# Output: Exports variable 'program'; no return value (yet)
#
# Other info: Updates repositories if possible, redirect to /dev/null if you don't want to see it
function determinePM() {
if [[ ! -z $(which apt-get 2>/dev/null) ]]; then # Most common, so it goes first
	export program="apt"
	apt-get update
elif [[ ! -z $(which dnf 2>/dev/null) ]]; then # This is why we love DistroWatch, learned about the 'replacement' to yum!
	export program="dnf"
	dnf check-update
elif [[ ! -z $(which yum 2>/dev/null) ]]; then
	export program="yum"
	yum check-update
elif [[ ! -z $(which slackpkg 2>/dev/null) ]]; then
	export program="slackpkg"
	slackpkg update
elif [[ ! -z $(which rpm 2>/dev/null) ]]; then
	export program="rpm"
	rpm -F --justdb # Only updates the DB, not the system
elif [[ ! -z $(which yast 2>/dev/null) ]]; then # YaST is annoying af, so look for rpm and yum first
	export program="yast"
elif [[ ! -z $(which pacman 2>/dev/null) ]]; then
	export program="pacman"
	sudo pacman -Syy &>/dev/null # Refreshes the repos, always read the man pages!
	
	# Conditional statement to install yaourt
	[[ -z $(which yaourt 2>/dev/null) ]] && announce "pacman detected! yaourt will be installed as well!" "This insures all packages can be found and installed" && sudo pacman -S base-devel yaourt
elif [[ ! -z $(which aptitude 2>/dev/null) ]]; then # Just in case apt-get is somehow not installed with aptitude, happens
	export program="aptitude"
	aptitude update
fi
debug "Package manager found! $program"
}

## universalInstaller()
# Function: Attempt to install all programs listed in called args
# PreReq: Must run determinePM() beforehand, or have $program set to a valid option
#
# Call: universalInstaller <program1> [program2] [program3] ...
#
# Input: As many arguments as you want, each one a valid package name
#
# Output: stdout, no return values at this time
#
# Other info: Loops through arguments and installs one at a time, encapsulate in ' ' if you want some installed together
#             e.g. universalInstaller wavemon gpm 'zsh ssh' -> wavemon and gpm installed by themselves, zsh and ssh installed together
function universalInstaller() {
for var in "$@"
do
	case $program in
		apt)
		apt-get --assume-yes install "$var"  
		;;
		dnf)
		dnf -y install "$var"
		;;
		yum)
		yum install "$var" 
		;;
		slackpkg)
		slackpkg install "$var"
		;;
		yast)
		yast -i "$var" 
		;;
		rpm)
		rpm -i "$var" 
		;;
		pacman)
		sudo pacman -S --noconfirm "$var"
		
		# If pacman can't install it, it can likely be found in AUR/yaourt
		if [[ $? -eq 1 ]]; then
			debug "$var not found with pacman, attempting install with yaourt!"
			announce "$var not found with pacman, trying yaourt!" "This is interactive because it could potentially break your system."
			yaourt "$var"
		fi 
		;;
		aptitude)
		aptitude -y install "$var" 
		;;
		*)
		announce "Package manager not found! Please update script or diagnose problem!"
		#exit 300
		;;
	esac
done
	# Insert code dealing with failed installs here
}

## announce()
# Function: Make a visible notice to display text - catch the user's eye
# PreReq: None
#
# Call: announce <text1> [text2] [text3] ...
#
# Input: Text in quotation marks. Each argument will be a new line in the announcement.
#
# Output: None, no return values
#
# Other info: Try not to make text too long, it may not display correctly. Includes a check in case no arguments given.
function announce() {
	# Determine highest amount of chars
	if [[ -z $1 ]]; then
		echo "ERROR: Incorrect call for announce()! Please read documentation and fix!"
		return
	fi
	
	# For everyting below, you can ignore SC2034. Too much work to change
	stars=0
		for j in "$@"; # Stupid quotation marks killed the whole thing.... ugh....
	do
		if [[ ${#j} -gt $stars ]]; then
			export stars=${#j}
		fi
	done
	let "stars += 8" # 4 beginning characters and 4 trailing
	
	# Now print beginning set of stars
	printf "\n "
	for l in $(seq 1 "$stars");
	do
		printf "*"
	done
	
	# Now, print announcements
	for i in $(seq 1 $#);
	do
		# First block prints the stars and spaces between statements
		printf "\n ***"
		for q in $(seq 1 "$((stars-6))");
		do
			printf " "
		done
		printf "***\n"
		printf " ***" # Initial stars for the message...
		
		# Math block to find out spaces for centering, for both even and odd numbers
		statement="${!i}"
		x=$((stars-${#statement}-6))
		if [[ $((x%2)) -eq 0 ]]; then
			evenFlag=1
		else
			evenFlag=0
		fi
		
		# Now print stars and statement, centering with spaces, depending on if even or odd
		case $evenFlag in
			1)
			for p in $(seq 1 "$((x/2))");
			do
				printf " "
			done
			printf "%s" "${!i}"
			for r in $(seq 1 "$((x/2))");
			do
				printf " "
			done
			;;
			0)
			for a in $(seq 1 "$((x/2))");
			do
				printf " "
			done
			printf "%s" "${!i}"
			for b in $(seq 1 "$((x/2+1))");
			do
				printf " "
			done
			;;
			*)
			export debugFlag=1
			debug "Congratulations on breaking the script. Please escort yourself to the nearest mental institute."
			exit 9009
			;;
		esac
		printf "***"
	done
	
	# One last line of spaces
	printf "\n ***"
		for q in $(seq 1 "$((stars-6))");
		do
			printf " "
		done
	printf "***"
	
	#Finally, print ending stars
	printf "\n "
	for k in $(seq 1 "$stars");
	do
		printf "*"
	done
	printf "\n\n"
	sleep 3
}

## debug()
# Function: When enabled, it allows you to send debug messages to a log or stdout
# PreReq: 'export debugFlag=1' if you want stdout
#
# Call: debug <message>
#
# Input: Text string for input. If log_file is present, it will echo>> to that file as well with 'Debug:' to denote debug output
#        Note: Message will only output if debugFlag=1, so that debug code doesn't need to be erased or commented out
#
# Output: stdout, no return value
#
# Other info: If log_file is present, it will ALWAYS send debug message to log - useful when sharing scripts
#             Note: Debug also runs 'touch' on file if not present, no need to do so in script now!
#             Note: Starting with v1.6.0, dynamic logs are now used. $2 will be ignored, so erase those from debug statements whenever there is time
function debug() {
	# It would be kinda awkward trying to write to a non-existent directory... Hate to run it every call but it is necessary
	if [[ ! -d $debugPrefix ]]; then
		mkdir "$debugPrefix"
	fi
	
	# Echoes the message if debug flag is on
	if [[ $debugFlag -eq 1 ]]; then
		(>&2 echo "Debug: $*") # Sends the message to stderr in a subshell so other redirection isn't effected, in case user quiets stdout
	fi
	
	if [[ ! -z $logFile ]]; then
		if [[ ! -f $logFile ]]; then
			touch "$logFile"
		fi
	
		# Initilize the log file
		if [[ $debugInit -eq 0 ]]; then
			export startTime=$(date)
			echo " " >> "$logFile"
			echo "*** Started at $startTime ***" >> "$logFile"
			echo " " >> "$logFile"
			export debugInit=1
		fi
		
		echo "$@" >> "$logFile"
	fi
}

## checkPrivilege()
# Function: Simple function to check if this script is being run as root or sudo, in case it is necessary
#
# Call: checkPrivilege [exit|(ask "$@")]
#
# Input: Putting "exit" as an argument will exit the script with code 777 if it fails; "ask" will re-run the script as root (be careful with this!).
#
# Output: stdout, sets privilege to 777 if not root, 0 if root; this allows you to call sudo <command>, or exit entire script
#
# Other info: Just calling will return 777; calling with the word "exit" at the end will kill the current script if not root
function checkPrivilege() {
if [ "$EUID" -ne 0 ]; then
	debug "Script is not being run as root!"
	announce "This script require root privileges, please run as root or sudo!"
	export privilege=777
	
	# Only exits if the flag ($1) is set
	if [[ "$1" == "exit" ]]; then
		debug "Script set to exit mode, exiting with error code 777!"
		exit 777
	fi
	
	if [[ "$1" == "ask" ]]; then
		debug "Script set to ask mode, re-running as sudo!"
		announce "Script will now re-run itself as root, please provide password when prompted!"
		shift # Gets rid of 'ask' argument when re-running script
		sudo "$0" "$@"
		exit $?
	fi
	
	return 77
else
	debug "Script is being run as root"
	export privilege=0
	return 0
fi
}

## ctrl_c()
# Function: Kills programs and closes scripts early on key capture. Asks for verification first.
#
# Call: ctrl_c
#
# Input: None
#
# Output: stdout (announce()), debug messages will be output when standardized log-names are created
#
# Other info: commonFunction.sh automatically includes a call for this. Everywhere else you will need to put 'trap ctrl_c INT' near the top of your script
#             Found here: https://rimuhosting.com/knowledgebase/linux/misc/trapping-ctrl-c-in-bash
function ctrl_c() {
	if [[ $cFlag -eq 0 ]]; then
		announce "Warning: CTRL+C event captured!" "If you would like kill hung or slow process, press CTRL+C again."
		export cFlag=1
	elif [[ $cFlag -eq 1 ]]; then
		announce "CTRL+C captured! Killing hung or slow process!" "If you would like to exit script, press CTRL+C once more"
		kill -s SIGINT $$
		export cFlag=2
	else
		kill -s SIGINT $$
		echo "Exiting script early based on user input (SIGINT)!"
		exit 999
	fi
}

## addCronJob()
# Function: Like the name implies, creates a cron job for the current user
#
# Call: addCronJob <number_of_mins> <min|hour> "/path/to/command.sh -in quotations" [no-null]
#
# Input: Number of minutes or hours to run script, min or hour indicator, and the command in quotation marks
#
# Output: stdout, returns a 1 if it could not be added, 0 if successful
#
# Other info: First three variables require in the correct order. Second variable accepts (min, mins, minutes, minute, hour, hours).
#             If the 4th argument is present, it will NOT redirect stdout to /dev/null. Otherwise cron will send you mail.
#             Only hours and minutes for now, might add more later. In addition, find a way to specify '15' vs '*/15'.
function addCronJob() {
	# First, determine if time is valid
	if [[ $1 -le 0 || $1 -gt 60 ]]; then
		echo "ERROR: Call for addCronJob() is outside the natural time limits! (Num: $1)" # Don't you just LOVE cryptic messages?
		return 1
	elif [[ $2 == "hour" && $1 -gt 24 || $2 == "hours" && $1 -gt 24 ]]; then
		echo "ERROR: There are not $1 hours in a day, please fix call!"
		return 1
	fi
	
	case $2 in
		min|mins|minute|minutes)
		announce "Preparing job $3 for cron!" "Job will every $1 minutes from now on."
		
		if [[ ! -z $4 ]]; then
			debug "cronjob will NOT redirect to /dev/null, expect lots of mail from cron!"
			#crontab -l 2>/dev/null; echo "*/$1 * * * * $3 " | crontab -
			touch tmpCron # Wasn't going to include this at first, but just in case user doesn't have write permission...
			crontab -l 2>/dev/null > tmpCron
			printf "\n# Added by %s on %s\n*/%s * * * * %s\n" "$0" "$(date)" "$1" "$3" >> tmpCron
			crontab tmpCron
			rm tmpCron
		else
			#crontab -l 2>/dev/null; echo "*/$1 * * * * $3 &>/dev/null" | crontab -
			touch tmpCron # Wasn't going to include this at first, but just in case user doesn't have write permission...
			crontab -l 2>/dev/null > tmpCron
			printf "\n# Added by %s on %s\n*/%s * * * * %s &>/dev/null\n" "$0" "$(date)" "$1" "$3" >> tmpCron
			crontab tmpCron
			rm tmpCron
		fi
		;;
		hour|hours)
		announce "Preparing job $3 for cron!" "Job will run once per day at $1 o'clock, Military Time"
		
		if [[ ! -z $4 ]]; then
			debug "cronjob will NOT redirect to /dev/null, expect lots of mail from cron!"
			#crontab -l 2>/dev/null; echo "* $1 * * * $3 " | crontab -
			touch tmpCron # Wasn't going to include this at first, but just in case user doesn't have write permission...
			crontab -l 2>/dev/null > tmpCron
			printf "\n# Added by %s on %s\n* %s * * * %s\n" "$0" "$(date)" "$1" "$3" >> tmpCron
			crontab tmpCron
			rm tmpCron
		else
			#crontab -l 2>/dev/null; echo "* $1 * * * $3 &>/dev/null" | crontab -
			touch tmpCron # Wasn't going to include this at first, but just in case user doesn't have write permission...
			crontab -l 2>/dev/null > tmpCron
			printf "\n# Added by %s on %s\n* %s * * * %s &/dev/null\n" "$0" "$(date)" "$1" "$3" >> tmpCron
			crontab tmpCron
			rm tmpCron
		fi
		;;
		*)
		echo "ERROR: Unknown call value: $2"
		return 1
		;;
	esac
	
	return 0
}

## getUserAnswer()
#
# Function: Asks a user for input, verifies input, then returns with the answer (0 for true/yes, 1 for false/no)
#
# Call: getUserAnswer "Question in quotation marks?" [variable_name] "Question for variable name, if present?"
#
# Input: User will be asked the question in quotes ($1). 
#        If [variable_name] ($2) is present, it will ask the second question ($3) and assign response to that variable
#
# Output: stdout (obviously), return value of 0 for yes/true response, value of 1 for no/false response
#
# Other info: Be careful which names you give to the variables, you may accidentally delete other variables!
function getUserAnswer() {
	export ans="NULL" # Guess re-declaration doesn't work properly in bash...
	announce "$1"
	
	until [[ $ans == "y" || $ans == "yes" || $ans == "n" || $ans == "no" ]]; do
		read -p "Please answer above prompt (y/n): " ans
	done
	
	#while [[ $ans == "NULL" || $ans != "y" || $ans != "yes" || $ans != "n" || $ans != "no" ]];
	#do
	#	read -p "Please answer yes/no: " ans
	#done
	
	if [[ ! -z $2 && $ans == "y" || ! -z $2 && $ans == "yes" ]]; then
		if [[ -z $3 ]]; then
			echo "ERROR: Incorrect call for function getUserAnswer()! Please look at documentation!"
		else
			announce "$3"
			read -p "Please assign a value to $2: " ${2}
			#echo "${1} is now equal to ${!1}!"
		fi
	fi
	
	case $ans in
		y|yes)
		return 0
		;;
		n|no)
		return 1
		;;
		NULL)
		announce "Congratulations, you somehow broke my script, Linux, and possibly the universe."
		return 66 #used to be 666, but apparently that isn't allowed. not that it should happene ANYWAYS...
		;;
		*)
		announce "You must not be very good at this if you made it here."
		return 111
		;;
	esac
}

## pause()
#
# Function: Prompts the user to press Enter to continue the script (or any message)
#
# Call: pause "prompt"
#
# Input: By including a prompt as $1, it will display that (make sure to tell user to press [Enter]!)
#
# Output: stdout
#
# Other info: If $1 is missing, it will use default prompt ot "Press [Enter] to continue..."
function pause() {
	if [[ -z $1 ]]; then
		read -p "Press [Enter] to continue..."
	else
		read -p "$@"
	fi
}

## checkRequirements()
#
# Function: Check to make sure programs are installed before running script
#
# Call: checkRequirements <program_1> [program_2] [program_3] ...
#
# Input: Each argument should be the proper name of a command or program to be searched for
#
# Output: None if successful, asks to install if anything is found. If it must be manually installed, script will exit.
#
# Other: Except for rare cases, this will not work for libraries ( e.g. anything with "lib" in it). These must be done manually.
#        Note: Now you can use "program/installer" to install program, in case the program is part of a larger package
function checkRequirements() {
	# Determine package manager before doing anything else
	if [[ -z $program || "$program" == "NULL" ]]; then
		determinePM
	fi
	
	for req in "$@"
	do
		if [[ "$req" == */* ]]; then
			reqm="$(echo "$req" | cut -d'/' -f1)"
			reqt="$(echo "$req" | cut -d'/' -f2)"
		else
			reqm="$req"
			reqt="$req"
		fi
		
		# No debug messages on success, keeps things silent
		if [[ -z "$(which $reqm 2>/dev/null)" ]]; then
			debug "$reqt is not installed for $0, notifying user for install"
			getUserAnswer "$reqt is not installed, would you like to do so now?"
			case $? in
				0)
				debug "Installing $reqt based on user input"
				universalInstaller "$reqt"
				;;
				1)
				debug "User chose not to install required program $reqt, quitting!"
				announce "Please install the program manually before running this script!"
				exit 1
				;;
				*)
				debug "Unknown return option from getUserAnswer: $?"
				announce "Invalid response, quitting"
				exit 123
				;;
			esac
		fi
	done
	
	# If everything is installed, it will reach this point
	debug "All requirements met, continuing with script."
}

## editTextFile()
#
# Function: Let the user edit a text file, then return to the script
#
# Call: editTextFile <text_file>
#
# Input: A text file to be edited
#
# Output: Opens editor with the provided file. Some stdout
#
# Other: Defaults to nano. If user is over 40 years old, it will use vi instead (lol). Uses $EDITOR and $VISUAL first.
function editTextFile() {
	# First, check if file was provided. Return error if not.
	if [[ -z $1 ]]; then
		debug "Incorrect call for editTextFile, please consult commonFunctions.sh"
		announce "Incorrect call for editTextFile!" "Please read documentation and fix script." "Script will continue without editing, press CTRL+C to quit"
		return 1
	fi
	
	# Now, find the editor and run it
	if [[ -z $EDITOR && -z $VISUAL ]]; then
		if [[ -z $(which nano 2>/dev/null) ]]; then
			debug "User error has lead to vi being the only editor, using it as a last resort!"
			announce "It seems vi is your only editor. Strange choice, or new installation?" "When done editing, press :wq to exit vi"
			vi "$1"
		else
			debug "Letting user edit $1 with nano"
			nano "$1"
		fi
	elif [[ -z $EDITOR ]]; then
		debug "Letting user edit $1 with $VISUAL"
		"$VISUAL" "$1"
	else
		debug "Letting user edit $1 with $EDITOR"
		"$EDITOR" "$1"
	fi
	return 0
}

# This following, which SHOULD be run in every script, will enable debugging if -v|--verbose is enabled.
# The 'shift' command lets the scripts use the rest of the arguments
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
	echo "Running in verbose mode!"
	export debugFlag=1
	shift
fi

#EOF