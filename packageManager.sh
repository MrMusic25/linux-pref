#!/bin/bash
#
# packageManager.sh, a.k.a pm - A universal package manager script
#
# Changes:
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
# - Make new cF.sh specifically for this script
#   ~ Add this script to cF.sh so other functions that depend on universalInstaller or determinePM can still use them
#     ~ For that matter, DON'T BREAK COMPATIBILITY! COPY+PASTE!
#   ~ Possibly add them to a folder of common functions, source all of them with a for loop or conditionally (ifdef, C++ style!)
#     ~ http://unix.stackexchange.com/questions/253805/ifdef-style-conditional-inclusions-for-shell
#   ~ Note: you might have to fix linking once everything is ready
#     ~ Idea: Script that sources everything from the $LP/commonFunctions.sh folder, solves a lot of issues
#       ~ You would have to export the location of $LP, but that's pretty easy to include with INSTALL.sh
# - If PM is Arch, make sure it is NOT running as sudo. Otherwise, checkPrivilege "quit"
#
#
# v1.0.0, 09 Oct. 2016 21:35 PST

### Variables

pmOptions="" # Options to be added when running package manager
#runMode="NULL"
program="NULL" # Uninitialized variables are unhappy variables

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
   [I]nstall <package_1> [package_2] ...     : Attempt to install all given packages
   [R]emove <package_1> [package_2] ...      : Remove given installed packages
   [Q]uery <package_1> [package_2] ...       : Search package databases for matching package names (does not install)
   [P]kginfo <package_1> [package_2] ...     : Display detailed info (dependencies, version, etc) about packages
   [C]lean                                   : Clean the system of stale and unnecessary packages

Options:
   -v | --verbose                   : Display detailed debugging info (note: MUST be first argument!)
   -o | --option <pm_option>        : Any options added here will be added when running the package manager
                                    : Use as many times as needed! 

endHelp
echo "$helpVar"
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
			pmOptions="$pmOptions"" ""$2"
			shift
			;;
			f|F|refresh|Refresh|update|Update) # Such alias.
			updatePM
			;;
			u|U|upgrade|Upgrade)
			upgradePM
			;;
			c|C|clean|Clean)
			cleanPM
			;;
			i|I|install|Install)
			for prog in "$@"
			do
				universalInstaller "$2"
				shift
			done
			;;
			r|R|remove|Remove)
			for prog in "$@"
			do
				removePM "$2"
				shift
			done
			;;
			q|Q|query|Query)
			for prog in "$@"
			do
				queryPM "$2"
				shift
			done
			;;
			p|P|pkg*|Pkg*) # Hopefully this works the way I want, wild cards can be tricky
			for prog in "$@"
			do
				pkgInfo "$2"
				shift
			done
			;;
		esac
		shift
	done
}

### Main Script

determinePM
if [[ "$program" == "pacman" && "$EUID" -eq 0 ]]; then
	debug "l3" "Please run as regular user when using arch-based distros, not sudo/root!"
	exit 1
fi

processArgs "$@" # Didn't plan it this way, but awesome that everything work with this script

announce "Done with script!"
exit 0

#EOF