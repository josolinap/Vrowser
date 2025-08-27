#!/bin/sh
set -e
USER=browser
HOME=/home/$USER
DISP=:1
export DISPLAY=$DISP

# 1. start headless X server
su-exec $USER Xvfb $DISP -screen 0 1280x720x24 -ac +extension RANDR +render -noreset &
while [ ! -e /tmp/.X11-unix/X${DISPLAY#*:} ]; do sleep 0.1; done

# 2. chromium kiosk
su-exec $USER chromium-browser \
  --no-sandbox \
  --disable-dev-shm-usage \
  --kiosk \
  --window-size=1280,720 \
  "https://duckduckgo.com" &

# 3. expose X11 via websockify + noVNC on port 8080
exec su-exec $USER websockify --web=/usr/share/novnc 8080 localhost:5901
