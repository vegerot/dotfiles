#!/bin/bash

xmodmap ~/.Xmodmap
xcape
setxkbmap -option ctrl:nocaps
xcape -e 'Control_L=Escape'
xrdb -merge ~/.Xresources
