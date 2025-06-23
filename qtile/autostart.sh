#!/bin/bash

# Create this file as ~/.config/qtile/autostart.sh
# Make it executable: chmod +x ~/.config/qtile/autostart.sh

# Wait a bit for the desktop to load
sleep 2

# Set wallpaper
xwallpaper --zoom ~/walls/castle.jpg &

# Set keyboard repeat rate
xset r rate 200 35 &

# Start compositor (Picom should already be running from NixOS config)
# picom &

# Start network manager applet
nm-applet &

# Start volume control applet  
# pavucontrol &

# Start bluetooth manager
blueman-applet &

# Start notification daemon (dunst should be available)
dunst &

# Start clipboard manager
copyq &

# You can add more applications here as needed
# discord &
# slack &
# spotify &
