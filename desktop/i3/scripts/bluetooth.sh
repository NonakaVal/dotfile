#!/bin/bash

if ! command -v bluetoothctl >/dev/null 2>&1; then
    echo "off"
    exit 0
fi

power=$(bluetoothctl show | awk -F': ' '/Powered/ {print $2}')

if [ "$power" != "yes" ]; then
    echo "off"
    exit 0
fi

device=$(bluetoothctl devices Connected | sed 's/^Device [^ ]* //g' | head -n1)

if [ -n "$device" ]; then
    echo "$device"
else
    echo "on"
fi
