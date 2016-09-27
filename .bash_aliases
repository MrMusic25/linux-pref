# All my favorite bash aliases
# Comments can be used in typical BASH-style

# First, setup the ls aliases!
alias ls='ls --color=auto'
alias dir='ls -l --color=auto'
alias l='ls --color=auto'
alias ll='ls -l --color=auto'
alias la='ls -l -a --color=auto'

# My favorite one, the only thing Windows does right!
alias cls='clear'

# A few safety ones, just cuz
alias rm='rm -iv'
alias mv='mv -iv'
alias cp='cp -iv'

# grep aliases
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Couple that I thought of, might be useful
alias push='git push'
alias pull='git pull'
alias commit='git commit -a'

# Found this on reddit one day from u/TheHamitron
# https://gist.github.com/hamitron/53aed9089f224727cf28917b6b573e9d
#alias catass="curl http://catfacts-api.appspot.com/api/facts | sed 's/.*\["\(.*\)"\].*/\1/' | sed -e 's/cat/asshole/g' | espeak -s 150"

#EOF
