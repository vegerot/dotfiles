#!/usr/bin/env bash
BASHPROFILE="$HOME"/bin/bash_profile
if test -f "$BASHPROFILE"; then
    source $BASHPROFILE
else
    source /etc/skel/.bash_profile
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/matt/.sdkman"
[[ -s "/Users/matt/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/matt/.sdkman/bin/sdkman-init.sh"
