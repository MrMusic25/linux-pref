#!/bin/bash
#
# mailScript.sh - A script to setup and send messages through SMTP
#
# Changes:
#
# v1.0.0
# - Tested, working, and ready for release! Not happy about some of my choices, but damn it, it works now!
# - After functional testing, cleartext is the way to go. Just do your best to obfuscate the password
# - Forgot about local function variables, added shift outside the processArgs loop
# - Added some code for a "txt" mode, for sending to phones. Useless for now, will likely require a function in the future. Proof-read your messages for now!
#
# v0.2.2
# - After research and some considerations, encryption may not be the way to go.
# - Instead, warning user to use 2FA, or a dummy email account
#
# v0.2.1
# - Added correct number of spaces for output to config file
# - Other minor output changes
# - Fixed lines with tee to redirect stdout to /dev/null
# - Added tail to name calculation in createConfig()
# - Learned that it meant local used with gpg; can't get gpg to work though, so might find a different crypto program
#
# v0.2.0
# - Script needs to be tested, but everything should be ready for use now
# - msmtp cannot send files. So, until further notice, ATTACHMENTS WILL NOT WORK. Will be implemented soon (after release)
# - Added -g option for global config
#
# v0.1.0
# - Untested, but createConfig() is ready
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
# - Add default port for manual input
# - Add ability to send locally
#   ~ Similar to sendmail for cron jobs, etc
# - Use mutt for attachments
#   ~ Should be a way to convert necessary options from msmtp config to mutt config
#
# v1.0.0, 10 Mar. 2018, 21:47 PST

### Variables

longName="mailScript"
shortName="ms"
attachmentSize=0 # Total attachment size, in bytes
maxAttachmentSize=20000000 # Maximum size of all attachements, in bytes
configLocation="$HOME/.msConfig.conf" # Default location to check
#gpgFile="$HOME"/.ms-cred.gpg # Default location for password file
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
-g | --global                : Force use of the global config, if it exists. 
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
		
		if [[ "$key" == *@* ]]; then
			# Assume we have reached the email address; set and move on
			sendToAddr="$key"
			shift # Everything else is the message contents
			message="$@"
			return 0
		elif [[ "$2" == *@* && "$key" != -* ]]; then
			# Optional subject
			subject="$key"
			sendToAddr="$2"
			shift
			shift
			message="$@"
			debug "INFO: Subject given: $subject"
			return 0
		fi
		
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
			debug "INFO: Using user-specified config at $configLocation"
			shift
			;;
			-g|--global)
			if [[ ! -e /usr/share/.msConfig.conf ]]; then
				debug "l2" "FATAL: No global configuration found! Please run setup and try again!"
				exit 1
			else
				debug "WARN: Using global config!"
				configLocation=/usr/share/.msConfig.conf
			fi
			;;
			-a|--attachment)
			debug "l3" "WARN: Attachments not supported, check for a future release!"
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

# Creates config file at $configLocation
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
		emailAddr="$(echo "$emailAddr" | awk '{print tolower($0)}')" # Convert email address toLower, email is case-insensitive
	done
	
	domain="$(echo "$emailAddr" | cut -d'@' -f2)"
	accountName="$(echo "$domain" | cut -d'.' -f1)" # Used for account info output
	subCount="$(echo "$domain" | sed -e 's/\(.\)/\n/g' | grep . | wc -l)" # Gets number of dots in domain, indicating subdomains
	found=0
	
	# Check subdomains
	while [[ "$subCount" -gt 1 && "$found" -eq 0 ]]; do
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
	
	# I hate the way I did these next few if statements, hopefully I can come back and fix them later
	origDomain="$(echo "$emailAddr" | cut -d'@' -f2)"
	origDomain="$(echo "$origDomain" | awk '{print tolower($0)}')"
	if [[ $found -ne 0 && "$domain" != "$origDomain" ]]; then
		debug "l2" "WARN: Settings for $origDomain not found, but exist for subdomain $domain!"
		getUserAnswer "No gurantees it will work, but would you like to use subdomain settings?"
		if [[ $? -eq 0 ]]; then
			debug "WARN: Attempting to use subdomain settings!"
			#debug "INFO: Settings found for domain $domain!"
			cp mailScriptSettings/"$domain" "$configLocation"
		fi
	elif [[ $found -ne 0 ]]; then
		debug "l2" "INFO: Settings found for domain $domain! Copying and continuing..."
		cp mailScriptSettings/"$domain" "$configLocation"
	else
		domain="$origDomain"
		debug "WARN: No settings found for $domain or subdomains, asking for manual input"
		announce "No settings found for $domain domain!" "Please find them online, and enter settings into the following prompts."
		
		# get SMTP address
		read -p "Please enter the SMTP address: " smtpAddr # Just gonna have to assume this is correct
		#getUserAnswer "Is this TLS or SSL? Answer [y]es for TLS, [n]o for SSL."
		#enc="$?" # 0 for TLS, 1 for SSL
		
		# get port number
		portNum="abc" # In order for loop to work
		until [[ $portNum -eq $portNum ]]; do # Just to make sure port is only numbers
			read -p "What port number does this use? " portNum
		done

		cp mailScriptSettings/default "$configLocation"
		printf "\# %s\naccount        %s\nhost           %s\nport           %s\n" "$accountName" "$accountName" "$smtpAddr" "$portNum" | tee -a "$configLocation" 1>/dev/null
	fi
	
	# determine outgoing address
	getUserAnswer "Would you like to use a different 'from' address than $emailAddr?"
	if [[ $? -eq 0 ]]; then
		until [[ $fromAddr == *@* ]]; do
			read -p "Please enter the from address: " fromAddr
		done
	else
		fromAddr="$emailAddr"
	fi
	
	printf "from           %s\nuser           %s\npassword       %s\n" "$fromAddr" "$emailAddr" "$pass" | tee -a "$configLocation" 1>/dev/null
	
	# Now, for the password
	announce "Next, you will be asked to enter a password." "It is highly recommended to create an app-specific password for this!" "This is very necessary with systems using 2FA!" "Or, if possible, use a dummy account or an open relay!"
	
	stty -echo # Trick I found to make stdin invisible
	read -p "Please enter the password now: " pass
	stty echo
	
	#printf "%s" "$pass" > "$gpgFile"
	
	# Set the account default
	name="$(cat "$configLocation" | grep account | tail -n1 | rev | cut -d' ' -f1 | rev)"
	printf "\naccount default : %s\n" "$name" | tee -a "$configLocation" 1>/dev/null
	
	chmod 600 "$gpgFile" # Keeps file as hidden as possible
	
	# Done at this point. But now ask user if you want to make this global
	getUserAnswer "Would you like to make this configuration global? NOTE: This will require sudo"
	if [[ $? -eq 0 ]]; then
		debug "WARN: Making config global per user request"
		sudo ln -s "$configLocation" /usr/share/.msConfig.conf
		
		announce "NOTE: User config will always take priority over global config!" "You can override this with the -u option!"
	fi
	
	# Wrap things up and exit
	debug "l2" "INFO: Done setting up config at $configLocation!"
	getUserAnswer "n" "It is recommended to rebot to clear memory of cleartext password. Would you like to do this now?"
	if [[ $? -eq 0 ]]; then
		sudo reboot
	fi
	return 0
}

### Main Script

checkRequirements "msmtp" # The SMTP client I have chosen to use for this project. Mostly due to better documentation.
processArgs "$@"

# Make sure config exists, and use global if not found
if [[ ! -f "$configLocation" ]]; then
	debug "l2" "ERROR: Given config at $configLocation not found! Trying global config..."
	if [[ -f /usr/share/.msConfig.conf ]]; then
		debug "l2" "WARN: Global config found, attempting to use!"
		configLocation=/usr/share/.msConfig.conf
	else
		debug "l2" "FATAL: No config found or given! Please fix and re-run! Exiting..."
		sleep 2
		displayHelp
		exit 1
	fi
fi

# Make sure we somehow didn't get to this step without valid send-to addr
if [[ -z $sendToAddr ]]; then
	debug "l2" "FATAL: Send-to address not found! Please fix call and re-run! Exiting..."
	exit 1
elif [[ "$sendToAddr" != *@*.* ]]; then
	debug "l2" "WARN: $sendToAddr does not follow standard convention of *@*.* . Email might not send, attempting anyways..."
fi

# Make sure message is set
if [[ -z $message ]]; then
	debug "l2" "ERROR: Message is empty, cannot send! Exiting..."
	exit 1
fi

# Almost ready to send. Check if "message" is a text file
if [[ -f "$1" ]]; then
	tmp="$(file -i "$1" | grep text)"
	if [[ -z $tmp ]]; then 
		# $1 is a file, but not a text file. Assume message?
		debug "l2" "ERROR: $1 is a file, but not a text file... Assuming part of message, confinuing."
	else
		debug "INFO: Text file $1 given for message body, using it!"
		mode="message"
	fi
fi

# Finally, time to send a message
debug "INFO: Sending message with given options to $sendToAddr!"
if [[ "$mode" == message ]]; then
	printf "%s\n" "$(cat "$1")" | msmtp -C "$configLocation" "$sendToAddr"
	val=$?
elif [[ "$mode" == txt ]]; then
	printf "%s\n" "$(echo "$message" | sed -e 's/\n/; /g')" | msmtp -C "$configLocation" "$sendToAddr" # Text messages look weird
	val=$?
else
	printf "%s\n" "$message" | msmtp -C "$configLocation" "$sendToAddr"
	val=$?
fi

# Report error/success
if [[ $val -eq 0 ]]; then
	debug "INFO: Message sent successfully!"
else
	debug "l2" "ERROR: Message may not have sent, non-zero return value of $val!"
fi

debug "l3" "INFO: Done with script!"

#EOF
