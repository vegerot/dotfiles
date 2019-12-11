#!/usr/bin/env zsh
ZSHRC="$HOME/"bin/zshrc
if test -f "$ZSHRC"; then
    source $ZSHRC
else
    source /etc/skel/.bash_profile
fi

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

