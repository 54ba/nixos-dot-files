#!/usr/bin/env bash
# Configure GNOME screen sharing permissions for Chrome/Chromium

set -euo pipefail

echo "Configuring GNOME screen sharing permissions..."

# Function to run dconf commands as user
run_as_user() {
    local user="$1"
    shift
    sudo -u "$user" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$user")/bus" "$@"
}

# Main user (from configuration)
USER="mahmoud"

if ! id "$USER" &>/dev/null; then
    echo "Error: User $USER does not exist"
    exit 1
fi

echo "Configuring screen sharing permissions for user: $USER"

# Enable screen sharing in GNOME
run_as_user "$USER" dconf write /org/gnome/desktop/remote-desktop/enabled true
run_as_user "$USER" dconf write /org/gnome/desktop/remote-desktop/remote-desktop-enabled true

# Configure screen sharing to work with portals
run_as_user "$USER" dconf write /org/gnome/desktop/remote-desktop/rdp-enabled true
run_as_user "$USER" dconf write /org/gnome/desktop/remote-desktop/vnc-enabled true

# Enable screen recording (needed for screen sharing)
run_as_user "$USER" dconf write /org/gnome/settings-daemon/plugins/media-keys/screencast "['<Control><Alt><Shift>r']"

# Configure privacy settings to allow screen capture
run_as_user "$USER" dconf write /org/gnome/desktop/privacy/disable-camera false
run_as_user "$USER" dconf write /org/gnome/desktop/privacy/disable-microphone false

# Configure shell to show screen sharing indicators
run_as_user "$USER" dconf write /org/gnome/shell/show-screenshot-ui true

# Enable desktop file handling for portals
run_as_user "$USER" dconf write /org/gnome/desktop/applications/terminal/exec "'gnome-terminal'"

# Configure portal permissions
run_as_user "$USER" dconf write /org/freedesktop/portal/desktop/screenshot-enabled true
run_as_user "$USER" dconf write /org/freedesktop/portal/desktop/screencast-enabled true

echo "GNOME screen sharing configuration complete!"

# Restart relevant services
echo "Restarting GNOME Shell and portal services..."

# Restart user services that handle screen sharing
if systemctl --user is-active xdg-desktop-portal >/dev/null 2>&1; then
    run_as_user "$USER" systemctl --user restart xdg-desktop-portal
    echo "Restarted xdg-desktop-portal service"
fi

if systemctl --user is-active xdg-desktop-portal-gnome >/dev/null 2>&1; then
    run_as_user "$USER" systemctl --user restart xdg-desktop-portal-gnome
    echo "Restarted xdg-desktop-portal-gnome service"
fi

echo ""
echo "Screen sharing configuration is complete!"
echo ""
echo "Next steps:"
echo "1. Log out and log back in to apply all changes"
echo "2. Open Chrome/Chromium and test screen sharing"
echo "3. When prompted, grant screen sharing permissions"
echo ""
echo "Available browsers with screen sharing support:"
echo "- System Chrome: Use 'google-chrome' command"
echo "- System Chromium: Use 'chromium' command" 
echo "- Flatpak Chrome: Should now work with desktop/window sharing"
echo "- Flatpak Chromium: Should now work with desktop/window sharing"
