#!/bin/bash
#
# Usage: ./programInstaller.sh <programs.txt>
#
# Determines which package manager is being used, then installs all the packages listed in programs.txt (or argument, if provided)
#
# v1.0 June 28, 2016, 16:58 PST

### Variables

file="programs.txt"
program="NULL"

### Functions

function determinePM() {
if [[ $(which apt-get) == 0 ]]; then # Most common, so it goes first
	program="apt"
	apt-get update
elif [[ $(which yum) == 0 ]]; then
	program="yum"
	#yum update
elif [[ $(which yast) == 0 ]]; then
	program="yast"
elif [[ $(which pacman) == 0 ]]; then
	program="pacman"
elif [[ $(which aptitude) == 0 ]]; then # Just in case apt-get is somehow not installed with aptitude, happens
	program="aptitude"
	aptitude update
fi
}

function install() {
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
	pacman)
	pacman -Syu $*
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

# Now we can install everything
while read -r line; do
	[[ $line = \#* ]] && continue # Skips comment lines
	install $line
done < $file

echo "Done installing programs!"

#EOF