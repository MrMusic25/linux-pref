#!/bin/bash
#
# packageManagerCF.sh - Common functions for package managers and similar functions
#
# Changes:
# v0.1.0
# - Added updatePM()
# - determinePM() no longer updates packages
# - Added 'zypper' as a valid program for SUSE distributions, getting rid of YaST as well
#
# v0.0.1
# - Updated to-do
# - Initial version
#
# TODO:
# - determinePM()
#   ~ If $packageManager is present in .bashrc, return and continue; else:
#     ~ Create array of all package managers
#     ~ Ask user to choose which package manager to use
#       ~ If only one present, confirm with user to use it (should only be one anyways)
#     ~ Export variable packageManager="$pm" to .bashrc, to save time later
#   ~ Separate updating databases from this function
#   ~ In cases like Arch with pacman/yaourt, inform user of dual-package managers
#
# v0.1.0, 05 Oct. 2016 00:11 PST

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

## determinePM()
# Function: Determine package manager (PM) and export for script use
# PreReq: None
#
# Call: determinePM
#
# Input: No input necessary; ignored
#
# Output: Exports variable 'program'; no return value (yet)
#
# Other info: Updates repositories if possible, redirect to /dev/null if you don't want to see it
function determinePM() {
	if [[ ! -z $(which apt-get 2>/dev/null) ]]; then # Most common, so it goes first
		export program="apt"
		#apt-get update
	elif [[ ! -z $(which dnf 2>/dev/null) ]]; then # This is why we love DistroWatch, learned about the 'replacement' to yum!
		export program="dnf"
		#dnf check-update
	elif [[ ! -z $(which yum 2>/dev/null) ]]; then
		export program="yum"
		#yum check-update
	elif [[ ! -z $(which slackpkg 2>/dev/null) ]]; then
		export program="slackpkg"
		#slackpkg update
	elif [[ ! -z $(which zypper 2>/dev/null) ]]; then # Main PM for openSUSE
		export program="zypper" 
	elif [[ ! -z $(which rpm 2>/dev/null) ]]; then
		export program="rpm"
		#rpm -F --justdb # Only updates the DB, not the system
	elif [[ ! -z $(which yast 2>/dev/null) ]]; then # YaST is annoying af, so look for rpm and yum first
		export program="yast"
	elif [[ ! -z $(which pacman 2>/dev/null) ]]; then
		export program="pacman"
		#sudo pacman -Syy &>/dev/null # Refreshes the repos, always read the man pages!
		
		# Conditional statement to install yaourt
		[[ -z $(which yaourt 2>/dev/null) ]] && announce "pacman detected! yaourt will be installed as well!" "This insures all packages can be found and installed" && sudo pacman -S base-devel yaourt
	fi
	debug "Package manager found! $program"
}

## updatePM()
#
# Function: Update the package manager's database(s)
# PreReq: $program must be set OR determinePM() must be run first
#
# Call: updatePM
#
# Input: None
#
# Output: stdout
#
# Other info: None, simple function
function updatePM() {
	# Check to make sure $program is set
	if [[ -z $program || "$program" == "NULL" ]]; then
		debug "Attempted to update package manager without setting program! Fixing..."
		announce "You are attempting to updatePM() without setting \$program!" "Script will fix this for you, but please fix your script."
		determinePM
	fi
	
	# Now, do the proper update command
	case $program in
		apt)
		apt-get update
		;;
		pacman)
		sudo pacman -Syy
		;;
		dnf)
		dnf check-update
		;;
		yum)
		yum check-update
		;;
		slackpkg)
		slackpkg update
		;;
		rpm)
		rpm -F --justdb # Only updates the DB, not the system
		;;
		zypper)
		zypper refresh
		;;
		*)
		debug "Unsupported package manager detected! Please contact script maintainer to get your added to the list!"
		;;
	esac
}

## universalInstaller()
# Function: Attempt to install all programs listed in called args
# PreReq: Must run determinePM() beforehand, or have $program set to a valid option
#
# Call: universalInstaller <program1> [program2] [program3] ...
#
# Input: As many arguments as you want, each one a valid package name
#
# Output: stdout, no return values at this time
#
# Other info: Loops through arguments and installs one at a time, encapsulate in ' ' if you want some installed together
#             e.g. universalInstaller wavemon gpm 'zsh ssh' -> wavemon and gpm installed by themselves, zsh and ssh installed together
function universalInstaller() {
for var in "$@"
do
	case $program in
		apt)
		apt-get --assume-yes install "$var"  
		;;
		dnf)
		dnf -y install "$var"
		;;
		yum)
		yum install "$var" 
		;;
		slackpkg)
		slackpkg install "$var"
		;;
		yast)
		yast -i "$var" 
		;;
		rpm)
		rpm -i "$var" 
		;;
		pacman)
		sudo pacman -S --noconfirm "$var"
		
		# If pacman can't install it, it can likely be found in AUR/yaourt
		if [[ $? -eq 1 ]]; then
			debug "$var not found with pacman, attempting install with yaourt!"
			announce "$var not found with pacman, trying yaourt!" "This is interactive because it could potentially break your system."
			yaourt "$var"
		fi 
		;;
		aptitude)
		aptitude -y install "$var" 
		;;
		*)
		announce "Package manager not found! Please update script or diagnose problem!"
		#exit 300
		;;
	esac
done
	# Insert code dealing with failed installs here
}


#EOF