#!/bin/bash
#
# <Insert script name and info blurb here>
#
# Changes:
# v0.0.1
# - Initial version
#
# TODO:
# - Things to do go here
#   ~ Use spaces because I said so
#     ~ Separate levels like this
#
# v0.0.1, <Insert date here>

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

function displayHelp() {
read -d '' helpVar <<"endHelp"

scriptName.sh - A script to perform a function or fulfill a purpose
Be sure to look at all the options below

Usage: ./scriptName.sh [options] <required_argument> <also_required> [optional_argument]

Options:
-o | --option                       : Option with an alias (default)
--output-only                       : Option with no shotrened name
-i | --include <file1> [file2] ...  : Option including possibly more than one argument
-a | --assume <[Y]es or [N]o>       : Option that supports full or shortened argument names
-v | --verbose                      : Prints verbose debug information. MUST be the first argument!

Put definitions, examples, and expected outcome here

endHelp
echo "$helpVar"
}

### Main Script



#EOF