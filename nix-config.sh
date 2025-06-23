#!/usr/bin/env bash

# NixOS Configuration Management Script
# This script helps manage the modular NixOS configuration

set -e

CONFIG_DIR="$(dirname "$(realpath "$0")")"
cd "$CONFIG_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Safe in-place file editing using temporary files
# This avoids issues with sed -i and ensures atomic writes
edit_in_place() {
    local file="$1"
    shift
    local sed_args="$@"
    
    if [[ ! -f "$file" ]]; then
        print_error "File does not exist: $file"
        return 1
    fi
    
    local tmp
    tmp=$(mktemp) || {
        print_error "Failed to create temporary file"
        return 1
    }
    
    # Apply sed transformation and write to temp file
    if sed "$sed_args" "$file" > "$tmp"; then
        # Preserve original file permissions
        chmod --reference="$file" "$tmp" 2>/dev/null || true
        # Atomically replace the original file
        if mv "$tmp" "$file"; then
            return 0
        else
            print_error "Failed to replace file: $file"
            rm -f "$tmp"
            return 1
        fi
    else
        print_error "sed transformation failed for file: $file"
        rm -f "$tmp"
        return 1
    fi
}

# Privilege / write-access guard
require_write_access() {
    # Check if we can write to CONFIG_DIR
    if ! touch "$CONFIG_DIR/.nixos_write_test" >/dev/null 2>&1 && [[ ! -w "$CONFIG_DIR" ]]; then
        print_warning "Write access required for configuration directory: $CONFIG_DIR"
        print_status "Re-executing with sudo privileges..."
        exec sudo "$0" "$@"
    fi
    
    # Clean up test file if it was created
    [[ -f "$CONFIG_DIR/.nixos_write_test" ]] && rm -f "$CONFIG_DIR/.nixos_write_test"
}

# Help function
show_help() {
    cat << EOF
NixOS Configuration Management Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
  build           Build the configuration without applying
  switch          Build and switch to the new configuration
  test            Build and test the configuration temporarily
  dev [ENV]       Enter development shell (default)
  update          Update flake inputs
  clean           Clean old generations
  enable [TYPE]   Enable optional package collection (media, development, gaming, popular, etc.)
  disable [TYPE]  Disable optional package collection
  list-packages   List available package collections
  check           Check configuration syntax
  help            Show this help message

Examples:
  $0 switch               # Apply configuration
  $0 dev pentest         # Enter pentest environment
  $0 enable-pentest      # Enable security tools
  $0 update && $0 switch # Update and apply

EOF
}

# Check if we're in a NixOS system
check_nixos() {
    if ! command -v nixos-rebuild >/dev/null 2>&1; then
        print_error "This script requires NixOS with nixos-rebuild command"
        exit 1
    fi
}

# Build configuration
build_config() {
    print_status "Building NixOS configuration..."
    nixos-rebuild build --flake . "$@"
    print_status "Build completed successfully"
}

# Switch configuration
switch_config() {
    print_status "Building and switching to new NixOS configuration..."
    sudo nixos-rebuild switch --flake . "$@"
    print_status "Configuration applied successfully"
}

# Test configuration
test_config() {
    print_status "Building and testing NixOS configuration..."
    sudo nixos-rebuild test --flake . "$@"
    print_status "Test completed successfully"
}

# Enter development environment
enter_dev() {
    local env="${1:-default}"
    
    case "$env" in
        "default"|"")
            print_status "Entering default development environment..."
            nix develop
            ;;
        "pentest")
            print_warning "Entering penetration testing environment"
            print_warning "Use these tools responsibly and only on authorized systems!"
            nix develop .#pentest
            ;;
        "media")
            print_status "Entering media production environment..."
            nix develop .#media
            ;;
        "full")
            print_status "Entering full environment with all packages..."
            nix develop .#full
            ;;
        *)
            print_error "Unknown environment: $env"
            print_error "Available environments: default, pentest, media, full"
            exit 1
            ;;
    esac
}

# Update flake inputs
update_flake() {
    print_status "Updating flake inputs..."
    nix flake update
    print_status "Flake inputs updated successfully"
}

# Clean old generations
clean_generations() {
    print_status "Cleaning old generations..."
    sudo nix-collect-garbage -d
    print_status "Cleanup completed"
}

# Enable penetration testing tools
enable_pentest() {
    require_write_access "$@"
    print_warning "Enabling penetration testing tools..."
    print_warning "These tools should only be used on systems you own or have permission to test!"
    
    # Check if pentest is already enabled
    if grep -q "pentest.enable = true" configuration.nix; then
        print_status "Penetration testing tools are already enabled"
        return
    fi
    
    # Enable the pentest configuration (since modules are now imported)
    edit_in_place configuration.nix 's/pentest.enable = false;/pentest.enable = true;/' || \
    edit_in_place configuration.nix 's/# Enable penetration testing tools/# Enable penetration testing tools (use responsibly!)\n  custom.security = {\n    pentest.enable = true;\n    pentest.warning = true;\n  };/'
    
    print_status "Penetration testing tools enabled in configuration"
    print_status "Run '$0 switch' to apply changes"
}

# Disable penetration testing tools
disable_pentest() {
    require_write_access "$@"
    print_status "Disabling penetration testing tools..."
    
    # Comment out the pentest configuration
    edit_in_place configuration.nix 's/custom.security = {/# custom.security = {/'
    edit_in_place configuration.nix 's/  pentest.enable = true;/#   pentest.enable = true;/'
    edit_in_place configuration.nix 's/  pentest.warning = true;/#   pentest.warning = true;/'
    edit_in_place configuration.nix 's/};/# };/'
    
    print_status "Penetration testing tools disabled in configuration"
    print_status "Run '$0 switch' to apply changes"
}

# List available package collections
list_packages() {
    print_header "Available Package Collections:"
    echo
    echo "Core Packages (always enabled):"
    echo "  - Essential system utilities, terminal tools, network utilities"
    echo
    echo "Optional Package Collections:"
    echo "  - media: Media and graphics packages (ffmpeg, gimp, blender, etc.)"
    echo "  - development: Development tools (nodejs, python, docker, etc.)"
    echo "  - productivity: Productivity apps (slack, libreoffice, obsidian, etc.)"
    echo "  - gaming: Gaming platforms (steam, lutris, heroic, etc.)"
    echo "  - entertainment: Entertainment apps (spotify, stremio, qbittorrent, etc.)"
    echo "  - editors: Modern code editors (code-cursor, warp-terminal, etc.)"
    echo "  - terminals: Terminal applications (warp-terminal, kitty, alacritty, etc.)"
    echo "  - popular: Popular packages (vscode, discord, firefox, git, docker, steam, etc.)"
    echo
    echo "Security Tools (optional, disabled by default):"
    echo "  - pentest: Penetration testing tools (nmap, wireshark, metasploit, etc.)"
    echo
    print_warning "Penetration testing tools should only be used on authorized systems!"
}

# Check if a package collection is enabled
is_package_enabled() {
    local package_type="$1"
    local marker_comment="# NIXCONFIG: $package_type packages enabled"
    grep -q "$marker_comment" configuration.nix
}

# Enable optional packages
enable_packages() {
    local package_type="$1"
    require_write_access "$@"
    
    # Check if already enabled
    if is_package_enabled "$package_type"; then
        print_status "$package_type packages are already enabled"
        return 0
    fi
    
    print_status "Enabling $package_type packages..."
    
    case "$package_type" in
        "editors")
            enable_editors_packages
            ;;
        "terminals")
            enable_terminals_packages
            ;;
        "media")
            enable_media_packages
            ;;
        "development")
            enable_development_packages
            ;;
        "gaming")
            enable_gaming_packages
            ;;
        "productivity")
            enable_productivity_packages
            ;;
        "entertainment")
            enable_entertainment_packages
            ;;
        "popular")
            enable_popular_packages
            ;;
        "nixgl")
            enable_nixgl_packages
            ;;
        *)
            print_error "Unknown package type: $package_type"
            print_error "Available types: editors, terminals, media, development, gaming, productivity, entertainment, popular, nixgl"
            exit 1
            ;;
    esac
    
    print_status "$package_type packages enabled. Run '$0 switch' to apply changes"
}

# Disable optional packages
disable_packages() {
    local package_type="$1"
    require_write_access "$@"
    
    # Check if already disabled
    if ! is_package_enabled "$package_type"; then
        print_status "$package_type packages are already disabled"
        return 0
    fi
    
    print_status "Disabling $package_type packages..."
    
    local marker_comment="# NIXCONFIG: $package_type packages enabled"
    local end_marker="# NIXCONFIG: end $package_type packages"
    
    # Remove the package block including markers
    edit_in_place configuration.nix "/^[[:space:]]*$marker_comment/,/^[[:space:]]*$end_marker/d"
    
    print_status "$package_type packages disabled. Run '$0 switch' to apply changes"
}

# Package-specific enable functions
enable_editors_packages() {
    print_status "Adding modern code editors..."
    
    # Find the line where to insert editors packages (after vscode line)
    local insert_line=$(grep -n "vscode" configuration.nix | head -1 | cut -d: -f1)
    if [[ -z "$insert_line" ]]; then
        print_error "Could not find vscode line in configuration.nix"
        return 1
    fi
    
    # Insert the editors packages block after vscode
    edit_in_place configuration.nix "${insert_line}a\    # NIXCONFIG: editors packages enabled\n    code-cursor\n    cursor\n    # NIXCONFIG: end editors packages"
}

enable_terminals_packages() {
    print_status "Adding modern terminal applications..."
    
    # Find the line with warp-terminal (it should already exist)
    local warp_line=$(grep -n "warp-terminal" configuration.nix | head -1 | cut -d: -f1)
    if [[ -n "$warp_line" ]]; then
        print_status "warp-terminal is already available in the configuration"
        # Add additional terminals after existing ones
        local insert_line=$(grep -n "tmux zellij" configuration.nix | head -1 | cut -d: -f1)
        if [[ -n "$insert_line" ]]; then
            edit_in_place configuration.nix "${insert_line}a\    # NIXCONFIG: terminals packages enabled\n    rio\n    hyper\n    # NIXCONFIG: end terminals packages"
        fi
    else
        # Find shells and terminals section to add warp-terminal
        local insert_line=$(grep -n "tmux zellij" configuration.nix | head -1 | cut -d: -f1)
        if [[ -z "$insert_line" ]]; then
            print_error "Could not find terminals section in configuration.nix"
            return 1
        fi
        
        # Insert the terminals packages block
        edit_in_place configuration.nix "${insert_line}a\    # NIXCONFIG: terminals packages enabled\n    warp-terminal\n    rio\n    hyper\n    # NIXCONFIG: end terminals packages"
    fi
}

enable_media_packages() {
    print_status "Adding media and graphics packages..."
    
    # Find a good insertion point (after existing media packages like vlc if present)
    local insert_line=$(grep -n "vlc" configuration.nix | head -1 | cut -d: -f1)
    if [[ -z "$insert_line" ]]; then
        # Fallback to finding cups line
        insert_line=$(grep -n "^    cups$" configuration.nix | head -1 | cut -d: -f1)
    fi
    
    if [[ -n "$insert_line" ]]; then
        edit_in_place configuration.nix "${insert_line}a\    \n    # NIXCONFIG: media packages enabled\n    # Media editing and production\n    gimp\n    inkscape\n    audacity\n    blender\n    # Media players and converters\n    mpv\n    ffmpeg\n    # Image viewers and managers\n    feh\n    imagemagick\n    # NIXCONFIG: end media packages"
    else
        print_error "Could not find insertion point for media packages"
        return 1
    fi
}

enable_development_packages() {
    print_status "Adding development tools..."
    
    # Find insertion point (after git if present)
    local insert_line=$(grep -n "^    git$" configuration.nix | head -1 | cut -d: -f1)
    if [[ -z "$insert_line" ]]; then
        # Fallback to cups line
        insert_line=$(grep -n "^    cups$" configuration.nix | head -1 | cut -d: -f1)
    fi
    
    if [[ -n "$insert_line" ]]; then
        edit_in_place configuration.nix "${insert_line}a\    \n    # NIXCONFIG: development packages enabled\n    # Programming languages and runtimes\n    nodejs\n    python3\n    rustc\n    cargo\n    go\n    # Development tools\n    docker\n    docker-compose\n    kubectl\n    terraform\n    # Databases\n    postgresql\n    sqlite\n    # NIXCONFIG: end development packages"
    else
        print_error "Could not find insertion point for development packages"
        return 1
    fi
}

enable_gaming_packages() {
    print_status "Adding gaming packages..."
    
    # Find insertion point
    local insert_line=$(grep -n "^    cups$" configuration.nix | head -1 | cut -d: -f1)
    if [[ -n "$insert_line" ]]; then
        edit_in_place configuration.nix "${insert_line}a\    \n    # NIXCONFIG: gaming packages enabled\n    # Gaming platforms\n    steam\n    lutris\n    heroic\n    # Game development\n    godot\n    # Gaming utilities\n    gamemode\n    mangohud\n    # NIXCONFIG: end gaming packages"
    else
        print_error "Could not find insertion point for gaming packages"
        return 1
    fi
}

enable_productivity_packages() {
    print_status "Adding productivity packages..."
    
    # Find insertion point
    local insert_line=$(grep -n "^    cups$" configuration.nix | head -1 | cut -d: -f1)
    if [[ -n "$insert_line" ]]; then
        edit_in_place configuration.nix "${insert_line}a\    \n    # NIXCONFIG: productivity packages enabled\n    # Office suites\n    libreoffice\n    # Note-taking and knowledge management\n    obsidian\n    notion-app-enhanced\n    # Communication\n    slack\n    zoom-us\n    thunderbird\n    # Productivity tools\n    todoist-electron\n    # NIXCONFIG: end productivity packages"
    else
        print_error "Could not find insertion point for productivity packages"
        return 1
    fi
}

enable_entertainment_packages() {
    print_status "Adding entertainment packages..."
    
    # Find insertion point
    local insert_line=$(grep -n "^    cups$" configuration.nix | head -1 | cut -d: -f1)
    if [[ -n "$insert_line" ]]; then
        edit_in_place configuration.nix "${insert_line}a\    \n    # NIXCONFIG: entertainment packages enabled\n    # Music and media streaming\n    spotify\n    # Video streaming and downloading\n    stremio\n    yt-dlp\n    # Torrent clients\n    qbittorrent\n    transmission-gtk\n    # Social media\n    whatsapp-for-linux\n    # NIXCONFIG: end entertainment packages"
    else
        print_error "Could not find insertion point for entertainment packages"
        return 1
    fi
}

# Enable popular packages - widely-used applications across categories
enable_popular_packages() {
    print_status "Adding popular packages (editors, terminals, media, dev tools, etc.)..."
    
    # Find the line where to insert popular packages (before the closing bracket of systemPackages)
    # Look for the line with "cups" which is at the end of systemPackages, but ensure we're in the right section
    local cups_line=$(grep -n "^    cups$" configuration.nix | head -1 | cut -d: -f1)
    if [[ -n "$cups_line" ]]; then
        # Insert after the cups line
        local insert_line="$cups_line"
    else
        # Fallback: look for the closing bracket of systemPackages (first occurrence)
        local closing_bracket=$(grep -n "^  ];" configuration.nix | head -1 | cut -d: -f1)
        if [[ -z "$closing_bracket" ]]; then
            print_error "Could not find insertion point in configuration.nix"
            return 1
        fi
        # Insert before the closing bracket
        local insert_line=$((closing_bracket - 1))
    fi
    
    # Insert the popular packages block with key applications from different categories
    edit_in_place configuration.nix "${insert_line}a\    \n    # NIXCONFIG: popular packages enabled\n    # Editors and IDEs (most popular)\n    code-cursor\n    firefox\n    # Communication and social\n    discord\n    # Productivity and note-taking\n    obsidian\n    # Media and entertainment\n    spotify\n    vlc\n    # Development tools\n    git\n    docker\n    # Terminal improvements\n    warp-terminal\n    # NIXCONFIG: end popular packages"
}

enable_nixgl_packages() {
    print_status "Enabling nixGL for graphics compatibility..."
    # Enable nixGL in configuration
    if grep -q "nixGL.enable = true" configuration.nix; then
        print_status "nixGL is already enabled in configuration"
    else
        # More specific pattern to match nixGL configuration block
        edit_in_place configuration.nix '/nixGL = {/,/};/ s/enable = false;/enable = true;/'
        print_status "nixGL enabled - use 'nixgl' aliases for graphics apps"
    fi
}

# Check configuration syntax
check_config() {
    print_status "Checking configuration syntax..."
    
    # Check if all required files exist
    local required_files=(
        "flake.nix"
        "configuration.nix"
        "hardware-configuration.nix"
        "nixGL.nix"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Missing required file: $file"
            exit 1
        fi
    done
    
    # Try to evaluate the flake
    if nix flake check; then
        print_status "Configuration syntax is valid"
    else
        print_error "Configuration has syntax errors"
        exit 1
    fi
}

# Main script logic
case "${1:-help}" in
    "build")
        check_nixos
        build_config "${@:2}"
        ;;
    "switch")
        check_nixos
        switch_config "${@:2}"
        ;;
    "test")
        check_nixos
        test_config "${@:2}"
        ;;
    "dev")
        enter_dev "$2"
        ;;
    "update")
        update_flake
        ;;
    "clean")
        check_nixos
        clean_generations
        ;;
    "enable")
        if [[ -z "$2" ]]; then
            print_error "Please specify package type to enable"
            print_error "Usage: $0 enable [TYPE]"
            exit 1
        fi
        enable_packages "$2"
        ;;
    "disable")
        if [[ -z "$2" ]]; then
            print_error "Please specify package type to disable"
            print_error "Usage: $0 disable [TYPE]"
            exit 1
        fi
        disable_packages "$2"
        ;;
    "enable-pentest")
        enable_pentest
        ;;
    "disable-pentest")
        disable_pentest
        ;;
    "list-packages")
        list_packages
        ;;
    "check")
        check_config
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac

