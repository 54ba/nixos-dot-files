#!/run/current-system/sw/bin/bash

# NixOS Enhanced Service Manager
# Provides easy management for all custom NixOS module services

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE} NixOS Service Manager${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

# Define service groups
declare -A SERVICE_GROUPS
SERVICE_GROUPS=(
    ["ai"]="ai-orchestrator ollama screen-analyzer audio-analyzer decision-engine model-manager feedback-collector"
    ["data"]="data-pipeline-api data-collector data-processor analysis-engine data-retention"
    ["health"]="health-monitor ssh-monitor"
    ["mobile"]="mobile-web-interface mobile-notifications uxplay"
    ["remote"]="sshd fail2ban mosh"
    ["core"]="NetworkManager systemd-resolved gdm pipewire"
)

# Function to show service status
show_service_status() {
    local service=$1
    local status=$(systemctl is-active "$service" 2>/dev/null || echo "inactive")
    local enabled=$(systemctl is-enabled "$service" 2>/dev/null || echo "disabled")
    
    case $status in
        "active")
            print_status $GREEN "✓ $service: active ($enabled)"
            ;;
        "inactive")
            print_status $YELLOW "○ $service: inactive ($enabled)"
            ;;
        "failed")
            print_status $RED "✗ $service: failed ($enabled)"
            ;;
        *)
            print_status $PURPLE "? $service: $status ($enabled)"
            ;;
    esac
}

# Function to show group status
show_group_status() {
    local group=$1
    local services=${SERVICE_GROUPS[$group]}
    
    print_status $CYAN "\n📦 $group Services:"
    echo "   ----------------------------------------"
    
    for service in $services; do
        show_service_status "$service"
    done
}

# Function to manage services
manage_service() {
    local action=$1
    local service=$2
    
    case $action in
        "start")
            print_status $BLUE "Starting $service..."
            systemctl start "$service"
            ;;
        "stop")
            print_status $BLUE "Stopping $service..."
            systemctl stop "$service"
            ;;
        "restart")
            print_status $BLUE "Restarting $service..."
            systemctl restart "$service"
            ;;
        "enable")
            print_status $BLUE "Enabling $service..."
            systemctl enable "$service"
            ;;
        "disable")
            print_status $BLUE "Disabling $service..."
            systemctl disable "$service"
            ;;
        "logs")
            print_status $BLUE "Showing logs for $service..."
            journalctl -u "$service" -f --lines=50
            ;;
        "status")
            print_status $BLUE "Status for $service:"
            systemctl status "$service"
            ;;
    esac
}

# Function to manage service groups
manage_group() {
    local action=$1
    local group=$2
    local services=${SERVICE_GROUPS[$group]}
    
    print_status $CYAN "Managing $group services: $action"
    
    for service in $services; do
        if systemctl list-units --all | grep -q "$service.service"; then
            manage_service "$action" "$service"
        else
            print_status $YELLOW "⚠ Service $service not found, skipping..."
        fi
    done
}

# Function to show logs for all services
show_all_logs() {
    print_status $BLUE "Recent logs from all custom services:\n"
    
    for group in "${!SERVICE_GROUPS[@]}"; do
        local services=${SERVICE_GROUPS[$group]}
        for service in $services; do
            if systemctl is-active "$service" &>/dev/null; then
                echo -e "${CYAN}=== $service ===${NC}"
                journalctl -u "$service" --lines=3 --no-pager 2>/dev/null || true
                echo ""
            fi
        done
    done
}

# Function to show health status
show_health_status() {
    print_status $BLUE "🏥 System Health Overview:\n"
    
    # Check critical services
    critical_services=("systemd-resolved" "NetworkManager" "gdm" "dbus" "nix-daemon")
    for service in "${critical_services[@]}"; do
        show_service_status "$service"
    done
    
    echo ""
    print_status $BLUE "📊 Resource Usage:"
    echo "   ----------------------------------------"
    
    # Memory usage
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", ($3/$2)*100}')
    print_status $GREEN "   Memory: ${mem_usage}%"
    
    # Disk usage for critical mounts
    df -h | grep -E "(/$|/tmp|/var)" | while read line; do
        local usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        local mount=$(echo "$line" | awk '{print $6}')
        if [ "$usage" -gt 85 ]; then
            print_status $RED "   Disk $mount: ${usage}%"
        elif [ "$usage" -gt 70 ]; then
            print_status $YELLOW "   Disk $mount: ${usage}%"
        else
            print_status $GREEN "   Disk $mount: ${usage}%"
        fi
    done
    
    # Load average
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    print_status $GREEN "   Load: $load"
}

# Function to run WiFi connectivity commands
wifi_management() {
    local action=$1
    
    case $action in
        "scan")
            print_status $BLUE "Scanning for WiFi networks..."
            nmcli device wifi list
            ;;
        "connect")
            if [ -z "${2:-}" ]; then
                echo "Usage: $0 wifi connect <SSID>"
                exit 1
            fi
            local ssid="$2"
            print_status $BLUE "Connecting to WiFi network: $ssid"
            nmcli device wifi connect "$ssid"
            ;;
        "disconnect")
            print_status $BLUE "Disconnecting from WiFi..."
            nmcli device disconnect wifi
            ;;
        "status")
            print_status $BLUE "WiFi Status:"
            nmcli device show | grep -E "(DEVICE|TYPE|STATE|CONNECTION)"
            echo ""
            print_status $BLUE "Active connections:"
            nmcli connection show --active
            ;;
        "saved")
            print_status $BLUE "Saved WiFi networks:"
            nmcli connection show | grep wifi
            ;;
        *)
            echo "WiFi commands: scan, connect <SSID>, disconnect, status, saved"
            ;;
    esac
}

# Main help function
show_help() {
    print_header
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  status                    - Show all services status"
    echo "  health                    - Show system health overview"
    echo "  logs                      - Show recent logs from all services"
    echo "  wifi <action>            - WiFi management (scan/connect/disconnect/status)"
    echo ""
    echo "Service Management:"
    echo "  group <action> <group>   - Manage service group"
    echo "  service <action> <name>  - Manage individual service"
    echo ""
    echo "Actions: start, stop, restart, enable, disable, logs, status"
    echo ""
    echo "Service Groups:"
    for group in "${!SERVICE_GROUPS[@]}"; do
        echo "  $group: ${SERVICE_GROUPS[$group]}"
    done
    echo ""
    echo "Examples:"
    echo "  $0 status                           # Show all service status"
    echo "  $0 group start ai                   # Start all AI services"
    echo "  $0 service logs health-monitor      # Show health monitor logs"
    echo "  $0 wifi scan                        # Scan for WiFi networks"
    echo "  $0 wifi connect MyNetwork           # Connect to WiFi"
}

# Main script logic
main() {
    case ${1:-} in
        "status")
            print_header
            for group in "${!SERVICE_GROUPS[@]}"; do
                show_group_status "$group"
            done
            ;;
        "health")
            print_header
            show_health_status
            ;;
        "logs")
            print_header
            show_all_logs
            ;;
        "wifi")
            shift
            wifi_management "$@"
            ;;
        "group")
            if [ $# -lt 3 ]; then
                echo "Usage: $0 group <action> <group>"
                exit 1
            fi
            manage_group "$2" "$3"
            ;;
        "service")
            if [ $# -lt 3 ]; then
                echo "Usage: $0 service <action> <service>"
                exit 1
            fi
            manage_service "$2" "$3"
            ;;
        "help"|"-h"|"--help"|"")
            show_help
            ;;
        *)
            echo "Unknown command: ${1:-}"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
