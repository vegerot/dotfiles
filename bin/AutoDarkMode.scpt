#!/usr/bin/env osascript
repeat while true
	
	set sunrise to do shell script "~/bin/sunrise.wl"
	set sunset to do shell script "~/bin/sunset.wl"
	set sunriseTomorrow to do shell script "~/bin/sunriseTomorrow.wl"
	
	
	set sunriseTime to date sunrise
	#set sunriseTime to sunriseTime - 5 * 60 * 60
	
	set sunsetTime to date sunset
#set sunsetTime to sunsetTime - 5 * 60 * 60
	
	set sunriseTimeTomorrow to date sunriseTomorrow
#set sunriseTimeTomorrow to sunriseTimeTomorrow
#	log sunrise
#	log sunset
#	log sunriseTimeTomorrow
	
	
	set currentTime to (current date)
	
	tell application "System Events"
		tell appearance preferences
			if (currentTime < sunriseTime) and (currentTime < sunsetTime) then
				set dark mode to true
				set waitUntil to sunriseTime - currentTime
			else if (currentTime > sunriseTime) and (currentTime < sunsetTime) then
				set dark mode to false
				set waitUntil to sunsetTime - currentTime
			else if (currentTime > sunriseTime and currentTime > sunsetTime) then
				set dark mode to true
				set waitUntil to (sunriseTimeTomorrow - currentTime)
			end if
		end tell
	end tell
	log waitUntil/60/60
	delay waitUntil + 60
end repeat

