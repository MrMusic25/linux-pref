# linux-pref
A repository that is meant to hold and install all my favorite programs, settings, aliases, and scripts whenever I decided
to install or try a new distribution of Linux. These are written entirely in bash so, it should work on anything that runs it
i.e. OSX, BSD, UNIX, and soon Windows 10!

## Notes and Info

- If a script requires root privileges, it will notify you and attempt to re-run itself as root.
- All scripts will save their logs to `~/.logs/`, look there for additional debug info if submitting a ticket or diagnosing errors.
- Please feel free to fork this for yourself, or leave a note here. I accept any input or suggestions on improvements or bug fixes.
- If you are interested in writing scripts like these, you can begin learning the syntax from the [Bash Hackers Wiki] (http://wiki.bash-hackers.org/), or look at the files in `examples/`

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
A script capable of managing packages on most of the common distributions.

More info to come once this script is ready, but it will replace programInstaller.sh, update.sh, and installPackages.sh

### programInstaller.sh
A multi-distro script that installs a list of programs, or a folder full of program lists.

Usage: `./programInstaller.sh <list_of_programs>/` OR `./programInstaller <list.txt>`

First argument should either be a single list of programs, or it can be a directory full of program lists.
If none is given, it will default to programLists/ in the current directory.

### update.sh
Another multi-distro script that updates the repos and upgrades all available packages.

Usage: `./update.sh <packages_to_install>`

Meant to be run by itself. Used to make a script like this everytime I installed a new distro...
If you supply packages at the end, it will attempt to install those packages after updating.
Also cleans up afterwards, e.g. `apt-get autoclean` , `apt-get autoremove`

### installPackages.sh
If all you want to do is install packages without upgrading, run this script!

Usage: `./programInstaller.sh <program_1> [program_2] ...`

Must be run with at least one argument, but you can install as many programs as you want at a time!

### gitCheck.sh
A script used to update a git repository inside a given folder.

This script assumes you ran `git clone git://<url>/<user>/<repo>.git` or something similar on that folder already.

Usage: `./gitCheck.sh <git_folder>`

Script will check to see if git upload info is present. If so, it will change into directory and run a `git pull`.

Add the following line to your crontab, since the script does not loop itself:

`*/15 * * * * /home/$USER/linux-pref/gitCheck.sh <path_to_git_folder> &>/dev/null`

Adding this line will check for an update every 15 minutes. You can also use addCronJob(), see commonFunctions.sh for more info.

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

#### determinePM()
Figures out which package manager you are using, and exports option to `$program`. Supports major distros.

#### universalInstaller()
Like the XKCD comic, I have created a universal installer (only distrobution packages, no pip etc.)

#### announce()
Sometimes just printing a line to the screen doesn't get a user's attention; therefore, I created a function that will print messages that demand attention!

#### debug()
This command will echo anything it receives to a dynamically made log file. Very useful, add statements everywhere using this!

By adding `export debugFlag=1` to any script, it will also echo messages to stderr ( >2& ).

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

#### checkRequirements()
If programs are require for a script, add them as an argument to this command. It will check that they are installed and quit if not.

#### Other jobs
There is now a small function that runs each time commonFunctions.sh is sourced - `if $1 is -v|--verbose`, it will enable debugging and shift arguments for use.

### packageManagerCF.sh
This is a file containing functions pertaining to package management. commonFunctions.sh will automatically import this file.
Below is a list and brief description for each function. Like with cF.sh, look at the script comments for detailed info.

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
