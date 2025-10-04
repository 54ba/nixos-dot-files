#!/usr/bin/env bash

set -euo pipefail

# Screen Sharing Debug Script
# Run this from your desktop terminal as your regular user

echo "🔍 Screen Sharing Debug Information"
echo "=================================="
echo

# Check current user and session
echo "📍 Session Information:"
echo "   User: $(whoami)"
echo "   Session Type: $XDG_SESSION_TYPE"
echo "   Desktop: $XDG_CURRENT_DESKTOP"
echo "   Wayland Display: $WAYLAND_DISPLAY"
echo "   Runtime Dir: $XDG_RUNTIME_DIR"
echo

# Check if we're in a proper user session
if [ -z "$XDG_RUNTIME_DIR" ] || [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    echo "❌ Error: Not in a user session. Please run this from your desktop terminal."
    exit 1
fi

echo "🔧 Checking Screen Sharing Services:"
echo

# Function to check service status
check_service() {
    local service=$1
    echo -n "   $service: "
    if systemctl --user is-active "$service" >/dev/null 2>&1; then
        echo "✅ Running"
    else
        echo "❌ Not running"
        systemctl --user status "$service" --no-pager -l | head -3 | grep -E "(Active:|Main PID:|Process:)" || echo "      No additional info"
    fi
}

# Check critical services
check_service "xdg-desktop-portal.service"
check_service "xdg-desktop-portal-gnome.service"
check_service "xdg-desktop-portal-gtk.service"
check_service "gnome-remote-desktop.service"

echo
echo "🔍 Checking PipeWire Services:"
check_service "pipewire.service"
check_service "wireplumber.service"

echo
echo "📂 Checking Portal Configuration:"
if [ -f "$HOME/.config/xdg-desktop-portal/portals.conf" ]; then
    echo "   User portal config: ✅ Found"
    echo "   Content:"
    cat "$HOME/.config/xdg-desktop-portal/portals.conf" | head -10 | sed 's/^/      /'
else
    echo "   User portal config: ❌ Missing (using system default)"
fi

echo
echo "🔍 Checking System Portal Configuration:"
if [ -f "/run/current-system/etc/xdg-desktop-portal/portals.conf" ]; then
    echo "   System portal config: ✅ Found"
    echo "   Content:"
    cat "/run/current-system/etc/xdg-desktop-portal/portals.conf" | head -10 | sed 's/^/      /'
else
    echo "   System portal config: ❌ Missing"
fi

echo
echo "🔍 Checking Available Portals:"
ls -la /run/current-system/sw/share/xdg-desktop-portal/portals/ 2>/dev/null | grep -E "\.(portal)$" | sed 's/^/   /'

echo
echo "🔍 Testing PipeWire Screen Capture:"
if command -v gst-device-monitor-1.0 >/dev/null 2>&1; then
    echo "   Testing GStreamer PipeWire sources (5 second timeout):"
    timeout 5 gst-device-monitor-1.0 Video/Source 2>/dev/null | head -10 | sed 's/^/      /' || echo "      No sources detected immediately"
else
    echo "   GStreamer tools not available"
fi

echo
echo "🔍 Process Information:"
echo "   XDG Desktop Portal processes:"
pgrep -f "xdg-desktop-portal" | head -5 | while read pid; do
    if [ -n "$pid" ]; then
        ps -p $pid -o pid,cmd --no-headers | sed 's/^/      /'
    fi
done

echo
echo "📋 Browser Testing Commands:"
echo "   Test Chromium with screen sharing:"
echo "      chromium --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland"
echo
echo "   Test Firefox with screen sharing:"
echo "      firefox-screenshare"
echo
echo "   Test Discord with screen sharing:"
echo "      discord-wayland"

echo
echo "🔧 Quick Fixes to Try:"
echo "   1. Restart portal services:"
echo "      systemctl --user restart xdg-desktop-portal xdg-desktop-portal-gnome"
echo
echo "   2. Test with web-based screen sharing:"
echo "      Open: https://webrtc.github.io/samples/src/content/getusermedia/getdisplaymedia/"
echo
echo "   3. Check Chrome flags (chrome://flags/):"
echo "      - #enable-webrtc-pipewire-capturer → Enabled"
echo "      - #ozone-platform-hint → Auto"

echo
echo "🏁 Debug Complete!"
echo "   If services are not running, use: /etc/nixos/scripts/fix-screen-sharing.sh"
