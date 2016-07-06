#!/bin/bash
#
# addRepository.sh - A multi-distro script that adds repositories from a file
#
# Usage: ./addRepository.sh <repo_list>
#
# repoFile should be a bash-friendly script/text file with the following allowed variables:
# repoName1=grive --> Package to be installed from repo
# repoPPA1="ppa:nilarimogard/webupd8" --> the PPA
#
# v0.1, 05 July 2016 16:17 PST

### Variables

repoFile=repositoryList.txt

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

### Main Script



#EOF