# Compute how long startup takes.
# Only GNU date supports milliseconds, and also only GNU date has `--help`
if type gdate > /dev/null; then
	start=$(gdate +%s.%N)
elif $(date --help &> /dev/null); then
	start=`date +%s.%N`
else
	start=$(python3 -c "import time; print(time.time())")
fi

# remove duplicates from PATH
typeset -aU path
typeset -U PATH

if command -v cmd.exe &>/dev/null; then
	local isWSL=true
else
	local isWSL=false
fi

if [[ -n "$XDG_CURRENT_SESSION" ]]; then
	local has_gnulinux_window_manager=true
else
	local has_gnulinux_window_manager=false
fi

[[ -r ~/.profile ]] && source ~/.profile

if [[ $OSTYPE == "darwin"* || $isWSL == true ]]; then
	echo async
	~/dotfiles/bin/randomcowcommand --async
else
	~/dotfiles/bin/randomcowcommand
fi;

if [[ $TERM_PROGRAM != "WarpTerminal" \
	&& -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"\
	]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# for some reason "\n" doesn't work in $PS1??
NEWLINE='
'
export PS1="${NEWLINE}%m%#${NEWLINE}$ "

# HISTORY
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=1073741823000
SAVEHIST=$HISTSIZE
HIST_EXPIRE_DUPS_FIRST=1
export HISTSIZE
export SAVEHIST

setopt EXTENDED_HISTORY
setopt incappendhistorytime

unsetopt histignorespace

export HELPDIR=/usr/share/zsh/$ZSH_VERSION/help
unalias run-help 2>/dev/null # sometimes this alias is set and sometimes it isn't
autoload -U run-help
alias help=run-help

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

# User configuration

# set up keymap stuff here because it's not working other places
keymaps() {
	if [[ -z $DISPLAY && -z $ALWAYS_SET_CAPS ]]; then
		return
	fi
	local is_caps_already_mapped=$(xmodmap -pke | rg --count-matches "keycode\s+66\s*=\s*Control_L")
	if [[ $is_caps_already_mapped -gt 0 && -z $ALWAYS_SET_CAPS ]]; then
		return
	fi
	echo $is_caps_already_mapped
	echo "Caps is not mapped to Control_L, mapping it now"
	echo "caps is currently mapped to: $(xmodmap -pke | rg "keycode\s+66\s*= ")"
	xmodmap ~/.Xmodmap
	xcape
	setxkbmap -option ctrl:nocaps
	xcape -e 'Control_L=Escape'
}

[[ $OSTYPE == "linux-gnu"* && $has_gnulinux_window_manager == true ]] && ! $isWSL && keymaps

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

# use # for comments in interactive mode
setopt interactivecomments

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
  ## POWERLEVEL10K
  if [[ $TERM_PROGRAM == "WarpTerminal" ]]; then
	  return
  fi
  local powerlevel10k_library_path="$HOME/workspace/github.com/romkatv/powerlevel10k/powerlevel10k.zsh-theme"
  local powerlevel10k_prompt_path="$HOME/.p10k.zsh"
  if [[ -r $powerlevel10k_library_path && -r $powerlevel10k_prompt_path ]]; then
	  source $powerlevel10k_library_path

	  ## To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
	  source $powerlevel10k_prompt_path
  fi

  local sapling_prompt_path="$HOME/workspace/github.com/facebook/sapling/eden/scm/contrib/scm-prompt.sh"
  if [[ -r $sapling_prompt_path ]]; then
	  source $sapling_prompt_path
  fi

  local zsh_syntax_highlighting_path="$HOME/workspace/github.com/zdharma-continuum/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
  if [[ -r $zsh_syntax_highlighting_path ]]; then
	  source $zsh_syntax_highlighting_path
  fi

  local zsh_autosuggestions_path="$HOME/workspace/github.com/zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh"
  if [[ -r $zsh_autosuggestions_path ]]; then
	  source $zsh_autosuggestions_path
  fi

  local zsh_history_substring_search_path="$HOME/workspace/github.com/zsh-users/zsh-history-substring-search/zsh-history-substring-search.zsh"
  if [[ -r $zsh_history_substring_search_path ]]; then
	  source $zsh_history_substring_search_path
	  ## Bind j and k for history-substring-search in normal mode
	  bindkey -M vicmd 'k' history-substring-search-up
	  bindkey -M vicmd 'j' history-substring-search-down
	  ## Bind ⬆️ and ⬇️ for history-substring-search in insert mode
	  bindkey '^[[A' history-substring-search-up
	  bindkey '^[[B' history-substring-search-down
	  bindkey "$terminfo[kcuu1]" history-substring-search-up
	  bindkey "$terminfo[kcud1]" history-substring-search-down
  fi

  if type jump > /dev/null; then
	  eval "$(jump shell zsh)"
  fi

  if type fzf > /dev/null; then
	  ## read by fzf program (see man fzf)
	  export FZF_DEFAULT_OPTS='--height=70% '
	  export FZF_DEFAULT_COMMAND='fd --no-require-git 2>/dev/null || git ls-tree -r --name-only HEAD'

	  # read by fzf/shell/key-bindings.zsh
	  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
	  export FZF_PREVIEW_OPTS='--preview "bat --color always {} 2>/dev/null || cat {}" --preview-window=right:60%:wrap'
	  export FZF_CTRL_T_OPTS=$FZF_PREVIEW_OPTS

	  source <(fzf --zsh)

	  ## from fzf.zsh plugin
	  bindkey '^p' fzf-file-widget
  fi

}
if [[ -z $ZSH_SKIP_LOADING_PLUGINS ]]; then
	load_plugins
fi

# j makes jumping to directories easier
# if j isn't installed, then do the poverty method of adding common directories
# to CDPATH
if ! type j > /dev/null; then
	export CDPATH="$CDPATH:$HOME/gecgithub01.walmart.com/m0c0j7y/:$HOME/gecgithub01.walmart.com/walmart-web/walmart-web-worktree/"
fi

## always source max_scripts_source_on_cd.sh in any directory I'm in when I cd

source_max_scripts() {
	find-up() {
	local current_path
	current_path=$(pwd)
	while [[ -n $current_path ]]; do
		if [[ -e $current_path/$1 ]]; then
			echo $current_path/$1
			return
		fi
		current_path=${current_path%/*}
	done
}
# search the directory tree upwards for max_scripts_source_on_cd.sh
local script_name="max_scripts_source_on_cd.sh"
local max_scripts
max_scripts=$(find-up $script_name)
if [[ -n $max_scripts ]]; then
	source $max_scripts
fi
}

chpwd_functions+=(source_max_scripts)
source_max_scripts

# Compute time taken
if type gdate > /dev/null; then
end=$(gdate +%s.%N)
elif $(date --help &> /dev/null); then
end=`date +%s.%N`
else
end=$(python3 -c "import time; print(time.time())")
fi
runtime=$( echo "$end - $start" | bc -l )

startuptime=$(printf '%.2f seconds\n' $runtime)
if type rainbow > /dev/null; then
	printf "$startuptime\n" | rainbow
else
	printf "$startuptime\n"
fi

