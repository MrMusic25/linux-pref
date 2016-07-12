#!/bin/bash
#
# commonFunctions.sh - A collection of functions to be used in this project
#
# Note: this script whould not be run by itself, as it only contains functions and variables
#
# Changes:
# v1.4
# - Added a re-run as sudo option to update.sh, then decided to make is common as part of checkPrivilege()
# - ctrl_c now kill hung process first, then asks to exit. Safety measure
#
# v1.3.1
# - ctrl_c() now send a SIGINT to kill process
#
# v1.3
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
# v1.2
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
# v1.1
# - Added announce() and debug() functions
#
# v1.4 12 July 2016 15:47 PST

### Variables

program="NULL" # This should be the start point for most scripts
debugFlag=0
privilege=0 # 0 if root, 777 if not
debugInit=0
debugPrefix="$HOME/.logs" # Use: scriptLog="$debugPrefix/scriptLog.log", then include $scriptLog in debug() statements

cFlag=0 # Used with the ctrl_c function
trap ctrl_c INT # This will run the function ctrl_c() when it captures the key press

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
if [[ ! -z $(which apt-get) ]]; then # Most common, so it goes first
	export program="apt"
	apt-get update
elif [[ ! -z $(which dnf) ]]; then # This is why we love DistroWatch, learned about the 'replacement' to yum!
	export program="dnf"
	dnf check-update
elif [[ ! -z $(which yum) ]]; then
	export program="yum"
	yum check-update
elif [[ ! -z $(which rpm) ]]; then
	export program="rpm"
	rpm -F --justdb # Only updates the DB, not the system
elif [[ ! -z $(which yast) ]]; then # YaST is annoying af, so look for rpm and yum first
	export program="yast"
elif [[ ! -z $(which pacman) ]]; then
	export program="pacman"
	pacman -yy # Refreshes the repos, always read the man pages!
elif [[ ! -z $(which aptitude) ]]; then # Just in case apt-get is somehow not installed with aptitude, happens
	export program="aptitude"
	aptitude update
fi
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
		apt-get install -y $var  
		;;
		dnf)
		dnf -y install $var
		;;
		yum)
		yum install $var 
		;;
		yast)
		yast -i $var 
		;;
		rpm)
		rpm -i $var 
		;;
		pacman)
		pacman -S $var 
		;;
		aptitude)
		aptitude install -y $var 
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
# Other info: Try not to make text too long, it may not display correctly
function announce() {
	# Determine highest amount of chars
	stars=0
		for j in "$@"; # Stupid quotation marks killed the whole thing.... ugh....
	do
		if [[ ${#j} -gt $stars ]]; then
			export stars=${#j}
		fi
	done
	let "stars += 8" # 4 beginning characters and 4 trailing
	
	# Now print beginning set of stars
	printf "\n\n"
	for l in `seq 1 $stars`;
	do
		printf "*"
	done
	printf "\n"
	
	# Now, print announcements
	for i in `seq 1 $#`;
	do
		printf "\n*** ${!i} ***\n"
	done
	
	#Finally, print ending stars
	printf "\n"
	for k in `seq 1 $stars`;
	do
		printf "*"
	done
	printf "\n\n"
	sleep 2
}

## debug()
# Function: When enabled, it allows you to send debug messages to a log or stdout
# PreReq: 'export debugFlag=1' if you want stdout
#
# Call: debug <message> [log_file]
#
# Input: Text string for input. If log_file is present, it will echo>> to that file as well with 'Debug:' to denote debug output
#        Note: Message will only output if debugFlag=1, so that debug code doesn't need to be erased or commented out
#
# Output: stdout, no return value
#
# Other info: If log_file is present, it will ALWAYS send debug message to log - useful when sharing scripts
#             Note: Debug also runs 'touch' on file if not present, no need to do so in script now!
function debug() {
	# It would be kinda awkward trying to write to a non-existent directory... Hate to run it every call but it is necessary
	if [[ ! -d $debugPrefix ]]; then
		mkdir $debugPrefix
	fi
	
	# Echoes the message if debug flag is on
	if [[ $debugFlag -eq 1 ]]; then
		echo "Debug: $1"
	fi
	
	if [[ ! -z $2 ]]; then
		if [[ ! -f $2 ]]; then
			touch "$2"
		fi
	
		# Initilize the log file
		if [[ $debugInit -eq 0 ]]; then
			export startTime=$(date)
			echo " " >> "$2"
			echo "*** Started at $startTime ***" >> "$2"
			echo " " >> "$2"
			export debugInit=1
		fi
		
		echo "$1" >> "$2"
	fi
}

## checkPrivilege()
# Function: Simple function to check if this script is being run as root or sudo, in case it is necessary
#
# Call: checkPrivilege [exit]
#
# Input: Only accepts the word "exit" as an argument
#
# Output: stdout, sets privilege to 777 if not root; this allows you to call sudo <command>, or exit entire script
#
# Other info: Just calling will return 777; calling with the word "exit" at the end will kill the current script if not root
function checkPrivilege() {
if [ "$EUID" -ne 0 ]; then
	announce "This script require root privileges, please run as root or sudo!"
	export privilege=777
	
	# Only exits if the flag ($1) is set
	if [[ "$1" == "exit" ]]; then
		exit 777
	fi
	
	if [[ "$1" == "ask" ]]; then
		announce "Script will now re-run itself as root, please provide password when prompted!"
		sudo $0
		exit $?
	fi
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