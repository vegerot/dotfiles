#!/usr/bin/env osascript

on run argv
    set recipient to item 1 of argv
    set message to item 2 of argv
    set sendTime to item 3 of argv
    set sendTime to date sendTime
    repeat while true
        set currentTime to current date
        --if the time of currentTime is greater than sendTime and the time of currentTime is less than (sendTime+60) then
        if currentTime>sendTime and currentTime<sendTime+60
            my send_message(recipient, message)
            set logMsg to  "sent " & message &" to " &recipient
            log logMsg
            tell me to "exit"
            error number -128
        end if
        delay sendTime-currentTime+3 
    end repeat
end run     

on send_message(friend, message)
   tell application "Messages"
       send message to buddy friend  
   end tell
end send_message
