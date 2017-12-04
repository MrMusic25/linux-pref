#!/bin/bash
#
# setupCommands.sh - A script that will ask to run different commands that get exported to .bashrc and /root/.bashrc
# Didn't mean for this to become a whole shell script, but because of how bash works, I was forced to
# Note: I will NOT be tracking changes to this script! Also, I wouldn't run this by itself!

### Variables

lngName="setupCommands"
shortName="sc"

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

function uecho() {
	getUserAnswer "Would you like to run $@ as $USER?"
	case $? in
		0)
		debug "Running $@ as $USER"
		echo "$@" | tee -a ~/.bashrc
		;;
		1)
		debug "Not running $@ for $USER"
		;;
		*)
		debug "ERROR: Unexpected value for uecho() in $0"
		exit 1
		;;
	esac
	
	getUserAnswer "Would you like to run $@ as root?"
	case $? in
		0)
		debug "Running $@ as root"
		echo "$@" | sudo tee -a /root/.bashrc
		;;
		1)
		debug "Not running $@ for root"
		;;
		*)
		debug "ERROR: Unexpected value for uecho() in $0"
		exit 1
		;;
	esac
}

### Main Script

# If you value your sanity, NEVER delete the following line!
uecho "PATH=$PATH:/usr/games" # Do not run this as USER, only as root!
uecho "export PATH" # Do not run a USER, only as root!
uecho "fortune | cowsay | lolcat"

#EOF
