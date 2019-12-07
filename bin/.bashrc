#!/usr/bin/env bash
BASHRC="$HOME"/bin/bashrc
if test -f "$BASHRC"; then
    source $BASHRC
else
    source /etc/skel/.bashrc
fi
