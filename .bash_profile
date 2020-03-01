start=`gdate +%s.%N`
set -o vi
source ~/.profile
. ~/.git-prompt.sh
PROMPT_COMMAND=__prompt_command
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWCOLORHINTS=true
__prompt_command()
{

    local EXIT="$?"
    PROMPT_DIRTRIM=$((1+$(($(tput cols)/12))))
    PS1=$(check_conda_env)
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

check_conda_env ()
{
    if [ ! -z "$CONDA_DEFAULT_ENV" ]; then
        printf -- "%s" "\[\e[0;39m\][`basename $CONDA_DEFAULT_ENV`]\[\e[0m\] "
    else
        printf -- "%s" ""
    fi
}

mkcdir () {
    mkdir -p -- "$1" && cd -P -- "$1"
}
#if brew command command-not-found-init > /dev/null 2>&1; then eval "$(brew command-not-found-init)"; fi

#eval "$(brew command-not-found-init)"
#export PS1

#export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\n\$ "
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

source ~/.aliases
~/bin/cowCommand.sh&

alias ?='. ~/bin/cowCommand.sh'
#alias ls='ls -FGh'
alias ccat='pygmentize -g -O style=colorful'
alias ls='ls --color=auto -FGh'

#. ~/bin/autoAlias.sh
#shopt -s cdable_vars
export iCloud=$HOME/Library/Mobile\ Documents/com\~apple\~CloudDocs/
#[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
. /usr/local/etc/bash_completion.d/*
. "/usr/local/etc/profile.d/bash_completion.sh"
source ~/.paths.sh
#export PYTHONPATH='$HOME/Library/Python/3.7/bin'
#export PATH="$PATH:$HOME/Library/Python/3.7/bin/"
# added by Anaconda3 installer
#export PATH="/usr/local/opt/coreutils/libexec/gnubin:/usr/local/opt/lsof/bin:$PATH:/Users/maxcoplan/bin:/usr/local/sbin:/Users/maxcoplan/anaconda3/bin"
eval "$(register-python-argcomplete conda)"

export workspace="$HOME/Documents/workspace"
export LS_OPTIONS=‘–color=auto’
d=~/.dir_colors
test -r $d && eval "$(dircolors $d)"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
#__conda_setup="$('/Users/maxcoplan/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
#if [ $? -eq 0 ]; then
#    eval "$__conda_setup"
#else
if [ -f "/usr/local/anaconda3/etc/profile.d/conda.sh" ]; then
    . "/usr/local/anaconda3/etc/profile.d/conda.sh" 
else
    export PATH="/usr/local/anaconda3/bin:$PATH"
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/maxcoplan/.sdkman"
[[ -s "/Users/maxcoplan/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/maxcoplan/.sdkman/bin/sdkman-init.sh"
#fi
#unset __conda_setup
# <<< conda initialize <<<

source "${HOME}/.iterm2_shell_integration.bash"
end=`gdate +%s.%N`

runtime=$(echo "$end - $start"|bc -l)
echo "$runtime seconds"
