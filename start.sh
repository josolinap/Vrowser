#!/bin/sh
set -e

USER=browser
HOME=/home/$USER
DISP=:1
export DISPLAY=$DISP

# 1. launch tiny X framebuffer
su-exec $USER Xvfb $DISP -screen 0 1280x720x24 -ac +extension RANDR +render -noreset &

# 2. wait for socket
while [ ! -e /tmp/.X11-unix/X${DISP#*:} ]; do sleep 0.1; done

# 3. start chromium kiosk
su-exec $USER chromium-browser \
        --no-sandbox \
        --disable-dev-shm-usage \
        --kiosk \
        --window-size=1280,720 \
        --window-position=0,0 \
        "https://duckduckgo.com" &

# 4. serve Xvfb over WebSocket on port 8080
exec su-exec $USER webvnc $DISP 8080
