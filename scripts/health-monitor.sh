#!/nix/store/smkzrg2vvp3lng3hq7v9svfni5mnqjh2-bash-interactive-5.2p37/bin/bash

# System Health Monitor Script
LOG_FILE="/var/log/health-monitor.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Function to log messages
log_message() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

# Function to check disk usage
check_disk() {
    log_message "=== Disk Usage Check ==="
df -h | grep -E '^/dev/' | while read line; do
    usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    mount=$(echo "$line" | awk '{print $6}')
    if [ "$usage" -gt 85 ]; then
        log_message "WARNING: Disk usage on $mount is $usage%"
    fi
done

}

# Function to check memory usage
check_memory() {
    log_message "=== Memory Usage Check ==="
mem_usage=$(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}')
if [ "$mem_usage" -gt 90 ]; then
    log_message "WARNING: Memory usage is $mem_usage%"
else
    log_message "Memory usage: $mem_usage%"
fi

}

# Function to check critical services
check_services() {
    log_message "=== Critical Services Check ==="
critical_services=(
    "systemd-resolved"
    "NetworkManager"
    "gdm"
    "dbus"
    "nix-daemon"
)

for service in "${critical_services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        log_message "✓ $service is running"
    else
        log_message "✗ WARNING: $service is not running"
    fi
done

}

# Function to check network connectivity
check_network() {
    log_message "=== Network Connectivity Check ==="
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    log_message "✓ Network connectivity is OK"
else
    log_message "✗ WARNING: Network connectivity issue"
fi

}

# Function to check failed systemd units
check_failed_units() {
    log_message "=== Failed Units Check ==="
    failed_units=$(systemctl --failed --no-legend | wc -l)
    if [ "$failed_units" -gt 0 ]; then
        log_message "WARNING: $failed_units failed systemd units found"
        systemctl --failed --no-legend | while read unit; do
            log_message "Failed unit: $unit"
        done
    else
        log_message "✓ No failed systemd units"
    fi
}

# Function to check system load
check_load() {
    log_message "=== System Load Check ==="
    load=$(uptime | awk -F'load average:' '{ print $2 }' | awk '{ print $1 }' | sed 's/,//')
    cpu_count=$(nproc)
    log_message "System load: $load (CPUs: $cpu_count)"
}

# Main execution
log_message "Starting health monitoring check"
check_disk
check_memory
check_services
check_network
check_failed_units
check_load
log_message "Health monitoring check completed"
log_message "=================================="
