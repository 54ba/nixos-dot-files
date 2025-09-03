#!/nix/store/smkzrg2vvp3lng3hq7v9svfni5mnqjh2-bash-interactive-5.2p37/bin/bash

# NixOS Generation Manager and Rescue Tool
# Provides advanced generation management with sorting and filtering

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/nixos-rescue.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Get generation information with enhanced metadata
get_generation_info() {
    local gen_path="$1"
    local gen_num=$(basename "$gen_path" | cut -d- -f2)
    local gen_date=""
    local gen_kernel=""
    local gen_nixos_version=""
    local gen_status="unknown"
    
    if [[ -f "$gen_path/nixos-version" ]]; then
        gen_nixos_version=$(cat "$gen_path/nixos-version")
    fi
    
    if [[ -f "$gen_path/kernel" ]]; then
        gen_kernel=$(readlink "$gen_path/kernel" | sed 's/.*linux-//' | sed 's/-.*//')
    fi
    
    # Get creation date from filesystem
    if [[ -e "$gen_path" ]]; then
        gen_date=$(stat -c %Y "$gen_path")
    fi
    
    # Check if generation is bootable
    if [[ -f "$gen_path/init" && -f "$gen_path/kernel" ]]; then
        gen_status="working"
    else
        gen_status="broken"
    fi
    
    # Check if it's the current generation
    if [[ "$gen_path" -ef "/nix/var/nix/profiles/system" ]]; then
        gen_status="current"
    fi
    
    echo "$gen_num|$gen_date|$gen_kernel|$gen_nixos_version|$gen_status|$gen_path"
}

# List all generations with detailed information
list_generations() {
    local sort_by="${1:-date}"
    local group_by="${2:-week}"
    local filter_status="${3:-all}"
    
    log "Listing generations (sort: $sort_by, group: $group_by, filter: $filter_status)"
    
    echo "=== NixOS Generation Analysis ==="
    echo "Current time: $(date)"
    echo "System: $(uname -a)"
    echo ""
    
    local generations=()
    local current_gen=""
    
    # Find current generation
    if [[ -L "/nix/var/nix/profiles/system" ]]; then
        current_gen=$(readlink "/nix/var/nix/profiles/system")
    fi
    
    # Collect all generation information
    for gen_path in /nix/var/nix/profiles/system-*-link; do
        if [[ -e "$gen_path" ]]; then
            local gen_info=$(get_generation_info "$gen_path")
            generations+=("$gen_info")
        fi
    done
    
    # Sort generations
    case "$sort_by" in
        "date")
            IFS=$'\n' generations=($(printf '%s\n' "${generations[@]}" | sort -t'|' -k2 -n -r))
            ;;
        "status")
            IFS=$'\n' generations=($(printf '%s\n' "${generations[@]}" | sort -t'|' -k5))
            ;;
        "name")
            IFS=$'\n' generations=($(printf '%s\n' "${generations[@]}" | sort -t'|' -k1 -n -r))
            ;;
    esac
    
    # Group and display generations
    local current_group=""
    local group_count=0
    
    for gen_info in "${generations[@]}"; do
        IFS='|' read -r gen_num gen_date gen_kernel gen_nixos_version gen_status gen_path <<< "$gen_info"
        
        # Filter by status if requested
        if [[ "$filter_status" != "all" && "$gen_status" != "$filter_status" ]]; then
            continue
        fi
        
        # Determine group
        local group_name=""
        local date_readable=$(date -d "@$gen_date" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")
        local date_group=""
        
        case "$group_by" in
            "day")
                date_group=$(date -d "@$gen_date" '+%Y-%m-%d' 2>/dev/null || echo "unknown")
                group_name="Day: $date_group"
                ;;
            "week")
                date_group=$(date -d "@$gen_date" '+%Y-W%U' 2>/dev/null || echo "unknown")
                group_name="Week: $date_group"
                ;;
            "month")
                date_group=$(date -d "@$gen_date" '+%Y-%m' 2>/dev/null || echo "unknown")
                group_name="Month: $date_group"
                ;;
            "status")
                group_name="Status: $gen_status"
                date_group="$gen_status"
                ;;
        esac
        
        # Print group header if changed
        if [[ "$date_group" != "$current_group" ]]; then
            if [[ $group_count -gt 0 ]]; then
                echo ""
            fi
            echo "=== $group_name ==="
            current_group="$date_group"
            ((group_count++))
        fi
        
        # Format status with colors
        local status_display=""
        case "$gen_status" in
            "current")
                status_display="[CURRENT]"
                ;;
            "working")
                status_display="[WORKING]"
                ;;
            "broken")
                status_display="[BROKEN] "
                ;;
            *)
                status_display="[UNKNOWN]"
                ;;
        esac
        
        # Display generation info
        printf "  Gen %-3s %s %s\n" "$gen_num" "$status_display" "$date_readable"
        printf "          Kernel: %-20s NixOS: %s\n" "$gen_kernel" "$gen_nixos_version"
        printf "          Path: %s\n" "$gen_path"
        
        # Add current generation marker
        if [[ "$gen_path" -ef "$current_gen" ]]; then
            printf "          >>> CURRENTLY ACTIVE <<<\n"
        fi
        
        echo ""
    done
    
    # Summary
    local total_gens=${#generations[@]}
    local working_gens=$(printf '%s\n' "${generations[@]}" | grep -c "|working|" || true)
    local broken_gens=$(printf '%s\n' "${generations[@]}" | grep -c "|broken|" || true)
    
    echo "=== Summary ==="
    echo "Total generations: $total_gens"
    echo "Working: $working_gens, Broken: $broken_gens"
    echo "Groups found: $group_count"
}

# Rollback to a specific generation
rollback_generation() {
    local target_gen="${1:-previous}"
    
    log "Attempting rollback to: $target_gen"
    
    if [[ "$target_gen" == "previous" ]]; then
        echo "Rolling back to previous generation..."
        nixos-rebuild switch --rollback
    elif [[ "$target_gen" =~ ^[0-9]+$ ]]; then
        echo "Rolling back to generation $target_gen..."
        local gen_path="/nix/var/nix/profiles/system-$target_gen-link"
        if [[ -e "$gen_path" ]]; then
            nix-env -p /nix/var/nix/profiles/system --switch-generation "$target_gen"
            "$gen_path/bin/switch-to-configuration" switch
        else
            echo "ERROR: Generation $target_gen not found!"
            return 1
        fi
    else
        echo "ERROR: Invalid generation specifier: $target_gen"
        return 1
    fi
    
    log "Rollback completed successfully"
}

# Cleanup old generations
cleanup_generations() {
    local keep_count="${1:-10}"
    local dry_run="${2:-false}"
    
    log "Generation cleanup: keeping $keep_count generations (dry_run: $dry_run)"
    
    echo "=== Generation Cleanup ==="
    echo "Keeping $keep_count most recent generations..."
    
    if [[ "$dry_run" == "true" ]]; then
        echo "DRY RUN - No changes will be made"
        nix-env -p /nix/var/nix/profiles/system --list-generations | tail -n +$((keep_count + 1))
    else
        nix-collect-garbage -d
        nix-env -p /nix/var/nix/profiles/system --delete-generations +$keep_count
        echo "Cleanup completed"
    fi
}

# System diagnostics
system_diagnostics() {
    log "Running system diagnostics"
    
    echo "=== System Diagnostics ==="
    echo "Timestamp: $(date)"
    echo ""
    
    echo "--- System Information ---"
    uname -a
    echo "NixOS Version: $(nixos-version 2>/dev/null || echo 'Unknown')"
    echo "Uptime: $(uptime)"
    echo ""
    
    echo "--- Memory Usage ---"
    free -h
    echo ""
    
    echo "--- Disk Usage ---"
    df -h
    echo ""
    
    echo "--- Nix Store ---"
    du -sh /nix/store 2>/dev/null || echo "Cannot access /nix/store"
    echo ""
    
    echo "--- Failed Services ---"
    systemctl --failed --no-legend || echo "No failed services"
    echo ""
    
    echo "--- Last Boot Messages ---"
    journalctl --boot --no-pager --lines=20 --priority=err 2>/dev/null || echo "Cannot access journal"
    echo ""
    
    echo "--- Generation Status ---"
    list_generations date week working | head -20
}

# Main function
main() {
    local action="${1:-help}"
    shift 2>/dev/null || true
    
    case "$action" in
        "list"|"list-generations")
            list_generations "$@"
            ;;
        "rollback")
            rollback_generation "$@"
            ;;
        "cleanup")
            cleanup_generations "$@"
            ;;
        "diagnostics"|"diag")
            system_diagnostics
            ;;
        "help"|*)
            echo "NixOS Generation Manager and Rescue Tool"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  list [sort] [group] [filter]  - List generations"
            echo "    sort: date, status, name (default: date)"
            echo "    group: day, week, month, status (default: week)"
            echo "    filter: all, working, broken, current (default: all)"
            echo ""
            echo "  rollback [target]             - Rollback to generation"
            echo "    target: previous, or generation number (default: previous)"
            echo ""
            echo "  cleanup [keep] [dry-run]      - Clean old generations"
            echo "    keep: number to keep (default: 10)"
            echo "    dry-run: true/false (default: false)"
            echo ""
            echo "  diagnostics                   - Run system diagnostics"
            echo "  help                          - Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 list date week working     # Working generations by week"
            echo "  $0 rollback 42                # Rollback to generation 42"
            echo "  $0 cleanup 5 true             # Dry run cleanup keeping 5"
            ;;
    esac
}

# Run main function with all arguments
main "$@"
