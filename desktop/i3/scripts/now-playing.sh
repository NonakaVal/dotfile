#!/bin/bash

if ! command -v playerctl >/dev/null 2>&1; then
    echo "🎵 off"
    exit 0
fi

# pega o primeiro player disponível
player=$(playerctl -l 2>/dev/null | head -n 1)

if [ -z "$player" ]; then
    echo "🎵 off"
    exit 0
fi

status=$(playerctl -p "$player" status 2>/dev/null)

if [ -z "$status" ]; then
    echo "🎵 off"
    exit 0
fi

artist=$(playerctl -p "$player" metadata artist 2>/dev/null)
title=$(playerctl -p "$player" metadata title 2>/dev/null)

if [ -n "$artist" ] && [ -n "$title" ]; then
    text="$artist - $title"
elif [ -n "$title" ]; then
    text="$title"
elif [ -n "$artist" ]; then
    text="$artist"
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
