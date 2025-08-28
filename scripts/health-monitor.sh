#!/usr/bin/env bash
# System Health Monitor for NixOS
# Monitors SMART attributes, GPU errors, and system stability

set -euo pipefail

LOG_FILE="/var/log/health-monitor.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

check_storage() {
    log "Checking storage health..."
    
    # Check all storage devices
    for device in /dev/sd? /dev/nvme?n?; do
        if [[ -e "$device" ]]; then
            # Check SMART health
            if smartctl -H "$device" | grep -q "PASSED"; then
                log "✓ $device: SMART health OK"
            else
                log "⚠ $device: SMART health FAILED"
                notify-send "Storage Warning" "$device SMART health failed" --urgency=critical 2>/dev/null || true
            fi
            
            # Check for reallocated sectors
            REALLOCATED=$(smartctl -A "$device" | awk '/Reallocated_Sector_Ct/ {print $10}' || echo "0")
            if [[ "$REALLOCATED" -gt 0 ]]; then
                log "⚠ $device: $REALLOCATED reallocated sectors detected"
                notify-send "Storage Warning" "$device has $REALLOCATED reallocated sectors" --urgency=normal 2>/dev/null || true
            fi
        fi
    done
}

check_gpu() {
    log "Checking GPU health..."
    
    # Check for nouveau errors
    NOUVEAU_ERRORS=$(dmesg | grep -c "nouveau.*error" || echo "0")
    if [[ "$NOUVEAU_ERRORS" -gt 10 ]]; then
        log "⚠ GPU: $NOUVEAU_ERRORS nouveau errors detected"
        notify-send "GPU Warning" "Multiple GPU errors detected" --urgency=normal 2>/dev/null || true
    fi
    
    # Check for channel errors
    CHANNEL_ERRORS=$(dmesg | grep -c "channel.*killed" || echo "0")
    if [[ "$CHANNEL_ERRORS" -gt 5 ]]; then
        log "⚠ GPU: $CHANNEL_ERRORS channel errors detected"
    fi
}

check_systemd() {
    log "Checking systemd health..."
    
    # Check for failed services
    FAILED_UNITS=$(systemctl --failed --no-legend | wc -l)
    if [[ "$FAILED_UNITS" -gt 1 ]]; then  # Allow 1 for home-manager
        log "⚠ SystemD: $FAILED_UNITS failed units detected"
        systemctl --failed --no-legend | while read -r unit; do
            log "  Failed unit: $unit"
        done
    else
        log "✓ SystemD: All critical services running"
    fi
}

check_memory() {
    log "Checking memory usage..."
    
    # Check memory usage
    MEMORY_USAGE=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
    if [[ "$MEMORY_USAGE" -gt 90 ]]; then
        log "⚠ Memory: ${MEMORY_USAGE}% usage detected"
        notify-send "Memory Warning" "Memory usage is ${MEMORY_USAGE}%" --urgency=normal 2>/dev/null || true
    else
        log "✓ Memory: ${MEMORY_USAGE}% usage OK"
    fi
}

check_disk_space() {
    log "Checking disk space..."
    
    # Check root partition
    ROOT_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ "$ROOT_USAGE" -gt 85 ]]; then
        log "⚠ Root partition: ${ROOT_USAGE}% full"
        notify-send "Disk Warning" "Root partition is ${ROOT_USAGE}% full" --urgency=normal 2>/dev/null || true
    fi
    
    # Check boot partition  
    BOOT_USAGE=$(df /boot | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ "$BOOT_USAGE" -gt 80 ]]; then
        log "⚠ Boot partition: ${BOOT_USAGE}% full"
        notify-send "Boot Warning" "Boot partition is ${BOOT_USAGE}% full - old generations may need cleanup" --urgency=normal 2>/dev/null || true
    fi
}

# Main execution
main() {
    log "Starting health check..."
    
    check_storage
    check_gpu  
    check_systemd
    check_memory
    check_disk_space
    
    log "Health check completed"
    
    # Rotate log file if it gets too large (>10MB)
    if [[ -f "$LOG_FILE" && $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE") -gt 10485760 ]]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        log "Log file rotated"
    fi
}

# Run main function
main "$@"
