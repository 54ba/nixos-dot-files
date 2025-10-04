#!/usr/bin/env bash

set -euo pipefail

# Screen Sharing Fix Script for Wayland/GNOME
# This script restarts the necessary services for screen sharing to work properly

echo "🔧 Fixing screen sharing on Wayland/GNOME..."

# Check if we're running in a user session
if [ -z "$XDG_RUNTIME_DIR" ] || [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    echo "❌ Error: This script must be run from within a user session (not from root/SSH)"
    echo "   Please run this script from the desktop terminal as your regular user"
    exit 1
fi

echo "📍 Current session info:"
echo "   User: $(whoami)"
echo "   Desktop: $XDG_CURRENT_DESKTOP"
echo "   Session: $XDG_SESSION_TYPE"
echo "   Runtime dir: $XDG_RUNTIME_DIR"
echo ""

# Function to restart a user service with proper error handling
restart_service() {
    local service=$1
    echo "🔄 Restarting $service..."
    
    # Stop the service first
    systemctl --user stop "$service" 2>/dev/null || echo "   Service wasn't running"
    
    # Start the service
    if systemctl --user start "$service"; then
        echo "   ✅ $service started successfully"
        return 0
    else
        echo "   ❌ Failed to start $service"
        return 1
    fi
}

# Function to check service status
check_service() {
    local service=$1
    echo "📊 Checking $service status..."
    
    if systemctl --user is-active "$service" >/dev/null 2>&1; then
        echo "   ✅ $service is running"
        return 0
    else
        echo "   ❌ $service is not running"
        systemctl --user status "$service" --no-pager -l | head -10
        return 1
    fi
}

echo "🚀 Phase 1: Restarting XDG Desktop Portal services..."
restart_service "xdg-desktop-portal.service"
sleep 2
restart_service "xdg-desktop-portal-gnome.service" 
sleep 2
restart_service "xdg-desktop-portal-gtk.service"
sleep 2

echo ""
echo "🚀 Phase 2: Restarting GNOME services..."
restart_service "gnome-remote-desktop.service"
sleep 1

echo ""
echo "📊 Phase 3: Checking service status..."
check_service "xdg-desktop-portal.service"
check_service "xdg-desktop-portal-gnome.service"
check_service "xdg-desktop-portal-gtk.service"
check_service "gnome-remote-desktop.service"

echo ""
echo "🔍 Phase 4: Checking for portal detection..."
# Check if xdg-desktop-portal is accessible
if command -v xdg-desktop-portal >/dev/null 2>&1; then
    echo "✅ xdg-desktop-portal command is available"
else
    echo "❌ xdg-desktop-portal command not found in PATH"
fi

# Check if portal directory exists
if [ -d "/run/user/$(id -u)/xdg-desktop-portal" ]; then
    echo "✅ XDG portal runtime directory exists"
    ls -la "/run/user/$(id -u)/xdg-desktop-portal/"
else
    echo "❌ XDG portal runtime directory missing"
fi

echo ""
echo "🧪 Phase 5: Testing screen sharing capability..."

# Test if we can enumerate video sources (requires portal to be working)
if command -v gst-device-monitor-1.0 >/dev/null 2>&1; then
    echo "🔍 Testing PipeWire/GStreamer screen capture sources..."
    timeout 5 gst-device-monitor-1.0 Video/Source 2>/dev/null | head -10 || echo "   No immediate sources detected (this may be normal)"
else
    echo "⚠️  GStreamer tools not available for testing"
fi

echo ""
echo "🎯 Phase 6: Browser-specific fixes..."

# Create browser launch scripts with proper flags
DESKTOP_DIR="$HOME/.local/share/applications"
mkdir -p "$DESKTOP_DIR"

# Firefox with screen sharing flags
cat > "$DESKTOP_DIR/firefox-screenshare.desktop" << EOF
[Desktop Entry]
Version=1.0
Name=Firefox (Screen Sharing)
Comment=Web Browser with Enhanced Screen Sharing
GenericName=Web Browser
Keywords=Internet;WWW;Browser;Web;Explorer;Screenshare
Exec=env MOZ_ENABLE_WAYLAND=1 MOZ_USE_XINPUT2=1 MOZ_WEBRENDER=1 firefox %u
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=firefox
Categories=GNOME;GTK;Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
StartupNotify=true
EOF

# Chrome with screen sharing flags
cat > "$DESKTOP_DIR/google-chrome-screenshare.desktop" << EOF
[Desktop Entry]
Version=1.0
Name=Google Chrome (Screen Sharing)
Comment=Access the Internet with Enhanced Screen Sharing
GenericName=Web Browser
Keywords=Internet;WWW;Browser;Web;Explorer;Screenshare
Exec=google-chrome --ozone-platform-hint=auto --enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder,VaapiIgnoreDriverChecks,WebRTCPipeWireCapturer --disable-features=UseChromeOSDirectVideoDecoder --enable-wayland-ime --disable-gpu-sandbox %U
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=google-chrome
Categories=Network;WebBrowser;
MimeType=application/pdf;application/rdf+xml;application/rss+xml;application/xhtml+xml;application/xhtml_xml;application/xml;image/gif;image/jpeg;image/png;image/webp;text/html;text/xml;x-scheme-handler/ftp;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
EOF

echo "✅ Created optimized browser launchers in $DESKTOP_DIR"

echo ""
echo "🎉 Screen sharing fix complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Log out and log back in (or reboot) to ensure all services are properly initialized"
echo "   2. Test screen sharing in:"
echo "      - Firefox: Use 'Firefox (Screen Sharing)' launcher or set MOZ_ENABLE_WAYLAND=1"
echo "      - Chrome: Use 'Google Chrome (Screen Sharing)' launcher"
echo "      - Discord: Should work with current Wayland optimizations"
echo "   3. If issues persist, check the browser's site permissions for camera/screen access"
echo ""
echo "🔧 Troubleshooting:"
echo "   - If no sources appear, try: sudo systemctl restart gdm"
echo "   - For more debug info, run: journalctl --user -u xdg-desktop-portal -f"
echo "   - Check portal config: ls -la ~/.config/xdg-desktop-portal/"
echo ""

# Set executable permissions
chmod +x "$0" 2>/dev/null || true
