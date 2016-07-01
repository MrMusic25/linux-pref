#!/bin/bash
#
# Usage: ./programInstaller.sh <programs.txt>
#
# Determines which package manager is being used, then installs all the packages listed in programs.txt (or argument, if provided)
#
# Changes:
#
# v1.1
# - Script now uses commonFunctions.sh
# - Changed most output to use announce() and debug()
# - determinePM() redirects to /dev/null now because it is not important to view except on failure
#
# v1.1 01 July, 2016, 13:10 PST

### Variables

file="programs.txt"
#program="NULL"
log="pm.log" # Remember to change this to 'install-logs/pm.log' when other scripts ready

### Functions

if [[ ! -f commonFunctions.sh ]]; then
	echo "commonFunctions.sh could not be found!" 
	echo "Please place in the same directory or create a link in $(pwd)!"
	exit 1
else
	source commonFunctions.sh
fi

### Main script

# First, check to see is user is root/sudo. Makes scripting easier
if [ "$EUID" -ne 0 ]; then
	announce "This script require root privileges, please run as root or sudo!"
	exit 2
fi

# Checks for argument and sets as file location
if [[ $# != 0 ]]; then
	file=$1
fi


# Test to make sure file valid
if [[ ! -e $file ]]; then
	announce "$file could not be found! Please check and re-run script!"
	exit 1
fi

# Now that file is valid, determine program to use
announce "Determining package manager and updating the package lists." "This may take time depending on internet speed and repo size."
determinePM &>/dev/null

debug "This distribution is using $program as it's package manager!" $log
announce "Now installing programs listed in $file!" "This may take a while depending on number of updates and internet speed" "Check $log for details"
sleep 2

# Now we can install everything
while read -r line; do
	[[ $line = \#* ]] && continue # Skips comment lines
	universalInstaller $line
done < $file

announce "Done installing programs!"

#EOF