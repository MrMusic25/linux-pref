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
compile () {
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
export VISUAL="nano"
export EDITOR="$VISUAL"

