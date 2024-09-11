#!/usr/bin/env bash

if type xmodmap &>/dev/null && [[ -f ~/.Xmodmap ]] && type xcape &>/dev/null &&
	type setxkbmap &>/dev/null && type xrdb &>/dev/null &&
	[[ -f ~/.Xresources ]] && [[ -f /etc/X11/xinit/xinitrc ]]; then
	xmodmap ~/.Xmodmap
	xcape
	setxkbmap -option ctrl:nocaps
	xcape -e 'Control_L=Escape'
	xrdb -merge ~/.Xresources
	. /etc/X11/xinit/xinitrc
fi

if type xterm &>/dev/null; then
	xterm  #-geometry  +1+1  -n  login  -display  :0
fi
