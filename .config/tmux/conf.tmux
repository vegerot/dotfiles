#!/usr/bin/env bash
set -e

DIRECTORY_NAME='#(basename #{pane_current_path})'

#COMMAND_NAME="#(ps -t #{pane_tty} -o command,pgid= | rg #{pane_pid} | tail -n1 | awk '{print $1}')"


# requires my tmux patch
COMMAND_NAME="ps -p #{pane_current_command_pid} -o command="
ABBREVIATED_COMMAND_NAME="#(source ~/.config/tmux/tmux_utils.sh ; get_cmd_and_abbreviate_it \"$COMMAND_NAME\")"
#ABBREVIATED_COMMAND_NAME="#(sh -c \"abbreviate_path $COMMAND_NAME\")"

PANE_NAME_END_PART='#{?window_flags,#{window_flags}, }'


tmux set -g window-status-current-format "👉#I:$ABBREVIATED_COMMAND_NAME"
tmux set -g window-status-format "#I:$ABBREVIATED_COMMAND_NAME"



# TODO:
# - if the command is `zsh`, hide it
# - abbreviate directory name like "foo/bar/baz/" -> "f/b/baz"
# - detect file names in command arguments and abbreviate them like "nvim foo/bar/baz.txt" -> "nvim f/b/baz.txt"
