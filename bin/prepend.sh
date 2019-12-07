#!/bin/sh
for file in *; do
    cat /Users/${whoami}/pam.d_backup/author $file >> $file.$$
    mv $file.$$ $file
done
