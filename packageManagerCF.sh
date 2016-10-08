#!/bin/bash
#
# packageManagerCF.sh - Common functions for package managers and similar functions
#
# Changes:
# v1.0.0
# - First release version
# - Added completed pkgInfo()
# - Added failsafes to all functions
# - determinePM() will now state if no package manager was found, then quit
# - Added as close to an '#ifndef' statement as I could for sourcing this script
#
# v0.4.1
# - Finished adding missing commands for emerge to other functions
#
# v0.4.0
# - Finished queryPM()
# - Added a completed removePM()
#
# v0.3.0
# - Added queryPM()
# - Started adding support for Portage/emerge for Gentoo based systems
#
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
# v1.0.0, 08 Oct. 2016 00:45 PST

### Variables

pmCFvar=0 # Ignore shellcheck saying this isn't used. Lets script know if this has been sourced or not.

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
# https://linuxconfig.org/comparison-of-major-linux-package-management-systems
function determinePM() {
	if [[ ! -z $program || "$program" != "NULL" ]]; then
		# nothing to be done!
	elif [[ ! -z $(which apt-get 2>/dev/null) ]]; then # Most common, so it goes first
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
	elif [[ ! -z $(wich emerge 2>/dev/null) ]]; then # Portage, PM for Gentoo (command is emerge)
		export program="emerge"
	elif [[ ! -z $(which rpm 2>/dev/null) ]]; then
		export program="rpm"
		#rpm -F --justdb # Only updates the DB, not the system
	else
		debug "l2" "ERROR: Package manager not found! Please contact script maintainter!"
		exit 1
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
		emerge)
		emerge --sync
		;;
		rpm)
		rpm -F --justdb # Only updates the DB, not the system
		;;
		zypper)
		zypper refresh
		;;
		*)
		debug "Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
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
			emerge)
			emerge "$var"
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
			debug "Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
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
		emerge)
		emerge --update --deep world # Gentoo is strange
		;;
		*)
		debug "Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
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
		emerge)
		emerge --clean
		emerge --depclean # Couldn't tell which was the only one necessary, so I included both
		;;
		*)
		debug "Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
		;;
	esac
}

## queryPM()
#
# Function: Check for packages with a similar name in package database
# PreReq: $program must be set, or run determinePM() must be run first
#
# Call: queryPM <package_name> [package_name] ...
#
# Input: Will search and return info for each argument
#
# Output: stdout
#
# Other info: It will print which package it is looking for before displaying information
function queryPM() {
	# Check to make sure $program is set
	if [[ -z $program || "$program" == "NULL" ]]; then
		debug "Attempted to query package manager without setting program! Fixing..."
		announce "You are attempting to queryPM() without setting \$program!" "Script will fix this for you, but please fix your script."
		determinePM
	fi
	
	for var in "$@"
	do
		debug "l3" "Querying packagage database for: $var"
		case $program in
			apt)
			apt-cache search "$var"
			;;
			pacman)
			pacman -Ss "$var" # No sudo required for this one, same for yaourt
			if [[ $? -ne 0 ]]; then
				debug "l3" "Package $var not found in pacman, searching AUR via yaourt instead."
				yaourt -Ss "$var"
			fi
			;;
			yum)
			yum search "$var" # Change to 'yum search all' if the results aren't good enough
			;;
			emerge)
			emerge --search "$var" # Like yum, use 'emerge --searchdesc' if the results aren't enough
			;;
			zypper)
			zypper search "$var"
			;;
			dnf)
			dnf search "$var"
			;;
			rpm)
			rpm -q "$var"
			;;
			slackpkg)
			slackpkg search "$var"
			;;
			*)
			debug "Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
			;;
		esac
	done
}

## removePM()
#
# Function: Remove given packages
# PreReq: Set $program, or run determinePM()
#
# Call: removePM <package_name> [package_name] ...
#
# Input: Names of packages to remove
#
# Output: stdout
#
# Other info: No --assume-yes, just in case. Pay attention!
function removePM() {
	# Check to make sure $program is set
	if [[ -z $program || "$program" == "NULL" ]]; then
		debug "Attempted to remove packages without setting program! Fixing..."
		announce "You are attempting to removePM() without setting \$program!" "Script will fix this for you, but please fix your script."
		determinePM
	fi
	
	for var in "$@"
	do
		debug "l3" "Attempting to remove $var..."
		case $program in
			apt)
			apt-get remove "$var"
			;;
			pacman)
			sudo pacman -R "$var"
			if [[ $? -ne 0 ]]; then
				debug "l3" "Couldn't find package $var with pacman, trying yaourt"
				sudo yaourt -R "$var"
			fi
			;;
			yum)
			yum remove "$var"
			;;
			emerge)
			emerge --remove --depclean "$var"
			;;
			dnf)
			dnf remove "$var"
			;;
			rpm)
			rpm -e "$var"
			;;
			slackpkg)
			slackpkg remove "$var"
			;;
			zypper)
			zypper remove "$var"
			;;
			*)
			debug "Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
			;;
		esac
	done
}

## pkgInfo()
#
# Function: Display info about a package (dependencies, version, maintainer, etc)
# PreReq: Have $program set, or run determinePM()
#
# Call: pkgInfo <package_name> [package_name] ...
#
# Input: Package names
#
# Output: stdout
#
# Other info: None, simple function
function pkgInfo() {
	# Check to make sure $program is set
	if [[ -z $program || "$program" == "NULL" ]]; then
		debug "Attempted to remove packages without setting program! Fixing..."
		announce "You are attempting to removePM() without setting \$program!" "Script will fix this for you, but please fix your script."
		determinePM
	fi
	
	for var in "$@"
	do
		debug "l3" "Displaying package info of: $var"
		case "$program" in
			pacman)
			pacman -Qi "$var"
			if [[ $? -ne 0 ]]; then
				debug "l3" "$var could not be found in pacman, trying yaourt!"
				yaourt -Qi "$var"
			fi
			;;
			apt)
			apt-cache show "$var"
			;;
			rpm)
			# This allows to check a .rpm file for data info
			if [[ -f "$var" ]]; then
				debug "$var is a file, checking contents for documentation"
				rpm -qip "$var"
			else
				rpm -qi "$var"
			fi
			;;
			yum)
			yum info "$var"
			;;
			emerge)
			equery meta "$var"
			equery depends "$var" # Shows dependencies
			;;
			slackpkg)
			slackpkg info "$var"
			;;
			dnf)
			dnf info "$var"
			;;
			zypper)
			zypper info "$var"
			;;
			*)
			debug "Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
			;;
		esac
	done
}

#EOF