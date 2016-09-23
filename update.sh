#!/bin/bash
#
# update[.sh] - A universal update and install script, similar to what XKCD made
# Usage: ./update <packages>
#
# Running update by itself will update and upgrade all system packages.
# If there are arguments, it will try to install the programs listed
#
# Changes:
# v1.2.8
# - Made a minor change. Brought the version up one. Yup.
#
# v1.2.7
# - Script now exit if being run as root on Arch-based distributions - yaourt doesn't like sudo
# - Random little changes
#
# v1.2.6
# - Updated script to use new call for checkPrivilege()
# - Cleaning with pacman is dangerous, so I put a warning instead of attempting the command
# - Made the calls for 'which' quieter
# - Added some more debug statements
#
# v1.2.5
# - Apparently I deleted 'yes' statements from apt-get, re-entered so script is non-interactive again
#
# v1.2.4
# - Distracted myself from updating README.md by changing this script to use getUserAnswer()
#
# v1.2.3
# - Got rid of legacy logging statements
#
# v1.2.2
# - Switched to dynamic logging
#
# v1.2.1
# - Added support for slackpkg
#
# v1.2.0
# - Started using a better numbering system for changelog
# - Added support for Raspberry Pi, specifically raspbian
#
# v1.1.6
# - Note really an update, but small change from commonFunctions.sh. Leftover code commented out
#
# v1.1.5
# - Had to change where $logFile was declared
# - Added a debug statement at the end, log for this looks boring
#
# v1.1.4
# - Script is now using $debugPrefix
#
# v1.1.3
# - Changed script to use checkPrivilege()
#
# v1.1.2
# - Added the ability to source from /usr/share automatically
#
# v1.1.1
# - Got rid of sleep statements now that it is in announce()
#
# v1.1.0
# - Script will now ask if you would like to reboot after updating, if it is needed
# - Changed echoes to announce()
#
# v1.2.8, 23 Sept 2016 00:16 PST

### Variables

#program="NULL"
#log="$debugPrefix/update.log"

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

# Upgrades the system based on PM
function upgradeSystem() {
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
	yast)
	announce "Systems running YaST must be manually updated!"
	#yast -i $*
	;;
	rpm)
	rpm -F
	;;
	pacman)
	sudo pacman -Syyu # Forces package refresh then upgrades
	yaourt -Syu --aur # Remember to refresh the AUR as well
	;;
	aptitude)
	announce "NOTE: aptitude will be doing a dist-upgrade!"
	aptitude -y dist-upgrade
	;;
	*)
	announce "Package manager not found! Please update script or diagnose problem!"
	exit 3
	;;
esac
}

# Cleans system of unneeded downloaded packages and dependencies
function cleanSystem() {
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
	yast)
	#echo "Systems running YaST must be manually updated!"
	#yast -i $*
	;;
	rpm)
	announce "RPM has no clean function"
	# Nothing to be done
	;;
	pacman)
	#pacman -cq
	announce "For your safety, please clean pacman yourself." "Use the command: pacman -Sc"
	;;
	aptitude)
	#echo "NOTE: aptitude will be doing a dist-upgrade!"
	aptitude clean -y
	aptitude autoclean -y
	;;
	*)
	announce "Package manager not found! Please update script or diagnose problem!"
	exit 3
	;;
esac
}

### Main Script
#log="$debugPrefix/update.log" # Needs to be declared down here apparently
#debug "Starting $0 ..."

determinePM # Do this first, arch doesn't like sudo...

# Arch doesn't like sudo with yaourt, hence this block
# Comment out this block if you login as root by default on Arch
if [[ "$program" == "pacman" && "$EUID" -eq 0 ]]; then
	announce "Arch-based distributions do not require root privilege." "Please re-run script without sudo, or as normal user!"
	exit 1
else
	[[ ! "$program" == "pacman" ]] && checkPrivilege "ask" "$@" # I will chuckle everytime I have to type this lol
fi

# Tell user what is happening
if [[ $# -ne 0 ]]; then
	announce "Script will upgrade system, then attempt to install packages from arguments."
else
	announce "Script will now upgrade your system."
fi

#determinePM
upgradeSystem

if [[ $# -ne 0 ]]; then
	universalInstaller "$@"
fi

announce "Everything is installed and upgraded, cleaning up now!"
cleanSystem

if [[ ! -z $(which msfupdate 2>/dev/null) ]]; then
	debug "Metasploit is installed, running msfupdate..."
	announce "Metasploit installed, updating as well!"
	msfupdate
fi

if [[ ! -z $(which rpi-update 2>/dev/null) ]]; then
	debug "rpi-update was found, running..."
	announce "This is a Raspberry Pi, running rpi-update as well!"
	rpi-update
fi

# Code that asks to reboot if it is required
if [[ -f /var/run/reboot-required ]]; then
	debug "After installing updates, a reboot is required by the system!"
	getUserAnswer "A reboot is required! Would you like to reboot now?"
	
	case $? in
		0)
		announce "System will reboot itself in 3 mins!" "Please save your work in preparation" "Press CTRL+C to reboot immediately."
		sleep 180
		debug "Rebooting computer after required update..."
		reboot
		;;
		1)
		debug "User decided not to reboot computer"
		announce "Please reboot your computer at a time where it is convinient for you!"
		;;
		*)
		debug "Unknown exit code: $?"
		announce "An error occurred! Please consult the log!"
		;;
	esac
fi

announce "Done!"
#debug "Finished at $(date) !"
#eof