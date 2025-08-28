#!/usr/bin/env bash

# System Automation Management Script
# Provides automation workflows for common system management tasks
# Compatible with NixOS and the automation-workflow module

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/lib/automation/logs"
CONFIG_DIR="/var/lib/automation/config"
WORKFLOWS_DIR="/var/lib/automation/workflows"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        ERROR)   echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
        WARN)    echo -e "${YELLOW}[WARN]${NC} $message" ;;
        INFO)    echo -e "${GREEN}[INFO]${NC} $message" ;;
        DEBUG)   echo -e "${BLUE}[DEBUG]${NC} $message" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
        *)       echo -e "$message" ;;
    esac
    
    # Also log to file
    mkdir -p "$LOG_DIR"
    echo "[$timestamp] [$level] $message" >> "$LOG_DIR/system-automation.log"
}

# Check if running as root for system operations
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log ERROR "This script must be run as root for system operations"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log INFO "Checking prerequisites..."
    
    # Check if NixOS
    if [[ ! -f /etc/nixos/configuration.nix ]]; then
        log ERROR "This script is designed for NixOS systems"
        exit 1
    fi
    
    # Check if automation module is enabled
    if ! nixos-option custom.automation-workflow.enable 2>/dev/null | grep -q true; then
        log WARN "automation-workflow module is not enabled in configuration"
    fi
    
    # Check required directories
    mkdir -p "$LOG_DIR" "$CONFIG_DIR" "$WORKFLOWS_DIR"
    
    log SUCCESS "Prerequisites check completed"
}

# System health check automation
system_health_check() {
    log INFO "Running automated system health check..."
    
    local report_file="$LOG_DIR/health-check-$(date +%Y%m%d-%H%M%S).json"
    
    # Collect system metrics
    cat > "$report_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "system": {
        "uptime": "$(uptime -p)",
        "load": "$(uptime | awk -F'load average:' '{print $2}' | xargs)",
        "memory": {
            "total": "$(free -h | awk 'NR==2{print $2}')",
            "used": "$(free -h | awk 'NR==2{print $3}')",
            "free": "$(free -h | awk 'NR==2{print $4}')",
            "usage_percent": $(free | awk 'NR==2{printf "%.2f", $3/$2*100}')
        },
        "disk": {
            "root_usage": "$(df -h / | awk 'NR==2{print $5}')",
            "root_free": "$(df -h / | awk 'NR==2{print $4}')"
        },
        "services": {
            "failed": $(systemctl --failed --no-legend | wc -l),
            "active": $(systemctl list-units --state=active --no-legend | wc -l)
        }
    }
}
EOF
    
    # Check for critical issues
    local memory_usage=$(free | awk 'NR==2{printf "%.0f", $3/$2*100}')
    local disk_usage=$(df / | awk 'NR==2{gsub(/%/,"",$5); print $5}')
    local failed_services=$(systemctl --failed --no-legend | wc -l)
    
    if (( memory_usage > 90 )); then
        log WARN "High memory usage: ${memory_usage}%"
    fi
    
    if (( disk_usage > 90 )); then
        log WARN "High disk usage: ${disk_usage}%"
    fi
    
    if (( failed_services > 0 )); then
        log WARN "Failed services detected: $failed_services"
        systemctl --failed --no-legend
    fi
    
    log SUCCESS "Health check completed. Report saved to $report_file"
}

# NixOS configuration management automation
nixos_management() {
    log INFO "Running NixOS configuration management..."
    
    # Backup current configuration
    local backup_dir="/var/lib/automation/backups/nixos/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    cp -r /etc/nixos/* "$backup_dir/"
    log INFO "Configuration backed up to $backup_dir"
    
    # Check configuration syntax
    log INFO "Checking NixOS configuration syntax..."
    if nixos-rebuild dry-run --flake /etc/nixos#mahmoud-laptop; then
        log SUCCESS "Configuration syntax is valid"
    else
        log ERROR "Configuration syntax error detected"
        return 1
    fi
    
    # Update flake inputs if requested
    if [[ "${1:-}" == "--update" ]]; then
        log INFO "Updating flake inputs..."
        cd /etc/nixos
        nix flake update
        log SUCCESS "Flake inputs updated"
    fi
    
    # Garbage collection
    log INFO "Running garbage collection..."
    nix-collect-garbage -d
    log SUCCESS "Garbage collection completed"
    
    # Store optimization
    log INFO "Optimizing Nix store..."
    nix store optimise
    log SUCCESS "Store optimization completed"
}

# Service automation management
service_management() {
    log INFO "Managing automation services..."
    
    # Check n8n service
    if systemctl is-active --quiet n8n; then
        log INFO "n8n service is running"
        
        # Check if n8n is accessible
        if curl -sf http://localhost:5678/healthz > /dev/null 2>&1; then
            log SUCCESS "n8n is accessible on port 5678"
        else
            log WARN "n8n service is running but not accessible"
        fi
    else
        log WARN "n8n service is not running"
    fi
    
    # Check Node-RED service
    if systemctl is-active --quiet node-red; then
        log INFO "Node-RED service is running"
        
        # Check if Node-RED is accessible
        if curl -sf http://localhost:1880 > /dev/null 2>&1; then
            log SUCCESS "Node-RED is accessible on port 1880"
        else
            log WARN "Node-RED service is running but not accessible"
        fi
    else
        log WARN "Node-RED service is not running"
    fi
    
    # Check PostgreSQL for workflow storage
    if systemctl is-active --quiet postgresql; then
        log SUCCESS "PostgreSQL is running for workflow storage"
    else
        log WARN "PostgreSQL is not running"
    fi
    
    # Check Redis for caching
    if systemctl is-active --quiet redis; then
        log SUCCESS "Redis is running for caching"
    else
        log INFO "Redis is not running (optional)"
    fi
}

# Workflow deployment automation
workflow_deployment() {
    local workflow_file="$1"
    
    if [[ ! -f "$workflow_file" ]]; then
        log ERROR "Workflow file not found: $workflow_file"
        return 1
    fi
    
    log INFO "Deploying workflow: $(basename "$workflow_file")"
    
    # Validate workflow format (basic JSON check)
    if ! jq empty "$workflow_file" 2>/dev/null; then
        log ERROR "Invalid JSON format in workflow file"
        return 1
    fi
    
    # Copy to workflows directory
    local workflow_name=$(basename "$workflow_file" .json)
    local deployed_file="$WORKFLOWS_DIR/$workflow_name-$(date +%Y%m%d-%H%M%S).json"
    cp "$workflow_file" "$deployed_file"
    
    log SUCCESS "Workflow deployed to $deployed_file"
    
    # If n8n is running, attempt to import
    if systemctl is-active --quiet n8n; then
        log INFO "Attempting to import workflow to n8n..."
        # Note: n8n CLI import would go here
        # This would require n8n CLI tools to be available
    fi
}

# Monitoring and alerting setup
setup_monitoring() {
    log INFO "Setting up automation monitoring..."
    
    # Create monitoring configuration
    cat > "$CONFIG_DIR/monitoring.conf" << EOF
# Automation Monitoring Configuration
LOG_LEVEL=INFO
HEALTH_CHECK_INTERVAL=300  # 5 minutes
ALERT_EMAIL=admin@localhost
WEBHOOK_URL=

# Thresholds
MEMORY_THRESHOLD=90
DISK_THRESHOLD=85
LOAD_THRESHOLD=5.0
EOF
    
    # Create systemd timer for regular health checks
    cat > /etc/systemd/system/automation-health-check.service << EOF
[Unit]
Description=Automation Health Check
After=network.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_DIR/system-automation.sh health-check
User=root
EOF
    
    cat > /etc/systemd/system/automation-health-check.timer << EOF
[Unit]
Description=Run automation health check every 5 minutes
Requires=automation-health-check.service

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Enable and start timer
    systemctl daemon-reload
    systemctl enable automation-health-check.timer
    systemctl start automation-health-check.timer
    
    log SUCCESS "Monitoring setup completed"
}

# API testing automation
api_testing() {
    local endpoint="$1"
    local method="${2:-GET}"
    local data="${3:-}"
    
    log INFO "Testing API endpoint: $method $endpoint"
    
    local timestamp=$(date -Iseconds)
    local test_file="$LOG_DIR/api-test-$(date +%Y%m%d-%H%M%S).json"
    
    # Perform API test with curl
    local start_time=$(date +%s%N)
    
    if [[ -n "$data" ]]; then
        response=$(curl -s -w "%{http_code}|%{time_total}" -X "$method" -H "Content-Type: application/json" -d "$data" "$endpoint" 2>/dev/null || echo "000|0")
    else
        response=$(curl -s -w "%{http_code}|%{time_total}" -X "$method" "$endpoint" 2>/dev/null || echo "000|0")
    fi
    
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    
    # Parse response
    local http_code=$(echo "$response" | grep -o '|[0-9]\{3\}|' | tr -d '|' || echo "000")
    local time_total=$(echo "$response" | grep -o '|[0-9.]*$' | tr -d '|' || echo "0")
    local body=$(echo "$response" | sed 's/|[0-9]\{3\}|[0-9.]*$//')
    
    # Create test report
    cat > "$test_file" << EOF
{
    "timestamp": "$timestamp",
    "test": {
        "endpoint": "$endpoint",
        "method": "$method",
        "data": "$data"
    },
    "response": {
        "status_code": $http_code,
        "time_total": $time_total,
        "duration_ms": $duration,
        "body_preview": "$(echo "$body" | head -c 100)"
    },
    "success": $(if (( http_code >= 200 && http_code < 300 )); then echo "true"; else echo "false"; fi)
}
EOF
    
    # Log results
    if (( http_code >= 200 && http_code < 300 )); then
        log SUCCESS "API test passed: HTTP $http_code in ${time_total}s"
    else
        log ERROR "API test failed: HTTP $http_code"
    fi
    
    log INFO "Test report saved to $test_file"
}

# Database backup automation
database_backup() {
    log INFO "Running database backup automation..."
    
    local backup_dir="/var/lib/automation/backups/databases/$(date +%Y%m%d)"
    mkdir -p "$backup_dir"
    
    # Backup PostgreSQL databases if running
    if systemctl is-active --quiet postgresql; then
        log INFO "Backing up PostgreSQL databases..."
        
        # Get list of databases
        local databases=$(sudo -u postgres psql -t -c "SELECT datname FROM pg_database WHERE NOT datistemplate AND datname != 'postgres';" | grep -v '^$' | xargs)
        
        for db in $databases; do
            local backup_file="$backup_dir/postgres_${db}_$(date +%H%M%S).sql"
            sudo -u postgres pg_dump "$db" > "$backup_file"
            gzip "$backup_file"
            log INFO "PostgreSQL database '$db' backed up to $backup_file.gz"
        done
    fi
    
    log SUCCESS "Database backup completed"
}

# Display help
show_help() {
    cat << EOF
System Automation Management Script

Usage: $0 <command> [options]

Commands:
    health-check          Run system health check
    nixos-manage         Manage NixOS configuration
    service-check        Check automation services status
    deploy-workflow      Deploy a workflow file
    setup-monitoring     Set up monitoring and alerting
    api-test            Test API endpoint
    db-backup           Backup databases
    help                Show this help message

Examples:
    $0 health-check
    $0 nixos-manage --update
    $0 deploy-workflow /path/to/workflow.json
    $0 api-test "http://localhost:5678/healthz"
    $0 api-test "http://localhost:1880/flows" GET

For more information, see the automation documentation.
EOF
}

# Main execution
main() {
    case "${1:-help}" in
        health-check)
            system_health_check
            ;;
        nixos-manage)
            check_root
            nixos_management "${2:-}"
            ;;
        service-check)
            service_management
            ;;
        deploy-workflow)
            workflow_deployment "${2:-}"
            ;;
        setup-monitoring)
            check_root
            setup_monitoring
            ;;
        api-test)
            api_testing "${2:-}" "${3:-GET}" "${4:-}"
            ;;
        db-backup)
            check_root
            database_backup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log ERROR "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Initialize
check_prerequisites

# Run main function with all arguments
main "$@"
