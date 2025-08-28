#!/usr/bin/env bash
# Quick System Health Check Script
# Created for mahmoud-laptop NixOS hardened configuration

set -euo pipefail

echo "🔍 NixOS System Health Check - $(date)"
echo "================================================"

# System Status
echo "📊 System Status:"
echo "  • Hostname: $(hostname)"
echo "  • Uptime: $(uptime | cut -d',' -f1 | cut -d' ' -f3-)"
echo "  • Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# Failed Services Check
echo "🚨 Failed Services:"
failed_count=$(systemctl --failed --no-legend | wc -l)
if [ "$failed_count" -eq 0 ]; then
    echo "  ✅ No failed services detected"
else
    echo "  ❌ $failed_count failed services found:"
    systemctl --failed --no-pager --no-legend
fi
echo ""

# Memory Usage
echo "💾 Memory Usage:"
free -h | grep -E "^Mem|^Swap" | while IFS= read -r line; do
    echo "  • $line"
done
echo ""

# Disk Usage
echo "💿 Disk Usage (>80% usage highlighted):"
df -h | awk 'NR==1 || $5+0 > 80 {print "  • " $0}'
if [ "$(df -h | awk 'NR>1 && $5+0 > 80' | wc -l)" -eq 0 ]; then
    echo "  ✅ All filesystems under 80% usage"
fi
echo ""

# Network Connectivity
echo "🌐 Network Status:"
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "  ✅ Internet connectivity working"
else
    echo "  ❌ Internet connectivity issues detected"
fi

if systemctl is-active NetworkManager >/dev/null 2>&1; then
    echo "  ✅ NetworkManager service active"
else
    echo "  ❌ NetworkManager service issues"
fi
echo ""

# Storage Performance
echo "🗄️  SSD2 Bind Mounts:"
for mount in /tmp /var; do
    if mountpoint -q "$mount" 2>/dev/null; then
        target=$(findmnt -n -o TARGET "$mount" 2>/dev/null || echo "unknown")
        echo "  ✅ $mount is mounted (target: $target)"
    else
        echo "  ⚠️  $mount may not be properly mounted"
    fi
done
echo ""

# Recent Errors (last 24h)
echo "🔍 Recent Critical Errors (last 24h):"
error_count=$(journalctl --since "24 hours ago" --priority=err --no-pager -q | wc -l)
if [ "$error_count" -eq 0 ]; then
    echo "  ✅ No critical errors in last 24 hours"
else
    echo "  ⚠️  $error_count critical errors found in last 24 hours"
    echo "  Run: journalctl --since '24 hours ago' --priority=err for details"
fi
echo ""

# Nix Store Status
echo "📦 Nix Store Status:"
store_size=$(du -sh /nix/store 2>/dev/null | cut -f1 || echo "unknown")
echo "  • Store size: $store_size"

# Check last garbage collection
if [ -f /nix/var/log/nix/gc.log ]; then
    last_gc=$(stat -c %y /nix/var/log/nix/gc.log 2>/dev/null | cut -d' ' -f1 || echo "unknown")
    echo "  • Last garbage collection: $last_gc"
else
    echo "  • Garbage collection: Not yet run"
fi
echo ""

# Security Status
echo "🛡️  Security Status:"
if systemctl is-active apparmor >/dev/null 2>&1; then
    echo "  ✅ AppArmor active"
else
    echo "  ⚠️  AppArmor not active"
fi

if systemctl is-active auditd >/dev/null 2>&1; then
    echo "  ✅ Audit daemon active"
else
    echo "  ⚠️  Audit daemon not active"
fi

if systemctl is-active systemd-resolved >/dev/null 2>&1; then
    echo "  ✅ systemd-resolved active"
else
    echo "  ⚠️  systemd-resolved not active"
fi
echo ""

echo "📋 Summary:"
if [ "$failed_count" -eq 0 ] && [ "$error_count" -lt 5 ]; then
    echo "  🎉 System is running optimally!"
else
    echo "  ⚠️  Some issues detected - review above output"
fi

echo ""
echo "🔧 Quick Commands:"
echo "  • Check logs: journalctl -f"
echo "  • Check services: systemctl status"
echo "  • Check security: sudo aa-status"
echo "  • Update system: nixos-rebuild switch --flake /etc/nixos#mahmoud-laptop"
echo ""
echo "Health check completed at $(date)"
