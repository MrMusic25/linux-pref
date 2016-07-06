# linux-pref
A repository with all my favorite aliases, settings, scripts, and installer scripts

## Scripts and Usage

### INSTALL.sh
Meant to be the main installation script - run this, and it will do all the heavy lifting for you.

~~I will update this once the script is ready. For now, it is empty.~~

Running `./INSTALL.sh` will now display the help module, with all the planned functionality I plan to code into the script

### programInstaller.sh
A multi-distro script that installs a list of programs.

Usage: `./programInstaller.sh <list_of_programs>`

Accepts a list of programs, seperated by breaks or whitespace, and attempts to install all programs.
Note: Breaks are preferred over whitespace, so that one unavailable packages does not stop the whole installation.
Programs list file my contain comments notated with #, those lines will be ignored.

If no argument is given, it will look for 'programs.txt' in the same directory instead.
Script exits with code 1 if no programs list is found.

### update.sh
Another multi-distro script that updates the repos and upgrades all available packages

Usage: `./update.sh <packages_to_install>`

Meant to be run by itself. Used to make a script like this everytime I installed a new distro...
If you supply packages at the end, it will attempt to install those packages after updating.
Also cleans up afterwards, e.g. `apt-get autoclean` , `apt-get autoremove`

### gitCheck.sh
A script used to update a folder linked to a git repository.
This script assumes you ran `git clone git://<url>.git` or something similar.

Usage: `./gitCheck.sh <git_folder>`

Script will check to see if git upload info is present. If so, it will change into directory and run a `git pull`.

Add the following line to your crontab, since the script does not loop itself:
`*/15 * * * * /home/$USER/linux-pref/gitCheck.sh <path_to_git_folder>`
This will check for an update every 15 minutes.

### grive.sh
This script will update your Google Drive using the grive2 program.
Checks to see if it is installed, directory is setup, and if there is internet connection. Lots of logging.

Usage: `./grive.sh [path_to_grive_folder]`

If no path is given, it assumes folder is found at $HOME/Grive. Script also assumes Grive has already been setup for that folder.

Use the following line in your crontab:
` */5 * * * * /home/$USER/linux-pref/grive.sh [path_to_grive_folder]`
This will sync every 5 minutes.

###
### commonFunctions.sh
A file I use to store all my functions that multiple scripts may need to use. Not meant to be run on its own, but rather imported by other scripts.

Usage: Add `import commonFunctions.sh` OR `. commonFunctions.sh` to the beginning of any bash-script

For best results, put commonFunctions.sh in /usr/share with a hard link, then import from there.

> Run (from cloned folder): `sudo ln commonFunctions.sh /usr/share`

> In script: `import /usr/share/commonFunctions.sh` OR `. /usr/share/commonFunctions.sh`

All of my scripts include if statements to check /usr/share before current directory, as this is easier and all users have read-access.

Since the file itself has VERY good documentation, I will only give breif descriptions of each function here

#### determinePM()
Figures out which package manager you are using, and exports option to `$program`. Only has major package managers at the moment.

#### universalInstaller()
Like the XKCD comic, I have created a universal installer (only distrobution packages, no pip etc.)

#### announce()
Sometimes just printing a line to the screen doesn't get a user's attention; therefore, I created a function that will print messages that deman attention!

#### debug()
A few simple lines of code, and with debugging turned on, you can selectively print messages. Very useful.

In recent updates, debug() now touches the log file, and makes sure the log directory is available as well.

#### checkPrivilege()
Checks to see if user has root privileges or not. Also has the option to exit script if privileges missing.

## Text Files and Data

### .bash_aliases
Self explanatory, all of my favorite bash aliases that will be loaded automatically with the default bash config

My recommendation would be to run the following commands from the cloned directory:
```
ln .bash_aliases ~/
sudo ln .bash_aliases /root
```

### programs.txt
A list of all my favorite programs that I want installed, pretty mch why I started this git.

Meant to be used as a reference, and by programInstaller.sh. Comments can be added with #, script will ignore those lines.

### .kaliPrograms.txt
Same as programs.txt, but specifically with penetration testing programs that may not need to be installed everytime. 