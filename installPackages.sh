#!/bin/bash
#
# installPackages.sh - A script that will attempt to install every package name given as an argument
#
# Usage: installPackages.sh <packages>
#
# Like my other scripts, it will install the packages one at a time. This is to prevent failed installation because one package could not be found
# Also like always, putting multiple items in quotes will install those items together
#
# Changes: 
# v1.0.3
# - Script now quits when run as sudo on Arch-based systems
#
# v1.0.2
# - Updated call for checkPrivilege()
#
# v1.0.1
# - Added a check to exit early if there are no arguments
#
# v1.0.0
# - Initial commit
# - Short and sweet, I would be suprised if I ever have to change this script
#
# v1.0.3 16 Aug. 2016 21:27 PST

### Variables



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

### Main Script

# Make sure there are arguments before running
if [[ $# -eq 0 ]]; then
	debug "No arguments given, quitting early!"
	echo "ERROR: Please provide packages to install!"
	echo "Usage: $0 <package_to_install> [package_to_install] . . . "
	exit 1
fi

# Check if root, run as root if not already

# Comment out this block if you login as root by default on Arch
determinePM
if [[ "$program" == "pacman" && "$EUID" -eq 0 ]]; then
	announce "Arch-based distributions do not require root privilege." "Please re-run script without sudo, or as normal user!"
	exit 1
else
	[[ ! "$program" == "pacman" ]] && checkPrivilege "ask" "$@" # I will chuckle everytime I have to type this lol
fi

announce "Now attempting to install programs!"
universalInstaller "$@"

debug "Done with script!"
#EOF