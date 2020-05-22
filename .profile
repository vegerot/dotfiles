
# include Mycroft commands
#source ~/.profile_mycroft

. /usr/share/autojump/autojump.sh

if test -t 0 -a -t 1 && command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
        tmux new-session -t default \; new-window\; set-option destroy-unattached on|| tmux new -s default
fi
