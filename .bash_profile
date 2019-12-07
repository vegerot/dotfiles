#!/usr/bin/env bash
BASHPROFILE="$HOME"/bin/bash_profile
if test -f "$BASHPROFILE"; then
    source $BASHPROFILE
else
    source /etc/skel/.bash_profile
fi
