#!/usr/bin/env bash
~/bin/timeLeft.py
prev=$?;
until [[ $prev == 0 ]]; do
    sleep 1;
    out=$(~/bin/timeLeft.py);
	prev=$?; 
done
echo $out;
exit 0
