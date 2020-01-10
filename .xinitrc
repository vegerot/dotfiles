#!/bin/bash
# Taken from:
#	https://raw.github.com/kaihendry/Kai-s--HOME/master/.xinitrc
#
# for terminus font in Archlinux :(
#xset +fp /usr/share/fonts/local
#xset fp rehash

#xset -b # disable bell
#eval `/usr/bin/ssh-agent`





doDWM()
{
    while true
    do
        VOL=$(amixer get Master | tail -1 | sed 's/.*\[\([0-9]*%\)\].*/\1/')
        LOCALTIME=$(date +%Z\=%Y-%m-%dT%H:%M)
        #	OTHERTIME=$(TZ=Europe/London date +%Z\=%H:%M)
        UPTIME=$(uptime | awk -F'( |,|:)+' '{d=h=m=0; if ($7=="min") m=$6; else {if ($7~/^day/) {d=$6;h=$8;m=$9} else {h=$6;m=$7}}} {print d+0":"h+0":"m+0""}')
        IP=$(for i in `ip r`; do echo $i; done | grep -A 1 src | tail -n1) # can get confused if you use vmware
        TEMP="$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))C"

        if acpi -a | grep off-line > /dev/null
        then
            BAT="Bat. $(acpi -b | awk '{ print $4 " " $5 }' | tr -d ',')"
            xsetroot -name "$IP $BAT $VOL $TEMP $LOCALTIME $UPTIME"
        else
            xsetroot -name "$IP $VOL $TEMP $LOCALTIME $UPTIME"
            fi
            sleep 20s
    done &

    feh --bg-scale /home/pi/Pictures/macOS-Sierra-Wallpaper-Macbook-Wallpaper.jpg
    exec dwm
}

xrandr --output HDMI-1 --mode 1920x1080
xmodmap ~/.Xmodmap
xcape
setxkbmap -option ctrl:nocaps
xcape -e 'Control_L=Escape'
autocutsel -selection CLIPBOARD -fork
autocutsel -selection PRIMARY -fork
xrdb -merge ~/.Xresources
#doDWM 
exec i3
. /etc/X11/xinit/xinitrc
