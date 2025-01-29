# include Mycroft commands
#source ~/.profile_mycroft


#if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
#       tmux new-session -t default \; new-window || tmux new -s default -u
#fi
[[ -r ~/.env ]] && . ~/.env
[[ -r ~/.sh_functions ]] && . ~/.sh_functions
[ -r ~/.aliases ] && . ~/.aliases

export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

if type dircolors > /dev/null 2>&1; then
	eval "$(dircolors ~/.dir_colors)"
fi

