#!/usr/bin/env bash
for path in /etc/pam.d/*; do
        file=$(basename "$path")
        sudo bash -c "cat <(echo 'auth       sufficient     pam_tid.so') /etc/pam.d/$file>/tmp/$file&&cp /tmp/$file /etc/pam.d/$file"
done

