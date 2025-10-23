#!/usr/bin/env bash
# NixOS Environment Inspector
# Comprehensive tool to inspect and manage environment variables for all installed packages and libraries

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to print colored headers
print_header() {
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to print section headers
print_section() {
    echo -e "\n${BOLD}${BLUE}▶ $1${NC}"
}

# Function to list all system packages
list_system_packages() {
    print_header "INSTALLED SYSTEM PACKAGES"
    
    print_section "System Binaries (Total: $(ls /run/current-system/sw/bin 2>/dev/null | wc -l))"
    echo "Located in: /run/current-system/sw/bin"
    
    print_section "System Libraries (Total: $(ls /run/current-system/sw/lib 2>/dev/null | wc -l))"
    echo "Located in: /run/current-system/sw/lib"
    
    print_section "System Headers"
    echo "Located in: /run/current-system/sw/include"
    
    print_section "System Store Items (Total: $(nix-store --query --requisites /run/current-system 2>/dev/null | wc -l))"
    echo "All packages in: /nix/store"
}

# Function to show all environment variables
show_all_env() {
    print_header "ALL ENVIRONMENT VARIABLES"
    
    print_section "NixOS-Specific Variables"
    env | grep -E '^(NIX_|NIXOS_|CMAKE_|PKG_CONFIG_)' | sort || echo "None set"
    
    print_section "Path Variables"
    echo -e "${GREEN}PATH:${NC}"
    echo "$PATH" | tr ':' '\n' | nl
    
    echo -e "\n${GREEN}LD_LIBRARY_PATH:${NC}"
    echo "${LD_LIBRARY_PATH:-Not set}" | tr ':' '\n' | nl
    
    echo -e "\n${GREEN}LIBRARY_PATH:${NC}"
    echo "${LIBRARY_PATH:-Not set}" | tr ':' '\n' | nl
    
    echo -e "\n${GREEN}CPATH:${NC}"
    echo "${CPATH:-Not set}" | tr ':' '\n' | nl
    
    echo -e "\n${GREEN}PKG_CONFIG_PATH:${NC}"
    echo "${PKG_CONFIG_PATH:-Not set}" | tr ':' '\n' | nl
    
    echo -e "\n${GREEN}CMAKE_PREFIX_PATH:${NC}"
    echo "${CMAKE_PREFIX_PATH:-Not set}" | tr ':' '\n' | nl
    
    print_section "Development Environment Variables"
    env | grep -E '^(CC|CXX|CFLAGS|CXXFLAGS|LDFLAGS|PYTHON|NODE|JAVA|RUST|GO)' | sort || echo "None set"
    
    print_section "XDG Variables"
    env | grep '^XDG_' | sort
    
    print_section "Wayland/Graphics Variables"
    env | grep -E '^(WAYLAND|DISPLAY|GDK|QT|MOZ|ELECTRON)' | sort || echo "None set"
}

# Function to show library paths
show_library_paths() {
    print_header "LIBRARY SEARCH PATHS"
    
    print_section "System Library Directories"
    echo "/run/current-system/sw/lib"
    echo "/nix/store/*/lib"
    
    print_section "Development Libraries"
    find /run/current-system/sw/lib -name "*.so*" 2>/dev/null | head -20
    echo "... (truncated, use 'find /run/current-system/sw/lib -name \"*.so*\"' to see all)"
    
    print_section "Static Libraries"
    find /run/current-system/sw/lib -name "*.a" 2>/dev/null | head -20
    echo "... (truncated)"
    
    print_section "PKG-CONFIG Files"
    find /run/current-system/sw/lib/pkgconfig -name "*.pc" 2>/dev/null | head -20
    echo "... (truncated)"
}

# Function to show header/include paths
show_header_paths() {
    print_header "HEADER/INCLUDE SEARCH PATHS"
    
    print_section "System Include Directories"
    find /run/current-system/sw/include -maxdepth 1 -type d 2>/dev/null | sort
    
    print_section "Common Header Files"
    find /run/current-system/sw/include -name "*.h" 2>/dev/null | head -30
    echo "... (truncated)"
}

# Function to test package availability
test_package() {
    local package="$1"
    
    print_header "TESTING PACKAGE: $package"
    
    # Check if binary exists
    if command -v "$package" &>/dev/null; then
        echo -e "${GREEN}✓${NC} Binary found: $(command -v "$package")"
        echo -e "${GREEN}✓${NC} Version: $("$package" --version 2>/dev/null | head -1 || echo "Unknown")"
    else
        echo -e "${RED}✗${NC} Binary not found in PATH"
    fi
    
    # Check if library exists
    if find /run/current-system/sw/lib -name "lib${package}*.so*" 2>/dev/null | grep -q .; then
        echo -e "${GREEN}✓${NC} Library found:"
        find /run/current-system/sw/lib -name "lib${package}*.so*" 2>/dev/null
    else
        echo -e "${YELLOW}!${NC} Library not found"
    fi
    
    # Check if headers exist
    if [ -d "/run/current-system/sw/include/$package" ] || find /run/current-system/sw/include -name "${package}.h" 2>/dev/null | grep -q .; then
        echo -e "${GREEN}✓${NC} Headers found:"
        find /run/current-system/sw/include -name "${package}*" -type d 2>/dev/null | head -5
        find /run/current-system/sw/include -name "${package}.h" 2>/dev/null
    else
        echo -e "${YELLOW}!${NC} Headers not found"
    fi
    
    # Check pkg-config
    if pkg-config --exists "$package" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} pkg-config available"
        echo "  CFLAGS: $(pkg-config --cflags "$package" 2>/dev/null)"
        echo "  LIBS: $(pkg-config --libs "$package" 2>/dev/null)"
    else
        echo -e "${YELLOW}!${NC} pkg-config not available"
    fi
}

# Function to search for a package/library
search_package() {
    local query="$1"
    
    print_header "SEARCHING FOR: $query"
    
    print_section "Binaries matching '$query'"
    find /run/current-system/sw/bin -name "*${query}*" 2>/dev/null | head -20
    
    print_section "Libraries matching '$query'"
    find /run/current-system/sw/lib -name "*${query}*.so*" -o -name "*${query}*.a" 2>/dev/null | head -20
    
    print_section "Headers matching '$query'"
    find /run/current-system/sw/include -name "*${query}*" 2>/dev/null | head -20
    
    print_section "Nix store packages matching '$query'"
    nix-store --query --requisites /run/current-system 2>/dev/null | grep -i "$query" | head -20
}

# Function to export environment for development
export_env() {
    print_header "EXPORTING COMPREHENSIVE DEVELOPMENT ENVIRONMENT"
    
    cat > /tmp/nixos-dev-env.sh <<'EOF'
#!/usr/bin/env bash
# NixOS Comprehensive Development Environment
# Source this file to set up all development paths

# System paths
export NIX_PROFILES="/nix/var/nix/profiles/default /run/current-system/sw $HOME/.nix-profile"
export PATH="/run/current-system/sw/bin:$PATH"

# Library paths
export LIBRARY_PATH="/run/current-system/sw/lib:${LIBRARY_PATH}"
export LD_LIBRARY_PATH="/run/current-system/sw/lib:${LD_LIBRARY_PATH}"

# Include paths
export CPATH="/run/current-system/sw/include:${CPATH}"
export C_INCLUDE_PATH="/run/current-system/sw/include:${C_INCLUDE_PATH}"
export CPLUS_INCLUDE_PATH="/run/current-system/sw/include:${CPLUS_INCLUDE_PATH}"

# Build system paths
export PKG_CONFIG_PATH="/run/current-system/sw/lib/pkgconfig:${PKG_CONFIG_PATH}"
export CMAKE_PREFIX_PATH="/run/current-system/sw:${CMAKE_PREFIX_PATH}"
export CMAKE_LIBRARY_PATH="/run/current-system/sw/lib:${CMAKE_LIBRARY_PATH}"
export CMAKE_INCLUDE_PATH="/run/current-system/sw/include:${CMAKE_INCLUDE_PATH}"

# Documentation paths
export MANPATH="/run/current-system/sw/share/man:${MANPATH}"
export INFOPATH="/run/current-system/sw/share/info:${INFOPATH}"

# Development tools
export ACLOCAL_PATH="/run/current-system/sw/share/aclocal:${ACLOCAL_PATH}"

# Locale
export LOCALE_ARCHIVE="/run/current-system/sw/lib/locale/locale-archive"

echo "NixOS Development Environment Loaded"
echo "All system packages and libraries are now available"
EOF
    
    chmod +x /tmp/nixos-dev-env.sh
    echo -e "${GREEN}✓${NC} Environment file created: /tmp/nixos-dev-env.sh"
    echo -e "${YELLOW}ℹ${NC} Source it with: ${BOLD}source /tmp/nixos-dev-env.sh${NC}"
    echo ""
    echo "Or add this to your ~/.bashrc or ~/.zshrc:"
    echo -e "${CYAN}source /tmp/nixos-dev-env.sh${NC}"
}

# Function to show statistics
show_stats() {
    print_header "SYSTEM PACKAGE STATISTICS"
    
    print_section "Package Counts"
    echo "System binaries: $(ls /run/current-system/sw/bin 2>/dev/null | wc -l)"
    echo "System libraries (.so): $(find /run/current-system/sw/lib -name "*.so*" 2>/dev/null | wc -l)"
    echo "Static libraries (.a): $(find /run/current-system/sw/lib -name "*.a" 2>/dev/null | wc -l)"
    echo "Header files: $(find /run/current-system/sw/include -name "*.h" 2>/dev/null | wc -l)"
    echo "pkg-config files: $(find /run/current-system/sw/lib/pkgconfig -name "*.pc" 2>/dev/null | wc -l)"
    echo "Store dependencies: $(nix-store --query --requisites /run/current-system 2>/dev/null | wc -l)"
    
    print_section "Disk Usage"
    echo "System store size: $(du -sh /nix/store 2>/dev/null | cut -f1)"
    echo "Current generation size: $(du -sh /run/current-system 2>/dev/null | cut -f1)"
}

# Main menu
show_menu() {
    print_header "NIXOS ENVIRONMENT INSPECTOR"
    echo ""
    echo "Usage: env-inspector.sh [command] [args]"
    echo ""
    echo "Commands:"
    echo "  ${GREEN}packages${NC}          - List all installed system packages"
    echo "  ${GREEN}env${NC}               - Show all environment variables"
    echo "  ${GREEN}libs${NC}              - Show library search paths"
    echo "  ${GREEN}headers${NC}           - Show header/include paths"
    echo "  ${GREEN}test${NC} <package>    - Test if a package/library is available"
    echo "  ${GREEN}search${NC} <query>    - Search for packages/libraries by name"
    echo "  ${GREEN}export${NC}            - Export comprehensive development environment"
    echo "  ${GREEN}stats${NC}             - Show system package statistics"
    echo "  ${GREEN}help${NC}              - Show this help message"
    echo ""
    echo "Examples:"
    echo "  env-inspector.sh packages"
    echo "  env-inspector.sh test gtk3"
    echo "  env-inspector.sh search python"
    echo "  env-inspector.sh export"
}

# Main script logic
case "${1:-help}" in
    packages)
        list_system_packages
        ;;
    env)
        show_all_env
        ;;
    libs)
        show_library_paths
        ;;
    headers)
        show_header_paths
        ;;
    test)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Please provide a package name${NC}"
            echo "Usage: env-inspector.sh test <package>"
            exit 1
        fi
        test_package "$2"
        ;;
    search)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Please provide a search query${NC}"
            echo "Usage: env-inspector.sh search <query>"
            exit 1
        fi
        search_package "$2"
        ;;
    export)
        export_env
        ;;
    stats)
        show_stats
        ;;
    help|--help|-h)
        show_menu
        ;;
    *)
        echo -e "${RED}Error: Unknown command '${1}'${NC}"
        show_menu
        exit 1
        ;;
esac
