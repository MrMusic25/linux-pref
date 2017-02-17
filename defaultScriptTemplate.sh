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

# These variables are used for logging
# longName is preferred, if it is missing it will use shortName. If both are missing, uses the basename of the script
longName="defaultScriptTemplate"
#shortName="dst"

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
# The following will read all text between the words 'helpVar' into the variable $helpVar
# The echo at the end will output it, exactly as shown, to the user
read -d '' helpVar <<"endHelp"

scriptName.sh - A script to perform a function or fulfill a purpose
Be sure to look at all the options below

Usage: ./scriptName.sh [options] <required_argument> <also_required> [optional_argument]

Options:
-h | --help                         : Display this help message and exit
-o | --option                       : Option with an alias (default)
--output-only                       : Option with no shotrened name
-i | --include <file1> [file2] ...  : Option including possibly more than one argument
-a | --assume <[Y]es or [N]o>       : Option that supports full or shortened argument names
-v | --verbose                      : Prints verbose debug information. MUST be the first argument!

Put definitions, examples, and expected outcome here

endHelp
echo "$helpVar"
}

function processArgs() {
	# displayHelp and exit if there is less than the required number of arguments
	# Remember to change this as your requirements change!
	if [[ $# -lt 1 ]]; then
		debug "l2" "ERROR: No arguments given! Please fix and re-run"
		displayHelp
		exit 1
	fi
	
	# This is an example of how most of my argument processors look
	# Psuedo-code: until condition is met, change values based on input; shift variable, then repeat
	while [[ $loopFlag -eq 0 ]]; do
		key="$1"
		
		# In this example, if $key and $2 are a file and a directory, then processing arguments can end. Otherwise it will loop forever
		# This is also where you would include code for optional 3rd argument, otherwise it will never be processed
		if [[ -f "$key" && -d "$2" ]]; then
			inputFile="$key"
			outputDir="$2"
			
			if [[ -f "$3" ]]; then
				tmpDir="$3"
			fi
			loopFlag=1 # This will kill the loop, and the function. A 'return' statement would also work here.
		fi
			
		case "$key" in
			--output-only) # Long, unaliased names should always go first so they do not create errors. Try to avoid similar names!
			outputOnly="true"
			;;
			-h|--help)
			displayHelp
			exit 0
			;;
			-o|--option)
			option=1
			;;
			-i|--include)
			# Be careful with these, always check for file validity before moving on
			# Doing it this way makes it you can add as many files as you want, and then continuing
			until [[ "$2" == -* ]]; do # Keep looping until an option (starting with a - ) is found
				if [[ -f "$2" ]]; then
					# This adds the filename to the array includeFiles - make code later to perform an action on each file
					includeFiles+=("$2")
					shift
				else
					# displayHelp and exit if the file could not be found, safety measure
					debug "l2" "ERROR: Argument $2 is not a valid file or argument!"
					displayHelp
					exit 1
				fi
			done
			;;
			-a|--assume)
			if [[ "$2" == "Y" || "$2" == "y" || "$2" == "Yes" || "$2" == "yes" ]]; then
				assume="true"
				shift
			elif [[ "$2" == "N" || "$2" == "n" || "$2" == "No" || "$2" == "no" ]]; then
				assume="false" # If this is the default value, you can delete this line, used for example purposes
				shift
			else
				# Invalid value given with -a, report and exit!
				debug "l2" "ERROR: Invalid option $2 given with $key! Please fix and re-run"
				displayHelp
				exit 1
			fi
			;;
			*)
			# Anything here is undocumented or uncoded. Up to user whether or not to continue, but it is recommended to exit here if triggered
			debug "l2" "ERROR: Unknown option given: $key! Please fix and re-run"
			displayHelp
			exit 1
			;;
		esac
		shift
	done
}

### Main Script

processArgs "$@" # Make sure to include the "$@" at the end of the call, otherwise function will not work

#EOF