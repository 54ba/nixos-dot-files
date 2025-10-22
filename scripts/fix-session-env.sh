#!/bin/sh
# Fix session environment for NixOS GUI applications

# Create necessary directories
mkdir -p "/run/user/$(id -u)"
mkdir -p "/run/user/$(id -u)/flatpak"
mkdir -p "$HOME/.cache"
mkdir -p "$HOME/.cache/gnome"
mkdir -p "$HOME/.cache/flatpak"

# Set proper permissions
chmod 700 "/run/user/$(id -u)"
chmod 700 "$HOME/.cache"

# Export environment variables for current session
export WAYLAND_DISPLAY="wayland-0"
export XDG_CURRENT_DESKTOP="GNOME"
export XDG_SESSION_TYPE="wayland"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export ELECTRON_OZONE_PLATFORM_HINT="auto"
export NIXOS_OZONE_WL="1"

echo "Session environment fixed for user $(id -u)"
