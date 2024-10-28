#!/usr/bin/env bash

if [[ -e ~/bin/remapCapslock ]]; then
	~/bin/remapCapslock
elif type xmodmap &>/dev/null && type xcape &>/dev/null && type setxkbmap &>/dev/null; then
	xmodmap -e 'clear Lock'
	xmodmap -e 'keycode 0x42 = Control_L'
	xmodmap -e 'keycode 169 = Delete'
	setxkbmap -option ctrl:nocaps
	xcape -e 'Control_L=Escape'
fi

[[ -e ~/.Xresources ]] && xrdb -merge ~/.Xresources

[[ -e /etc/X11/xinit/xinitrc ]] && source /etc/X11/xinit/xinitrc

if type xterm &>/dev/null; then
	xterm  #-geometry  +1+1  -n  login  -display  :0
fi
