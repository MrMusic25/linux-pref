#!/bin/bash
#
# packageManagerCF.sh - Common functions for package managers and similar functions
#
# Changes:
# v0.2.0
# - Changes to order of determining order of PM based on popularity online
# - Added cleanPM(), upgradePM()
# - Added a few more debug statements
# - All functions now check if program is set before running (unneeded safety measure, but I hate complaints; not like it wastes cycles)
#
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
# v0.2.0, 05 Oct. 2016 00:49 PST

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
	elif [[ ! -z $(which pacman 2>/dev/null) ]]; then
		export program="pacman"
		#sudo pacman -Syy &>/dev/null # Refreshes the repos, always read the man pages!
		
		# Conditional statement to install yaourt
		[[ -z $(which yaourt 2>/dev/null) ]] && announce "pacman detected! yaourt will be installed as well!" "This insures all packages can be found and installed" && sudo pacman -S base-devel yaourt
	elif [[ ! -z $(which slackpkg 2>/dev/null) ]]; then
		export program="slackpkg"
		#slackpkg update
	elif [[ ! -z $(which zypper 2>/dev/null) ]]; then # Main PM for openSUSE
		export program="zypper" 
		# https://en.opensuse.org/SDB:Zypper_usage for more info
	elif [[ ! -z $(which rpm 2>/dev/null) ]]; then
		export program="rpm"
		#rpm -F --justdb # Only updates the DB, not the system
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
	debug "Refreshing the package manager's database"
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
	# Check to make sure $program is set
	if [[ -z $program || "$program" == "NULL" ]]; then
		debug "Attempted to install with package manager without setting program! Fixing..."
		announce "You are attempting to run universalInstaller() without setting \$program!" "Script will fix this for you, but please fix your script."
		determinePM
	fi
	
	for var in "$@"
	do
		debug "Attempting to install $var"
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
			zypper)
			zypper --non-interactive install "$var"
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
			*)
			announce "Package manager not found! Please update script or diagnose problem!"
			#exit 300
			;;
		esac
	done
}

## upgradePM()
#
# Function: Upgrade all packages in the system with newer version available
# PreReq: $program must be set OR determinePM() must be run first
#
# Call: upgradePM
#
# Input: None
#
# Output: stdout
#
# Other info: None, simple function
function upgradePM() {
	# Check to make sure $program is set
	if [[ -z $program || "$program" == "NULL" ]]; then
		debug "Attempted to upgrade package manager without setting program! Fixing..."
		announce "You are attempting to upgradePM() without setting \$program!" "Script will fix this for you, but please fix your script."
		determinePM
	fi
	
	debug "Preparing to upgrade $program"
	case $program in
		apt)
		announce "NOTE: script will be running a dist-upgrade!"
		apt-get --assume-yes dist-upgrade
		;;
		dnf)
		dnf -y upgrade
		;;
		yum)
		yum upgrade
		;;
		slackpkg)
		slackpkg install-new # Required line
		slackpkg upgrade-all
		;;
		zypper)
		zypper --non-interactive update
		;;
		rpm)
		rpm -F
		;;
		pacman)
		sudo pacman -Syu
		yaourt -Syu --aur # Remember to refresh the AUR as well
		;;
		*)
		announce "Package manager not found! Please update script or diagnose problem!"
		exit 1
		;;
	esac
}

## cleanPM()
#
# Function: Cleans the systme of stale packages and wasted space
# PreReq: $program must be set OR determinePM() must be run first
#
# Call: cleanPM
#
# Input: None
#
# Output: stdout
#
# Other info: Some functions do not have a clean option, it will notify the user if so
function cleanPM() {
	# Check to make sure $program is set
	if [[ -z $program || "$program" == "NULL" ]]; then
		debug "Attempted to clean package manager without setting program! Fixing..."
		announce "You are attempting to cleanPM() without setting \$program!" "Script will fix this for you, but please fix your script."
		determinePM
	fi
	
	debug "Preparing to clean with $program"
	case $program in
		apt)
		apt-get --assume-yes autoremove
		apt-get autoclean
		;;
		dnf)
		dnf -y clean all
		dnf -y autoerase
		;;
		yum)
		yum clean all
		;;
		slackpkg)
		slackpkg clean-system
		;;
		rpm)
		announce "RPM has no clean function"
		# Nothing to be done
		;;
		pacman)
		#pacman -cq
		announce "For your safety, please clean pacman yourself." "Use the command: pacman -Sc"
		;;
		zypper)
		announce "Zypper has no clean function"
		;;
		*)
		announce "Package manager not found! Please update script or diagnose problem!"
		exit 3
		;;
	esac
}

#EOF