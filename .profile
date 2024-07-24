
# include Mycroft commands
#source ~/.profile_mycroft

export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

#if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
#       tmux new-session -t default \; new-window || tmux new -s default -u
#fi
[ -r ~/.env ] && . ~/.env
[ -r ~/.sh_functions ] && . ~/.sh_functions
[ -r ~/.aliases ] && . ~/.aliases

#eval "$( /usr/local/opt/coreutils/libexec/gnubin/dircolors ~/.dir_colors)"
