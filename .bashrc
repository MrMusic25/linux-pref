# Things that I would like added to my .bashrc list
# NOTE: This is NOT a replacement for the actual .bashrc, only do so if you know what you are doing!

# A 'very popular' function. Looks helpful!
function extract()
{
     if [ -f $1 ] ; then
         case $1 in
            *.tar.bz2)   
                tar xvjf $1     
                ;;
            *.tar.gz)    
                tar xvzf $1     
                ;;
            *.bz2)       
                bunzip2 $1      
                ;;
            *.rar)
                unrar x $1      
                ;;
            *.gz)
                gunzip $1       
                ;;
            *.tar)
                tar xvf $1      
                ;;
            *.tbz2)
                tar xvjf $1     
                ;;
            *.tgz)
                tar xvzf $1     
                ;;
            *.zip)
                unzip $1        
                ;;
            *.Z)
                uncompress $1   
                ;;
            *.7z)
                7z x $1         
                ;;
            *)  
                echo "'$1' cannot be extracted via extract" 
                ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Found this on /r/linux, https://www.reddit.com/r/linux/comments/4v3cfw/share_some_scripts_that_youve_made_or_ones_you/
# Depends on extract() above. Make sure to use both!
function compile () {
    if [ -z "$1" ]
    then
        echo "Usage: compile <source code archive>"
    else
        if [ -f "$1" ]
        then
            extract "$1"
            filename=$(basename "$1") 
            foldername="${filename%.*}" 
            if [[ "${foldername##*.}" = *tar ]]
            then
                foldername="${foldername%.*}" 
            fi
            pushd "$foldername"
            if ls --color=auto ./autogen* > /dev/null 2>&1
            then
                sh ./autogen*
            fi
            if ls --color=auto ./configure > /dev/null 2>&1
            then
                sh ./configure
            elif ls --color=auto ./configure.sh > /dev/null 2>&1
            then
                sh ./configure.sh
            fi
            make
            sudo make install
            make distclean
            popd
        else
            echo "Error: file $1 does not exist"
        fi
    fi
}

# Uncomment the line below if aliases do not work. Change to '/root/.bash_aliases' for root user
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases

# The following two lines make nano the default editor. Comments if you use vim or others, or change it
export VISUAL
VISUAL="nano"
export EDITOR
EDITOR="nano"

# A fun little program I found on Reddit one day, change city to official list at wttr.in!
wttrCity="los_angeles"
alias weather='curl wttr.in/$wttrCity'

function push() {
	# If arg provided, use that as directory. Otherwise, assume pwd
	if [[ -z "$1" ]]; then
		if [[ ! -d .git ]]; then
			echo "$(pwd) is not a valid git directory!"
		else
			git push
		fi
	else
		if [[ ! -d "$1"/.git ]]; then
			echo "$1 is not a valid git directory!"
		else
			OPWD="$(pwd)"
			cd "$1"
			git push
			cd "$OPWD"
		fi
	fi
}

function pull() {
	# If arg provided, use that as directory. Otherwise, assume pwd
	if [[ -z "$1" ]]; then
		if [[ ! -d .git ]]; then
			echo "$(pwd) is not a valid git directory!"
		else
			git pull
		fi
	else
		if [[ ! -d "$1"/.git ]]; then
			echo "$1 is not a valid git directory!"
		else
			OPWD="$(pwd)"
			cd "$1"
			git pull
			cd "$OPWD"
		fi
	fi
}

function commit() {
	# If arg provided, use that as directory. Otherwise, assume pwd
	if [[ -z "$1" ]]; then
		if [[ ! -d .git ]]; then
			echo "$(pwd) is not a valid git directory!"
		else
			git commit -a
		fi
	else
		if [[ ! -d "$1"/.git ]]; then
			echo "$1 is not a valid git directory!"
		else
			OPWD="$(pwd)"
			cd "$1"
			git commit -a
			cd "$OPWD"
		fi
	fi
}

# Got the idea for this one day
if [[ -z $logDir ]]; then
	logDir="$HOME/.logs" # If logDir is unset, set it to the default. Typically should be set to system-wide directory, unless system is shared
fi

function log() {

read -d '' logUsage << endHelp
Usage: log <logFile> [numLines] OR log <command>
Type 'log command' to see supported commands.
numLines is the number of lines you would like to be read (via tail).
endHelp

	if [[ -z $1 ]]; then
		printf "ERROR: No arguments given with log()!\n\n%s\n" "$logUsage"
		return 1
	fi

	case $1 in
		-h|--help|help)
		printf "%s\n" "$logUsage"
		return 0
		;;
		ls|list)
		printf "Displaying files in %s...\n" "$logDir"
		ls -l "$logDir"
		return 0
		;;
		dir|display|show)
		printf "Log directory is located at: %s\nType in \'log cd\' to switch to the directory!\n" "$logDir"
		return 0
		;;
		cd|switch)
		printf "Changing current directory to %s!\n" "$logDir"
		cd "$logDir"
		return 0
		;;
		command*)
		printf "Commands:\n  ls|list          : List the files in the set log directory\n  cd|switch        : Switch to the set log directory\n dir|display|show  : Tells you the name of the set log directory\n"
		return 0
		;;
		*)
		true # Used to be an error here, but now with file guessing it is irrelevent
		;;
	esac

	if [[ ! -z $2 && "$2" -eq "$2" ]]; then
		nlines="$2"
	else
		nlines="20"
	fi
	
	OPWD="$(pwd)"
	cd "$logDir" # Makes searching easier
	
	if [[ -e "$1" ]]; then
		logRead="$1"
	else # Partial name, guess the rest
		printf "WARN: Partial name given for log file, guessing the rest!\n"
		logRead="$(ls *.log | grep "$1")"
	fi
	
	printf "INFO: Showing the last %s lines of log file %s:\n\n" "$nlines" "$logRead"
	tail -n "$nlines" "$logRead"
	cd "$OPWD"
	return 0
}

# Tired of starting a graphical program from the terminal but hate the stdout? Daemonize it!
# Runs 'eval' on all output, and runs it as a daemon
# Fun fact: I came up with this fun name while watching Supernatural, lol
function daemonize() {

read -d '' daemonizeUsage << endHelp
Usage: daemonize <program> [arguments]
All arguments will be run as given.
Use this function to run any function as a daemon.
endHelp

	if [[ -z $1 ]]; then
		printf "ERROR: No arguments given with daemonize()!\n\n%s\n" "$daemonizeUsage"
		return 1
	fi
	
	# Only real requirement. Run everything else in an eval statement
	eval "$@" &>/dev/null 2>&1 &disown;
}