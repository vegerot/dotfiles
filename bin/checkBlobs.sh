#!/usr/bin/env bash

while true; do
    stat=$(curl -s "https://tsssaver.1conan.com/isitsigned.php"|gsed -n 's:.*\(iPhone9,3</td><td>\{0,1\}...<\).*:\1:p')
    echo $stat
    if echo $stat|grep yes ; then
        ~/Downloads/tsschecker -B D101AP -e D68E828E91526 -i 12.1.1 --beta -s -o --save-path ~/Desktop/short/
        ~/Downloads/tsschecker-latest/tsschecker_macos -d iPhone9,3 -e D68E828E91526 -i 12.1.1 --beta -o -s -m /Users/maxcoplan/Downloads/1211b3/BuildManifest.plist --buildid 16C5050a --save-path ~/Desktop/long/
        rm -r /tmp/tsschecker
        rm /tmp/ota.json
        rm /tmp/firmware.json
    fi
    sleep 60
done
