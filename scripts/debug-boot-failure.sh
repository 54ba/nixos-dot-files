#!/usr/bin/env bash

# Boot Failure Debug Script
# This script helps collect comprehensive logs after a boot failure

set -euo pipefail

echo "=== NixOS Boot Failure Debug Tool ==="
echo "This script collects detailed logs to identify boot failures"
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

# Create debug log directory
DEBUG_DIR="/tmp/nixos-boot-debug-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DEBUG_DIR"

info "Creating debug log collection in: $DEBUG_DIR"

# Function to collect current generation info
collect_generation_info() {
    info "Collecting generation information..."
    
    echo "=== GENERATION INFORMATION ===" > "$DEBUG_DIR/generation-info.log"
    echo "Current generation:" >> "$DEBUG_DIR/generation-info.log"
    nixos-rebuild list-generations | grep current >> "$DEBUG_DIR/generation-info.log" 2>&1 || echo "Failed to get current generation" >> "$DEBUG_DIR/generation-info.log"
    echo >> "$DEBUG_DIR/generation-info.log"
    
    echo "Last 10 generations:" >> "$DEBUG_DIR/generation-info.log"
    nixos-rebuild list-generations | head -10 >> "$DEBUG_DIR/generation-info.log" 2>&1 || echo "Failed to get generation list" >> "$DEBUG_DIR/generation-info.log"
    echo >> "$DEBUG_DIR/generation-info.log"
    
    echo "Boot entries in GRUB:" >> "$DEBUG_DIR/generation-info.log"
    grep -n "Configuration" /boot/grub/grub.cfg | head -10 >> "$DEBUG_DIR/generation-info.log" 2>&1 || echo "Failed to get GRUB entries" >> "$DEBUG_DIR/generation-info.log"
}

# Function to collect kernel and boot logs
collect_boot_logs() {
    info "Collecting boot and kernel logs..."
    
    # Current boot logs
    echo "=== CURRENT BOOT LOGS ===" > "$DEBUG_DIR/boot-logs.log"
    journalctl --boot=0 --no-pager >> "$DEBUG_DIR/boot-logs.log" 2>&1 || echo "Failed to get current boot logs" >> "$DEBUG_DIR/boot-logs.log"
    
    # Previous boot logs (if available)
    echo "=== PREVIOUS BOOT LOGS ===" > "$DEBUG_DIR/previous-boot-logs.log"
    journalctl --boot=-1 --no-pager >> "$DEBUG_DIR/previous-boot-logs.log" 2>&1 || echo "No previous boot logs available" >> "$DEBUG_DIR/previous-boot-logs.log"
    
    # Kernel messages
    echo "=== KERNEL MESSAGES ===" > "$DEBUG_DIR/kernel-logs.log"
    dmesg >> "$DEBUG_DIR/kernel-logs.log" 2>&1 || echo "Failed to get kernel messages" >> "$DEBUG_DIR/kernel-logs.log"
    
    # Failed services
    echo "=== FAILED SERVICES ===" > "$DEBUG_DIR/failed-services.log"
    systemctl --failed --no-pager >> "$DEBUG_DIR/failed-services.log" 2>&1 || echo "Failed to get failed services" >> "$DEBUG_DIR/failed-services.log"
}

# Function to collect hardware information
collect_hardware_info() {
    info "Collecting hardware information..."
    
    echo "=== HARDWARE INFORMATION ===" > "$DEBUG_DIR/hardware-info.log"
    echo "PCI devices:" >> "$DEBUG_DIR/hardware-info.log"
    lspci >> "$DEBUG_DIR/hardware-info.log" 2>&1 || echo "Failed to get PCI info" >> "$DEBUG_DIR/hardware-info.log"
    echo >> "$DEBUG_DIR/hardware-info.log"
    
    echo "USB devices:" >> "$DEBUG_DIR/hardware-info.log"
    lsusb >> "$DEBUG_DIR/hardware-info.log" 2>&1 || echo "Failed to get USB info" >> "$DEBUG_DIR/hardware-info.log"
    echo >> "$DEBUG_DIR/hardware-info.log"
    
    echo "Loaded kernel modules:" >> "$DEBUG_DIR/hardware-info.log"
    lsmod >> "$DEBUG_DIR/hardware-info.log" 2>&1 || echo "Failed to get module info" >> "$DEBUG_DIR/hardware-info.log"
    echo >> "$DEBUG_DIR/hardware-info.log"
    
    echo "Current kernel parameters:" >> "$DEBUG_DIR/hardware-info.log"
    cat /proc/cmdline >> "$DEBUG_DIR/hardware-info.log" 2>&1 || echo "Failed to get kernel parameters" >> "$DEBUG_DIR/hardware-info.log"
}

# Function to compare kernel parameters across generations
compare_kernel_params() {
    info "Comparing kernel parameters across generations..."
    
    echo "=== KERNEL PARAMETER COMPARISON ===" > "$DEBUG_DIR/kernel-params-comparison.log"
    
    # Get current (working) generation parameters
    echo "Generation 16 (known working):" >> "$DEBUG_DIR/kernel-params-comparison.log"
    grep -A3 "Configuration 16" /boot/grub/grub.cfg | grep "linux.*init=" | head -1 >> "$DEBUG_DIR/kernel-params-comparison.log" 2>&1 || echo "Gen 16 not found" >> "$DEBUG_DIR/kernel-params-comparison.log"
    echo >> "$DEBUG_DIR/kernel-params-comparison.log"
    
    # Get latest generation parameters
    local current_gen=$(nixos-rebuild list-generations | grep current | awk '{print $1}')
    echo "Generation $current_gen (current):" >> "$DEBUG_DIR/kernel-params-comparison.log"
    grep -A3 "Configuration $current_gen" /boot/grub/grub.cfg | grep "linux.*init=" | head -1 >> "$DEBUG_DIR/kernel-params-comparison.log" 2>&1 || echo "Current gen not found" >> "$DEBUG_DIR/kernel-params-comparison.log"
    echo >> "$DEBUG_DIR/kernel-params-comparison.log"
    
    # Get a few recent failed generations
    for gen in 35 34 33 32; do
        echo "Generation $gen:" >> "$DEBUG_DIR/kernel-params-comparison.log"
        grep -A3 "Configuration $gen" /boot/grub/grub.cfg | grep "linux.*init=" | head -1 >> "$DEBUG_DIR/kernel-params-comparison.log" 2>&1 || echo "Gen $gen not found" >> "$DEBUG_DIR/kernel-params-comparison.log"
        echo >> "$DEBUG_DIR/kernel-params-comparison.log"
    done
}

# Function to collect graphics and driver information
collect_graphics_info() {
    info "Collecting graphics and driver information..."
    
    echo "=== GRAPHICS INFORMATION ===" > "$DEBUG_DIR/graphics-info.log"
    
    echo "Graphics hardware:" >> "$DEBUG_DIR/graphics-info.log"
    lspci | grep -i vga >> "$DEBUG_DIR/graphics-info.log" 2>&1 || echo "Failed to get graphics hardware info" >> "$DEBUG_DIR/graphics-info.log"
    echo >> "$DEBUG_DIR/graphics-info.log"
    
    echo "Current graphics drivers:" >> "$DEBUG_DIR/graphics-info.log"
    echo "NVIDIA modules:" >> "$DEBUG_DIR/graphics-info.log"
    lsmod | grep nvidia >> "$DEBUG_DIR/graphics-info.log" 2>&1 || echo "No NVIDIA modules loaded" >> "$DEBUG_DIR/graphics-info.log"
    echo "Nouveau modules:" >> "$DEBUG_DIR/graphics-info.log"
    lsmod | grep nouveau >> "$DEBUG_DIR/graphics-info.log" 2>&1 || echo "No nouveau modules loaded" >> "$DEBUG_DIR/graphics-info.log"
    echo "Intel i915 modules:" >> "$DEBUG_DIR/graphics-info.log"
    lsmod | grep i915 >> "$DEBUG_DIR/graphics-info.log" 2>&1 || echo "No i915 modules loaded" >> "$DEBUG_DIR/graphics-info.log"
    echo >> "$DEBUG_DIR/graphics-info.log"
    
    echo "GPU power states:" >> "$DEBUG_DIR/graphics-info.log"
    echo "Intel GPU:" >> "$DEBUG_DIR/graphics-info.log"
    cat /sys/class/drm/card*/device/power_state 2>/dev/null >> "$DEBUG_DIR/graphics-info.log" || echo "Cannot read GPU power states" >> "$DEBUG_DIR/graphics-info.log"
    echo >> "$DEBUG_DIR/graphics-info.log"
    
    echo "Display server info:" >> "$DEBUG_DIR/graphics-info.log"
    echo "XDG_SESSION_TYPE: ${XDG_SESSION_TYPE:-Not set}" >> "$DEBUG_DIR/graphics-info.log"
    echo "WAYLAND_DISPLAY: ${WAYLAND_DISPLAY:-Not set}" >> "$DEBUG_DIR/graphics-info.log"
    echo "DISPLAY: ${DISPLAY:-Not set}" >> "$DEBUG_DIR/graphics-info.log"
}

# Function to check for ACPI and power management issues
collect_acpi_info() {
    info "Collecting ACPI and power management information..."
    
    echo "=== ACPI INFORMATION ===" > "$DEBUG_DIR/acpi-info.log"
    
    echo "ACPI errors in logs:" >> "$DEBUG_DIR/acpi-info.log"
    journalctl --boot=0 --no-pager | grep -i "acpi.*error" | tail -20 >> "$DEBUG_DIR/acpi-info.log" 2>&1 || echo "No ACPI errors found" >> "$DEBUG_DIR/acpi-info.log"
    echo >> "$DEBUG_DIR/acpi-info.log"
    
    echo "Power management info:" >> "$DEBUG_DIR/acpi-info.log"
    echo "CPU governor:" >> "$DEBUG_DIR/acpi-info.log"
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null >> "$DEBUG_DIR/acpi-info.log" || echo "Cannot read CPU governor" >> "$DEBUG_DIR/acpi-info.log"
    echo >> "$DEBUG_DIR/acpi-info.log"
    
    echo "Thermal zones:" >> "$DEBUG_DIR/acpi-info.log"
    ls /sys/class/thermal/thermal_zone*/type 2>/dev/null | while read zone; do
        echo -n "$(dirname $zone | xargs basename): " >> "$DEBUG_DIR/acpi-info.log"
        cat "$zone" 2>/dev/null >> "$DEBUG_DIR/acpi-info.log" || echo "Cannot read" >> "$DEBUG_DIR/acpi-info.log"
    done
}

# Main execution
main() {
    info "Starting comprehensive boot failure analysis..."
    
    collect_generation_info
    collect_boot_logs
    collect_hardware_info
    compare_kernel_params
    collect_graphics_info
    collect_acpi_info
    
    # Create summary
    echo "=== DEBUG SUMMARY ===" > "$DEBUG_DIR/SUMMARY.log"
    echo "Debug collection completed at: $(date)" >> "$DEBUG_DIR/SUMMARY.log"
    echo "Debug directory: $DEBUG_DIR" >> "$DEBUG_DIR/SUMMARY.log"
    echo >> "$DEBUG_DIR/SUMMARY.log"
    echo "Files created:" >> "$DEBUG_DIR/SUMMARY.log"
    ls -la "$DEBUG_DIR" >> "$DEBUG_DIR/SUMMARY.log"
    echo >> "$DEBUG_DIR/SUMMARY.log"
    echo "To analyze the logs, examine the files in $DEBUG_DIR" >> "$DEBUG_DIR/SUMMARY.log"
    echo "Key files to check:" >> "$DEBUG_DIR/SUMMARY.log"
    echo "- boot-logs.log: Current boot process logs" >> "$DEBUG_DIR/SUMMARY.log"
    echo "- previous-boot-logs.log: Previous boot attempt logs" >> "$DEBUG_DIR/SUMMARY.log"
    echo "- kernel-params-comparison.log: Parameter differences between generations" >> "$DEBUG_DIR/SUMMARY.log"
    echo "- failed-services.log: Services that failed to start" >> "$DEBUG_DIR/SUMMARY.log"
    echo "- graphics-info.log: Graphics hardware and driver status" >> "$DEBUG_DIR/SUMMARY.log"
    
    success "Debug information collected successfully!"
    success "Debug directory: $DEBUG_DIR"
    warn "After testing a failing generation, run this script to collect detailed failure logs"
    
    echo
    info "Quick analysis tips:"
    echo "1. Check kernel-params-comparison.log for parameter conflicts"
    echo "2. Look for 'failed' or 'error' in boot-logs.log" 
    echo "3. Check failed-services.log for systemd service failures"
    echo "4. Review graphics-info.log for driver conflicts"
    echo "5. Check acpi-info.log for hardware compatibility issues"
}

# Run main function
main "$@"
