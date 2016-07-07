#!/bin/bash
#
# programInstaller.sh - Used to install programs from a text-based, tab-delimited source
# Usage: ./programInstaller.sh <programs.txt>
#
# Determines which package manager is being used, then installs all the packages listed in programs.txt (or argument, if provided)
#
# Changes:
# v1.1.7
# - Changed where $log was declared so script works properly again
# - Added ending debug statement
#
# v1.1.6
# - Script is now using $debugPrefix
#
# v1.1.5
# - Changed script to use checkPrivilege()
#
# v1.1.4
# - Added the ability to source from /usr/share automatically
#
# v1.1.3
# - Got rid of sleep statements, as I added it to announce()
#
# v1.1.2
# - Added dnf to programs, added commands for clean and upgrade
#
# v1.1.1
# - Syntax change, now multiple programs on one line will install at the same time
#
# v1.1
# - Script now uses commonFunctions.sh
# - Changed most output to use announce() and debug()
# - determinePM() redirects to /dev/null now because it is not important to view except on failure
#
# v1.1.7 07 July, 2016, 11:49 PST

### Variables

file="programs.txt"
#program="NULL"
#log="$debugPrefix/pm.log"

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

### Main script
log="$debugPrefix/pm.log"
debug "Starting $0..." $log
# First, check to see is user is root/sudo. Makes scripting easier
checkPrivilege "exit" #lol

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

# Now we can install everything
while read -r line; do
	[[ $line = \#* ]] && continue # Skips comment lines
	universalInstaller "$line"
done < $file

announce "Done installing programs!"
debug "Finished $0 at $(date)" $log
#EOF