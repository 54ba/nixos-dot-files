#!/usr/bin/env bash
# NixOS System Maintenance Script
# Automated maintenance tasks for hardened mahmoud-laptop configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/nixos-maintenance.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "🔧 Starting NixOS System Maintenance"
log "================================================"

# 1. System Health Check
log "📊 Running system health check..."
if [[ -x "$SCRIPT_DIR/quick-health-check.sh" ]]; then
    "$SCRIPT_DIR/quick-health-check.sh" >> "$LOG_FILE" 2>&1
else
    log "❌ Health check script not found"
fi

# 2. Clean up old generations (keep last 5)
log "🗑️  Cleaning up old generations..."
if command -v nix-collect-garbage >/dev/null 2>&1; then
    # Keep last 5 generations
    sudo nix-collect-garbage --delete-older-than 7d
    log "✅ Generation cleanup completed"
else
    log "❌ nix-collect-garbage not available"
fi

# 3. Optimize Nix store
log "🔄 Optimizing Nix store..."
if command -v nix-store >/dev/null 2>&1; then
    nix-store --optimise
    log "✅ Store optimization completed"
else
    log "❌ nix-store not available"
fi

# 4. Check for system updates (dry run)
log "📦 Checking for system updates..."
if [[ -f "/etc/nixos/flake.nix" ]]; then
    cd /etc/nixos
    # Update flake inputs
    nix flake update --commit-lock-file 2>&1 | tee -a "$LOG_FILE" || log "⚠️  Flake update failed"
    
    # Show what would be updated
    nixos-rebuild dry-run --flake .#mahmoud-laptop 2>&1 | tail -10 | tee -a "$LOG_FILE" || log "⚠️  Dry run failed"
    log "✅ Update check completed"
else
    log "❌ Flake configuration not found"
fi

# 5. Clean systemd journal logs (keep 1 week)
log "📋 Cleaning old logs..."
if command -v journalctl >/dev/null 2>&1; then
    sudo journalctl --vacuum-time=7d
    log "✅ Journal cleanup completed"
else
    log "❌ journalctl not available"
fi

# 6. Verify critical services
log "🛡️  Verifying critical services..."
critical_services=("NetworkManager" "systemd-resolved" "display-manager" "docker" "sshd")

all_good=true
for service in "${critical_services[@]}"; do
    if systemctl is-active "$service" >/dev/null 2>&1; then
        log "✅ $service is active"
    else
        log "❌ $service is not active"
        all_good=false
    fi
done

if [[ "$all_good" == "true" ]]; then
    log "✅ All critical services are running"
else
    log "⚠️  Some critical services have issues"
fi

# 7. Check disk usage
log "💿 Checking disk usage..."
df -h | awk 'NR==1 {print "  • " $0} NR>1 && $5+0 > 85 {print "  ⚠️  " $0 " (HIGH USAGE)"}' | tee -a "$LOG_FILE"

# 8. System security check
log "🔒 Security status check..."
if systemctl is-active apparmor >/dev/null 2>&1; then
    log "✅ AppArmor is active"
else
    log "❌ AppArmor is not active"
fi

if systemctl is-active auditd >/dev/null 2>&1; then
    log "✅ Audit daemon is active"
else
    log "❌ Audit daemon is not active"
fi

# 9. Check for failed systemd units
log "🚨 Checking for failed services..."
failed_count=$(systemctl --failed --no-legend | wc -l)
if [[ "$failed_count" -eq 0 ]]; then
    log "✅ No failed services"
else
    log "❌ $failed_count failed services found:"
    systemctl --failed --no-pager --no-legend | tee -a "$LOG_FILE"
fi

# 10. Final recommendations
log "📋 Maintenance Summary:"
log "  • Log file: $LOG_FILE"
log "  • Next maintenance recommended: $(date -d '+1 week')"

# Check if update is needed
log ""
log "🎯 Recommendations:"
log "  • Review any failed services above"
log "  • Consider running system update if dry-run showed changes"
log "  • Monitor disk usage (currently $(df -h / | awk 'NR==2 {print $5}')"

# Create quick maintenance alias suggestions
log ""
log "🔧 Quick maintenance commands:"
log "  • sudo $0                    # Run this maintenance script"
log "  • journalctl -f              # Follow system logs"
log "  • systemctl --failed         # Check failed services"
log "  • df -h                      # Check disk usage"
log "  • nixos-rebuild switch --flake /etc/nixos#mahmoud-laptop  # Apply updates"

log ""
log "🎉 System maintenance completed at $(date)"
log "================================================"

# Return exit code based on system health
if [[ "$failed_count" -eq 0 ]]; then
    exit 0
else
    exit 1
fi
