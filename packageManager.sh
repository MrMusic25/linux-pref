#!/bin/bash
#
# packageManager.sh, a.k.a pm - A universal package manager script
#
# Changes:
# v0.0.1
# - No real scripting, but added a long list of things to-do
# - Initial version
#
# TODO:
# - Add the following functions, and copy over functions from other scripts
#   ~ For all functions: find a way to do a "did you mean: $package?" type thing
#   ~ Update (refresh DB and install updates, also make refresh-only mode) with alias of Upgrade
#     ~ Separate determinePM() and refreshDB(), use conditional calling
#     ~ Find a way to detect multiple PMs
#   ~ Install (using universalInstaller() )
#     ~ For dists like arch with multiple PMs, ask before installing
#     ~ Package name, text file, and folder of text files should be supported
#   ~ Remove (alias uninstall)
#   ~ Clean/'autoremove'
#   ~ Query
#     ~ Check database for packages matching name given (apt-cache search, pacsearch, etc)
#   ~ pkgInfo (find a better alias)
#     ~ Display info for the package given (pacman -Qi, etc.)
# - Make new cF.sh specifically for this script
#   ~ Add this script to cF.sh so other functions that depend on universalInstaller or determinePM can still use them
#     ~ For that matter, DON'T BREAK COMPATIBILITY! COPY+PASTE!
#   ~ Possibly add them to a folder of common functions, source all of them with a for loop or conditionally (ifdef, C++ style!)
#     ~ http://unix.stackexchange.com/questions/253805/ifdef-style-conditional-inclusions-for-shell
#   ~ Note: you might have to fix linking once everything is ready
#     ~ Idea: Script that sources everything from the $LP/commonFunctions.sh folder, solves a lot of issues
#       ~ You would have to export the location of $LP, but that's pretty easy to include with INSTALL.sh
# - If PM is Arch, make sure it is NOT running as sudo. Otherwise, checkPrivilege "quit"
#
#
# v0.0.1, Sept. 28 2016 18:08 PST

### Variables



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