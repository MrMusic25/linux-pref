#!/bin/bash
#
# gitCheck.sh - Script that will pull from a git repo every X minutes
#
# Usage: ./gitCheck.sh [options] <working_git_directory>
#
# Relies on the .git folder in the directory to be able to pull, therefore must be setup beforehand!
#
# v0.1, 05 July 2016 16:40 PST

### Variables

sleepTime=900 # Time in seconds to wait until going through loop again. 900 seconds (15 minutes) by default

### Functions 

if [[ -f commonFunctions.sh ]]; then
	source commonFunctions.sh
elif [[ -f /usr/share/commonFunctions.sh ]]; then
	source /usr/share/commonFunctions.sh
else
	echo "commonFunctions.sh could not be located!"
	
	# Comment/uncomment below depending on if script actually uses common functions
	#echo "Script will now exit, please put file in same directory as script, or link to /usr/share!"
	#exit 1
fi

### Main Script



#EOF