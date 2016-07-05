#!/bin/bash
#
# INSTALL.sh - A script meant to automatically install and setup my personal favorite options
# Usage: ./INSTALL.sh
#
# Note: This will change soon as functionality is added
# 
# v0.1 05 July 2016 13:06 PST

### Variables

sudoRequired=0 # Set to 0 by default - script will close if sudo is false and sudoRequired is true
installOnly=0 # Used by -n|--no-run, if 1 then files will be copied and verified, but not executed

### Functions

if [[ -f commonFunctions.sh ]]; then
	source commonFunctions.sh
elif [[ -f /usr/share/commonFunctions.sh ]]; then
	source /usr/share/commonFunctions.sh
else
	echo "commonFunctions.sh could not be located!"
	
	# Comment/uncomment below depending on if script actually uses common functions
	#echo "Script will now exit, please put file in same directory as script, or link to /usr/share!"
	#exit 1
fi

function displayHelp() {
	# Don't use announce() in here in case script fails from beng unable to source comonFunctions.sh
	echo " "
	echo " Usage: $0 [options] <install_option>"
	echo " "
	echo " Install Options:"
	echo " NOTE: Running any install option will check if /usr/share/commonFunctions.sh exists. If not, sudo permission will be requested to install."
	echo "    all                 - Installs all the scripts below"
	echo "    update              - Installs update script"
	echo "    programs [file]     - Installs programs using programInstaller.sh, or provided text-based tab-delimited file"
	echo "    kali [file]         - Same as 'programs', but installs from .kaliPrograms.txt by default. Also accepts file input."
	echo "    git                 - Installs git monitoring script and sets up cron job to run at boot
	echo " "
	echo " Options:"
	echo "    -h | --help                        : Displays this help message"
	echo "    -s | --sudo                        : Makes script check for root privileges before running anything"
	echo "    -e | --except <install_option>     : Installs everything except option specified. e.g './INSTALL.sh -e kali' "
	echo "    -n | --no-run                      : Only installs scripts to be used, does not execute scripts"
}

### Main Script

displayHelp
exit 5

#EOF