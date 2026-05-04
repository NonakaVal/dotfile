#!/bin/bash
# iconic font icon search: https://fontawesome.com/v4.7/cheatsheet/

OPTIONS="󰣆 Terminal
 Chrome
 WhatsApp
󰖟 ChatGPT
 Gemini
󰉋 Files
󰈙 Obsidian
󰎆 Spotify
󰍲 Settings"

CHOICE=$(echo "$OPTIONS" | rofi -dmenu -i -p "")

case "$CHOICE" in
    "󰣆 Terminal")
        exec kitty & ;;
        
    " Chrome")
        exec google-chrome-stable & ;;
        
    " WhatsApp")
        dex "/home/val/Desktop/chrome-hnpfjngllnobngcgfapefoaidbinmjnm-Default.desktop" & ;;
        
    "󰖟 ChatGPT")
        dex "/home/val/Desktop/chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default.desktop" & ;;
        
    " Gemini")
        dex "/home/val/Desktop/chrome-gdfaincndogidkdcdkhapmbffkckdkhn-Default.desktop" & ;;
        
    "󰉋 Files")
        exec dolphin & ;;
        
    "󰈙 Obsidian")
        exec obsidian & ;;
        
    "󰎆 Spotify")
        dex "/home/val/Desktop/chrome-pjibgclleladliembfgfagdaldikeohf-Default.desktop" & ;;
                
    *)
        exit 0 ;;
esac
