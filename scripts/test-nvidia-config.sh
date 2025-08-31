#!/usr/bin/env bash

# Safe NVIDIA Configuration Testing Script
# This script helps test NVIDIA configuration changes safely

set -euo pipefail

echo "=== NixOS NVIDIA Configuration Testing Script ==="
echo "This script will help you safely test NVIDIA driver configuration"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to backup current generation
backup_current_generation() {
    local current_gen=$(nixos-rebuild list-generations | grep "current" | awk '{print $1}')
    info "Current generation: $current_gen"
    info "This generation will be your fallback if NVIDIA testing fails"
}

# Function to check hardware
check_hardware() {
    info "Checking hardware configuration..."
    echo
    echo "=== COMPREHENSIVE HARDWARE ANALYSIS ==="
    echo
    echo "1. Graphics Hardware:"
    lspci | grep -i vga
    echo
    echo "2. Current Drivers Loaded:"
    echo "NVIDIA: $(lsmod | grep nvidia || echo 'Not loaded')"
    echo "Nouveau: $(lsmod | grep nouveau | head -1 || echo 'Not loaded')"  
    echo "Intel i915: $(lsmod | grep i915 | head -1 || echo 'Not loaded')"
    echo
    echo "3. Current Kernel Parameters:"
    cat /proc/cmdline | tr ' ' '\n' | grep -E "(nvidia|nouveau|i915|drm)" || echo "No relevant GPU parameters found"
    echo
    echo "4. Display Server:"
    echo "Session Type: ${XDG_SESSION_TYPE:-Not set}"
    echo "Wayland Display: ${WAYLAND_DISPLAY:-Not set}"
    echo "X11 Display: ${DISPLAY:-Not set}"
    echo
    echo "5. GPU Power States:"
    echo "Intel GPU (card0): $(cat /sys/class/drm/card0/device/power_state 2>/dev/null || echo 'Unknown')"
    echo "NVIDIA GPU (card1): $(cat /sys/class/drm/card1/device/power_state 2>/dev/null || echo 'Unknown')"
    echo
    echo "6. CPU Governor:"
    echo "Current: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'Unknown')"
    echo
}

# Function to test configuration
test_nvidia_config() {
    warn "About to test NVIDIA configuration..."
    warn "This will build but NOT switch to the new configuration"
    echo
    read -p "Continue with test build? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Test cancelled"
        exit 0
    fi
    
    info "Testing NVIDIA configuration..."
    if sudo nixos-rebuild test --flake .#mahmoud-laptop; then
        success "NVIDIA configuration test passed!"
        echo
        info "The configuration built successfully and is running temporarily"
        info "If your display works properly, you can make it permanent with:"
        echo "  sudo nixos-rebuild switch --flake .#mahmoud-laptop"
        echo
        warn "If your display stops working, simply reboot to return to the previous generation"
        return 0
    else
        error "NVIDIA configuration test failed!"
        info "Your system remains on the current working generation"
        return 1
    fi
}

# Function to switch to NVIDIA permanently
switch_nvidia_config() {
    warn "About to permanently switch to NVIDIA configuration..."
    warn "Make sure you've tested it first and your display is working!"
    echo
    read -p "Continue with permanent switch? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Switch cancelled"
        exit 0
    fi
    
    info "Switching to NVIDIA configuration permanently..."
    if sudo nixos-rebuild switch --flake .#mahmoud-laptop; then
        success "Successfully switched to NVIDIA configuration!"
        echo
        info "NVIDIA offloading is now enabled. Use these commands:"
        echo "  nvidia-smi              # Check NVIDIA GPU status"
        echo "  nvidia-offload <app>    # Run app with NVIDIA GPU"
        echo "  nvitop                  # Monitor GPU usage"
        return 0
    else
        error "Switch failed! Your system should still be bootable on the previous generation"
        return 1
    fi
}

# Function to check current status
check_current_status() {
    info "Current system status:"
    echo
    echo "Current generation:"
    nixos-rebuild list-generations | grep "current"
    echo
    echo "NVIDIA Performance module enabled: $(grep -q 'custom.nvidiaPerformance.enable = true' /etc/nixos/configuration.nix && echo 'Yes' || echo 'No')"
    echo
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "NVIDIA driver status:"
        nvidia-smi --query-gpu=name,driver_version,temperature.gpu,power.draw --format=csv,noheader,nounits || echo "NVIDIA driver not active"
    else
        echo "NVIDIA driver: Not installed/active"
    fi
    echo
}

# Function to rollback if needed
rollback_to_working() {
    warn "Rolling back to last working generation..."
    echo
    local working_gen=$(nixos-rebuild list-generations | grep -v "current" | head -1 | awk '{print $1}')
    
    read -p "Rollback to generation $working_gen? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Rolling back..."
        sudo nixos-rebuild switch --rollback
        success "Rolled back to working generation"
    fi
}

# Main menu
show_menu() {
    echo
    echo "Choose an option:"
    echo "1. Check current status"
    echo "2. Check hardware"
    echo "3. Test NVIDIA configuration (safe)"
    echo "4. Switch to NVIDIA permanently"
    echo "5. Rollback to working generation"
    echo "6. Exit"
    echo
}

# Main script
main() {
    check_current_status
    
    while true; do
        show_menu
        read -p "Enter choice [1-6]: " choice
        case $choice in
            1)
                check_current_status
                ;;
            2)
                check_hardware
                ;;
            3)
                backup_current_generation
                test_nvidia_config
                ;;
            4)
                switch_nvidia_config
                ;;
            5)
                rollback_to_working
                ;;
            6)
                info "Exiting"
                exit 0
                ;;
            *)
                warn "Invalid option. Please choose 1-6."
                ;;
        esac
    done
}

# Run main function
main "$@"
