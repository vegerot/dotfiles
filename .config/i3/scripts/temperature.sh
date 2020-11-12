#!/usr/bin/env bash

out=$(/opt/vc/bin/vcgencmd measure_temp)
temp=${out#"temp="}
num=${temp%".0'C"}

WARN_TEMP=60
CRIT_TEMP=78
COOL_TEMP=46

echo $num"C"

#if [[ $num -ge $CRIT_TEMP ]];then
##    str="\033[31m"
#    echo "#FF0000"
#elif [[ $num -ge $WARN_TEMP ]]; then
##    str="\033[33m"
#    echo "#FFB900"
#fi

 
[[ $num -ge $CRIT_TEMP ]] && exit 33
[[ $num -ge $WARN_TEMP ]] && echo "#FFB900"
[[ $num -le $COOL_TEMP ]] && echo "#00BFFF"

exit 0
