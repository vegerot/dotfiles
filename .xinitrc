#!/usr/bin/env bash

if [[ -f ~/bin/.mapCapslock ]]; then
	~/bin/.mapCapslock
elif type xmodmap &>/dev/null && type xcape &>/dev/null &&
	type setxkbmap &>/dev/null && type xrdb &>/dev/null &&
	[[ -f ~/.Xresources ]] && [[ -f /etc/X11/xinit/xinitrc ]]; then
	xmodmap -e 'clear Lock; keycode 0x42 = Control_L; keycode 169 = Delete'
	setxkbmap -option ctrl:nocaps
	xcape -e 'Control_L=Escape'
	xrdb -merge ~/.Xresources
	. /etc/X11/xinit/xinitrc
fi

if type xterm &>/dev/null; then
	xterm  #-geometry  +1+1  -n  login  -display  :0
fi
