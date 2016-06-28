#!/bin/bash
# Script that automates my youtube-dl settings
# Usage: ./yt-script.sh <playlist_URL> <directory>
#
# Directory is optional, otherwise it will send to $HOME/Videos/youtube
#
# v1.0 May 28, 2016

# Variables

playlist="NULL"
DIR="$HOME/Videos/youtube"
answer="NULL" # Used for program check
ans="NULL" # Used for directory check

# Functions

function checkProgramInstall() {
if [[ $(which youtube-dl) == /usr/bin/youtube-dl ]]; then
	echo "youtube-dl is installed!"
else
	while [[ $answer != "y" && $answer != "yes" && $answer != "n" && $answer != "no" ]];
	do
		echo "youtube-dl is not installed! Would you like to install it now? (y/n)"
		read answer
	done

	case $answer in
		y|yes)
		echo "Installing, please grant sudo privileges..."
		sudo apt-get install -y youtube-dl
		if [[ $? == 1 ]]; then
			echo "youtube-dl not found in repository, manual installation required!"
			echo "Exiting script..."
			exit 1
		fi
		;;
		n|no)
		echo "Not installing, please install manually!"
		exit 1
		;;
	esac
fi
}

function download() {
	echo ''$DIR'/%(autonumber)s-%(title)s.%(ext)s'
	youtube-dl --verbose --output "$DIR/%(autonumber)s-%(title)s.%(ext)s" -f mp4 $playlist
	if [[ $? != 0 ]]; then
		echo "Something went wrong, please diagnose and re-run script!"
		exit 1
	fi
}

function displayHelp() {
	echo "Usage: $0 <playlist_URL> <directory>"
	echo " "
	echo "Directory can be omitted, defaults to 'HOME'/Videos/youtube"
	echo "Script will also check if program is installed using apt-get"
	echo " "
	echo "Please re-run with valid arguments!"
}

function checkDir() {
	if [[ -d $DIR ]]; then
		echo "$DIR exists..."
	else
		while [[ "$ans" != "y" && "$ans" != "yes" && "$ans" != "n" && "$ans" != "no" ]]; do
			echo "$DIR does not exist, would you like this script to create it for you? (y/n)"
			read ans
		done
		
		case $ans in
			y|yes)
			mkdir $DIR
			if [[ $# == 1 ]]; then
				echo "Error making directory, you may not have permissions!"
				echo "Please re-run script with a directory you have permissions for!"
				exit 1
			fi
			echo "Directory made!"
			;;
			n|no)
			echo "Please re-run script with a different directory! Or, make directory manually!"
			exit 1
			;;
		esac
	fi	
}

# Main Script

if [[ $# = 0 ]]; then 
	displayHelp
	exit 1
fi

playlist="$1"
if [[ $# = 2 ]]; then
	DIR="$2"
fi

checkProgramInstall
checkDir
download

echo "Done downloading playlist!"

#EOF