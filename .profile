
# include Mycroft commands
#source ~/.profile_mycroft

if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
        tmux new-session -t default \; new-window\; set-option destroy-unattached on|| tmux new -s default
fi
