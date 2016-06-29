# linux-pref
A repository with all my favorite aliases, settings, scripts, and installer scripts

## Scripts and Usage

### programInstaller.sh
A multi-distro script that installs a list of programs.

Usage: ./programInstaller.sh <list_of_programs>

Accepts a list of programs, seperated by breaks or whitespace, and attempts to install all programs.
Note: Breaks are preferred over whitespace, so that one unavailable packages does not stop the whole installation.
Programs list file my contain comments notated with #, those lines will be ignored.

If no argument is given, it will look for 'programs.txt' in the same directory instead.
Script exits with code 1 if no programs list is found.

### update.sh
Another multi-distro script that updates the repos and upgrades all available packages

Usage: ./update.sh <packages_to_install>

Meant to be run by itself. Used to make a script like this everytime I installed a new distro...
If you supply packages at the end, it will attempt to install those packages after updating.
Also cleans up afterwards, e.g. apt-get autoclean; apt-get autoremove
