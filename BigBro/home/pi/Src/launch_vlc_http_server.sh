#!/bin/bash
# LoB

# default pidfile is: /var/run/vncserver-x11-serviced.pid

export DISPLAY=:0 # avoids DBUS error message

vlc --random --daemon -I http --http-password 12345 /data/Music

echo "------------------------------------------------------------------------"
echo "VLC Interface: http://192.168.42.1:8080 (no login, password=12345)"
echo "------------------------------------------------------------------------"

