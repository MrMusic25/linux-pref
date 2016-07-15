#!/bin/bash
#
# update[.sh] - A universal update and install script, similar to what XKCD made
# Usage: ./update <packages>
#
# Running update by itself will update and upgrade all system packages.
# If there are arguments, it will try to install the programs listed
#
# Changes:
# v1.2.0
# - Started using a better numbering system for changelog
# - Added support for Raspberry Pi, specifically raspbian
#
# v1.1.6
# - Note really an update, but small change from commonFunctions.sh. Leftover code commented out
#
# v1.1.5
# - Had to change where $log was declared
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
# v1.2.0, 15 July 2016 11:23 PST

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
case $program in
	apt)
	announce "NOTE: script will be running a dist-upgrade!"
	apt-get dist-upgrade
	;;
	dnf)
	dnf -y upgrade
	;;
	yum)
	yum upgrade
	;;
	yast)
	announce "Systems running YaST must be manually updated!"
	#yast -i $*
	;;
	rpm)
	rpm -F
	;;
	pacman)
	pacman -Syu
	;;
	aptitude)
	announce "NOTE: aptitude will be doing a dist-upgrade!"
	aptitude dist-upgrade
	;;
	*)
	announce "Package manager not found! Please update script or diagnose problem!"
	exit 3
	;;
esac
}

# Cleans system of unneeded downloaded packages and dependencies
function cleanSystem() {
case $program in
	apt)
	apt-get autoremove -y
	apt-get autoclean
	;;
	dnf)
	dnf -y clean all
	dnf -y autoerase
	;;
	yum)
	yum clean all
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
	pacman -cq
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
log="$debugPrefix/update.log" # Needs to be declared down here apparently
debug "Starting $0 ..." $log
checkPrivilege "ask" # I will chuckle everytime I have to type this lol

#if [[ $privilege -eq 777 ]]; then
#	announce "Re-running script as sudo!"
#	sudo $0
#	exit $?
#fi

if [[ $# -ne 0 ]]; then
	announce "Script will upgrade system, then attempt to install packages from arguments."
else
	announce "Script will now upgrade your system."
fi

determinePM
upgradeSystem

if [[ $# -ne 0 ]]; then
	universalInstaller $*
fi

announce "Everything is installed and upgraded, cleaning up now!"
cleanSystem

if [[ ! -z $(which msfupdate) ]]; then
	announce "Metasploit installed, updating as well!"
	msfupdate
fi

if [[ ! -z $(which rpi-update) ]]; then
	announce "This is a Raspberry Pi, running rpi-update as well!"
	rpi-update
fi

# Code that asks to reboot if it is required
if [[ -f /var/run/reboot-required ]]; then
	announce "A reboot is required after updating!" 
	printf "\nWould you like the script to manually reboot for you? (y/n): "
	answer="NULL"
	while [[ $answer != "y" && $answer != "yes" && $answer != "n" && $answer != "no" ]]; do
		read answer
		case $answer in
			y|yes)
			announce "Script will reboot computer in 3 minutes! Please close your work!" "Press any key to reboot immediately!"
			sleep 180
			announce "Rebooting computer now!"
			sleep 5
			reboot
			;;
			n|no)
			echo "Computer will not be rebooted. Please reboot manually later."
			;;
			*)
			printf "\nWould you like the script to manually reboot for you? (y/n): "
			;;
		esac
	done
fi

announce "Done!"
debug "Finished at $(date) !" $log
#eof