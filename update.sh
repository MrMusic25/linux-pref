#!/bin/bash
#
# update[.sh] - A universal update and install script, similar to what XKCD made
# Usage: ./update <packages>
#
# Running update by itself will update and upgrade all system packages.
# If there are arguments, it will try to install the programs listed
#
# v1.0, 29 June 2016 12:22 PST

### Variables

program="NULL"

### Functions

# determinePM() and install() taken from programInstaller.sh, make sure to mirror changes to both!\
# Determines the PM in use, and updates the repos if possible
function determinePM() {
#echo "Finding which package manager is in use..."
if [[ ! -z $(which apt-get) ]]; then # Most common, so it goes first
	export program="apt"
	apt-get update
elif [[ ! -z $(which yum) ]]; then
	export program="yum"
	#yum update
elif [[ ! -z $(which rpm) ]]; then
	export program="rpm"
	rpm -F --justdb # Only updates the DB, not the system
elif [[ ! -z $(which yast) ]]; then # YaST is annoying af, so look for rpm and yum first
	export program="yast"
elif [[ ! -z $(which pacman) ]]; then
	export program="pacman"
	pacman -yy # Refreshes the repos, always read the man pages!
elif [[ ! -z $(which aptitude) ]]; then # Just in case apt-get is somehow not installed with aptitude, happens
	export program="aptitude"
	aptitude update
fi
}

# Attempts to install program(s) in $* based on PM
function install() {
printf "\nInstalling $*\n" 
case $program in
	apt)
	apt-get install -y $*  
	;;
	yum)
	yum install $* 
	;;
	yast)
	yast -i $* 
	;;
	rpm)
	rpm -i $* 
	;;
	pacman)
	pacman -S $* 
	;;
	aptitude)
	aptitude install -y $* 
	;;
	*)
	echo "Package manager not found! Please update script or diagnose problem!"
	exit 3
	;;
esac
	# Insert code dealing with failed installs here
}

# Upgrades the system based on PM
function upgradeSystem() {
case $program in
	apt)
	echo "NOTE: script will be running a dist-upgrade!"
	apt-get dist-upgrade
	;;
	yum)
	yum upgrade
	;;
	yast)
	echo "Systems running YaST must be manually updated!"
	#yast -i $*
	;;
	rpm)
	rpm -F
	;;
	pacman)
	pacman -Syu
	;;
	aptitude)
	echo "NOTE: aptitude will be doing a dist-upgrade!"
	aptitude dist-upgrade
	;;
	*)
	echo "Package manager not found! Please update script or diagnose problem!"
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
	yum)
	yum clean all
	;;
	yast)
	#echo "Systems running YaST must be manually updated!"
	#yast -i $*
	;;
	rpm)
	echo "RPM has no clean function"
	# Nothing to be done
	;;
	pacman)
	pacman -cq
	;;
	aptitude)
	echo "NOTE: aptitude will be doing a dist-upgrade!"
	aptitude clean -y
	aptitude autoclean -y
	;;
	*)
	echo "Package manager not found! Please update script or diagnose problem!"
	exit 3
	;;
esac
}

### Main Script

if [ "$EUID" -ne 0 ]; then
	echo "This script require root privileges, please run as root or sudo!"
	exit 2
fi

if [[ $# -ne 0 ]]; then
	echo "Script will upgrade system, then attempt to install packages from arguments."
else
	echo "Script will now upgrade your system."
fi

determinePM
upgradeSystem

if [[ $# -ne 0 ]]; then
	install $*
fi

echo "Everything is installed and upgraded, cleaning up now!"
cleanSystem

if [[ ! -z $(which msfupdate) ]]; then
	echo "Metasploit installed, updating as well!"
	msfupdate
fi

echo "Done!"

#eof