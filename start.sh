#!/bin/sh
set -e
USER=browser
HOME=/home/$USER
DISP=:1
export DISPLAY=$DISP

su-exec $USER Xvfb $DISP -screen 0 1280x720x24 -ac +extension RANDR +render -noreset &
while [ ! -e /tmp/.X11-unix/X${DISP#*:} ]; do sleep 0.1; done

su-exec $USER chromium-browser --no-sandbox --disable-dev-shm-usage --kiosk --window-size=1280,720 "https://duckduckgo.com" &
exec su-exec $USER webvnc $DISP 8080
