#!/run/current-system/sw/bin/bash

# Touchpad Fix Script for Lenovo S540 GTX 15IWL
# Fixes touchpad scrolling and gesture issues

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        exit 1
    fi
}

# Function to detect touchpad
detect_touchpad() {
    print_status "Detecting touchpad devices..."

    # List input devices
    echo "Available input devices:"
    ls -la /dev/input/event* 2>/dev/null || echo "No input devices found"

    # Show touchpad info
    if command -v xinput &> /dev/null; then
        echo ""
        echo "Touchpad devices:"
        xinput list | grep -i touchpad || echo "No touchpad devices found"
    fi

    # Show libinput info
    if command -v libinput &> /dev/null; then
        echo ""
        echo "Libinput device info:"
        sudo libinput list-devices | grep -A 10 -i touchpad || echo "No libinput touchpad info"
    fi
}

# Function to fix touchpad permissions
fix_touchpad_permissions() {
    print_status "Fixing touchpad permissions..."

    # Fix input device permissions
    if [ -d "/dev/input" ]; then
        sudo chmod 644 /dev/input/event*
        sudo chown root:input /dev/input/event*
        print_success "Touchpad permissions fixed"
    else
        print_warning "Input directory not found"
    fi

    # Fix user input group
    if ! groups $USER | grep -q input; then
        sudo usermod -a -G input $USER
        print_success "User added to input group"
        print_warning "You may need to log out and back in for this to take effect"
    else
        print_success "User already in input group"
    fi
}

# Function to reload input modules
reload_input_modules() {
    print_status "Reloading input modules..."

    # Reload libinput
    if command -v modprobe &> /dev/null; then
        sudo modprobe -r libinput 2>/dev/null || true
        sleep 1
        sudo modprobe libinput
        print_success "Libinput module reloaded"
    fi

    # Reload synaptics if available
    if lsmod | grep -q synaptics; then
        sudo modprobe -r psmouse 2>/dev/null || true
        sleep 1
        sudo modprobe psmouse
        print_success "PSMouse module reloaded"
    fi
}

# Function to restart input services
restart_input_services() {
    print_status "Restarting input services..."

    # Restart touchegg if running
    if systemctl is-enabled touchegg &> /dev/null; then
        sudo systemctl restart touchegg
        print_success "Touchegg service restarted"
    fi

    # Restart GNOME shell if running
    if pgrep -f "gnome-shell" &> /dev/null; then
        print_status "Restarting GNOME shell..."
        killall -HUP gnome-shell || true
        print_success "GNOME shell restarted"
    fi

    # Restart display manager if possible
    if systemctl is-active display-manager &> /dev/null; then
        print_warning "Display manager restart required for full effect"
        print_warning "You may need to manually restart or reboot"
    fi
}

# Function to create touchpad configuration
create_touchpad_config() {
    print_status "Creating touchpad configuration..."

    # Create libinput configuration
    mkdir -p ~/.config/libinput
    cat > ~/.config/libinput/gestures.conf << 'EOF'
# Libinput gestures configuration for Lenovo S540
# Touchpad and gesture settings

# Enable gestures
gesture:
  swipe:
    up: 3
    down: 3
    left: 3
    right: 3
  pinch:
    in: 2
    out: 2
  rotate: 2

# Touchpad settings
touchpad:
  # Enable tapping
  tapping: true

  # Enable natural scrolling
  natural-scrolling: true

  # Enable horizontal scrolling
  horizontal-scrolling: true

  # Disable while typing
  disable-while-typing: true

  # Click method
  click-method: clickfinger

  # Scroll method
  scroll-method: twofinger

  # Acceleration profile
  accel-profile: adaptive

  # Acceleration speed
  accel-speed: 0.5
EOF

    # Create touchegg configuration
    mkdir -p ~/.config/touchegg
    cat > ~/.config/touchegg/touchegg.conf << 'EOF'
# TouchEgg Configuration for Lenovo S540
# Touchpad and gesture settings

# General settings
General = {
    GestureBeginTimeout = 100
    GestureEndTimeout = 100
}

# Two finger gestures
"2" = {
    Gesture = DRAG
    Action = MOVE_WINDOW
}

"2" = {
    Gesture = PINCH
    Action = RESIZE_WINDOW
}

"2" = {
    Gesture = ROTATE
    Action = ROTATE_WINDOW
}

# Three finger gestures
"3" = {
    Gesture = SWIPE
    Action = SWITCH_DESKTOP
}

"3" = {
    Gesture = TAP
    Action = MOUSE_CLICK
    MouseButton = 2
}

# Four finger gestures
"4" = {
    Gesture = SWIPE
    Action = SHOW_DESKTOP
}
EOF

    print_success "Touchpad configuration files created"
}

# Function to test touchpad
test_touchpad() {
    print_status "Testing touchpad functionality..."

    echo "Touchpad test instructions:"
    echo "1. Try scrolling with two fingers"
    echo "2. Try tapping with one finger"
    echo "3. Try two-finger right-click"
    echo "4. Try three-finger swipe"
    echo "5. Try pinch gestures"
    echo ""
    echo "Press Enter when ready to test..."
    read -r

    # Show current touchpad status
    if command -v xinput &> /dev/null; then
        echo "Current touchpad properties:"
        xinput list-props "Synaptics TM3276-031" 2>/dev/null || \
        xinput list-props "ELAN0732:00 04F3:22E1 Touchpad" 2>/dev/null || \
        xinput list-props "SynPS/2 Synaptics TouchPad" 2>/dev/null || \
        echo "Touchpad not found or different name"
    fi
}

# Function to show help
show_help() {
    echo "Touchpad Fix Script for Lenovo S540 GTX 15IWL"
    echo "============================================="
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  detect        - Detect touchpad devices"
    echo "  permissions   - Fix touchpad permissions"
    echo "  modules       - Reload input modules"
    echo "  services      - Restart input services"
    echo "  config        - Create touchpad configuration"
    echo "  test          - Test touchpad functionality"
    echo "  all           - Apply all fixes"
    echo "  help          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 detect      # Detect touchpad devices"
    echo "  $0 permissions # Fix permissions"
    echo "  $0 all         # Apply all fixes"
    echo ""
    echo "After applying fixes, you may need to:"
    echo "1. Log out and back in"
    echo "2. Restart GNOME shell"
    echo "3. Reboot the system"
}

# Main function
main() {
    check_root

    case "${1:-all}" in
        "detect")
            detect_touchpad
            ;;
        "permissions")
            fix_touchpad_permissions
            ;;
        "modules")
            reload_input_modules
            ;;
        "services")
            restart_input_services
            ;;
        "config")
            create_touchpad_config
            ;;
        "test")
            test_touchpad
            ;;
        "all")
            print_status "Applying all touchpad fixes..."
            detect_touchpad
            fix_touchpad_permissions
            reload_input_modules
            create_touchpad_config
            restart_input_services
            test_touchpad
            print_success "All touchpad fixes applied!"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac

    print_status "Touchpad fix complete!"
    print_status "If issues persist, try logging out and back in, or reboot"
}

# Run main function with all arguments
main "$@"