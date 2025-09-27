#!/usr/bin/env bash
# XDG Utilities Management Script for NixOS
# Comprehensive XDG Base Directory Specification management

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${CYAN}=== $1 ===${NC}"
}

# Check XDG Base Directory compliance
check_xdg_compliance() {
    print_header "XDG Base Directory Compliance Check"
    
    if command -v xdg-ninja &>/dev/null; then
        print_info "Running XDG ninja compliance check..."
        xdg-ninja
    else
        print_warning "xdg-ninja not found, performing manual check..."
        
        # Check XDG directories
        echo "XDG Environment Variables:"
        echo "  XDG_CONFIG_HOME: ${XDG_CONFIG_HOME:-~/.config}"
        echo "  XDG_DATA_HOME: ${XDG_DATA_HOME:-~/.local/share}"
        echo "  XDG_CACHE_HOME: ${XDG_CACHE_HOME:-~/.cache}"
        echo "  XDG_STATE_HOME: ${XDG_STATE_HOME:-~/.local/state}"
        echo "  XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
        echo
        
        # Check for common XDG violations
        local violations=()
        [[ -f ~/.bashrc && ! -L ~/.bashrc ]] && violations+=("~/.bashrc (should use XDG_CONFIG_HOME)")
        [[ -f ~/.vimrc && ! -L ~/.vimrc ]] && violations+=("~/.vimrc (should use XDG_CONFIG_HOME)")
        [[ -d ~/.ssh && ! -L ~/.ssh ]] && violations+=("~/.ssh (could use XDG_CONFIG_HOME)")
        
        if [[ ${#violations[@]} -gt 0 ]]; then
            print_warning "Found potential XDG violations:"
            for violation in "${violations[@]}"; do
                echo "  - $violation"
            done
        else
            print_success "No obvious XDG violations detected"
        fi
    fi
    echo
}

# Show file associations
show_file_associations() {
    print_header "File Associations"
    
    local common_types=(
        "text/plain"
        "image/png" 
        "image/jpeg"
        "application/pdf"
        "video/mp4"
        "audio/mp3"
        "application/zip"
    )
    
    for mime_type in "${common_types[@]}"; do
        local app
        app=$(xdg-mime query default "$mime_type" 2>/dev/null || echo "none")
        printf "%-20s -> %s\n" "$mime_type" "$app"
    done
    echo
}

# Set file associations
set_file_association() {
    local mime_type="$1"
    local desktop_file="$2"
    
    print_info "Setting association: $mime_type -> $desktop_file"
    
    if xdg-mime default "$desktop_file" "$mime_type"; then
        print_success "Association set successfully"
    else
        print_error "Failed to set association"
        return 1
    fi
}

# Test XDG utilities
test_xdg_utilities() {
    print_header "Testing XDG Utilities"
    
    # Test xdg-open
    print_info "Testing xdg-open with a URL..."
    if command -v xdg-open &>/dev/null; then
        echo "xdg-open would open: https://nixos.org"
        print_success "xdg-open is available"
    else
        print_error "xdg-open not found"
    fi
    
    # Test file type detection
    if command -v file &>/dev/null; then
        print_info "Testing file type detection..."
        local test_files=("/etc/passwd" "/etc/hosts" "/usr/bin/ls")
        for test_file in "${test_files[@]}"; do
            if [[ -f "$test_file" ]]; then
                local file_type
                file_type=$(file -b --mime-type "$test_file" 2>/dev/null || echo "unknown")
                printf "  %-15s: %s\n" "$(basename "$test_file")" "$file_type"
            fi
        done
    fi
    
    # Test handlr if available
    if command -v handlr &>/dev/null; then
        print_info "Testing handlr file association manager..."
        handlr list | head -5
    fi
    
    echo
}

# Show installed XDG tools
show_xdg_tools() {
    print_header "Available XDG Tools"
    
    local xdg_tools=(
        "xdg-open:Open files/URLs with default applications"
        "xdg-mime:Query/set MIME type associations" 
        "xdg-settings:Query/set desktop settings"
        "xdg-user-dirs:Manage XDG user directories"
        "xdg-desktop-menu:Install desktop menu items"
        "xdg-desktop-icon:Install desktop icons"
        "xdg-screensaver:Control screensaver"
        "desktop-file-validate:Validate desktop files"
        "handlr:Alternative file association manager"
        "mimeo:MIME type manager"
        "file:Determine file types"
        "xdg-ninja:Check XDG compliance"
    )
    
    for tool_info in "${xdg_tools[@]}"; do
        IFS=':' read -r tool desc <<< "$tool_info"
        if command -v "$tool" &>/dev/null; then
            printf "${GREEN}✓${NC} %-20s - %s\n" "$tool" "$desc"
        else
            printf "${RED}✗${NC} %-20s - %s\n" "$tool" "$desc"
        fi
    done
    echo
}

# Configure XDG user directories
setup_xdg_directories() {
    print_header "Setting up XDG User Directories"
    
    if command -v xdg-user-dirs-update &>/dev/null; then
        print_info "Updating XDG user directories..."
        xdg-user-dirs-update
        
        print_info "Current XDG user directories:"
        local dir_vars=(
            "XDG_DESKTOP_DIR"
            "XDG_DOWNLOAD_DIR" 
            "XDG_TEMPLATES_DIR"
            "XDG_PUBLICSHARE_DIR"
            "XDG_DOCUMENTS_DIR"
            "XDG_MUSIC_DIR"
            "XDG_PICTURES_DIR"
            "XDG_VIDEOS_DIR"
        )
        
        for var in "${dir_vars[@]}"; do
            local dir
            dir=$(xdg-user-dir "${var#XDG_}" 2>/dev/null || echo "not set")
            printf "  %-20s: %s\n" "$var" "$dir"
        done
        
        print_success "XDG user directories configured"
    else
        print_warning "xdg-user-dirs-update not available"
    fi
    echo
}

# Test desktop portals
test_desktop_portals() {
    print_header "Testing Desktop Portals"
    
    # Check if xdg-desktop-portal is running
    if pgrep -x "xdg-desktop-portal" &>/dev/null; then
        print_success "xdg-desktop-portal is running"
    else
        print_warning "xdg-desktop-portal is not running"
    fi
    
    # Check available portal implementations
    local portal_dirs=("/usr/share/xdg-desktop-portal/portals" "/run/current-system/sw/share/xdg-desktop-portal/portals")
    
    for dir in "${portal_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_info "Available portals in $dir:"
            for portal in "$dir"/*.portal 2>/dev/null; do
                if [[ -f "$portal" ]]; then
                    local name
                    name=$(basename "$portal" .portal)
                    echo "  - $name"
                fi
            done
        fi
    done
    echo
}

# Fix common XDG issues
fix_xdg_issues() {
    print_header "Fixing Common XDG Issues"
    
    # Ensure XDG directories exist
    local xdg_dirs=(
        "${XDG_CONFIG_HOME:-$HOME/.config}"
        "${XDG_DATA_HOME:-$HOME/.local/share}"
        "${XDG_CACHE_HOME:-$HOME/.cache}"
        "${XDG_STATE_HOME:-$HOME/.local/state}"
    )
    
    for dir in "${xdg_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            print_info "Creating XDG directory: $dir"
            mkdir -p "$dir"
            print_success "Created $dir"
        else
            print_info "XDG directory exists: $dir"
        fi
    done
    
    # Fix permissions
    print_info "Setting correct permissions on XDG directories..."
    for dir in "${xdg_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            chmod 755 "$dir"
        fi
    done
    
    print_success "XDG directory permissions fixed"
    echo
}

# Export XDG environment
export_xdg_environment() {
    print_header "XDG Environment Export"
    
    cat << 'EOF'
# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"  
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# XDG user directories (set by xdg-user-dirs-update)
export XDG_DESKTOP_DIR="$HOME/Desktop"
export XDG_DOWNLOAD_DIR="$HOME/Downloads"
export XDG_TEMPLATES_DIR="$HOME/Templates"
export XDG_PUBLICSHARE_DIR="$HOME/Public"
export XDG_DOCUMENTS_DIR="$HOME/Documents"
export XDG_MUSIC_DIR="$HOME/Music"
export XDG_PICTURES_DIR="$HOME/Pictures"
export XDG_VIDEOS_DIR="$HOME/Videos"
EOF
    echo
}

# Show usage
show_usage() {
    cat << EOF
XDG Utilities Management Script

USAGE:
    $0 <command>

COMMANDS:
    check                - Check XDG Base Directory compliance
    associations        - Show current file associations
    set-association <mime> <app.desktop> - Set file association
    test                - Test XDG utilities functionality
    tools               - List available XDG tools
    directories         - Setup XDG user directories
    portals             - Test desktop portals
    fix                 - Fix common XDG issues
    export              - Show XDG environment variables
    help                - Show this help message

EXAMPLES:
    $0 check
    $0 associations
    $0 set-association text/plain org.gnome.TextEditor.desktop
    $0 test
    $0 directories

NOTES:
    - Run without root privileges for user-specific operations
    - Some operations require a desktop environment to be running
    - File associations are stored in ~/.config/mimeapps.list

EOF
}

# Main function
main() {
    local command="${1:-help}"
    
    case "$command" in
        "check"|"compliance")
            check_xdg_compliance
            ;;
        "associations"|"assoc")
            show_file_associations
            ;;
        "set-association"|"set")
            if [[ $# -lt 3 ]]; then
                print_error "Usage: $0 set-association <mime-type> <app.desktop>"
                exit 1
            fi
            set_file_association "$2" "$3"
            ;;
        "test")
            test_xdg_utilities
            ;;
        "tools"|"list")
            show_xdg_tools
            ;;
        "directories"|"dirs")
            setup_xdg_directories
            ;;
        "portals")
            test_desktop_portals
            ;;
        "fix")
            fix_xdg_issues
            ;;
        "export"|"env")
            export_xdg_environment
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
