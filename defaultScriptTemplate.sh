#!/bin/bash
#
# <Insert script name and info blurb here>
#
# Changes:
# v0.0.1
# - Initial version
#
# v0.0.1, <Insert date here>

### Variables

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

### Functions



### Main Script



#EOF