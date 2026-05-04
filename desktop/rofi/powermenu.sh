#!/bin/bash
options="Logout\nReboot\nShutdown"

chosen=$(echo -e "$options" | rofi -dmenu -p "Power")

case "$chosen" in
    Logout) i3-msg exit ;;
    Reboot) reboot ;;
    Shutdown) poweroff ;;
esac
