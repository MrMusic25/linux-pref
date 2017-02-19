# linux-pref
A repository that is meant to hold and install all my favorite programs, settings, aliases, and scripts whenever I decided
to install or try a new distribution of Linux. These are written entirely in bash so, it should work on anything that runs it
i.e. OSX, BSD, UNIX, and Windows 10!

## General Note and Information

- If a script requires root privileges, it will notify you and attempt to re-run itself as root.
- All scripts will save their logs to `~/.logs/`, look there for additional debug info when diagnosing errors.
- Please feel free to fork this for yourself, or leave a note here. I accept any input or suggestions/improvements.
- If you are interested in writing scripts like these, you can begin learning the syntax from the [Bash Hackers Wiki] (http://wiki.bash-hackers.org/), or look at the files in `examples/`
- I wrote most of these on a Manjaro system, but also do a lot of it with Bash for Windows. Below are the versions my scripts have been tested on:
  ~ Bash for Windows: version 4.3.11(1)-release (x86_64-pc-linux-gnu)
  ~ Manjaro Linux: Bash version 4.4? (will verify)

## Scripts and Usage

### INSTALL.sh
This is the main installation script. Run it, and it will do the heavy lifting for you.

INSTALLATION INSTRUCTIONS:

> 1. cd ~/ && git clone https://github.com/mrmusic25/linux-pref.git

> 2. cd linux-pref/

> 3. ./INSTALL.sh all

If you receive any type of execution error, run the following command:

`for script in $(ls | grep *.sh); do chmod +x $script; done`

The script has a lot of interactive parts and will ask before changing most settings.

Alternatively, you can use the different commands listed when running the script by itself.

Also displays with `./INSTALL.sh -h` or `./INSTALL.sh --help`

### packageManager.sh
The Swiss Army Knife of the Bash world! This script can update, install, remove, query, and display package information on almost any distribution.

This makes lifes easier, with commands such as `sudo pm fuc` will re[f]resh, [u]pdate, and [c]lean your system.

Please run `packageManager.sh --help` to get a more complete list of commands and functions of this script. 

### gitManager.sh
A script that will update a single given repository, OR update from a known list of repositories.

Using the file `$HOME/.gitDirectoryList`, this script will update every valid git directory on its current branch.

You can also update a single repository simply by running the script with the directory as an argument.

NOTE: This means you must run `gitManager.sh .` to update your current directory!

Read the help section for this script by running `gitManager.sh --help` for more info!

Generally, this script will be run as a cronjob every 15 minutes. This can be configured by running `gm --install`

### grive.sh
This script will update your Google Drive using the webupd8/grive2 program.
Checks to see if it is installed, directory is setup, and if there is internet connection. Lots of logging.

Usage: `./grive.sh [path_to_grive_folder]`

If no path is given, it assumes folder is found at $HOME/Grive. Script also assumes Grive has already been setup for that folder.

Run `INSTALL.sh grive` if you would like help setting up grive.

Use the following line in your crontab:
` */5 * * * * /home/$USER/linux-pref/grive.sh [path_to_grive_folder] &>/dev/null`
This will sync every 5 minutes. Redirects info to /dev/null, as it is not necessary as a daemon.

### setupCommands.sh
This script will add useful and fun lines to your .bashrc files for current user and root.

Usage: `./setupCommands.sh`

No arguments needed. The script will always ask before installing a line to the .bashrc file.

### defaultScriptTemplate.sh
This file is the template file I use for all of my scripts. Simply copy+paste and rename, and use as a new script!

### commonFunctions.sh
A file I use to store all my functions that multiple scripts may need to use. Not meant to be run on its own, but rather imported by other scripts.

Usage: Add `import commonFunctions.sh` OR `. commonFunctions.sh` to the beginning of any bash-script

For best results, put commonFunctions.sh in /usr/share with a hard link, then import from there.

> Run (from cloned folder): `sudo ln commonFunctions.sh /usr/share`

> In script: `import /usr/share/commonFunctions.sh` OR `. /usr/share/commonFunctions.sh`

All of my scripts include if statements to check /usr/share before current directory, as this is easier and all users have read-access.

Since the file itself has VERY good documentation, I will only give breif descriptions of each function here

#### announce()
Sometimes just printing a line to the screen doesn't get a user's attention; therefore, I created a function that will print messages that demand attention!

#### debug()
This command will echo anything it receives to a dynamically made log file. Very useful, add statements everywhere using this!

Debug now supports levels! Below are what each level does, see function for more info:

L1: Log only
L2: stderr + log
L3: stdout (via announce()) + log
L4: stderr + stdout (via announce()) + log
L5: Log, but ONLY if verbose mode is on!

L5 is useful for debugging repetitive scripts; only outputs messages in verbose mode, so log is not flooded after every run

#### checkPrivilege()
Checks to see if user has root privileges or not.

If you run `checkPrivilege "exit"`, the script will exit if not root. `checkPrivilege "ask" "$@"` will re-run the script as `sudo`.

#### addCronJob()
Like the name suggests, it will automatically add a job to your current crontab. Be careful which user this gets run as.
Also, pay close attention to the documentation! Incorrect calls can kill!

#### getUserAnswer()
Asks the user a given question, then can optionally have user assign a value to a variable for use. See documentation for more info.

#### pause()
Simply prompts the user to press [Enter] to continue. Can also use custom prompt.

#### editTextFile()
Opens a text file for editing with the user's preferred text editor.

#### win2UnixPath()
Created for my other script, [m3uToUSB.sh] (https://github.com/mrmusic25/bash-projects), to convert Windows directories to Unix-friendly ones. See documentation.

#### Other jobs
There is now a small function that runs each time commonFunctions.sh is sourced - `if $1 is -v|--verbose`, it will enable debugging and shift arguments for use.

### packageManagerCF.sh
This is a file containing functions pertaining to package management. commonFunctions.sh will automatically import this file.
Below is a list and brief description for each function. Like with cF.sh, look at the script comments for detailed info.

#### determinePM()
Determines which package manager you are using and sets it accordingly for future use. Other functions will call this if var is empty.

#### updatePM()
Refreshes the package databases for known package managers.

#### universalInstaller()
Like the XKCD comic, but a little more sophisticated. (No support for language managers like pip or npm, though)

#### upgradePM()
Upgrades the system with the latest packages from the maintainer. Be sure to run updatePM() beforehand!

#### cleanPM()
Cleans the system of stale and unused packages, if it supports this functions. Gives an error if else.

#### queryPM()
Searches the package database for the specified package

#### removePM()
Uninstalls the specifed package from the system

#### pkgInfo()
Displays specific information about the package given

#### checkRequirements()
Checks to see if required programs for the script are installed, and installs them if they are not found.

## Text Files and Data

### .bash_aliases
Self explanatory, all of my favorite bash aliases that will be loaded automatically with the default bash config

My recommendation would be to run the following commands from the cloned directory:
```
ln .bash_aliases ~/
sudo ln .bash_aliases /root
```

### .bashrc
I also decided to include a .bashrc that should also be linked to `~/` or `$HOME`.

NOTE: This is not a replacement .bashrc! I recommend adding the following line to your maintainer's .bashrc:

`source ~/linux-pref/.bashrc`

I would also recommend doing the same for .bash_aliases. Perform the same actions for root as well. (All of this is done by INSTALL.sh, of course)

### programLists/
I tried putting all my favorite programs in one document, but found it to be inefficient as I didn't want ALL the packages installaed on EVERY computer.

My solution: split the programs up based on how I use them, and then modify the installer script to ask before installing each list of programs.

Running `./programInstaller.sh programLists/` will ask before installing each file from the folder. Go through the files you plan on running and comment-out programs you do not want. 

NOTE: `requires-ppa.txt` holds programs that may not be in your distributions' default repositories. Look up how to add or obtain these programs from Google if you are interested!

### examples/
Though it is not in the git, I keep a script call `scriptTest.sh` in my working directory. I use it to test code to make sure it works before putting it into a script. Think of it as a proof-of-concept script.

Whenever I do this, I export the script, and it's output, to an example in this folder. Updated occasionally, each file has the following format:

1. Explanation of what this proof-of-concept is
2. The script that was run
3. The output of the script

This is a useful place for beginners to learn more about bash.

### nonScriptCommands.txt
When INSTALL.sh is done, it will echo the lines in this file to remind you to set these up yourself.

This is for things like adding keyboard shortcuts and changing mouse settings, things that can't be done (easily) from the command line.
