#!/bin/bash


URL="https://www.infowars.com/rss.xml"
rss_path="/home/raz13/Downloads/rss.xml"


# Open Brave Browser with the specified URL
brave "$URL"
sleep 6

xdotool mousemove 540 447 #captcha / clicks on middle of page for save command
xdotool click 1
sleep 2

xdotool key ctrl+s
sleep 2
xdotool mousemove 1484 386 #save button
xdotool click 1
sleep 3



# Extract and list all the links starting with https://www.infowars.com/posts/
grep -oP '(?<=<link>)https://www.infowars.com/posts/[^<]+' "$rss_path"


#xdotool mousemove 1882 194
#xdotool click 1