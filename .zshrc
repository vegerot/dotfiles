# Compute how long startup takes
start=`gdate +%s.%N`

#start Tmux, maybe
source ~/.profile

# Command line editing
setopt vi
autoload -U edit-command-line
zle -N edit-command-line
## 10ms for key sequences
KEYTIMEOUT=1
bindkey -M vicmd "" edit-command-line


# History
HISTSIZE=1073741823000
SAVEHIST=$HISTSIZE
HIST_EXPIRE_DUPS_FIRST=1
export HISTSIZE
export SAVEHIST
export HIST_EXPIRE_DUPS_FIRST

setopt EXTENDED_HISTORY
setopt histexpiredupsfirst
setopt incappendhistorytime

unsetopt histignorespace



## OMZ bs
# Path to your oh-my-zsh installation.
export ZSH="/Users/m0c0j7y/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
COMPLETION_WAITING_DOTS="true"

plugins=(
	git
	vi-mode
	zsh-syntax-highlighting
	zsh-autosuggestions
	history-substring-search
	npm
	zsh-better-npm-completion
)




source $ZSH/oh-my-zsh.sh

# User configuration


eval "$(jump shell)"

source ~/.env
source ~/.aliases
source ~/.sh_functions

# change cursor shape in vi mode
precmd_functions+=(zle-keymap-select)

zle-keymap-select () {
    if [[ $KEYMAP == vicmd ]]; then
        # the command mode for vi
        echo -ne "\e[2 q"
    else
        # the insert mode for vi
        echo -ne "\e[5 q"
    fi
}

# Bind j and k for history-substring-search in vim mode
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down


test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Compute time taken
end=`gdate +%s.%N`
runtime=$( echo "$end - $start"|bc -l )
echo "$runtime seconds"




