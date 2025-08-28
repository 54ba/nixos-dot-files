#!/bin/bash

# Wine Setup Script for NixOS
# This script helps configure Wine for optimal performance and compatibility

set -e

echo "🍷 Wine Setup Script for NixOS"
echo "================================"

# Check if running as user (not root)
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root"
   echo "Please run as your regular user: bash wine-setup.sh"
   exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
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

# Check if Wine is installed
check_wine() {
    print_status "Checking Wine installation..."

    if command -v wine &> /dev/null; then
        print_success "Wine is installed"
        wine --version
    else
        print_error "Wine is not installed. Please install it first."
        exit 1
    fi

    if command -v winetricks &> /dev/null; then
        print_success "Winetricks is installed"
    else
        print_warning "Winetricks is not installed"
    fi
}

# Create Wine prefix
create_wine_prefix() {
    print_status "Setting up Wine prefix..."

    export WINEPREFIX="$HOME/.wine"
    export WINEARCH="win64"

    if [ -d "$WINEPREFIX" ]; then
        print_warning "Wine prefix already exists at $WINEPREFIX"
        read -p "Do you want to recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Removing existing Wine prefix..."
            rm -rf "$WINEPREFIX"
        else
            print_status "Using existing Wine prefix"
            return
        fi
    fi

    print_status "Creating new Wine prefix..."
    wineboot --init

    print_success "Wine prefix created successfully"
}

# Install essential components
install_wine_components() {
    print_status "Installing essential Wine components..."

    # Install Wine Mono (for .NET applications)
    if command -v wine &> /dev/null; then
        print_status "Installing Wine Mono..."
        wine wineboot --update

        print_status "Installing Wine Gecko..."
        wine wineboot --update
    fi

    print_success "Wine components installed"
}

# Configure Wine for performance
configure_wine_performance() {
    print_status "Configuring Wine for optimal performance..."

    export WINEPREFIX="$HOME/.wine"

    # Enable Esync
    print_status "Enabling Esync..."
    wine reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v ObCaseInsensitive /t REG_DWORD /d 1 /f

    # Configure audio
    print_status "Configuring audio..."
    wine reg add "HKEY_CURRENT_USER\Software\Wine\Drivers" /v Audio /t REG_SZ /d "pulse" /f

    # Configure graphics
    print_status "Configuring graphics..."
    wine reg add "HKEY_CURRENT_USER\Software\Wine\X11 Driver" /v "UseTakeFocus" /t REG_SZ /d "N" /f

    print_success "Wine performance configuration completed"
}

# Install common Windows fonts
install_windows_fonts() {
    print_status "Installing Windows fonts..."

    if command -v winetricks &> /dev/null; then
        print_status "Installing core fonts..."
        winetricks corefonts

        print_status "Installing additional fonts..."
        winetricks liberation
        winetricks dejavu
    else
        print_warning "Winetricks not available, skipping font installation"
    fi

    print_success "Font installation completed"
}

# Configure Wine for gaming
configure_wine_gaming() {
    print_status "Configuring Wine for gaming..."

    export WINEPREFIX="$HOME/.wine"

    # Enable CSMT (Command Stream Multi-Threading)
    print_status "Enabling CSMT..."
    wine reg add "HKEY_CURRENT_USER\Software\Wine\Direct3D" /v "CSMT" /t REG_DWORD /d 1 /f

    # Configure DirectX
    print_status "Configuring DirectX..."
    wine reg add "HKEY_CURRENT_USER\Software\Wine\Direct3D" /v "MaxVersionGL" /t REG_DWORD /d 30002 /f

    # Enable mouse capture
    print_status "Configuring mouse capture..."
    wine reg add "HKEY_CURRENT_USER\Software\Wine\DirectInput" /v "MouseWarpOverride" /t REG_SZ /d "force" /f

    print_success "Gaming configuration completed"
}

# Create desktop shortcuts
create_desktop_shortcuts() {
    print_status "Creating desktop shortcuts..."

    # Wine Configuration
    cat > "$HOME/Desktop/Wine Configuration.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Wine Configuration
Comment=Configure Wine settings
Exec=winecfg
Icon=wine
Terminal=false
Categories=System;Emulator;
EOF

    # Winetricks
    if command -v winetricks &> /dev/null; then
        cat > "$HOME/Desktop/Winetricks.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Winetricks
Comment=Install and configure Wine components
Exec=winetricks
Icon=wine
Terminal=false
Categories=System;Emulator;
EOF
    fi

    # PlayOnLinux
    if command -v playonlinux &> /dev/null; then
        cat > "$HOME/Desktop/PlayOnLinux.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=PlayOnLinux
Comment=Manage Wine applications
Exec=playonlinux
Icon=wine
Terminal=false
Categories=System;Emulator;
EOF
    fi

    # Lutris
    if command -v lutris &> /dev/null; then
        cat > "$HOME/Desktop/Lutris.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Lutris
Comment=Game library manager
Exec=lutris
Icon=lutris
Terminal=false
Categories=Game;Emulator;
EOF
    fi

    chmod +x "$HOME/Desktop/"*.desktop

    print_success "Desktop shortcuts created"
}

# Main setup function
main() {
    echo
    print_status "Starting Wine setup..."

    check_wine
    create_wine_prefix
    install_wine_components
    configure_wine_performance
    install_windows_fonts
    configure_wine_gaming
    create_desktop_shortcuts

    echo
    print_success "Wine setup completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Run 'winecfg' to configure Wine settings"
    echo "2. Use 'winetricks' to install additional components"
    echo "3. Use 'playonlinux' or 'lutris' to manage applications"
    echo "4. Check the desktop shortcuts for easy access"
    echo
    echo "Your Wine prefix is located at: $HOME/.wine"
    echo "Wine architecture: win64"
    echo
    echo "Happy Windows application running! 🎉"
}

# Run main function
main "$@"