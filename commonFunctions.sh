#!/bin/bash
#
# commonFunctions.sh - A collection of functions to be used in this project
# Note: this script whould not be run by itself, as it only contains functions and variables
#
# Changes:
# v1.12.2
# - Figured out a small math/logic error with dL(), fixed it
#
# v1.12.1
# - Fixed and tested dynamicLinker(), working as intended
# - Polished with shellcheck
#
# v1.12.0
# - Finished writing dynamicLinker()
# - Untested, but should be working. Testing and subsequent bug fixes to come.
#
# v1.11.2
# - importText() now uses mapfile to import variable
# - Tested importText(), fixed what wasn't working. Function is ready to go!
#
# v1.11.1
# - Impressive, broke ALL my scripts by not testing that function. Fixed it now
# - Note: That means I fixed it so this properly imports now, haven't actually tested functionality YET
#
# v1.11.0
# - Added importText() since I use it so often in many scripts. See documentation, pretty self-explanatory
# - Moved most of the changelog to oldChangelogs.txt
# - Minor text fixes
#
# v1.10.3
# - I need to run shellcheck more often... minor fixes that (hopefully) make life better
#
# v1.10.2
# - Got bored and updated all the "debug" statements to the new format
# - Other small changes I forgot to write down
#
# v1.10.1
# - Did some testing, added improved math for sleep
# - checkout() will now declare variable if previously undeclared
#
# v1.10.0
# - Added checkout() to be used in parallel scripting
# - You can now 'checkout' funtions for use using a lock variable so the threads don't step on each other
# - See documentation for more info
#
# v1.9.5
# - Debug now uses shortName when outputting to stderr/stdout
# - Added a one-time run function  to support this
# - Did some optimization to announce
#
# v1.9.4
# - Changed the way dynamic logging works - now uses $longName (per script) and $shortName for logFile
# - Still dynamic logging, but more control over names, and no duplicates "pm.log" and "packageManager.log" etc.
#
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
# v1.12.2, 03 Dec. 2017, 17:54 PST

### Variables

#program="NULL" # This should be the start point for most scripts
debugFlag=0
privilege=0 # 0 if root, 777 if not
cfVar=0 # Used for '#ifndef', sourcing
debugInit=0
debugPrefix="$HOME/.logs" # Use: scriptLog="$debugPrefix/scriptLog.log", then include $scriptLog in debug() statements
#logFile=$debugPrefix/$( basename "$0" | cut -d '.' -f 1 ).log # Now every script has a unique yet dynamic log name!
debugLevel=1 # Default, directs to log; see debug() for more info
assume="nothing" # Mysterious guys get the most girls :3
timeoutVal=10 # Seconds to wait when assuming yes/no in getUserAnswer()

cFlag=0 # Used with the ctrl_c function
#trap ctrl_c INT # This will run the function ctrl_c() when it captures the key press

# Eacho script should have $longName and $shortName set; Use them accordingly, longName preferred
# Uses old default of basename if variables are empty. Still dynamic logging!
if [[ ! -z $longName ]]; then
	logFile="$debugPrefix"/"$longName".log
elif [[ ! -z $shortName ]]; then
	logFile="$debugPrefix"/"$shortName".log
else
	logFile="$debugPrefix"/$( basename "$0" | cut -d '.' -f 1 ).log
fi

# Smilar to above, use the shortName for debugging, if present. Should be a 2-3 letter name for better display
if [[ ! -z $shortName ]]; then
	debugOutputPrefix="$shortName"
else
	debugOutputPrefix="Debug"
fi

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
	
	# Make the beginning and end string, then print it once to begin
	tmpStar=0
	longString=""
	spaceString="" # Clear these in case they were already set
	until [[ $tmpStar -eq $stars ]];
	do
		longString+="*"
		if [[ $((tmpStar + 6)) -lt $stars ]]; then
			spaceString+=" "
		fi
		((tmpStar++))
	done
	printf "\n %s" "$longString"
	
	# Now, print announcements
	for i in $(seq 1 $#);
	do
		# First block prints the stars and spaces between statements
		printf "\n ***%s***\n ***" "$spaceString"
		
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
			debug "l3" "ERROR: Congratulations on breaking the script. Please escort yourself to the nearest mental institute."
			exit 99
			;;
		esac
		printf "***"
	done
	
	# One last line of spaces
	printf "\n ***%s***" "$spaceString"
	
	#Finally, print ending stars
	printf "\n %s \n\n" "$longString"
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
		(>&2 printf "%s: %s\n" "$debugOutputPrefix" "$@")
		;;
		3)
		printf "%s: %s\n" "$debugOutputPrefix" "$@"
		;;
		4)
		(>&2 printf "%s: %s\n" "$debugOutputPrefix" "$@")
		announce "$debugOutputPrefix: $*"
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
			printf "\n*** Started at $startTime ***\n\n" >> "$logFile"
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
	debug "l3" "WARN: Script requires root privileges, but is not root/sudo!"
	export privilege=77
	
	# Only exits if the flag ($1) is set
	if [[ "$1" == "exit" ]]; then
		debug "WARN: Script set to exit mode, exiting with error code 77!"
		exit 77
	fi
	
	if [[ "$1" == "ask" ]]; then
		debug "l3" "INFO: Script set to ask mode, re-running as sudo!"
		shift # Gets rid of 'ask' argument when re-running script
		sudo "$0" "$@"
		exit $?
	fi
	
	return 77
else
	debug "INFO: Script is being re-run as root"
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
		debug "l2" "ERROR: Call for addCronJob() is outside the natural time limits! (Num: $1)" # Don't you just LOVE cryptic messages?
		return 1
	elif [[ $2 == "hour" && $1 -gt 24 || $2 == "hours" && $1 -gt 24 ]]; then
		debug "l2" "ERROR: There are not $1 hours in a day, please fix call!"
		return 1
	fi
	
	case $2 in
		min|mins|minute|minutes)
		announce "Preparing job $3 for cron!" "Job will every $1 minutes from now on."
		
		if [[ ! -z $4 ]]; then
			debug "WARN: cronjob will NOT redirect to /dev/null, expect lots of mail from cron!"
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
			debug "WARN: cronjob will NOT redirect to /dev/null, expect lots of mail from cron!"
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
		debug "l2" "ERROR: Unknown call for addCronJob()! Value: $2"
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
			if [[ $ans != "y" && $ans != "yes" && $ans != "n" && $ans != "no" ]]; then
				printf "\n" # Formatting
				ans="y"
			fi
		done
		;;
		no)
		until [[ $ans == "y" || $ans == "yes" || $ans == "n" || $ans == "no" ]]; do
			read -t "$timeoutVal" -p "Please answer above prompt (y/N): " ans
			if [[ $ans != "y" && $ans != "yes" && $ans != "n" && $ans != "no" ]]; then
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
			debug "l2" "ERROR: Incorrect call for function getUserAnswer()! Please look at documentation!"
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
		announce "WARN: Congratulations, you somehow broke my script, Linux, and possibly the universe."
		return 66 #used to be 666, but apparently that isn't allowed. not that it should happene ANYWAYS...
		;;
		*)
		announce "ERROR: You must not be very good at this if you made it here."
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
	debug "l5" "INFO: pause() has been called" # Let's verbose users know what is happening
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
		debug "l3" "ERROR: Incorrect call for editTextFile(), please consult commonFunctions.sh! Script will continue anyways, press CTRL+C to quit!"
		return 1
	fi
	
	# Now, find the editor and run it
	if [[ -z $EDITOR && -z $VISUAL ]]; then
		if [[ -z $(which nano 2>/dev/null) ]]; then
			debug "User error has lead to vi being the only editor, using it as a last resort!"
			# Was gonna delete this when I introduced new debug() format, but this is too good to delete lol
			announce "It seems vi is your only editor. Strange choice, or new installation?" "When done editing, press :wq to exit vi"
			vi "$1"
		else
			debug "INFO: Letting user edit $1 with nano"
			nano "$1"
		fi
	elif [[ -z $EDITOR ]]; then
		debug "INFO: Letting user edit $1 with $VISUAL"
		"$VISUAL" "$1"
	else
		debug "INFO: Letting user edit $1 with $EDITOR"
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

## checkout()
#
# Function: Used for parallel processing. Makes it so only one instance of the specified function can be run at a time, based on the lock variable given
#           Once function is called, it will wait until the specified function is available, waiting random times in ms. Then, it will return so script can continue.
#           It will lock the variable beore returning so no one else can use the function. Make sure to run 'checkout done <var>' when the function is done!
#
# Call: checkout <wait|done> <lockVarName>
#
# Input: Variable you wish to use as the lock for the process
#
# Output: Stderr, if any errors are encountered. Doesn't call debug (minus at beginning) because it could cause infinite loops.
#
# Other: To checkout the function for use, run 'checkout wait <lockVar>'. Be sure to include 'checkout done <lockVar>' when you are done though!
function checkout() {
	if [[ $# -ne 2 ]]; then
		# I know I said not to call debug, but I know how this works and what I'm doing. No infinite loops because I do everything correctly (r/IAmVerySmart)
		debug "l2" "ERROR: Incorrect number of arguments for checkout()! Please read documentation and try again!"
		return 1
	fi
	
	# Assuming the correct number of variables...
	case $1 in
		w*)
		if [[ -z ${!2} ]]; then
			# If the variable isn't declared, function has not been run yet, so safe to continue
			${!2}=1
			return 0
		fi
		
		until [[ ${!2} -eq 0 ]];
		do
			sleep "0$(echo "scale=3; $((RANDOM%50+51)) / 1000" | bc -l )" # This sleeps for a random time between 50-100ms
		done
		${!2}=1 # Variable is locked, ready to roll!
		return 0
		;;
		d*)
		${!2}=0 # Variable unlocked
		return 0
		;;
		*)
		(>2& printf "FATAL: %s is an incorrect option for checkout()! Please read documentation and retry!" "$1")
		return 1
		;;
	esac
}

## importText()
#
# Function: Import the given text (or other newline-delimited file) to the given variable
#           I use this so often I finally decided to make it a common function
#
# Call: importText <filename> <variable> [include_hash]
#
# Input: filename of the text file, variable where the imported file will be stored
#        If the last var is present, function will put ALL lines into the variable, instead of ignoring '#' comments (default)
#
# Output: Stderr for problems, and an ARRAY with the text file contents
#         Return value of 0 on success, value of 1 if there was a problem. Let's the script decide whether or not to quit
#
# Other: NOTE - everything is stored in an array, so when examining it in a loop, make sure you use "$var[@]"!
function importText() {
	# argc check
	if [[ -z $2 ]]; then
		debug "l2" "FATAL: Incorrect call for importText!"
		return 1
	fi
	
	# Make sure we can see the file
	if [[ -f "$1" ]]; then
		local fileName="$1"
	else
		debug "l2" "ERROR: $1 is not a file!"
		return 1
	fi
	local var="$2"
	#declare -a "${var}"
	if [[ ! -z $3 ]]; then
		debug "INFO: importText will import comments as well!"
		comments=1
	fi
	
	# Now, read the file to the variable
	local count=0
	while read -r line
	do
		[[ "$line" == "" || "$line" == " " ]] && continue # Skip blank and empty lines, everytime
		[[ "$line" == \#* && -z $comments ]] && continue # Conditionally skip comments
		
		 mapfile -t -O "$count" "${var}" <<< "$line"
		((count++))
	done < "${fileName}"
	debug "l5" "INFO: Read $count lines into variable $var!"
	return 0
}

## dynamicLinker()
#
# Function: Dynamically link script to given directory, /usr/bin, or first folder in $PATH
#           Location will be determined in the above order
#
# Call: dynamicLinker <script_location> [PATH_location]
#
# Input: Script (if not absolute path, will be converted), location to send links
#
# Output: Stderr if problems occur, otherwise nothing besides log
#
# Other: Works on all files. Also, NOTE: all links will be symbolic!
function dynamicLinker() {
	if [[ -z $1 ]]; then
		debug "l2" "ERROR: No arguments given with dynamicLinker! Please read documentation and try again!"
		return 1
	fi
	
	# Check if path is absolute
	if [[ "$1" == \/* ]]; then
		debug "l1" "INFO: Argument given to dynamicLinker ($1) is absolute, moving on..."
		fullScriptPath="$1"
	elif [[ -z $(ls *"$1"* 2>/dev/null) ]]; then
		debug "l1" "WARN: Script $1 is not in current folder, attempting to determine absolute path..."
		# The following is brought to you by none other than StackOverflow!
		# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
		SOURCE="${BASH_SOURCE[0]}"
		while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
		  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
		  SOURCE="$(readlink "$SOURCE")"
		  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
		done
		fullScriptPath="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
	else
		debug "l1" "WARN: Path is not absolute, but script is present in directory. Combining and moving on..."
		fullScriptPath="$(pwd)"/"$1"
	fi
	
	if [[ -z $fullScriptPath ]]; then
		debug "l2" "FATAL: Script location could not be determined! Please manually link scripts!"
		return 1
	fi
	
	# Absolute path set, now determine which path to link to
	if [[ ! -z $2 ]]; then
		if [[ ! -d "$2" || -z $(echo "$PATH" | grep "$2") ]]; then
			debug "l2" "ERROR: Given argument $2 is not a directory, or is not in user's path! Please fix and re-run!"
			return 1
		fi
		debug "l1" "INFO: Given argument $2 is in user's path! Moving on..."
		linkLocation="$2"
	elif [[ ! -z $(echo "$PATH" | grep /usr/bin) ]]; then
		debug "l1" "INFO: No PATH given, assuming /usr/bin. Continuing..."
		linkLocation="/usr/bin"
	else
		# No PATH given and /usr/bin somehow not in user's path. Use first directory from PATH instead
		linkLocation="$(echo "$PATH" | cut -d':' -f1)"
		debug "l2" "WARN: No path given, and /usr/bin not in user's PATH! Resorting to first PATH instead, $linkLocation..."
	fi
	
	if [[ "$linkLocation" != \/* ]]; then
		debug "l2" "FATAL: Path ($linkLocation) is not absolute! Please link manually!"
		return 1
	fi
	
	# Finally, figure out the how many links to do
	numLinks=1 # Full script name
	if [[ ! -z $(cat "$fullScriptPath" | grep longName=) ]]; then
		((numLinks+=2))
	fi
	if [[ ! -z $(cat "$fullScriptPath" | grep shortName=) ]]; then
		((numLinks+=4))
	fi
	
	# And now, for our grand finale, watch as we link everything together!
	debug "l2" "WARN: Linking requires sudo privileges, please provide when asked!"
	while [[ $numLinks -gt 0 ]]; do
		case $numLinks in
		1)
			linkName="$linkLocation"/"$(echo "$fullScriptPath" | rev | cut -d'/' -f1 | rev)"
			((numLinks-=1))
			;;
		3)
			#linkName="$(echo "$fullScriptLocation" | rev | cut -d'/' -f1 --complement | rev)"
			linkName="$linkLocation"/"$(cat "$fullScriptPath" | grep longName= | cut -d'=' -f2 | sed -e 's/\"//g')"
			((numLinks-=2))
			;;
		[57])
			#linkName="$(echo "$fullScriptLocation" | rev | cut -d'/' -f1 --complement | rev)"
			linkName="$linkLocation"/"$(cat "$fullScriptPath" | grep shortName= | cut -d'=' -f2 | sed -e 's/\"//g')"
			((numLinks-=4))
			;;
		*)
			debug "l2" "ERROR: Unexpected case number in dynamicLinker()! Returning, please link manually..."
			return
			;;
		esac
		if [[ -e "$linkName" ]]; then
			debug "l2" "ERROR: Link/file at $linkName already exists, skipping and continuing!"
		else
			debug "l1" "INFO: Attempting to link $fullScriptPath to $linkName"
			sudo ln -s "$fullScriptPath" "$linkName"
			val="$?"
			if [[ $val -ne 0 ]]; then
				debug "l2" "ERROR: And error occurred while attempting a link $fullScriptPath to $linkName! Error code: $val"
			fi
		fi
		#((numLinks--))
	done
	# Done with function
}

# This following, which SHOULD be run in every script, will enable debugging if -v|--verbose is enabled.
# The 'shift' command lets the scripts use the rest of the arguments
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
	echo "INFO: Running in verbose mode!"
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
		echo "ERROR: packageManagerCF.sh could not be located!"

		# Comment/uncomment below depending on if script actually uses common functions
		#echo "Script will now exit, please put file in same directory as script, or link to /usr/share!"
		#exit 1
	fi
fi

#EOF