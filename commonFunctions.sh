#!/bin/bash
#
# commonFunctions.sh - A collection of functions to be used in this project
#
# Note: this script whould not be run by itself, as it only contains functions and variables
#
# Changes:
# v1.9.3
# - Added level 5 debugging to debug(); only sends message to stderr and log if verbose mode is on
# - Finally got around to it: announce() does not print stars in verbose mode - this makes 'set -x' output cleaner
#
# v1.9.2
# - Small change to debug(), not sure if it helps or not but conforms to other scripts now
#
# v1.9.1
# - Automatic space conversion disabled for win2UnixPath(), it was giving me problems
# - win2UnixPath() can still edit spaces, but now you must include "space" as the last argument
#
# v1.9.0
# - New function: win2UnixPath()
#
# v1.8.1
# - The best kind of updates are those that go untested, amirite? Lol, bug fixes
# - Added a newline so text doesn't get chopped
#
# v1.8.0
# - getUserAnswer() can now assume yes/no ans timeout for "headless" scripts. Doesn't effect legacy calls.
#
# v1.7.6
# - Moved checkRequirements() to pmCF.sh
# - Added a source argument for pmCF.sh
# - Fixed SC2145
#
# v1.7.5
# - A comment required a version change... Script now relies on $program not being set
# - Added as close to an '#ifndef' statement as I could for sourcing
#
# v1.7.4
# - Debug now supports levels! See function for more info (legacy calls are not effected)
#
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
#   ~ MAYBE start doing log levels (1 log only, 2 stderr+log, 3 stdout+log, 4 stderr+stdout+log)
#     ~ If $tmpLevel != 0, echo to stderr||stdout, then set $tmpLevel=0 every time function is called
#   ~ If $1 == "echo", send debug message to stdout as well
#     ~ Eliminates need for "export debugFlag=1" statements for exiting, cleaner execution
# - announce()
#   ~ If announce() reaches $MAX_CHAR_LIMIT, output extra data to second line
#   ~ Disable stars and printf statements when -v|--verbose is on, makes debugging cleaner
# - getUserAnswer()
#   ~ For y/n answers, add an option that assumes a default option ( y/N or Y/n)
#   ~ If the option times out, assum the answer and return that value
#     ~ This allows for user input while still being non-interactive
#   ~ Add a way to specify the timeout value from the default in cF.sh
# - timeDifference()
#   ~ Display (and possibly log) the difference between two times. Thought of for m2u
#     ~ Possibly just add to debug()? Or finally in the implementation of 'script start' or 'script end <exit_code>'
#   ~ http://stackoverflow.com/questions/8903239/how-to-calculate-time-difference-in-bash-script
# - Implement universal version checking for commonFunctions.sh
#   ~ Recommend when cF.sh should be updated
#   ~ Log message if 'required' versions are mismatched
#
# v1.9.3, 11 Dec. 2016 02:32 PST

### Variables

#program="NULL" # This should be the start point for most scripts
debugFlag=0
privilege=0 # 0 if root, 777 if not
cfVar=0 # Used for '#ifndef', sourcing
debugInit=0
debugPrefix="$HOME/.logs" # Use: scriptLog="$debugPrefix/scriptLog.log", then include $scriptLog in debug() statements
logFile=$debugPrefix/$( basename "$0" | cut -d '.' -f 1 ).log # Now every script has a unique yet dynamic log name!
debugLevel=1 # Default, directs to log; see debug() for more info
assume="nothing" # Mysterious guys get the most girls :3
timeoutVal=10 # Seconds to wait when assuming yes/no in getUserAnswer()

cFlag=0 # Used with the ctrl_c function
#trap ctrl_c INT # This will run the function ctrl_c() when it captures the key press

### Functions

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
	
	# If verbose mode is on, do not print stars, just the messages with "Announce: " appended to is
	# I really wanted this to be used with 'set -x', but I have no way to tell if it is set beforehand or not
	# 'set -x' is almost always used in conjunction with --verbose though, so it should be fine
	if [[ "$debugFlag" -ne 0 ]]; then
		printf "\n"
		for message in "$@";
		do
			printf "Announce: %s\n" "$message"
		done
		printf "\n"
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
	
	oldLevel="$debugLevel" # Respect user's choice, reset at the end of the script
	# Set the debug level, if it is present. This way not all legacy calls ave to be changed
	if [[ "$1" == l* ]]; then
		case $1 in
			l1)
			debugLevel=1 # Log only
			;;
			l2)
			debugLevel=2 # Log + stderr
			;;
			l3)
			debugLevel=3 # Log + stdout (using announce)
			;;
			l4)
			debugLevel=4 # Log + stdout + stderr (this probably won't be used often, but coded it in anyways
			;;
			l5)
			if [[ "$debugFlag" -eq 0 ]]; then # Only display/log the message if script is in verbose mode. Use case: diagnosing loop iterations
				return
			else
				debugLevel=2
			fi
			;;
		esac
		shift # So that the level doesn't get included in the debug message
	fi
	
	# Now, redirect output based on debugLevel
	case $debugLevel in
		2)
		(>&2 echo "Debug: $@")
		;;
		3)
		announce "Debug: $@"
		;;
		4)
		(>&2 echo "Debug: $@")
		announce "Debug: $@"
		;;
	esac
	debugLevel="$oldLevel"
	
	# Echoes the message if debug flag is on
	#if [[ $debugFlag -eq 1 ]]; then
	#	(>&2 echo "Debug: $*") # Sends the message to stderr in a subshell so other redirection isn't effected, in case user quiets stdout
	#fi
	
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
# Call: getUserAnswer [y/n] "Question in quotation marks?" [variable_name] "Question for variable name, if present?"
#
# Input: User will be asked the question in quotes ($1). 
#        If [variable_name] ($2) is present, it will ask the second question ($3) and assign response to that variable
#
# Output: stdout (obviously), return value of 0 for yes/true response, value of 1 for no/false response
#
# Other info: Be careful which names you give to the variables, you may accidentally delete other variables!
#             If first argument is y or n, it will assume answer is yes/no respectively. Script will not assume input values (for now)
function getUserAnswer() {
	export ans="NULL" # Guess re-declaration doesn't work properly in bash...
	
	# Allows for assuming yes/no without needed to edit all current calls
	if [[ "$1" == "y" || "$2" == "yes" ]]; then
		assume="yes"
		shift
	elif [[ "$1" == "n" || "$1" == "no" ]]; then
		assume="no"
		shift
	fi
	
	announce "$1"
	
	case $assume in
		yes)
		until [[ $ans == "y" || $ans == "yes" || $ans == "n" || $ans == "no" ]]; do
			read -t "$timeoutVal" -p "Please answer above prompt (Y/n): " ans
			if [[ $ans != "y" || $ans != "yes" || $ans != "n" || $ans != "no" ]]; then
				printf "\n" # Formatting
				ans="y"
			fi
		done
		;;
		no)
		until [[ $ans == "y" || $ans == "yes" || $ans == "n" || $ans == "no" ]]; do
			read -t "$timeoutVal" -p "Please answer above prompt (y/N): " ans
			if [[ $ans != "y" || $ans != "yes" || $ans != "n" || $ans != "no" ]]; then
				printf "\n"
				ans="n"
			fi
		done
		;;
		*)
		until [[ $ans == "y" || $ans == "yes" || $ans == "n" || $ans == "no" ]]; do
			read -p "Please answer above prompt (y/n): " ans
		done
		;;
	esac
	
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

## win2UnixPath()
#
# Function: Converts a Windows path to a POSIX path and echoes the response to stdout; typical use case will look like the following:
#           directory="$(win2UnixPath "$windowsDirectory")"
#
# Call: win2UnixPath <Windows_path> [prefix] [upper OR cut] [space]
#
# Input: String containing a Windows path
#
# Output: Outputs converted string to stdout
#
# Other: By default, the Windows 'root' drive (C:\) will be converted tolower, useful in Bash for Windows (make sure prefix="/mnt" in this case!)
#        Appending upper to the end of the call will leave the uppercase letter intact; appending cut will remove the Windows root outright
#        Both of these appendages can be used by themselves, but the prefix must ALWAYS go first if it is not set somewhere else in the script!
#        As of 1.9.1, function will not automatically convert spaces. Include "space" at the end of the call to have this done from now on.
function win2UnixPath() {
	# Make sure an argument is given
	if [[ -z $1 ]]; then
		debug "l2" "ERROR: No argument given for win2UnixPath!"
		return
	fi
	
	dir="$1" # Getting ready to have nasty things done to it
	
	# Explained: winDir            \ -> /       : -> ''    ' ' -> '\ '
	dir="$(echo "/$dir" | sed -e 's/\\/\//g' -e 's/://')" #-e 's/ /\\ /g')"
	
	# Determing if second argument is prefix
	if [[ $# -gt 2 ]]; then
		prefix="$2" # Assume the user knows what they're doing
		shift
	elif [[ -d "$2" ]]; then
		prefix="$2"
		shift
	fi
	
	# Now, do 'cut', 'upper', or 'space' if the user requested it
	if [[ ! -z $2 ]]; then
		case "$2" in
			u*) # upper in documentation
			true # Essentiallly, do nothing, since default behavior is to make 'c drive' lowercase (built for bash on Windows!)
			;;
			c*) # cut in documentation
			dir="$(echo "$dir" | cut -d'/' -f2 --complement)"
			#dir="/""$dir" # Command cut off root in trials, this can be remedied later anyways
			;;
			s*)
			dir="$(echo "$dir" | sed -e 's/ /\ /g')"
			;;
			*)
			debug "l2" "ERROR: Bad call for winToUnixPath(): $2 is neither an acceptable command nor a valid prefix!"
			return
			;;
		esac
		shift
	else
		# Convert the Windows 'root' drive tolower, common use in Bash for Windows
		drive="$(echo "$dir" | cut -d'/' -f2 | awk '{print tolower($1)}')"
		dir=/"$drive""$(echo "$dir" | cut -d'/' -f2 --complement)" # Scary, only way to test this is to run the script!
	fi
	
	# Now that THAT'S all over with, time to add the prefix!
	if [[ ! -z $prefix ]]; then
		dir="$prefix"/"$dir"
	fi
	
	# Change any escape characters
	#                             $ -> \$       @ -> \@       # -> \#       ! -> \!
	#dir="$(echo "$dir" | sed -e 's,\$,\\\$,g' -e 's,\@,\\\@,g' -e 's,\#,\\\#,g' -e 's,\!,\\\!,g')"
	
	# Lastly, if the user requested it, edit the spaces; no need to check contents of last call, should be the only argument
	[[ ! -z $2 ]] && dir="$(echo "$dir" | sed -e 's/ /\\ /g')"
	
	# One final cleanup... Change any double slashes to single
	dir="$(echo "$dir" | sed -e 's,//,/,g' -e 's,\\\\,\\,g')"
	
	# Congratulations if you made it this far!
	echo "$dir"
}

# This following, which SHOULD be run in every script, will enable debugging if -v|--verbose is enabled.
# The 'shift' command lets the scripts use the rest of the arguments
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
	echo "Running in verbose mode!"
	export debugFlag=1
	export debugLevel=2
	shift
fi

if [[ -z $pmCFvar ]]; then
	if [[ -f packageManagerCF.sh ]]; then
		source packageManagerCF.sh
	elif [[ -f /usr/share/packageManagerCF.sh ]]; then
		source /usr/share/packageManagerCF.sh
	else
		echo "packageManagerCF.sh could not be located!"

		# Comment/uncomment below depending on if script actually uses common functions
		#echo "Script will now exit, please put file in same directory as script, or link to /usr/share!"
		#exit 1
	fi
fi

#EOF