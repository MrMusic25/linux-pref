#!/bin/bash
#
# update[.sh] - A universal update and install script, similar to what XKCD made
# Usage: ./update <packages>
#
# Running update by itself will update and upgrade all system packages.
# If there are arguments, it will try to install the programs listed
#
# Changes:
#
# v1.1
# - Script will now ask if you would like to reboot after updating, if it is needed
# - Changed echoes to announce()
#
# v1.1, 01 July 2016 14:47 PST

### Variables

#program="NULL"
log="update.log"

### Functions

if [[ ! -f commonFunctions.sh ]]; then
	echo "commonFunctions.sh could not be found!" 
	echo "Please place in the same directory or create a link in $(pwd)!"
	exit 1
else
	source commonFunctions.sh
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

if [ "$EUID" -ne 0 ]; then
	announce "This script require root privileges, please run as root or sudo!"
	exit 2
fi

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

#eof