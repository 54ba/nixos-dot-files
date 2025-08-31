#!/usr/bin/env bash
# NixOS Environment Helper Script
# This script helps manage environment variables for NixOS configuration

set -euo pipefail

# Configuration
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${CONFIG_DIR}/.env"
ENV_EXAMPLE="${CONFIG_DIR}/.env.example"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists and create if needed
setup_env() {
    if [[ ! -f "$ENV_FILE" ]]; then
        if [[ -f "$ENV_EXAMPLE" ]]; then
            log_warning ".env file not found. Creating from template..."
            cp "$ENV_EXAMPLE" "$ENV_FILE"
            log_success "Created .env file from template"
            log_warning "Please edit .env with your specific values before continuing"
            return 1
        else
            log_error ".env.example template not found!"
            return 1
        fi
    fi
    return 0
}

# Source environment variables
source_env() {
    if setup_env; then
        log_info "Sourcing environment variables from .env..."
        # shellcheck disable=SC1090
        set -a  # automatically export all variables
        source "$ENV_FILE"
        set +a  # disable automatic export
        log_success "Environment variables loaded"
        return 0
    fi
    return 1
}

# Validate required environment variables
validate_env() {
    local required_vars=(
        "NIXOS_HOSTNAME"
        "NIXOS_USERNAME" 
        "NIXOS_TIMEZONE"
        "NIXOS_LOCALE"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        log_warning "Please edit .env and set these variables"
        return 1
    fi
    
    log_success "All required environment variables are set"
    return 0
}

# Display current environment configuration
show_config() {
    log_info "Current NixOS Configuration:"
    echo "  Hostname: ${NIXOS_HOSTNAME:-'<not set>'}"
    echo "  Username: ${NIXOS_USERNAME:-'<not set>'}"
    echo "  Timezone: ${NIXOS_TIMEZONE:-'<not set>'}"
    echo "  Locale: ${NIXOS_LOCALE:-'<not set>'}"
    echo "  GPU Vendor: ${NIXOS_GPU_VENDOR:-'nvidia'}"
    echo "  Hardware Model: ${NIXOS_HARDWARE_MODEL:-'generic'}"
    echo ""
    echo "Feature Flags:"
    echo "  AI Services: ${NIXOS_ENABLE_AI_SERVICES:-'true'}"
    echo "  Development: ${NIXOS_ENABLE_DEVELOPMENT:-'true'}"
    echo "  Media: ${NIXOS_ENABLE_MEDIA:-'true'}"
    echo "  Gaming: ${NIXOS_ENABLE_GAMING:-'false'}"
    echo "  Penetration Testing: ${NIXOS_ENABLE_PENTEST:-'false'}"
}

# Build commands
nixos_rebuild() {
    local action="${1:-switch}"
    local hostname="${NIXOS_HOSTNAME:-}"
    
    if [[ -z "$hostname" ]]; then
        log_error "NIXOS_HOSTNAME not set. Please configure .env file"
        return 1
    fi
    
    local cmd="sudo nixos-rebuild $action --flake .#$hostname"
    log_info "Running: $cmd"
    
    if ! eval "$cmd"; then
        log_error "nixos-rebuild failed"
        return 1
    fi
    
    log_success "nixos-rebuild $action completed successfully"
}

# Home Manager build
home_manager_rebuild() {
    local username="${NIXOS_USERNAME:-}"
    
    if [[ -z "$username" ]]; then
        log_error "NIXOS_USERNAME not set. Please configure .env file"
        return 1
    fi
    
    local cmd="home-manager switch --flake .#$username"
    log_info "Running: $cmd"
    
    if ! eval "$cmd"; then
        log_error "home-manager rebuild failed"
        return 1
    fi
    
    log_success "home-manager rebuild completed successfully"
}

# Usage information
show_usage() {
    cat << EOF
NixOS Environment Helper Script

Usage: $0 [COMMAND]

Commands:
    source              Source environment variables from .env
    validate            Check that all required environment variables are set
    config              Show current environment configuration
    switch              Build and switch to new configuration
    test                Build and test configuration without switching
    boot                Build configuration for next boot
    dry-run             Show what would change without building
    home-manager        Rebuild home-manager configuration
    help                Show this help message

Environment Setup:
    1. Copy .env.example to .env
    2. Edit .env with your configuration
    3. Run: source $0 source
    4. Run: $0 validate
    5. Run: $0 switch

Examples:
    $0 source           # Source environment variables
    $0 validate         # Check configuration
    $0 switch           # Build and apply system configuration
    $0 test             # Test configuration without applying
    $0 home-manager     # Rebuild home-manager configuration

EOF
}

# Main function
main() {
    cd "$CONFIG_DIR"
    
    case "${1:-help}" in
        "source")
            source_env
            ;;
        "validate")
            if source_env; then
                validate_env
            fi
            ;;
        "config"|"show-config")
            if source_env; then
                show_config
            fi
            ;;
        "switch")
            if source_env && validate_env; then
                nixos_rebuild "switch"
            fi
            ;;
        "test")
            if source_env && validate_env; then
                nixos_rebuild "test"
            fi
            ;;
        "boot")
            if source_env && validate_env; then
                nixos_rebuild "boot"
            fi
            ;;
        "dry-run")
            if source_env && validate_env; then
                # Note: dry-run doesn't need sudo
                local hostname="${NIXOS_HOSTNAME}"
                log_info "Running: nixos-rebuild dry-run --flake .#$hostname"
                nixos-rebuild dry-run --flake ".#$hostname"
            fi
            ;;
        "home-manager"|"hm")
            if source_env && validate_env; then
                home_manager_rebuild
            fi
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            log_error "Unknown command: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
