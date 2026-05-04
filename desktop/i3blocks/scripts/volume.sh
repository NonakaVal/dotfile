#!/bin/bash

case "$BLOCK_BUTTON" in
    1) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;   # clique esquerdo
    3) pavucontrol & ;;                               # clique direito
    4) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;   # scroll up
    5) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;   # scroll down
esac

wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%d%%", $2*100}'
