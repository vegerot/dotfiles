#!/bin/bash

curl -s "http://api.openweathermap.org/data/2.5/weather/?APPID=ff857e9892398d2b7d4fc3f3b02fe84e&units=imperial&q=Baltimore"|python3 -c "import sys,json; print(json.load(sys.stdin)['weather'][0]['description'])"
