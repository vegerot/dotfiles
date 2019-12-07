start=`gdate +%s.%N`

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
source ~/.paths.sh

# Path to your oh-my-zsh installation.
export ZSH="/Users/maxcoplan/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="MaxCoplanTheme"
ZSH_THEME="powerlevel10k/powerlevel10k"
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder
fpath=(/usr/local/share/zsh-completions /usr/local/share/zsh-completions/conda-zsh-completion $fpath)
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit
autoload -U promptinit && promptinit
autoload -Uz run-help
autoload -Uz run-help-git
autoload -Uz run-help-svn
autoload -Uz run-help-svk
unalias run-help
alias help=run-help
#rm -f ~/.zcompdump; compinit
source /usr/local/share/zsh-completions/helpers
. "/usr/local/etc/profile.d/bash_completion.sh"

#if brew command command-not-found-init > /dev/null 2>&1; then eval "$(brew command-not-found-init)"; fi
eval "$(brew command-not-found-init)"
# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  #osx
  colored-man-pages
  colorize
  pip
  python
  brew
  vi-mode  
  zsh-syntax-highlighting
  history-substring-search
  #zsh-autosuggestions
  cd-gitroot
  #zsh-apple-touchbar
) 
source $ZSH/oh-my-zsh.sh
setopt vi
autoload -U edit-command-line
zle -N edit-command-line
# 10ms for key sequences
KEYTIMEOUT=1
bindkey -M vicmd "" edit-command-line

precmd_functions+=(zle-keymap-select)
#echo -ne "\e[5 q"
zle-keymap-select () {
    if [[ $KEYMAP == vicmd ]]; then
        # the command mode for vi
        echo -ne "\e[2 q"
    else
        # the insert mode for vi
        echo -ne "\e[5 q"
    fi
}

if [[ $'\e\x5b3D' == "$(echoti cub 3)" ]] &&
   [[ $'\e\x5b33m' == "$(echoti setaf 3)" ]]; then
  zstyle -e ':completion:*' list-colors $'reply=( "=(#b)(${(b)PREFIX})(?)([^ ]#)*=0=0=${PREFIX:+${#PREFIX}D${(l:$#PREFIX:: :):-…}\e\x5b}35=33" )'
fi
zstyle ':completion:*:*(directories|files)*' list-colors ''



#export PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH:/Users/maxcoplan/bin:/Users/maxcoplan/anaconda3/bin"
#export PATH="/usr/local/opt/coreutils/libexec/gnubin:/usr/local/opt/lsof/bin:$PATH:/usr/local/opt:/opt:/Users/maxcoplan/bin:/Users/maxcoplan/anaconda3/bin:/usr/local/sbin"
# added by Anaconda3 installer
#export PATH="$PATH:/Users/maxcoplan/bin:/Users/maxcoplan/anaconda3/bin"
#export PATH="$PATH:/Users/maxcoplan/Library/Python/3.7/bin:/usr/local/lib/python3.7/site-packages"

export FZF_DEFAULT_OPTS='--height=70% --preview "bat --color always {} || cat {}" --preview-window=right:60%:wrap'
#export FZF_DEFAULT_OPTS='--height=70% --preview "~/.vim/bundle/fzf.vim/bin/preview.rb {}" --color --preview-window=right:60%:wrap'
export FZF_DEFAULT_COMMAND='git ls-tree -r --name-only HEAD || rg --files 2>/dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
source "$HOME/.fzf-extras/fzf-extras.zsh"
source "$HOME/.fzf-extras/fzf-extras.sh"


mkcdir ()
{
	mkdir -p -- "$1" &&
		cd -P -- "$1"
}
#zstyle ':completion::complete:*' use-cache 1

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
source .aliases
#alias ls="colorls --sort-dirs"
alias pman='man-preview'
alias cdg="cd-gitroot"
alias ls="gls --group-directories-first --color=tty -XhF"

#ZSH-SYTAX-HIGHLIGHTING
ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=white

zstyle ':completion:*:*:vim:*' file-patterns '^*.class:source-files' '*:all-files'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
#eval "$(rbenv init -)"
#source $(dirname $(gem which colorls))/tab_complete.sh

#prompt pure

local return_code="%(?..%{$fg_bold[red]%}%? ↵%{$reset_color%})"
RPS1="${return_code}"

#source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
#echo "$(gdate +%s.%N) - $start"|bc -l
source ~/.iterm2_shell_integration.zsh
cowCommand


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
#__conda_setup="$('/Users/maxcoplan/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
#if [ $? -eq 0 ]; then
#    eval "$__conda_setup"
#else
    if [ -f "/Users/maxcoplan/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/maxcoplan/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/maxcoplan/anaconda3/bin:$PATH"
    fi
#fi
#unset __conda_setup
# <<< conda initialize <<<

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

end=`gdate +%s.%N`
runtime=$( echo "$end - $start"|bc -l )
#runtime=$(echo "$end - $start"|bc -l)
echo "$runtime seconds"
