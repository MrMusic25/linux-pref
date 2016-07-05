#!/bin/bash
#
# INSTALL.sh - A script meant to automatically install and setup my personal favorite options
# Usage: ./INSTALL.sh
#
# Note: This will change soon as functionality is added
# 
# v0.1 05 July 2016 13:06 PST

### Variables



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