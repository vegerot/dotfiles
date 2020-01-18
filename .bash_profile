start=`date +%s.%N`
set -o vi
source ~/.profile
. ~/.git-prompt.sh
source ~/.paths.sh
1>&2 ~/bin/cowCommand.sh&
PROMPT_COMMAND=__prompt_command
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWCOLORHINTS=true
__prompt_command()
{

    local EXIT="$?"
    PROMPT_DIRTRIM=$((1+$(($(tput cols)/12))))
    PS1=""
    local RCol='\[\e[0m\]'
    local Red='\[\e[0;31m\]'
    local Blue='\[\e[0;36m\]'
    if [ $EXIT != 0 ]; then
        PS1+="${Red}\u${Rcol}"
    else
        PS1+="${Blue}\u${Rcol}"
    fi
    #PS1+="\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\n\$ "
    PS1+="\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\033[35m$(__git_ps1)\033[m \n\$ "	

}

win()
{
    local command="cd \\\"$PWD\\\"; clear"
    (( $# > 0 )) && command="${command}; $*"

    local app=$TERM_PROGRAM
    if [[ "$app" == 'Apple_Terminal' ]]
    then
        osascript > /dev/null <<EOF
    tell application "System Events"
        tell process "Terminal" to keystroke "n" using command down
    end tell
      tell application "Terminal" to do script "${command}" in front window
EOF

else
    echo "win: unsupported terminal app: $the_app"
    false
fi
}


mkcdir () {
    mkdir -p -- "$1" && cd -P -- "$1"
}

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

source ~/.aliases
alias ?='. ~/bin/cowCommand.sh'
alias ccat='pygmentize -g -O style=colorful'
alias ls='ls --color=auto -FGh'

#. ~/bin/autoAlias.sh

export workspace="$HOME/Documents/workspace"
export LS_OPTIONS=‘–color=auto’
d=~/.dir_colors
test -r $d && eval "$(dircolors $d)"

if [ -f /usr/share/bash-completion/bash_completion ]; then
	. /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi


wait
end=`date +%s.%N`

runtime=$(echo "$end - $start"|bc -l)
1>&2 echo "$runtime seconds"
