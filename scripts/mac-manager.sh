#!/usr/bin/env bash
# MAC Address Management and Spoofing Script for NixOS
# Provides comprehensive network interface MAC address manipulation

set -euo pipefail

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

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root for network interface manipulation"
        print_info "Usage: sudo $0 [command]"
        exit 1
    fi
}

# Get list of network interfaces
get_interfaces() {
    local interface_type="$1"
    case "$interface_type" in
        "wifi"|"wireless")
            iw dev | awk '$1=="Interface"{print $2}' 2>/dev/null || true
            ;;
        "ethernet"|"wired")
            find /sys/class/net -type l -not -name lo -exec basename {} \; | grep -E '^(eth|enp|ens)' 2>/dev/null || true
            ;;
        "all")
            find /sys/class/net -type l -not -name lo -exec basename {} \;
            ;;
        *)
            print_error "Invalid interface type: $interface_type"
            exit 1
            ;;
    esac
}

# Generate random MAC address
generate_mac() {
    local prefix="${1:-02:00:00}"  # Default to locally administered unicast
    printf "%s:%02x:%02x:%02x\n" "$prefix" $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256))
}

# Get current MAC address of interface
get_current_mac() {
    local interface="$1"
    if [[ -d "/sys/class/net/$interface" ]]; then
        cat "/sys/class/net/$interface/address" 2>/dev/null || echo "unknown"
    else
        echo "interface_not_found"
    fi
}

# Get original/permanent MAC address
get_permanent_mac() {
    local interface="$1"
    if command -v ethtool &>/dev/null; then
        ethtool -P "$interface" 2>/dev/null | awk '{print $3}' || echo "unknown"
    else
        echo "ethtool_not_available"
    fi
}

# Change MAC address using different methods
change_mac_macchanger() {
    local interface="$1"
    local new_mac="$2"
    
    print_info "Using macchanger to set MAC address..."
    
    # Bring interface down
    ip link set "$interface" down
    
    if [[ "$new_mac" == "random" ]]; then
        macchanger -r "$interface"
    elif [[ "$new_mac" == "permanent" ]]; then
        macchanger -p "$interface"
    else
        macchanger -m "$new_mac" "$interface"
    fi
    
    # Bring interface back up
    ip link set "$interface" up
}

change_mac_iproute2() {
    local interface="$1"
    local new_mac="$2"
    
    print_info "Using ip command to set MAC address..."
    
    # Bring interface down
    ip link set "$interface" down
    
    # Set new MAC address
    ip link set dev "$interface" address "$new_mac"
    
    # Bring interface back up
    ip link set "$interface" up
}

# Main MAC changing function
change_mac() {
    local interface="$1"
    local new_mac="$2"
    local method="${3:-auto}"
    
    # Validate interface exists
    if [[ ! -d "/sys/class/net/$interface" ]]; then
        print_error "Interface $interface not found"
        return 1
    fi
    
    # Get current MAC
    local current_mac
    current_mac=$(get_current_mac "$interface")
    print_info "Current MAC for $interface: $current_mac"
    
    # Generate random MAC if requested
    if [[ "$new_mac" == "random" ]]; then
        new_mac=$(generate_mac)
        print_info "Generated random MAC: $new_mac"
    elif [[ "$new_mac" == "permanent" ]]; then
        new_mac=$(get_permanent_mac "$interface")
        print_info "Using permanent MAC: $new_mac"
    fi
    
    # Choose method
    case "$method" in
        "macchanger")
            if command -v macchanger &>/dev/null; then
                change_mac_macchanger "$interface" "$new_mac"
            else
                print_error "macchanger not found, falling back to ip command"
                change_mac_iproute2 "$interface" "$new_mac"
            fi
            ;;
        "iproute2")
            change_mac_iproute2 "$interface" "$new_mac"
            ;;
        "auto")
            if command -v macchanger &>/dev/null; then
                change_mac_macchanger "$interface" "$new_mac"
            else
                change_mac_iproute2 "$interface" "$new_mac"
            fi
            ;;
        *)
            print_error "Invalid method: $method"
            return 1
            ;;
    esac
    
    # Verify change
    sleep 1
    local final_mac
    final_mac=$(get_current_mac "$interface")
    
    if [[ "$final_mac" != "$current_mac" ]]; then
        print_success "MAC address changed successfully!"
        print_info "Interface: $interface"
        print_info "Old MAC:   $current_mac"
        print_info "New MAC:   $final_mac"
        
        # Restart NetworkManager to recognize the change
        if systemctl is-active NetworkManager &>/dev/null; then
            print_info "Restarting NetworkManager..."
            systemctl restart NetworkManager
        fi
    else
        print_error "MAC address change failed"
        return 1
    fi
}

# List all interfaces with their MAC addresses
list_interfaces() {
    print_info "Network Interfaces and MAC Addresses:"
    echo
    printf "%-15s %-18s %-18s %-10s\n" "Interface" "Current MAC" "Permanent MAC" "State"
    printf "%-15s %-18s %-18s %-10s\n" "---------" "-----------" "-------------" "-----"
    
    for interface in $(get_interfaces all); do
        local current_mac permanent_mac state
        current_mac=$(get_current_mac "$interface")
        permanent_mac=$(get_permanent_mac "$interface")
        
        if [[ -f "/sys/class/net/$interface/operstate" ]]; then
            state=$(cat "/sys/class/net/$interface/operstate")
        else
            state="unknown"
        fi
        
        printf "%-15s %-18s %-18s %-10s\n" "$interface" "$current_mac" "$permanent_mac" "$state"
    done
    echo
}

# Randomize all wireless interfaces
randomize_wireless() {
    print_info "Randomizing MAC addresses for all wireless interfaces..."
    
    local wifi_interfaces
    wifi_interfaces=$(get_interfaces wifi)
    
    if [[ -z "$wifi_interfaces" ]]; then
        print_warning "No wireless interfaces found"
        return 0
    fi
    
    for interface in $wifi_interfaces; do
        print_info "Randomizing MAC for wireless interface: $interface"
        change_mac "$interface" "random"
    done
}

# Restore original MAC addresses
restore_original() {
    local interface_type="${1:-all}"
    
    print_info "Restoring original MAC addresses for $interface_type interfaces..."
    
    local interfaces
    interfaces=$(get_interfaces "$interface_type")
    
    if [[ -z "$interfaces" ]]; then
        print_warning "No interfaces found for type: $interface_type"
        return 0
    fi
    
    for interface in $interfaces; do
        print_info "Restoring original MAC for: $interface"
        change_mac "$interface" "permanent"
    done
}

# Show NetworkManager MAC randomization status
show_nm_status() {
    print_info "NetworkManager MAC Randomization Status:"
    echo
    
    if ! command -v nmcli &>/dev/null; then
        print_warning "NetworkManager CLI (nmcli) not found"
        return 1
    fi
    
    # Show current connection MAC settings
    nmcli -t -f NAME,TYPE,DEVICE connection show --active | while IFS=: read -r name type device; do
        if [[ -n "$device" && "$device" != "--" ]]; then
            echo "Connection: $name ($type) on $device"
            
            # Get MAC address settings for this connection
            local wifi_mac ethernet_mac
            wifi_mac=$(nmcli -t -f 802-11-wireless.cloned-mac-address connection show "$name" 2>/dev/null || echo "not-set")
            ethernet_mac=$(nmcli -t -f 802-3-ethernet.cloned-mac-address connection show "$name" 2>/dev/null || echo "not-set")
            
            echo "  WiFi MAC setting: $wifi_mac"
            echo "  Ethernet MAC setting: $ethernet_mac"
            echo
        fi
    done
}

# Configure NetworkManager for better MAC randomization
configure_nm_randomization() {
    print_info "Configuring enhanced NetworkManager MAC randomization..."
    
    local nm_config="/etc/NetworkManager/conf.d/99-privacy.conf"
    
    cat > "$nm_config" << 'EOF'
# Enhanced MAC address randomization for privacy
[main]
# Use systemd-resolved for DNS
dns=systemd-resolved

[connection]
# Default MAC randomization settings for new connections
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random

[device]
# Randomize MAC during WiFi scanning
wifi.scan-rand-mac-address=yes

# MAC randomization for different connection states
[connection-mac-randomization]
# Randomize on every connection
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random

[logging]
# Reduce logging for privacy
level=WARN
EOF

    print_success "NetworkManager privacy configuration created: $nm_config"
    print_info "Restarting NetworkManager to apply changes..."
    systemctl restart NetworkManager
    
    print_success "NetworkManager MAC randomization configured!"
}

# Show usage information
show_usage() {
    cat << EOF
MAC Address Management Script

USAGE:
    sudo $0 <command> [arguments]

COMMANDS:
    list                          - List all network interfaces and their MAC addresses
    change <interface> <mac>      - Change MAC address of specific interface
    random <interface>            - Set random MAC for specific interface  
    randomize-wifi               - Randomize MAC addresses for all WiFi interfaces
    restore [interface_type]     - Restore original MAC addresses (all/wifi/ethernet)
    generate                     - Generate a random MAC address
    nm-status                    - Show NetworkManager MAC randomization status
    nm-configure                 - Configure NetworkManager for enhanced MAC randomization
    
EXAMPLES:
    sudo $0 list
    sudo $0 change wlan0 02:00:00:aa:bb:cc
    sudo $0 random wlan0
    sudo $0 randomize-wifi
    sudo $0 restore wifi
    sudo $0 nm-configure

NOTES:
    - MAC addresses starting with 02:xx:xx:xx:xx:xx are locally administered
    - Random MAC generation avoids multicast addresses
    - NetworkManager automatically handles some MAC randomization
    - Changes may require NetworkManager restart for full effect

EOF
}

# Main script logic
main() {
    local command="${1:-help}"
    
    case "$command" in
        "list"|"ls")
            list_interfaces
            ;;
        "change")
            check_root
            if [[ $# -lt 3 ]]; then
                print_error "Usage: $0 change <interface> <mac_address>"
                exit 1
            fi
            change_mac "$2" "$3"
            ;;
        "random")
            check_root
            if [[ $# -lt 2 ]]; then
                print_error "Usage: $0 random <interface>"
                exit 1
            fi
            change_mac "$2" "random"
            ;;
        "randomize-wifi"|"randomize-wireless")
            check_root
            randomize_wireless
            ;;
        "restore")
            check_root
            local iface_type="${2:-all}"
            restore_original "$iface_type"
            ;;
        "generate")
            echo "Generated MAC: $(generate_mac)"
            ;;
        "nm-status"|"nm-show")
            show_nm_status
            ;;
        "nm-configure"|"configure")
            check_root
            configure_nm_randomization
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
