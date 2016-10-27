#!/bin/bash
#
# packageManager.sh, a.k.a pm - A universal package manager script
#
# Changes:
# v1.2.1
# - Spaces break things. Removed offending spaces.
# - Script will now quit early if not root on most systems
#
# v1.2.0
# - Added option for -n|--no-confirm to reflect new default in pmCF.sh of non-interactive management
# - Gives warnings for dangerous -n cases
#
# v1.1.0
# - Install mode now works with files and folders of files, like programInstaller.sh
#
# v1.0.1
# - Some functions didn't work, fixed it with shift statements
#
# v1.0.0
# - Release version ready
# - Everything is in the processArgs() function
#
# v0.2.0
# - Updated displayHelp()
# - Prep for -o|--option
# - Runtime options can now be a single letter
# - Added privilege check for arch-based distros
#
# v0.1.0
# - Added displayHelp()
#
# v0.0.1
# - No real scripting, but added a long list of things to-do
# - Initial version
#
# TODO:
#
# v1.2.1, 26 Oct. 2016 18:37 PST

### Variables

pmOptions="" # Options to be added when running package manager
#runMode="NULL"
program="NULL" # Uninitialized variables are unhappy variables
programMode="name"
confirm=0 # 0 Indicates no change, anything else indicates running noConfirm()

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

Usage: pm [options] <mode> [package(s)]
Note: For mode, you can use full names listed below, or single letter in brackets.

Run Modes:
   Re[f]resh                                 : Update the list of available packages and updates from package maintainer
   [U]pgrade                                 : Refresh the package list, and then install all available upgrades
   [I]nstall <package_1> [package_2] ...     : Attempt to install all given packages. Works with text files and directories as well!
   [R]emove <package_1> [package_2] ...      : Remove given installed packages
   [Q]uery <package_1> [package_2] ...       : Search package databases for matching package names (does not install)
   [P]kginfo <package_1> [package_2] ...     : Display detailed info (dependencies, version, etc) about packages
   [C]lean                                   : Clean the system of stale and unnecessary packages

Options:
   -v | --verbose                   : Display detailed debugging info (note: MUST be first argument!)
   -o | --option <pm_option>        : Any options added here will be added when running the package manager
                                    : Use as many times as needed!
   -n | --no-confirm                : Runs specified actions without prompting user to continue
   
endHelp
echo "$helpVar"
}

function noConfirm() {
	[[ -z $program || "$program" == "NULL" ]] && determinePM
	
	case $program in
		apt)
		pmOptions="$pmOptions""--assume-yes"
		;;
		pacman)
		pmOptions="$pmOptions""--no-confirm"
		;;
		dnf)
		pmOptions="$pmOptions""-y"
		;;
		zypper)
		pmOptions="$pmOptions""--non-interactive"
		;;
	esac
}

function processArgs() {
	# Make sure arguments is not empty
	if [[ -z $1 ]]; then
		debug "l2" "ERROR: $0 requires at least one argument to run!"
		displayHelp
		exit 1
	fi
	
	for var in "$@"
	do
		case "$var" in
			-h|--help)
			displayHelp
			exit 0
			;;
			-o|--option)
			pmOptions="$pmOptions""$2"
			shift
			;;
			-n|--no-confirm)
			confirm=1
			noConfirm
			;;
			f|F|refresh|Refresh|update|Update) # Such alias.
			updatePM
			;;
			u|U|upgrade|Upgrade)
			upgradePM
			;;
			c|C|clean|Clean)
			# Give a warning if running in non-interactive mode
			if [[ $confirm -ne 0 ]]; then
				debug "Warning user against cleaning the package manager non-interactively..."
				announce "WARNING: It can be dangerous to clean package managers without confirmation!" "Script will continue shortly, but it is recommended to CTRL+C now!"
				sleep 5
			fi
			
			cleanPM
			;;
			i|I|install|Install)
			shift
			for prog in "$@"
			do
				programInstaller "$1"
				shift
			done
			;;
			r|R|remove|Remove)
			shift
			
			# Give a warning if running in non-interactive mode
			if [[ $confirm -ne 0 ]]; then
				debug "Warning user against removing programs non-interactively..."
				announce "WARNING: It is dangerous to remove programs without confirmation!" "Script will continue shortly, but it is highly recommended to CTRL+C now!"
				sleep 5
			fi
			
			for prog in "$@"
			do
				removePM "$1"
				shift
			done
			;;
			q|Q|query|Query)
			shift
			for prog in "$@"
			do
				queryPM "$1"
				shift
			done
			;;
			p|P|pkg*|Pkg*) # Hopefully this works the way I want, wild cards can be tricky
			shift
			for prog in "$@"
			do
				pkgInfo "$1"
				shift
			done
			;;
		esac
		shift
	done
}

function programInstaller() {
	# Decide on mode
	if [[ -f $1 ]]; then
		debug "$1 is a file, running in file mode!"
		export file=$1
		export programMode="file"
	elif [[ -d $1 ]]; then
		debug "$1 is a folder, running in directory mode!"
		export file=$1
		export programMode="directory"
	else
		debug "Argument is not a file or folder, assuming $1 is a program!"
	fi
	
	# Now, install based on mode. Taken from the old programInstaller.sh
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
		name)
		universalInstaller "$1"
		;;
		*)
		debug "Everything is broken. Why. At least you have unique debug messages for an easy CTRL+F."
		exit 72
		;;
	esac
}

### Main Script

determinePM
if [[ "$program" == "pacman" && "$EUID" -eq 0 ]]; then
	debug "l3" "Please run as regular user when using arch-based distros, not sudo/root!"
	exit 1
fi

checkPrivilege "quit"

processArgs "$@" # Didn't plan it this way, but awesome that everything work with this script

announce "Done with script!"
exit 0

#EOF