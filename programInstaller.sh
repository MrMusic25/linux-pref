#!/bin/bash
#
# programInstaller.sh - Used to install programs from a text-based, tab-delimited source
# Usage: ./programInstaller.sh <list_of_programs.txt>
#
# Determines which package manager is being used, then installs all the packages listed in programs.txt (or argument, if provided)
#
# Changes:
# v1.3.1
# - Fixed runtime error
# - Mother. Flippin. Minor. Text. Changes. =D
#
# v1.3.0
# - Had a wake up call - you can now edit programs  you want in the script itself before installing
# - Using the new function in cF you can edit text fiels without leaving script
#
# v1.2.3
# - Script now quits if root when on Arch-based systems
#
# v1.2.2
# - Updated call for checkPrivilege()
# - Changed script so that a 'major' shellcheck error went away
#
# v1.2.1
# - Fixed many tiny errors keeping script from working, along with commonFunctions.sh
# - Directory installation now works!
#
# v1.2.0
# - Re-wrote most of the main script to support directory installs
# - Input can now be either a directory or file, script will determine which and proceed accordingly
#
# v1.1.9
# - Switched to dynamic logging
#
# v1.1.8
# - Not ready to add new "per-file" install functionality, so interim update that fixes current implementation
#
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
# v1.1.0
# - Script now uses commonFunctions.sh
# - Changed most output to use announce() and debug()
# - determinePM() redirects to /dev/null now because it is not important to view except on failure
#
# v1.3.1, 23 Sept. 2016 00:14 PST

### Variables

file="NULL"
programMode="directory" # Can be directory or file mode. File mode installs from given file. Directory mode install all files from directory. Both from $1
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

# First, check to see is user is root/sudo. Makes scripting easier
announce "Determining package manager and updating the package lists." "This may take time depending on internet speed and repo size."
determinePM &>/dev/null

# Comment out this block if you login as root by default on Arch
if [[ "$program" == "pacman" && "$EUID" -eq 0 ]]; then
	announce "Arch-based distributions do not require root privilege." "Please re-run script without sudo, or as normal user!"
	exit 1
else
	[[ ! "$program" == "pacman" ]] && checkPrivilege "ask" "$@" # I will chuckle everytime I have to type this lol
fi

# Checks if argument is present, then tests if directory or file and sets options accordingly
if [[ -f $1 ]]; then
	debug "$1 is a file, running in file mode!"
	export file=$1
	export programMode="file"
elif [[ -d $1 ]]; then
	debug "$1 is a folder, running in directory mode!"
	export file=$1
elif [[ -d "programLists/" ]]; then
	debug "No folder/file given, using default folder!"
	export file="programLists"
else
	debug "Script is broken! Please fix!"
	exit 59
fi

debug "This distribution is using $program as it's package manager!"
#announce "Now installing programs listed in $file!" "This may take a while depending on number of updates and internet speed" "Check $logFile for details"

# Now we can install everything
case $programMode in
	file)
	announce "Now installing programs listed in $file!" "This may take a while depending on number of updates and internet speed" "Check $logFile for details"
	while read -r line; do
		[[ $line = \#* ]] && continue # Skips comment lines
		universalInstaller "$line"
	done <$file
	;;
	directory)
	announce "Installing all directories from $file!" "This WILL take a long time!" "Don't go anywhere, you will be asked if each section should be installed!"
	cd "$file"
	for list in *.txt;
	do
		debug "Asking user if they would like to install $list"
		getUserAnswer "Would you like to install the programs listed in $list?"
		if [[ $? -eq 1 ]]; then
			debug "Skipping $list at user's choice..."
		else
			# Ask if user wants to edit file before installing
			getUserAnswer "Would you like to edit $list before installing?"
			case $? in
			0)
			editTextFile "$list"
			;;
			1)
			debug "User chose not to edit $list"
			;;
			*)
			debug "Unknown option: $?"
			announce "Error occurred! Please consult log!"
			exit 1
			;;
			esac
			
			while read -r line; do
				[[ $line = \#* ]] && continue # Skips comment lines
				universalInstaller "$line"
			done <"$list"
		fi
	done
	[[ ! -z $OLDPWD ]] && cd "$OLDPWD" || cd .. # Return to previous location so other scripts don't break
	;;
	*)
	debug "Everything is broken. Why. At least you have unique debug messages for an easy CTRL+F."
	exit 72
	;;
esac

announce "Done installing programs!"
debug "Finished $0 at $(date)"
#EOF