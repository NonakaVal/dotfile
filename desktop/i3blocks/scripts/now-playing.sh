#!/bin/bash

if ! command -v playerctl >/dev/null 2>&1; then
    echo "🎵 off"
    exit 0
fi

status=$(playerctl status 2>/dev/null)

if [ -z "$status" ]; then
    echo "🎵 off"
    exit 0
fi

artist=$(playerctl metadata artist 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)

text=""

if [ -n "$artist" ] && [ -n "$title" ]; then
    text="$artist - $title"
elif [ -n "$title" ]; then
    text="$title"
else
    text="media"
fi

max=45
if [ ${#text} -gt $max ]; then
    text="${text:0:$max}..."
fi

case "$status" in
    Playing) echo "🎵 $text" ;;
    Paused)  echo "⏸ $text" ;;
    *)       echo "🎵 off" ;;
esac
