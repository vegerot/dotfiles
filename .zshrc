# Compute how long startup takes.
# Only GNU date supports milliseconds, and also only GNU date has `--help`
if type gdate > /dev/null; then
  start=$(gdate +%s.%N)
elif $(date --help &> /dev/null); then
  start=`date +%s.%N`
else
  start=$(python3 -c "import time; print(time.time())")
fi

source ~/.profile
if [[ $TERM_PROGRAM != "WarpTerminal" \
  && -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"\
  ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
~/dotfiles/bin/randomcowcommand&

export CDPATH="$CDPATH:$HOME/gecgithub01.walmart.com/m0c0j7y/:$HOME/gecgithub01.walmart.com/walmart-web/walmart-web-worktree/"

# for some reason "\n" doesn't work in $PS1??
NEWLINE="
"
export PS1="${NEWLINE}$PS1${NEWLINE}$ "

# HISTORY
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
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

# COMMAND LINE EDITING
setopt vi
bindkey -v '^?' backward-delete-char
## edit the current line in vim with `C-x C-e` like in bash
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line
## 10ms for key sequences.  Makes going to normal mode fast
KEYTIMEOUT=1
bindkey -M vicmd "" edit-command-line

bindkey "^R" history-incremental-search-backward

## change cursor shape in vi mode
zle-keymap-select () {
    if [[ $KEYMAP == vicmd ]]; then
        # the command mode for vi
        echo -ne "\e[2 q"
    else
        # the insert mode for vi
        echo -ne "\e[5 q"
    fi
}
precmd_functions+=(zle-keymap-select)
zle -N zle-keymap-select

setopt correct
COMPLETION_WAITING_DOTS="true"

## give case-insensitive filepath completions
## credit: https://stackoverflow.com/a/24237590/6100005
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

## Only check compinit once a day
## credit: https://medium.com/@dannysmith/little-thing-2-speeding-up-zsh-f1860390f92
autoload -Uz compinit
for dump in ~/.zcompdump(N.mh+24); do
  compinit
done
compinit -C

# PLUGINS
load_plugins() {
  eval "$(jump shell zsh)"
  source ~/workspace/github.com/ohmyzsh/ohmyzsh/plugins/colored-man-pages/colored-man-pages.plugin.zsh

  ## POWERLEVEL10K
  if [[ $TERM_PROGRAM == "WarpTerminal" ]]; then
	  return
  fi
  source ~/workspace/github.com/romkatv/powerlevel10k/powerlevel10k.zsh-theme
  source ~/workspace/github.com/facebook/sapling/eden/scm/contrib/scm-prompt.sh
  ## To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

  source ~/workspace/github.com/zdharma-continuum/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
  source ~/workspace/github.com/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh
  source ~/workspace/github.com/zsh-users/zsh-history-substring-search/zsh-history-substring-search.zsh
  ## Bind j and k for history-substring-search in normal mode
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
  ## Bind ⬆️ and ⬇️ for history-substring-search in insert mode
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down

  # FZF
  ## read by fzf program (see man fzf)
  export FZF_DEFAULT_OPTS='--height=70% '
  export FZF_DEFAULT_COMMAND='fd --no-require-git || git ls-tree -r --name-only HEAD'

  # read by fzf/shell/key-bindings.zsh
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_PREVIEW_OPTS='--preview "bat --color always {} || cat {}" --preview-window=right:60%:wrap'
  export FZF_CTRL_T_OPTS=$FZF_PREVIEW_OPTS

  source "$FZF_BASE/shell/key-bindings.zsh"
  source "$FZF_BASE/shell/completion.zsh"

  source "$HOME/.fzf-extras/fzf-extras.zsh"

  ## from fzf.zsh plugin
  bindkey '^p' fzf-file-widget
  # FZF end

}
if [[ -z $ZSH_SKIP_LOADING_PLUGINS ]]; then
  load_plugins
fi

# Compute time taken
if type gdate > /dev/null; then
  end=$(gdate +%s.%N)
elif $(date --help &> /dev/null); then
  end=`date +%s.%N`
else
  end=$(python3 -c "import time; print(time.time())")
fi
runtime=$( echo "$end - $start" | bc -l )
printf "%.2f seconds\n" $runtime
