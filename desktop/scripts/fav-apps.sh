#!/bin/bash

OPTIONS="󰣆 Terminal
󰖟 Chrome
󰖟 WhatsApp
󰖟 ChatGPT
󰖟 Gemini
󰉋 Files
󰈙 Obsidian
󰎆 Spotify
󰍲 Settings"

CHOICE=$(echo "$OPTIONS" | rofi -dmenu -i -p "apps")

case "$CHOICE" in
    "󰣆 Terminal") kitty ;;
    "󰖟 Chrome") google-chrome ;;
    "󰖟 WhatsApp") dex "$HOME/Área de trabalho/chrome-hnpfjngllnobngcgfapefoaidbinmjnm-Default.desktop" ;;
    "󰖟 ChatGPT") dex "$HOME/Área de trabalho/chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default.desktop" ;;
    "󰖟 Gemini") dex "$HOME/Área de trabalho/chrome-caidcmannjgahlnbpmidmiecjcoiiigg-Default.desktop" ;;
    "󰉋 Files") dolphin ;;
    "󰈙 Obsidian") obsidian ;;
    "󰎆 Spotify") spotify ;;
    "󰍲 Settings") lxappearance ;;
    *) exit 0 ;;
esac