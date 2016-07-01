#!/bin/bash
#
# commonFunctions.sh - A collection of functions to be used in this project
#
# Note: this script whould not be run by itself, as it only contains functions and variables
#
# v1.0 29 June 2016 13:38 PST

### Variables

program="NULL" # This should be the start point for most scripts

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
		echo "Package manager not found! Please update script or diagnose problem!"
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
	let "stars += 9" # 4 beginning characters and 5 trailing
	
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
		printf "\n*** ${!i} \n"
	done
	
	#Finally, print ending stars
	printf "\n"
	for k in `seq 1 $stars`;
	do
		printf "*"
	done
	printf "\n\n"
}