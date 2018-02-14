#!/bin/bash
#
# mailScript.sh - A script to setup and send messages through SMTP
#
# Changes:
#
# v0.0.1
# - Initial version
# - Got displayHelp() and processArgs() ready for everything else
#
# TODO:
# - Include options to change defaults
#   ~ e.g. Load default config, then overwrite SMTP address, or port, etc
#   ~ Not too many use cases, and too much to code for now, so maybe in a later release
# - Accept piped input
#   ~ Looked easy at first, but it's not. Save it for a later release.
#
# v0.0.1, 13 Feb. 2018, 23:22 PST

### Variables

longName="mailScript"
shortName="ms"
attachmentSize=0 # Total attachment size, in bytes
maxAttachmentSize=20000000 # Maximum size of all attachements, in bytes
configLocation="$HOME/.msConfig.conf" # Default location to check
declare -a attachments # For when the user sends attachments
subject="Message from $(whoami 2>/dev/null)" # Subject used when sending emails

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

Usage: mailScript.sh [options] [emailSubject] <emailAddress> <messageContents OR message.txt>

Options:
-h | --help                  : Display this help message and exit
-v | --verbose               : Prints verbose debug information. MUST be the first argument!
-s | --setup [file]          : Initiates setup of mailScript, then exits. Will optionally write config to file
-c | --config <file>         : Use given config file to run mailScript
-a | --attachment <file>     : Attach a file to the email. Use as many times as

By default, script will use config file at $HOME/.msConfig.conf
If not found, will try /usr/share/.msConfig.conf
When using a file, the whole file will be sent as text, not as an attachment
Email subject not required, defaults to "Message from {username}"

endHelp
echo "$helpVar"
}

function processArgs() {
	if [[ $# -lt 1 ]]; then
		debug "l2" "ERROR: No arguments given! Please fix and re-run"
		displayHelp
		exit 1
	fi
	
	loopFlag=0
	while [[ $loopFlag -eq 0 ]]; do
		key="$1"
			
		case "$key" in
			-h|--help)
			displayHelp
			exit 0
			;;
			-s|--setup)
			debug "INFO: Generating config at user request!"
			if [[ ! -z $2 ]]; then
				configLocation="$2"
				shift
			fi
			createConfig
			exit "$?"
			;;
			-c|--config)
			if [[ -z $2 ]]; then
				debug "l2" "ERROR: No config file given with option $key! Please fix and re-run!"
				displayHelp
				exit 1
			elif [[ ! -e "$2" ]]; then
				debug "l2" "ERROR: Given file $2 is not readable, or does not exist! Please fix and re-run!"
				displayHelp
				exit 1
			fi
			configLocation="$2"
			shift
			;;
			-a|--attachment)
			if [[ -z $2 ]]; then
				debug "l2" "ERROR: No attachment given with option $key! Please fix and re-run"
				displayHelp
				exit 1
			elif [[ ! -e "$2" || -d "$2" ]]; then
				debug "l2" "ERROR: Attachment $2 either does not exist, or is not a file! Please fix and re-run!"
				displayHelp
				exit 1
			fi
			attachments+=("$2")
			((attachmentSize+=$(stat --printf="%s" "$2"))) # Get size of  file and add to attachmentSize
			shift
			;;
			*)
			debug "l2" "ERROR: Unknown option given: $key! Please fix and re-run"
			displayHelp
			exit 1
			;;
		esac
		shift
	done
}

# Creates config file
function createConfig() {
	return
}
### Main Script

processArgs "$@"

#EOF