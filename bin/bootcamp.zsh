#!/bin/zsh
# tell macOS to change the boot disk
# nextonly just for the next time — without the default would be Windows

/usr/sbin/bless -mount /Volumes/BOOTCAMP --setBoot --nextonly &&\
# reboot
/sbin/shutdown -r now
