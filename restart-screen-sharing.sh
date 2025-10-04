#!/usr/bin/env bash

set -euo pipefail

# Screen sharing restart script - must be run as the user in a desktop session
# This script restarts the screen sharing services with proper environment variables

echo "🔧 Restarting screen sharing services..."
echo "======================================"

# Check if we're in a proper user session
if [ -z "$XDG_RUNTIME_DIR" ]; then
    echo "❌ Error: This script must be run from within a user desktop session"
    echo "   Please run this from a terminal in your desktop environment"
    exit 1
fi

if [ "$(whoami)" = "root" ]; then
    echo "❌ Error: This script must be run as a regular user, not root"
    echo "   Please run this from a terminal as user 'mahmoud'"
    exit 1
fi

echo "📍 Current user: $(whoami)"
echo "📍 Runtime dir: $XDG_RUNTIME_DIR"
echo

# Set critical environment variables for this session
export XDG_SESSION_TYPE="wayland"
export XDG_CURRENT_DESKTOP="gnome" 
export WAYLAND_DISPLAY="wayland-0"
export PIPEWIRE_RUNTIME_DIR="$XDG_RUNTIME_DIR"

echo "🌍 Setting environment variables:"
echo "   XDG_SESSION_TYPE=$XDG_SESSION_TYPE"
echo "   XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP"
echo "   WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
echo "   PIPEWIRE_RUNTIME_DIR=$PIPEWIRE_RUNTIME_DIR"
echo

# Function to restart a user service
restart_user_service() {
    local service="$1"
    echo "🔄 Restarting $service..."
    if systemctl --user stop "$service" 2>/dev/null; then
        echo "   ✅ Stopped $service"
    else
        echo "   ℹ️  $service was not running"
    fi
    
    sleep 1
    
    if systemctl --user start "$service" 2>/dev/null; then
        echo "   ✅ Started $service"
    else
        echo "   ❌ Failed to start $service"
    fi
    echo
}

# Restart desktop portal services in the correct order
echo "🚀 Phase 1: Restarting XDG desktop portal services..."
restart_user_service "xdg-desktop-portal.service"
sleep 2
restart_user_service "xdg-desktop-portal-gnome.service"
sleep 1
restart_user_service "xdg-desktop-portal-gtk.service"
sleep 1

echo "🚀 Phase 2: Restarting GNOME services..."
restart_user_service "gnome-remote-desktop.service"

echo "🔍 Phase 3: Checking service status..."
for service in "xdg-desktop-portal" "xdg-desktop-portal-gnome" "xdg-desktop-portal-gtk" "gnome-remote-desktop"; do
    if systemctl --user is-active "$service.service" >/dev/null 2>&1; then
        echo "   ✅ $service is running"
    else
        echo "   ❌ $service is not running"
    fi
done
echo

echo "🧪 Phase 4: Testing portal detection..."
if command -v dbus-send >/dev/null 2>&1; then
    echo "Testing desktop portal via DBus..."
    if dbus-send --session --print-reply --dest=org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.DBus.Introspectable.Introspect 2>/dev/null | grep -q "ScreenCast"; then
        echo "   ✅ ScreenCast interface is available via DBus"
    else
        echo "   ❌ ScreenCast interface not found via DBus"
    fi
else
    echo "   ℹ️  DBus tools not available for testing"
fi
echo

echo "🎉 Screen sharing restart completed!"
echo
echo "📋 Next steps:"
echo "1. Close any browser windows that were testing screen sharing"
echo "2. Open a new browser window"
echo "3. Test screen sharing in a web application (Discord, Meet, etc.)"
echo "4. If still not working, try logging out and logging back in completely"
echo
