#!/bin/bash
#
# packageManagerCF.sh - Common functions for package managers and similar functions
#
# Changes:
# v1.2.2
# - Changed updatePM() to only update pacman, no need to update twice with yaourt!
#
# v1.2.1
# - Small change to checkRequirements for non-sudo scripts
# - checkRequirements now uses pm.sh to install programs, turns out sudo-ing functions is difficult
#
# v1.2.0
# - All programs now support the -o|--options from pm.sh
# - Package managers are no longer non-interactive by default
# - Fixed a bug that was keeping yaourt from working...
#
# v1.1.2
# - Foiled by a bang!
#
# v1.1.1
# - Changed a couple debug calls
#
# v1.1.0
# - That was a quick major version... Moved checkRequirements() to this script from cF.sh
# - Added a recursive call for sourcing commonFunctions, just in case...
# - Fixed SC1048
#
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
# - Add npm and npm to install(), update(), upgrade(), remove(), and possibly query()/info() - but NOT to determinePM()
# - For all functions - add ability to 'run PM as $1' if there is an argument
#   ~ e.g. "upgradePM" will upgrade the current PM, "upgradePM npm" will (attempt to) upgrade npm
#
# v1.2.2, 01 Mar. 2017 00:53 PST

### Variables

pmCFvar=0 # Ignore shellcheck saying this isn't used. Lets script know if this has been sourced or not.
pmOptions="" # Options to be added before running any package manager

### Functions

if [[ -z $cfVar ]]; then
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
	if [[ -z $program || "$program" != "NULL" ]]; then
		true
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
		apt-get $pmOptions update
		;;
		pacman)
		sudo pacman $pmOptions -Syy
		yaourt $pmOptions -Syy
		;;
		dnf)
		dnf $pmOptions check-update
		;;
		yum)
		yum $pmOptions check-update
		;;
		slackpkg)
		slackpkg $pmOptions update
		;;
		emerge)
		emerge $pmOptions --sync
		;;
		rpm)
		rpm $pmOptions -F --justdb # Only updates the DB, not the system
		;;
		zypper)
		zypper $pmOptions refresh
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
			apt-get $pmOptions install "$var"  
			;;
			dnf)
			dnf $pmOptions install "$var"
			;;
			yum)
			yum $pmOptions install "$var" 
			;;
			slackpkg)
			slackpkg $pmOptions install "$var"
			;;
			zypper)
			zypper $pmOptions install "$var"
			;;
			rpm)
			rpm $pmOptions -i "$var" 
			;;
			emerge)
			emerge $pmOptions "$var"
			;;
			pacman)
			sudo pacman $pmOptions -S "$var"
			
			# If pacman can't install it, it can likely be found in AUR/yaourt
			if [[ $? -eq 1 ]]; then
				debug "l2" "$var not found with pacman, attempting install with yaourt!"
				yaourt $pmOptions -S "$var"
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
		apt-get $pmOptions dist-upgrade
		;;
		dnf)
		dnf $pmOptions upgrade
		;;
		yum)
		yum $pmOptions upgrade
		;;
		slackpkg)
		slackpkg $pmOptions install-new # Required line
		slackpkg $pmOptions upgrade-all
		;;
		zypper)
		zypper $pmOptions update
		;;
		rpm)
		rpm $pmOptions -F
		;;
		pacman)
		sudo pacman $pmOptions -Syu
		yaourt $pmOptions -Syu --aur # Remember to refresh the AUR as well
		;;
		emerge)
		emerge $pmOptions --update --deep world # Gentoo is strange
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
		apt-get $pmOptions autoremove
		apt-get $pmOptions autoclean
		;;
		dnf)
		dnf $pmOptions clean all
		dnf $pmOptions autoerase
		;;
		yum)
		yum $pmOptions clean all
		;;
		slackpkg)
		slackpkg $pmOptions clean-system
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
		emerge $pmOptions --clean
		emerge $pmOptions --depclean # Couldn't tell which was the only one necessary, so I included both
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
			apt-cache $pmOptions search "$var"
			;;
			pacman)
			pacman $pmOptions -Ss "$var" # No sudo required for this one, same for yaourt
			if [[ $? -ne 0 ]]; then
				debug "l3" "Package $var not found in pacman, searching AUR via yaourt instead."
				yaourt $pmOptions -Ss "$var"
			fi
			;;
			yum)
			yum $pmOptions search "$var" # Change to 'yum search all' if the results aren't good enough
			;;
			emerge)
			emerge $pmOptions --search "$var" # Like yum, use 'emerge --searchdesc' if the results aren't enough
			;;
			zypper)
			zypper $pmOptions search "$var"
			;;
			dnf)
			dnf $pmOptions search "$var"
			;;
			rpm)
			rpm $pmOptions -q "$var"
			;;
			slackpkg)
			slackpkg $pmOptions search "$var"
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
			apt-get $pmOptions remove "$var"
			;;
			pacman)
			sudo pacman -R "$var"
			if [[ $? -ne 0 ]]; then
				debug "l3" "Couldn't find package $var with pacman, trying yaourt"
				sudo yaourt $pmOptions -R "$var"
			fi
			;;
			yum)
			yum $pmOptions remove "$var"
			;;
			emerge)
			emerge $pmOptions --remove --depclean "$var"
			;;
			dnf)
			dnf $pmOptions remove "$var"
			;;
			rpm)
			rpm $pmOptions -e "$var"
			;;
			slackpkg)
			slackpkg $pmOptions remove "$var"
			;;
			zypper)
			zypper $pmOptions remove "$var"
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
			pacman $pmOptions -Qi "$var"
			if [[ $? -ne 0 ]]; then
				debug "l3" "$var could not be found in pacman, trying yaourt!"
				yaourt $pmOptions -Qi "$var"
			fi
			;;
			apt)
			apt-cache show "$var"
			;;
			rpm)
			# This allows to check a .rpm file for data info
			if [[ -f "$var" ]]; then
				debug "$var is a file, checking contents for documentation"
				rpm $pmOptions -qip "$var"
			else
				rpm $pmOptions -qi "$var"
			fi
			;;
			yum)
			yum $pmOptions info "$var"
			;;
			emerge)
			equery $pmOptions meta "$var"
			equery $pmOptions depends "$var" # Shows dependencies
			;;
			slackpkg)
			slackpkg $pmOptions info "$var"
			;;
			dnf)
			dnf $pmOptions info "$var"
			;;
			zypper)
			zypper $pmOptions info "$var"
			;;
			*)
			debug "Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
			;;
		esac
	done
}

## checkRequirements()
#
# Function: Check to make sure programs are installed before running script
#
# Call: checkRequirements <program_1> [program_2] [program_3] ...
#
# Input: Each argument should be the proper name of a command or program to be searched for
#
# Output: None if successful, asks to install if anything is found. If it must be manually installed, script will exit.
#
# Other: Except for rare cases, this will not work for libraries ( e.g. anything with "lib" in it). These must be done manually.
#        Note: Now you can use "program/installer" to install program, in case the program is part of a larger package
function checkRequirements() {
	# Determine package manager before doing anything else
	if [[ -z $program || "$program" == "NULL" ]]; then
		determinePM
	fi
	
	for req in "$@"
	do
		if [[ "$req" == */* ]]; then
			reqm="$(echo "$req" | cut -d'/' -f1)"
			reqt="$(echo "$req" | cut -d'/' -f2)"
		else
			reqm="$req"
			reqt="$req"
		fi
		
		# No debug messages on success, keeps things silent
		if [[ -z "$(which $reqm 2>/dev/null)" ]]; then
			debug "$reqt is not installed for $0, notifying user for install"
			getUserAnswer "$reqt is not installed, would you like to do so now?"
			case $? in
				0)
				debug "Installing $reqt based on user input"
				if [[ "$program" == "pacman" ]]; then
					if [[ -e packageManager.sh ]]; then
						packageManager.sh install "$reqt"
					elif [[ -e /usr/bin/pm ]]; then
						pm install "$reqt"
					else
						debug "l2" "ERROR: Unable to locate packageManager.sh! Please install $reqt manually!"
						exit 1
					fi
				else
					if [[ -e packageManager.sh ]]; then
						sudo packageManager.sh install "$reqt"
					elif [[ -e /usr/bin/pm ]]; then
						sudo pm install "$reqt"
					else
						debug "l2" "ERROR: Unable to locate packageManager.sh! Please install $reqt manually!"
						exit 1
					fi
				fi
				;;
				1)
				debug "User chose not to install required program $reqt, quitting!"
				announce "Please install the program manually before running this script!"
				exit 1
				;;
				*)
				debug "Unknown return option from getUserAnswer: $?"
				announce "Invalid response, quitting"
				exit 123
				;;
			esac
		fi
	done
	
	# If everything is installed, it will reach this point
	debug "All requirements met, continuing with script."
}

#EOF
