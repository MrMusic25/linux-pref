#!/bin/bash
#
# INSTALL.sh - A script meant to automatically install and setup my personal favorite options
# Usage: ./INSTALL.sh [options] <install_option>
# Run with the -h|--help option to see full list of install options (or look at displayHelp())
#
# Changes:
# v2.0.0
# - Started work on re-written, more efficient install script
# - Use 0b664c6 to get original script, most of it was erased after that commit
# - Wrote displayHelp and supporting variables/processArgs() fills
# - Added a monstorosity of a switch to decide which options to run
#
# TODO:
#
# v2.0.0, 03 Dec. 2017, 22:32 PST

### Variables

longName="INSTALL" #shortName and longName used for logging
shortName="iS" # installScript
specific="unset" # Used to tell if except/only mode is on
sudoCheck=0 # Tells script whether to ignore sudo warning
run=0 # Indicates whether or not scripts will be run by default
ask=0 # Whether or not user will be asked before running each script

### Functions

# Used to link commonFunctions.sh to /usr/share, in case it is not there already
# This version only used in the installer script, as it is usually the first thing run from the repo
function linkCF() {
	if [[ ! -f commonFunctions.sh ]]; then
		echo "ERROR: commonFunctions.sh is somehow not available, please correct and re-run!"
		echo "Please cd into the directoy containing $0 and commonFunctions.sh!"
		exit 1
	fi
	
	if [[ "$EUID" -ne 0 ]]; then
		echo "Linking to /usr/share requires root permissions, please login"
		sudo ln -s "$(pwd)"/commonFunctions.sh /usr/share/commonFunctions.sh
		sudo ln -s "$(pwd)"/packageManagerCF.sh /usr/share/packageManagerCF.sh
	else
		echo "Linking to commonFunctions.sh to /usr/share/ !"
		sudo ln -s "$(pwd)"/commonFunctions.sh /usr/share/commonFunctions.sh
		sudo ln -s "$(pwd)"/packageManagerCF.sh /usr/share/packageManagerCF.sh
	fi
}

if [[ -f /usr/share/commonFunctions.sh ]]; then
	source /usr/share/commonFunctions.sh
elif [[ -f commonFunctions.sh ]]; then
	source commonFunctions.sh
	linkCF
else
	echo "commonFunctions.sh could not be located!"
	echo "Script will now exit, please put file in same directory as script, or link to /usr/share!"
	exit 1
fi

function displayHelp() {
# The following will read all text between the words 'helpVar' into the variable $helpVar
# The echo at the end will output it, exactly as shown, to the user
read -d '' helpVar <<"endHelp"

INSTALL.sh - A script that sets up a new computer with other scripts and settings from mrmusic25/linux-pref

Usage: ./INSTALL.sh [options] <install_option>
       ./INSTALL.sh [options] -e <iOption>,[iOption]
	   ./INSTALL.sh [options] -o <iOption>,[iOption]

Options:
  -h | --help                         : Display this help message and exit
  -v | --verbose                      : Prints verbose debug information. MUST be the first argument!
  -s | --sudo                         : Ignores sudo-check (use this option if root is only user being used on system)
  -n | --no-run                       : Only setup links, don't run any of the scripts
  -a | --ask                          : Ask before running each script
  -e | --except <iOption>,[iOption]   : Assumes install option 'all'. See note below for usage.
  -o | --only <iOption>,[iOption]     : Only installs selected options; similar to -e|--except

Install Options (iOptions):
  all                                 : Installs all the below options/scripts
  pm | packageManager                 : Universal package manager script
  programs                            : Installs programs from the local programLists folder
  gm | gitManager                     : Git management and update script
  bash                                : Installs .bashrc and .bash_aliases for selected users (will be asked)
  grive                               : Installs grive2, and the grive2 management script
  uninstall                           : Uninstalls all scripts and changes listed in ~/.lpChanges.conf

For --except and --only options, specify programs you don't (or do) want installed in comma delimited format.
  e.g. ./INSTALL.sh -e pm,bash   <-- This command will install everything but pm and bash
       ./INSTALL.sh -o pm,bash   <-- This command will only install pm and bash, nothing else
If your package manager does not have grive2 by default, it will be installed from the repo vitalif/grive2

endHelp
echo "$helpVar"
}

function processArgs() {
	# displayHelp and exit if there is less than the required number of arguments
	# Remember to change this as your requirements change!
	if [[ $# -lt 1 ]]; then
		debug "l2" "ERROR: No arguments given! Please fix and re-run"
		displayHelp
		exit 1
	fi
	
	# This is an example of how most of my argument processors look
	# Psuedo-code: until condition is met, change values based on input; shift variable, then repeat
	while [[ $loopFlag -eq 0 ]]; do
		key="$1"
			
		case "$key" in
			-h|--help)
			displayHelp
			exit 0
			;;
			-v|--verbose)
			debugFlag=1
			debugLevel=2
			debug "l2" "WARN: Vebose mode enabled! In the future, however, please make -v|--verbose the first argument!"
			;;
			-s|--sudo)
			sudoCheck=1
			;;
			-n|--no-run)
			run=1
			debug "l1" "INFO: User has indicated not to run scripts"
			;;
			-a|--ask)
			ask=1
			debug "l1" "INFO: User will be asked before each script is run"
			;;
			-e|--except)
			if [[ -z $2 ]]; then
				debug "l2" "ERROR: No arguments given with $key, please fix and re-run!"
				exit 1
			fi
			specific="except"
			loopFlag=1 # Assume the rest is install options and continue
			;;
			-o|--only)
			if [[ -z $2 ]]; then
				debug "l2" "ERROR: No arguments given with $key, please fix and re-run!"
				exit 1
			fi
			specific="only"
			loopFlag=1
			;;
			--dry-run)
			dryRun="set" # Oh, a secret argument! When run, script will only output anticipated changes/debug messages without making changes
			debug "l1" "WARN: Doing a dry-run, nothing will be changed!"
			;;
			*)
			# If it is not an option, assume it is the run mode and continue
			loopFlag=1
			;;
		esac
		shift
	done
}

### Main Script

processArgs "$@"

# First, make sure user isn't sudo
if [[ $EUID -eq 0 ]]; then
	if [[ $sudoCheck -ne 0 ]]; then
		debug "l1" "WARN: Ignoring sudo check, continuing with script as root!"
	else
		announce "This script is meant to be run as a normal user, not root!" "Please run the script without sudo." "Or, if root is the only user, run with the -s|--sudo option!"
		debug "l1" "INFO: Warned user about using script as sudo, exiting..."
		exit 1
	fi
fi

# Now, time to decide what to run
# Scripts to install/run are decided by an array with the following values
# Program:    pm  programs  gm  bash  grive 
# Location:  [0]    [1]    [2]  [3]    [4]
declare -a iOptions
for i in {0..4}
do
	iOptions[$i]=0 # Initialize array, nothing by default
done

case $specific in:
	except)
	for i in {0..4}
	do
		iOptions[$i]=1
	done
	for i in {0.."$(awk -F',' '{print NF-1}' <<< "$1")"..1} # char count of commas in string; hopefully 0 doesn't cause it to fail
	do
		iOpt="$(echo "$1" | cut -d',' -f $i)" # By this point, $1 should be the only arg left
		case "$iOpt" in:
			all)
			debug "l2" "FATAL: iOption all is not compatible with -e|--except! Please fix and re-run!"
			exit 1
			;;
			pm|pac*)
			iOptions[0]=0
			;;
			pr*)
			iOptions[1]=0
			;;
			gm|gi*)
			iOptions[2]=0
			;;
			ba*)
			iOptions[3]=0
			;;
			gr*)
			iOptions[4]=0
			;;
			uni*)
			debug "l2" "FATAL: iOption uninstall is not compatible with -e|--except! Please fix and re-run!"
			exit 1
			;;
			*)
			debug "l2" "ERROR: $iOpt is not a valid install option. Attempting to continue..."
			;;
		esac
	done
	;;
	only)
	for i in {0.."$(awk -F',' '{print NF-1}' <<< "$1")"..1} # char count of commas in string; hopefully 0 doesn't cause it to fail
	do
		iOpt="$(echo "$1" | cut -d',' -f $i)"
		case "$iOpt" in:
			all)
			debug "l2" "FATAL: iOption all is not compatible with -o|--only! Please fix and re-run!"
			exit 1
			;;
			pm|pac*)
			iOptions[0]=1
			;;
			pr*)
			iOptions[1]=1
			;;
			gm|gi*)
			iOptions[2]=1
			;;
			ba*)
			iOptions[3]=1
			;;
			gr*)
			iOptions[4]=1
			;;
			uni*)
			debug "l2" "FATAL: iOption uninstall is not compatible with -o|--only! Please fix and re-run!"
			exit 1
			;;
			*)
			debug "l2" "ERROR: $iOpt is not a valid install option. Attempting to continue..."
			;;
		esac
	done
	;;
	*)
	case "$1" in:
		all)
		for i in {0..4}
		do
			iOptions[$i]=1
		done
		;;
		pm|pac*)
		iOptions[0]=1
		;;
		pr*)
		iOptions[1]=1
		;;
		gm|gi*)
		iOptions[2]=1
		;;
		ba*)
		iOptions[3]=1
		;;
		gr*)
		iOptions[4]=1
		;;
		uni*)
		debug "l2" "FATAL: iOption uninstall is not compatible with -o|--only! Please fix and re-run!"
		exit 1
		;;
		*)
		debug "l2" "ERROR: $iOpt is not a valid install option. Attempting to continue..."
		;;
	esac
	;;
esac

#EOF