#!/usr/bin/env bash

# Fingerprint Reader Setup Script for NixOS
# This script helps configure and test fingerprint readers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
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

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to check if fingerprint services are running
check_services() {
    print_info "Checking fingerprint services..."

    if systemctl is-active --quiet fprintd; then
        print_success "fprintd service is running"
    else
        print_warning "fprintd service is not running"
        print_info "Starting fprintd service..."
        systemctl start fprintd
        systemctl enable fprintd
    fi

    if systemctl is-active --quiet fprintd-tod; then
        print_success "fprintd-tod service is running"
    else
        print_warning "fprintd-tod service is not running"
        print_info "Starting fprintd-tod service..."
        systemctl start fprintd-tod
        systemctl enable fprintd-tod
    fi
}

# Function to check for fingerprint devices
check_devices() {
    print_info "Checking for fingerprint devices..."

    # Check USB devices that might be fingerprint readers
    local fingerprint_vendors=("06cb" "27c6" "138a" "0483" "1c7a")

    for vendor in "${fingerprint_vendors[@]}"; do
        local devices=$(lsusb | grep -i "$vendor" || true)
        if [[ -n "$devices" ]]; then
            print_success "Found potential fingerprint device: $devices"
        fi
    done

    # Check if libfprint can detect devices
    if command -v fprintd-list &> /dev/null; then
        print_info "Checking fprintd device list..."
        fprintd-list || print_warning "No devices found by fprintd"
    fi
}

# Function to check kernel modules
check_kernel_modules() {
    print_info "Checking kernel modules..."

    local modules=("uinput" "evdev" "usbhid")

    for module in "${modules[@]}"; do
        if lsmod | grep -q "$module"; then
            print_success "Kernel module $module is loaded"
        else
            print_warning "Kernel module $module is not loaded"
            print_info "Loading $module..."
            modprobe "$module" || print_error "Failed to load $module"
        fi
    done
}

# Function to check PAM configuration
check_pam_config() {
    print_info "Checking PAM configuration..."

    local pam_files=("/etc/pam.d/login" "/etc/pam.d/sudo" "/etc/pam.d/su")

    for file in "${pam_files[@]}"; do
        if [[ -f "$file" ]]; then
            if grep -q "fprint" "$file"; then
                print_success "PAM file $file has fingerprint configuration"
            else
                print_warning "PAM file $file missing fingerprint configuration"
            fi
        else
            print_warning "PAM file $file not found"
        fi
    done
}

# Function to test fingerprint enrollment
test_enrollment() {
    print_info "Testing fingerprint enrollment..."

    if command -v fprintd-enroll &> /dev/null; then
        print_info "fprintd-enroll is available"
        print_info "To enroll a fingerprint, run: fprintd-enroll"
        print_info "To test authentication, run: fprintd-verify"
    else
        print_error "fprintd-enroll not found"
    fi
}

# Function to show troubleshooting tips
show_troubleshooting() {
    print_info "Troubleshooting tips:"
    echo "1. Make sure your fingerprint reader is connected via USB"
    echo "2. Check if the device is recognized: lsusb"
    echo "3. Verify services are running: systemctl status fprintd"
    echo "4. Check system logs: journalctl -u fprintd"
    echo "5. Test device detection: fprintd-list"
    echo "6. Enroll fingerprint: fprintd-enroll"
    echo "7. Test authentication: fprintd-verify"
    echo ""
    echo "Common vendor IDs:"
    echo "  - 06cb: Synaptics"
    echo "  - 27c6: Goodix"
    echo "  - 138a: Validity"
    echo "  - 0483: STMicroelectronics"
    echo "  - 1c7a: EgisTec"
}

# Main function
main() {
    print_info "Fingerprint Reader Setup Script for NixOS"
    print_info "=========================================="

    check_root
    check_services
    check_devices
    check_kernel_modules
    check_pam_config
    test_enrollment

    echo ""
    show_troubleshooting

    print_success "Setup check completed!"
}

# Run main function
main "$@"