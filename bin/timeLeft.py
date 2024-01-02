#!/usr/bin/env python3
import subprocess
import re
import sys

def main():
    process = subprocess.check_output('pmset -g batt', shell=True).decode('utf-8')
    source = re.compile(r"Now drawing from '(?P<source>.*?) Power'")
    time = re.compile(r"; (?P<time>(\d*?):(\d*?)) remaining present")

    chargeInfo = subprocess.check_output('system_profiler SPPowerDataType', shell = True).decode('utf-8')
    charging = re.compile(r'AC Charger Information:.*?Connected: (?P<connected>(Yes|No))'\
                          '(.*?Wattage \(W\): (?P<wattage>(\d+)))?\n.*?Charging: (?P<charging>(Yes|No))',
                          re.DOTALL)

    parsedInfo = charging.search(chargeInfo)

    wattage = ' '+parsedInfo.group('wattage')+"(W)" if parsedInfo.group('wattage') else ""

    try:
        timeRemaining = time.search(process).group('time')
        ret = 0
    except AttributeError:
        timeRemaining = 'Not Charging' if (parsedInfo.group('charging') =='No'
                                           and parsedInfo.group('connected') =='Yes') else "No Estimate"
        ret = 1


    icon = '\033[107m 🔌 \033[0m' if source.match(process).group('source') == 'AC' else '🔋'
    print(timeRemaining+wattage, icon)

    sys.exit(ret)
if __name__ == "__main__":
    main()

