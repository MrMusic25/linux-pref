#!/bin/bash
#
# Usage: ./programInstaller.sh <programs.txt>
#
# Determines which package manager is being used, then installs all the packages listed in programs.txt (or argument, if provided)
#
# v1.0.1 June 29, 2016, 12:28 PST

### Variables

file="programs.txt"
program="NULL"
log="pm.log" # Remember to change this to 'install-logs/pm.log' when other scripts ready

### Functions

function determinePM() {
#echo "Finding which package manager is in use..."
if [[ ! -z $(which apt-get) ]]; then # Most common, so it goes first
	export program="apt"
	apt-get update &>/dev/null
elif [[ ! -z $(which yum) ]]; then
	export program="yum"
	yum check-update &>/dev/null
elif [[ ! -z $(which rpm) ]]; then
	export program="rpm"
	rpm -F --justdb &>/dev/null # Only updates the DB, not the system
elif [[ ! -z $(which yast) ]]; then
	export program="yast"
elif [[ ! -z $(which pacman) ]]; then
	export program="pacman"
	pacman -yy &>/dev/null
elif [[ ! -z $(which aptitude) ]]; then # Just in case apt-get is somehow not installed with aptitude, happens
	export program="aptitude"
	aptitude update &>/dev/null
fi
}

function install() {
printf "\nInstalling $*\n" >> "$log"
case $program in
	apt)
	apt-get install -y $* >> "$log" 
	;;
	yum)
	yum install $* >> "$log"
	;;
	yast)
	yast -i $* >> "$log"
	;;
	rpm)
	rpm -i $* >> "$log"
	;;
	pacman)
	pacman -S $* >> "$log"
	;;
	aptitude)
	aptitude install -y $* >> "$log"
	;;
	*)
	echo "Package manager not found! Please update script or diagnose problem!"
	exit 3
	;;
esac
	# Insert code dealing with failed installs here
}

### Main script

# First, check to see is user is root/sudo. Makes scripting easier
if [ "$EUID" -ne 0 ]; then
	echo "This script require root privileges, please run as root or sudo!"
	exit 2
fi

# Checks for argument and sets as file location
if [[ $# != 0 ]]; then
	file=$1
fi


# Test to make sure file valid
if [[ ! -e $file ]]; then
	echo "$file could not be found! Please check and re-run script!"
	exit 1
fi

# Now that file is valid, determine program to use
echo "Determining package manager and updating. This may take time depending on internet speed and repo size."
determinePM
echo "This distribution is using $program as it's package manager!"
echo "Now installing programs from $file!"
echo " "
echo "Note: This may take some time depending on size of list."
echo "      Check $log for progress and details!"
echo " "

# Now we can install everything
touch $log # Touch logfile so nothing fails
while read -r line; do
	[[ $line = \#* ]] && continue # Skips comment lines
	install $line
done < $file

echo "Done installing programs!"

#EOF