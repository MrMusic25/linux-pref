#!/bin/bash
#
# mailScript.sh - A script to setup and send messages through SMTP
#
# Changes:
#
# v0.0.2
# - More work on config
# - For now, config will now exit if not in linux-pref/
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
# - Make attachments comma-delimited
#   ~ Can't imagine sending more than one attachment at once, but that's not the point. Always be dynamic as possible!
# - High priotity email
# - Make config runnable from anywhere
#
# v0.0.2, 03 Feb. 2018, 17:27 PST

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
-a | --attachment <file>     : Attach a file to the email. Use as many times as necessary.

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
			((attachmentSize+=$(stat --printf="%s" "$2"))) # Get size of file and add to attachmentSize
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
	# Make sure folder is linux-pref/
	if [[ "$(pwd)" != *linux-pref ]]; then
		debug "l2" "FATAL: Please run $longName setup from linux-pref/ directory! Exiting..."
		exit 1
	fi
	
	# First, check if config location is free
	if [[ -e "$configLocation" ]]; then
		debug "l3" "ERROR: Config file at $configLocation already exists!"
		getUserAnswer "Would you like to overwrite this file?"
		if [[ $? -eq 1 ]]; then
			debug "WARN: User chose not to overwirte config, exiting..."
			exit 1
		fi
		
		# else, move on. Backup config, just in case
		debug "INFO: Backing up $configLocation to $configLocation.bak!"
		mv "$configLocation" "$configLocation".bak
	fi
	
	debug "l2" "INFO: Creating config! Can be found later at $configLocation!"
	#touch "$configLocation"
	
	# Enter email, then search for settings 
	until [[ "$emailAddr" == *@*.* ]]; do
		read -p "Please enter the email you would like to use: " emailAddr
	done
	
	domain="$(echo "$emailAddr" | cut -d'@' -f2)"
	subCount="$(echo "$domain" | sed -e 's/\(.\)/\n/g' | grep . | wc -l)" # Gets number of dots in domain, indicating subdomains
	found=0
	while [[ "$subCount" -gt 1 && "$found" -eq 0]]; do
		if [[ -f mailScriptSettings/"$domain" ]]; then
			found=1
		else
			domain="$(echo "$domain" | cut -d'.' -f1 --complement)"
		fi
	done
	
	# Assume domain is now <domain>.<tld>
	if [[ $found -eq 0 ]]; then
		if [[ -f mailScriptSettings/"$domain" ]]; then
			found=1
		fi
	fi
	
	if [[ $found -eq 1 ]]; then
		if [[ "$domain" != "$(echo "$emailAddr" | cut -d'@' -f2)" ]]; then
			debug "l2" "WARN: Settings for $(echo "$emailAddr" | cut -d'@' -f2) not found, but exist for subdomain $domain!"
			getUserAnswer "No gurantees it will work, but would you like to use subdomain settings?"
			if [[ $? -eq
		debug "INFO: Settings found for domain $domain!"
		cp mailScriptSettings/"$domain" "$configLocation"
	else
		debug "l2" 
}
### Main Script

checkRequirements "msmtp" "gpg/gpgme" # The SMTP client I have chosen to use for this project. Mostly due to better documentation.
processArgs "$@"

#EOF