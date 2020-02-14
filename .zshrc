start=`gdate +%s.%N`
zmodload zsh/zprof
## If you come from bash you might have to change your $PATH.
##Open Tmux
source ~/.profile
#~/bin/cowCommand.sh
source ~/.paths.sh
#
## Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
#
## ZSH_THEME="MaxCoplanTheme"
ZSH_THEME="powerlevel10k/powerlevel10k"
#
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
#
fpath=(/usr/local/share/zsh-completions /usr/local/share/zsh-completions/conda-zsh-completion $fpath)
setopt LOCAL_OPTIONS NO_NOTIFY 
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit
autoload -U promptinit && promptinit       
autoload -Uz run-help                      
autoload -Uz run-help-git                  
autoload -Uz run-help-svn                  
autoload -Uz run-help-svk                  
wait
unalias run-help
alias help=run-help
#
##source /usr/local/share/zsh-completions/helpers
##. "/usr/local/etc/profile.d/bash_completion.sh"
#
#if brew command command-not-found-init > /dev/null; then
#  eval "$(brew command-not-found-init)"
#fi
plugins=(
  git
  osx
  colored-man-pages
  colorize
  pip
  python
  brew
  vi-mode  
  zsh-syntax-highlighting
  history-substring-search
  docker
  docker-compose
  docker-machine
  fzf
  zsh-better-npm-completion 
) 
source $ZSH/oh-my-zsh.sh
setopt vi
autoload -U edit-command-line
zle -N edit-command-line
## 10ms for key sequences
#KEYTIMEOUT=1
bindkey -M vicmd "" edit-command-line
#
precmd_functions+=(zle-keymap-select)
#
zle-keymap-select () {
    if [[ $KEYMAP == vicmd ]]; then
        # the command mode for vi
        echo -ne "\e[2 q"
    else
        # the insert mode for vi
        echo -ne "\e[5 q"
    fi
}
#
if [[ $'\e\x5b3D' == "$(echoti cub 3)" ]] &&
   [[ $'\e\x5b33m' == "$(echoti setaf 3)" ]]; then
  zstyle -e ':completion:*' list-colors $'reply=( "=(#b)(${(b)PREFIX})(?)([^ ]#)*=0=0=${PREFIX:+${#PREFIX}D${(l:$#PREFIX:: :):-…}\e\x5b}35=33" )'
fi
zstyle ':completion:*:*(directories|files)*' list-colors ''

export export HISTSIZE=1073741823
export SAVEHIST=$HISTSIZE
setopt EXTENDED_HISTORY
#
export FZF_DEFAULT_OPTS='--height=70% --preview "bat --color always {} || cat {}" --preview-window=right:60%:wrap'
export FZF_DEFAULT_COMMAND='git ls-tree -r --name-only HEAD || rg --files 2>/dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

source "$HOME/.fzf-extras/fzf-extras.zsh"
source "$HOME/.fzf-extras/fzf-extras.sh"
. /usr/local/etc/profile.d/autojump.sh

#
mkcdir ()
{
	mkdir -p -- "$1" &&
		cd -P -- "$1"
}
#
##Aliases
source ~/.aliases
source ~/.functions
alias pman='man-preview'
alias ls="gls --group-directories-first --color=tty -XhF"
#
##ZSH-SYTAX-HIGHLIGHTING
ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=white
#
zstyle ':completion:*:*:vim:*' file-patterns '^*.class:source-files' '*:all-files'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

local return_code="%(?..%{$fg_bold[red]%}%? ↵%{$reset_color%})"
RPS1="${return_code}"

source ~/.iterm2_shell_integration.zsh
#
#eval "$(jenv init -)"
#
## >>> conda initialize >>>
        . "/usr/local/anaconda3/etc/profile.d/conda.sh"
#
## To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

end=`gdate +%s.%N`
runtime=$( echo "$end - $start"|bc -l )
echo "$runtime seconds"
