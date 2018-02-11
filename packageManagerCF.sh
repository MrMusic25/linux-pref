#!/bin/bash
#
# packageManagerCF.sh - Common functions for package managers and similar functions
#
# Changes:
# v1.3.2
# - Fixed debug messages
# - Added return values to necessary functions for pm.sh
# - Added snapd capabilities for Ubuntu/Debian systems
# - Small functional change to checkRequirements()
#
# v1.3.1
# - Turns out yaourt is not recommended. Changed all functions to use pacaur instead
#
# v1.3.0
# - Added distUpgradePM() for full distributions upgrades
# - Fixed apt-get in upgradePM() accordingly
# - Updated all functions to use yaourt exclusively from now on (personal decision)
# - Removed warning for cleaning Arch systems, turns out I didn't know what it did
#
# v1.2.3
# - Updating changelog to new settings
#
# v1.2.2
# - Changed updatePM() to only update pacman, no need to update twice with yaourt!
# - Update: *Reaper voice* Didn't take
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
# v1.3.2, 10 Feb. 2018, 14:04 PST

### Variables

pmCFvar=0 # Ignore shellcheck saying this isn't used. Lets script know if this has been sourced or not.
pmOptions="" # Options to be added before running any package manager
rval=0 # Just to make sure 
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
		[[ ! -z $(which snap 2>/dev/null) ]] && debug "l3" "INFO: apt detected, installing snapd!" && sudo apt-get install snapd
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
		[[ -z $(which yaourt 2>/dev/null) ]] && debug "l3" "INFO: pacman detected! pacaur will be installed for additional package availability." && sudo pacman -S git cower expac pacaur
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
	debug "l5" "INFO: Package manager found! $program"
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
		debug "l2" "WARN: Attempted to update package manager without setting program! Fixing..."
		#announce "You are attempting to updatePM() without setting \$program!" "Script will fix this for you, but please fix your script."
		determinePM
	fi
	
	# Now, do the proper update command
	debug "INFO: Refreshing the package manager's database"
	case $program in
		apt)
		apt-get $pmOptions update
		# No update option for snapd
		;;
		pacman)
		pacaur $pmOptions -Syy
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
		debug "l2" "ERROR: Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
		;;
	esac
	return $?
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
	
	rval=0 # Return value
	
	for var in "$@"
	do
		debug "INFO: Attempting to install $var"
		case $program in
			apt)
			sudo apt-get $pmOptions install "$var" 
			v=$?
			((rval+=v))
			if [[ $v -ne 0 ]]; then
				debug "l2" "WARN: $var not found with apt, checking snapd!"
				sudo snap install "$var"
				v1=$?
				((rval+=v1))
				[[ $v1 -ne 0 ]] && debug "l2" "ERROR: $var not found with snapd either! Could not be installed!"
			fi
			;;
			dnf)
			sudo dnf $pmOptions install "$var"
			((rval+=$?))
			;;
			yum)
			sudo yum $pmOptions install "$var"
			((rval+=$?))
			;;
			slackpkg)
			sudo slackpkg $pmOptions install "$var"
			((rval+=$?))
			;;
			zypper)
			sudo zypper $pmOptions install "$var"
			((rval+=$?))
			;;
			rpm)
			sudo rpm $pmOptions -i "$var" 
			((rval+=$?))
			;;
			emerge)
			sudo emerge $pmOptions "$var"
			((rval+=$?))
			;;
			pacman)
			pacaur $pmOptions -S "$var"
			((rval+=$?))
			#if [[ "$?" -ne 0 ]]; then
			#	debug "l2" "WARN: Package $var not found in Arch repos! Checking AUR..."
			#	yaourt $pmOptions -S --aur "$var"
			#	if [[ "$?" -ne 0 ]]; then
			#		debug "l2" "ERROR: $var was not found or could not be installed!"
			#	fi
			#fi
			;;
			*)
			debug "l2" "ERROR: Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
			;;
		esac
	done
	return "$rval"
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
		debug "l2" "WARN: Attempted to upgrade package manager without setting program! Fixing..."
		#announce "You are attempting to upgradePM() without setting \$program!" "Script will fix this for you, but please fix your script."
		determinePM
	fi
	rval=0
	
	debug "INFO Preparing to upgrade $program"
	case $program in
		apt)
		#announce "NOTE: script will be running a dist-upgrade!"
		sudo apt-get $pmOptions upgrade
		((rval+=$?))
		# snapd has no formal upgrade option, done on a package-by-package system
		;;
		dnf)
		sudo dnf $pmOptions upgrade
		((rval+=$?))
		;;
		yum)
		sudo yum $pmOptions upgrade
		((rval+=$?))
		;;
		slackpkg)
		sudo slackpkg $pmOptions install-new # Required line
		((rval+=$?))
		sudo slackpkg $pmOptions upgrade-all
		((rval+=$?))
		;;
		zypper)
		sudo zypper $pmOptions update
		((rval+=$?))
		;;
		rpm)
		sudo rpm $pmOptions -F
		((rval+=$?))
		;;
		pacman)
		#sudo pacman $pmOptions -Syu
		pacaur $pmOptions -Syu # Remember to refresh the AUR as well
		((rval+=$?))
		;;
		emerge)
		sudo emerge $pmOptions --update --deep world # Gentoo is strange
		((rval+=$?))
		;;
		*)
		debug "l2" "ERROR: Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
		;;
	esac
	return "$rval"
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
	rval=0
	
	debug "INFO: Preparing to clean with $program"
	case $program in
		apt)
		apt-get $pmOptions autoremove
		((rval+=$?))
		apt-get $pmOptions autoclean
		((rval+=$?))
		;;
		dnf)
		dnf $pmOptions clean all
		((rval+=$?))
		dnf $pmOptions autoerase
		((rval+=$?))
		;;
		yum)
		yum $pmOptions clean all
		((rval+=$?))
		;;
		slackpkg)
		slackpkg $pmOptions clean-system
		((rval+=$?))
		;;
		rpm)
		announce "RPM has no clean function"
		# Nothing to be done
		;;
		pacman)
		pacaur -Sc
		((rval+=$?))
		;;
		zypper)
		announce "Zypper has no clean function"
		;;
		emerge)
		emerge $pmOptions --clean
		((rval+=$?))
		emerge $pmOptions --depclean # Couldn't tell which was the only one necessary, so I included both
		((rval+=$?))
		;;
		*)
		debug "l2" "ERROR: Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
		;;
	esac
	return "$rval"
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
		debug "l2" "ERROR: Attempted to query package manager without setting program! Fixing..."
		#announce "You are attempting to queryPM() without setting \$program!" "Script will fix this for you, but please fix your script."
		determinePM
	fi
	
	rval=0 # return value
	
	for var in "$@"
	do
		debug "l3" "INFO: Querying packagage database for: $var"
		case $program in
			apt)
			apt-cache $pmOptions search "$var"
			v=$?
			((rval+=v))
			if [[ "$v" -ne 0 ]]; then
				debug "l2" "WARN: $var was not found in apt, checking snapd!"
				snap find "$var" 2>/dev/null
				v1=$?
				((rval+=v1))
				[[ $v1 -ne 0 ]] && debug "l2" "ERROR: $var not found with snapd either!"
			fi
			;;
			pacman)
			pacaur $pmOptions -Ss "$var" # Program automatically displays Arch-repo AND AUR programs
			((rval+=$?))
			;;
			yum)
			yum $pmOptions search "$var" # Change to 'yum search all' if the results aren't good enough
			((rval+=$?))
			;;
			emerge)
			emerge $pmOptions --search "$var" # Like yum, use 'emerge --searchdesc' if the results aren't enough
			((rval+=$?))
			;;
			zypper)
			zypper $pmOptions search "$var"
			((rval+=$?))
			;;
			dnf)
			dnf $pmOptions search "$var"
			((rval+=$?))
			;;
			rpm)
			rpm $pmOptions -q "$var"
			((rval+=$?))
			;;
			slackpkg)
			slackpkg $pmOptions search "$var"
			((rval+=$?))
			;;
			*)
			debug "l2" "ERROR: Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
			;;
		esac
	done
	return "$rval"
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
		debug "l2" "WARN: Attempted to remove packages without setting program! Fixing..."
		#announce "You are attempting to removePM() without setting \$program!" "Script will fix this for you, but please fix your script."
		determinePM
	fi
	rval=0
	
	for var in "$@"
	do
		debug "l3" "WARN: Attempting to remove program $var..."
		case $program in
			apt)
			sudo apt-get $pmOptions remove "$var"
			v=$?
			((rval+=v))
			if [[ $v -ne 0 ]]; then
				debug "l2" "WARN: $var not found with apt, attempting to remove with snapd"
				sudo snapd remove "$var"
				v1=$?
				((rval+=v1))
				[[ "$v1" -ne 0 ]] && debug "l2" "ERROR: $var not found with snapd either, could not remove!"
			fi
			;;
			pacman)
			pacaur $pmOptions -R "$var"
			((rval+=$?))
			#if [[ $? -ne 0 ]]; then
			#	debug "l3" "Couldn't find package $var with yaourt, trying pacman"
			#	sudo pacman $pmOptions -R "$var"
			#fi
			;;
			yum)
			sudo yum $pmOptions remove "$var"
			;;
			emerge)
			sudo emerge $pmOptions --remove --depclean "$var"
			((rval+=$?))
			;;
			dnf)
			sudo dnf $pmOptions remove "$var"
			((rval+=$?))
			;;
			rpm)
			sudo rpm $pmOptions -e "$var"
			((rval+=$?))
			;;
			slackpkg)
			sudo slackpkg $pmOptions remove "$var"
			((rval+=$?))
			;;
			zypper)
			sudo zypper $pmOptions remove "$var"
			((rval+=$?))
			;;
			*)
			debug "l2" "ERROR: Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
			;;
		esac
	done
	return "$rval"
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
		debug "l2" "WARN: Attempted to remove packages without setting program! Fixing..."
		#announce "You are attempting to removePM() without setting \$program!" "Script will fix this for you, but please fix your script."
		determinePM
	fi
	rval=0
	
	for var in "$@"
	do
		debug "l3" "INFO: Displaying package info of: $var"
		case "$program" in
			pacman)
			#pacman $pmOptions -Qi "$var"
			#if [[ $? -ne 0 ]]; then
			#	debug "l3" "$var could not be found in pacman, trying yaourt!"
			pacaur $pmOptions -Qi "$var"
			((rval+=$?))
			#fi
			;;
			apt)
			apt-cache show "$var"
			v=$?
			((rval+=v))
			if [[ "$v" -ne 0 ]]; then
				debug "l2" "WARN: $var not found with apt, checking snapd!"
				snap info "$var"
				v1=$?
				((rval+=v1))
				[[ "$v1" -ne 0 ]] && debug "l2" "ERROR: $var not found with snapd, could not display info!"
			fi
			;;
			rpm)
			# This allows to check a .rpm file for data info
			if [[ -f "$var" ]]; then
				debug "$var is a file, checking contents for documentation"
				rpm $pmOptions -qip "$var"
				((rval+=$?))
			else
				rpm $pmOptions -qi "$var"
				((rval+=$?))
			fi
			;;
			yum)
			yum $pmOptions info "$var"
			((rval+=$?))
			;;
			emerge)
			equery $pmOptions meta "$var"
			((rval+=$?))
			equery $pmOptions depends "$var" # Shows dependencies
			((rval+=$?))
			;;
			slackpkg)
			slackpkg $pmOptions info "$var"
			((rval+=$?))
			;;
			dnf)
			dnf $pmOptions info "$var"
			((rval+=$?))
			;;
			zypper)
			zypper $pmOptions info "$var"
			((rval+=$?))
			;;
			*)
			debug "l2" "ERROR: Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
			;;
		esac
	done
	return "$rval"
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
	rval=0
	
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
			debug "WARN: $reqt is not installed for $0, notifying user for install"
			getUserAnswer "$reqt is not installed, would you like to do so now?"
			case $? in
				0)
				debug "INFO: Installing $reqt based on user input"
				if [[ -e packageManager.sh ]]; then
					packageManager.sh install "$reqt"
					((rval+=$?))
				elif [[ -e /usr/bin/pm ]]; then
					pm install "$reqt"
					((rval+=$?))
				else
					debug "l2" "ERROR: Unable to locate packageManager.sh! Please install $reqt manually!"
					exit 1
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
	debug "INFO: All requirements met, continuing with script."
}

## distUpgradePM()
#
# Function: Upgrade the distribution according to package manager's default instructions (if the feature exists)
#
# Call: distUpgradePM
#
# Input: None
#
# Output: stdout
#
# Other: A warning will be given before proceeding, as this can break systems and dependencies
function distUpgradePM() {
	# Check to make sure $program is set
	if [[ -z $program || "$program" == "NULL" ]]; then
		debug "l2" "WARN: Attempted to upgrade package manager without setting program! Fixing..."
		#announce "You are attempting to upgradePM() without setting \$program!" "Script will fix this for you, but please fix your script."
		determinePM
	fi
	rval=0
	
	debug "INFO: Warning user about running a distribution upgrade"
	announce "WARNING! User indicated to run a distribution upgrade!" "This can be dangerous as it can break system dependencies. Be sure before proceeding."
	pause "Press CTRL+C twice to exit script, or [Enter] to continue"
	case $program in
		apt)
		sudo apt-get $pmOptions dist-upgrade
		((rval+=$?))
		if [[ ! -z $(which do-release-upgrade 2>/dev/null) ]]; then
			announce "Optionally, you can upgrade to the next release cycle, depending on your settings"
			getUserAnswer "n" "Would you like to upgrade for the latest version of Ubuntu?"
			case $? in
				0)
				debug "l2" "WARN: Upgrading Ubuntu system at user request!"
				sudo do-release-upgrade
				((rval+=$?))
				;;
				*)
				debug "INFO: Not upgrading Ubuntu system"
				;;
			esac
		fi
		;;
		dnf)
		sudo dnf $pmOptions upgrade
		((rval+=$?))
		;;
		yum)
		sudo yum $pmOptions upgrade
		((rval+=$?))
		;;
		slackpkg)
		sudo slackpkg $pmOptions install-new # Required line
		((rval+=$?))
		sudo slackpkg $pmOptions upgrade-all
		((rval+=$?))
		;;
		zypper)
		sudo zypper $pmOptions update
		((rval+=$?))
		;;
		rpm)
		sudo rpm $pmOptions -F
		((rval+=$?))
		;;
		pacman)
		debug "l2" "INFO: Beginning upgrade with pacman, as it is recommended"
		sudo pacman $pmOptions -Syu
		((rval+=$?))
		pacaur $pmOptions -Syu # Remember to refresh the AUR as well
		((rval+=$?))
		;;
		emerge)
		sudo emerge $pmOptions --update --deep world # Gentoo is strange
		((rval+=$?))
		;;
		*)
		debug "l2" "ERROR: Unsupported package manager detected! Please contact script maintainer to get yours added to the list!"
		;;
	esac
}

#EOF