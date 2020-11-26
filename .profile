
# include Mycroft commands
#source ~/.profile_mycroft

export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
       tmux new-session -t default \; new-window || tmux new -s default
fi
eval "$( /usr/local/opt/coreutils/libexec/gnubin/dircolors ~/.dir_colors)"
