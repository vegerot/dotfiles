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

if [[ -n "$XDG_CURRENT_SESSION" || -n "$XDG_CURRENT_DESKTOP" ]]; then
	local has_gnulinux_window_manager=true
else
	local has_gnulinux_window_manager=false
fi

[[ -r ~/.profile ]] && source ~/.profile

if [[ -z $ZSH_SKIP_LOADING_PLUGINS && $OSTYPE == "darwin"* || $isWSL == true ]]; then
	~/dotfiles/bin/randomcowcommand --async
elif [[ -z $ZSH_SKIP_LOADING_PLUGINS ]]; then
	~/dotfiles/bin/randomcowcommand
fi;

if [[ $TERM_PROGRAM != "WarpTerminal" \
	&& -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"\
	&& -z $ZSH_SKIP_LOADING_PLUGINS \
	]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
else
	if [[ -f ~/workspace/github.com/facebook/sapling/eden/scm/contrib/scm-prompt.sh ]]; then
		source ~/workspace/github.com/facebook/sapling/eden/scm/contrib/scm-prompt.sh
	fi
	maybe_scm_prompt() {
		if type _scm_prompt >/dev/null 2>&1; then
			_scm_prompt
		fi
	}
	function prompt_precmd() {
		NEWLINE=$'\n'
		local EXIT=$?
		PROMPT_DIRTRIM=3

		BOLD_START="%B"
		BOLD_END="%b"

		RED_START='%F{red}'
		GREEN_START='%F{green}'
		LIGHT_GREEN_START='%F{green}'
		BLUE_START='%F{blue}'
		MAGENTA_START='%F{magenta}'

		COLOR_RESET='%f'

		PROMPT_LAST_STATUS="$([ $EXIT != 0 ] && echo ❌${RED_START}\($EXIT\)%f || printf '')"
		PROMPT_WHOAMI="🪪${GREEN_START}%n${COLOR_RESET}💻${LIGHT_GREEN_START}%m${COLOR_RESET}"
		PROMPT_WHEREAMI="📁${BLUE_START}%${PROMPT_DIRTRIM}~/${COLOR_RESET}"
		PROMPT_JUST_BRANCH="$(git branch --show-current >/dev/null 2>&1 && printf "🌿$(git branch --show-current) "|| printf "")"
		PROMPT_SAPLING="$(maybe_scm_prompt)"
		PROMPT_BRANCH="${MAGENTA_START}${PROMPT_JUST_BRANCH}${PROMPT_SAPLING}${COLOR_RESET}"
		PROMPT_START='$ '
		PROMPT="${NEWLINE}${BOLD_START}${PROMPT_LAST_STATUS}${PROMPT_WHOAMI}: ${PROMPT_WHEREAMI}${BOLD_END} ${PROMPT_BRANCH}${NEWLINE}${PROMPT_START}"
	}

	precmd_functions+=(prompt_precmd)

fi


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

# set up keymap stuff here because it's not working other places

[[ $OSTYPE == "linux-gnu"* && $has_gnulinux_window_manager == true ]] && ! $isWSL && $HOME/bin/remapCapslock

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
typeset -A plugin_paths=(
	[powerlevel10k]="$HOME/workspace/github.com/romkatv/powerlevel10k"
	[sapling]="$HOME/workspace/github.com/facebook/sapling"
	[zsh-syntax-highlighting]="$HOME/workspace/github.com/zdharma-continuum/fast-syntax-highlighting"
	[zsh-autosuggestions]="$HOME/workspace/github.com/zsh-users/zsh-autosuggestions"
	[zsh-history-substring-search]="$HOME/workspace/github.com/zsh-users/zsh-history-substring-search"
	[zig-shell-complete]="$HOME/workspace/github.com/ziglang/shell-completions"
)
load_plugins() {
  # install from https://github.com/gsamokovarov/jump
  if type jump > /dev/null; then
	  eval "$(jump shell)"
  fi

  if [[ $TERM_PROGRAM == "WarpTerminal" ]]; then
	  return
  fi

  ## POWERLEVEL10K
  local powerlevel10k_library_path=${plugin_paths[powerlevel10k]}/powerlevel10k.zsh-theme
  local powerlevel10k_prompt_path="$HOME/.p10k.zsh"
  if [[ -r $powerlevel10k_library_path && -r $powerlevel10k_prompt_path ]]; then
	  source $powerlevel10k_library_path

	  ## To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
	  source $powerlevel10k_prompt_path
  fi

  local sapling_prompt_path=${plugin_paths[sapling]}/eden/scm/contrib/scm-prompt.sh
  if [[ -r $sapling_prompt_path ]]; then
	  source $sapling_prompt_path
  fi

  local zsh_syntax_highlighting_path=${plugin_paths[zsh-syntax-highlighting]}/fast-syntax-highlighting.plugin.zsh
  if [[ -r $zsh_syntax_highlighting_path ]]; then
	  source $zsh_syntax_highlighting_path
  fi

  local zsh_autosuggestions_path=${plugin_paths[zsh-autosuggestions]}/zsh-autosuggestions.zsh
  if [[ -r $zsh_autosuggestions_path ]]; then
	  source $zsh_autosuggestions_path
  fi

  local zsh_history_substring_search_path=${plugin_paths[zsh-history-substring-search]}/zsh-history-substring-search.zsh
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

  local zig_shell_complete_path=${plugin_paths[zig-shell-complete]}/zig-shell-completions.plugin.zsh
  if [[ -r $zig_shell_complete_path ]]; then
	  source $zig_shell_complete_path
  fi

  if type gh > /dev/null; then
	source <(TCELL_MINIMIZE=1 gh completion -s zsh)
  fi

  if type fd > /dev/null; then
	  source <(fd --gen-completions)
  fi

  if type rg > /dev/null; then
	  source <(rg --generate=complete-zsh)
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

update_plugins() {
	# TODO: install plugins if not installed
	function pull_and_update() {
		set -o errexit
		set -o nounset
		set -o pipefail
		dir=$1
		if [[ -d "$dir/.git" ]]; then
			(cd "$dir" && git pull)
		elif [[ -d "$dir/.sl" ]]; then
			(cd "$dir" && sl pull && sl top --newest)
		fi
	}
	ZSH_SKIP_LOADING_PLUGINS=1 parallel zsh -c "$(declare -f pull_and_update) && pull_and_update {}" ::: "${plugin_paths[@]}"
}

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
	echo "Sourcing $max_scripts"
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

