#!/usr/bin/env zsh
for file in *; do
    cat <(echo "auth\tsufficient\tpam_tid.so\n") $file >> /tmp/$file.$$
    mv /tmp/$file.$$ $file
done
