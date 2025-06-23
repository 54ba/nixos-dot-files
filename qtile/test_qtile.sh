#!/bin/bash

# Qtile Configuration Setup Script for NixOS
# This script helps set up qtile configuration properly

set -e

echo "🔧 Setting up Qtile configuration for NixOS..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
print_status "Script directory: $SCRIPT_DIR"

# Create qtile directory structure
print_status "Creating qtile directory structure..."
mkdir -p ~/.config/qtile
mkdir -p ~/.local/share/qtile
mkdir -p ~/.cache/qtile

# Check if qtile config exists in script directory
if [ -f "$SCRIPT_DIR/qtile/config.py" ]; then
    print_status "Found qtile config in script directory"
    cp "$SCRIPT_DIR/qtile/config.py" ~/.config/qtile/config.py
    print_success "Copied qtile config to ~/.config/qtile/config.py"
elif [ -f "$SCRIPT_DIR/config.py" ]; then
    print_status "Found qtile config in current directory"
    cp "$SCRIPT_DIR/config.py" ~/.config/qtile/config.py
    print_success "Copied qtile config to ~/.config/qtile/config.py"
else
    print_warning "No qtile config found in expected locations"
    print_status "Please ensure your config.py is in either:"
    print_status "  - $SCRIPT_DIR/qtile/config.py"
    print_status "  - $SCRIPT_DIR/config.py"
fi

# Create autostart script
print_status "Creating autostart script..."
cat > ~/.config/qtile/autostart.sh << 'EOF'
#!/bin/bash
# Qtile autostart script

# Wait for X11 to be ready
sleep 2

# Check if we're in qtile session
if [ "$XDG_CURRENT_DESKTOP" != "qtile" ]; then
    exit 0
fi

# Set wallpaper (uncomment and adjust path as needed)
# feh --bg-scale ~/.config/qtile/wallpaper.jpg &
# nitrogen --restore &

# Start compositor (picom should be handled by systemd, but fallback)
if ! pgrep -x "picom" > /dev/null; then
    picom &
fi

# System tray applications
if command -v nm-applet &> /dev/null; then
    nm-applet &
fi

if command -v blueman-applet &> /dev/null; then
    blueman-applet &
fi

# Notification daemon
if command -v dunst &> /dev/null; then
    dunst &
fi

# Screenshot tool daemon
if command -v flameshot &> /dev/null; then
    flameshot &
fi

# Clipboard manager
if command -v copyq &> /dev/null; then
    copyq &
fi

# Set X11 properties
if command -v xset &> /dev/null; then
    xset r rate 300 50  # Key repeat rate
    xset s off          # Disable screen saver
    xset -dpms          # Disable DPMS
fi

# Auto-lock screen (optional - uncomment if you want)
# if command -v xss-lock &> /dev/null && command -v i3lock &> /dev/null; then
#     xss-lock -- i3lock -c 000000 &
# fi

echo "Qtile autostart completed at $(date)" >> ~/.cache/qtile/autostart.log
EOF

chmod +x ~/.config/qtile/autostart.sh
print_success "Created autostart script"

# Check NixOS configuration
print_status "Checking NixOS configuration..."

NIXOS_CONFIG="/etc/nixos/configuration.nix"
if [ -f "$NIXOS_CONFIG" ]; then
    print_status "Found NixOS configuration at $NIXOS_CONFIG"
    
    # Check if qtile is enabled
    if grep -q "windowManager.qtile" "$NIXOS_CONFIG"; then
        print_success "Qtile is enabled in NixOS configuration"
    else
        print_warning "Qtile may not be enabled in NixOS configuration"
        print_status "Make sure your configuration.nix includes:"
        print_status "  services.xserver.windowManager.qtile.enable = true;"
    fi
    
    # Check for required packages
    if grep -q "python.*qtile" "$NIXOS_CONFIG"; then
        print_success "Python qtile package found in configuration"
    else
        print_warning "Make sure python qtile packages are installed"
    fi
else
    print_warning "Could not find NixOS configuration file"
fi

# Check if required programs are available
print_status "Checking required programs..."

REQUIRED_PROGRAMS=("python3" "qtile" "rofi" "kitty" "firefox")
MISSING_PROGRAMS=()

for program in "${REQUIRED_PROGRAMS[@]}"; do
    if command -v "$program" &> /dev/null; then
        print_success "$program is available"
    else
        print_warning "$program is not available"
        MISSING_PROGRAMS+=("$program")
    fi
done

if [ ${#MISSING_PROGRAMS[@]} -gt 0 ]; then
    print_warning "Some required programs are missing:"
    printf '%s\n' "${MISSING_PROGRAMS[@]}"
    print_status "Make sure they are installed in your NixOS configuration"
fi

# Test qtile configuration
print_status "Testing qtile configuration..."
if [ -f ~/.config/qtile/config.py ]; then
    if python3 -c "import sys; sys.path.insert(0, '$HOME/.config/qtile'); import config" 2>/dev/null; then
        print_success "Qtile configuration syntax is valid"
    else
        print_error "Qtile configuration has syntax errors"
        print_status "Run: python3 -c \"import sys; sys.path.insert(0, '$HOME/.config/qtile'); import config\""
        print_status "To see the specific errors"
    fi
else
    print_error "No qtile configuration found at ~/.config/qtile/config.py"
fi

# Create a simple wallpaper directory
mkdir -p ~/.config/qtile/wallpapers
print_status "Created wallpapers directory at ~/.config/qtile/wallpapers"

# Create session selection helper
cat > ~/.local/bin/qtile-session << 'EOF'
#!/bin/bash
# Helper script to ensure proper qtile session

export XDG_CURRENT_DESKTOP="qtile"
export XDG_SESSION_DESKTOP="qtile"

# Start qtile with proper error handling
exec qtile start 2>&1 | tee ~/.cache/qtile/qtile.log
EOF

chmod +x ~/.local/bin/qtile-session 2>/dev/null || true

print_status "Setup complete!"
print_status ""
print_status "Next steps:"
print_status "1. Make sure your NixOS configuration includes the qtile setup"
print_status "2. Run: sudo nixos-rebuild switch"
print_status "3. Log out and select 'qtile' from the session menu in GDM"
print_status "4. Your qtile config is at: ~/.config/qtile/config.py"
print_status "5. Autostart script is at: ~/.config/qtile/autostart.sh"
print_status ""
print_status "Troubleshooting:"
print_status "- Check qtile logs: ~/.cache/qtile/qtile.log"
print_status "- Check autostart logs: ~/.cache/qtile/autostart.log"
print_status "- Test config: cd ~/.config/qtile && python3 -c 'import config'"
print_status ""
print_success "Qtile setup completed successfully!"
