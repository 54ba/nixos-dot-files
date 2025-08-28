#!/run/current-system/sw/bin/bash

# Simple Wine Setup Script for NixOS
# This script sets up basic Wine configuration and .NET Framework support

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if Wine is installed
if ! command -v wine64 &> /dev/null; then
    echo "Wine64 is not installed. Please install it first via NixOS configuration."
    exit 1
fi

print_status "Setting up basic Wine configuration..."

# Create main Wine prefix
export WINEPREFIX="$HOME/.wine"
export WINEARCH="win64"

# Initialize Wine prefix
print_status "Initializing Wine prefix..."
wine64 wineboot --init

# Wait for Wine to finish
sleep 10

# Kill any remaining Wine processes
wineserver -k

print_status "Installing Windows components..."
export WINEPREFIX="$HOME/.wine"
wine64 winetricks corefonts vcrun2019 vcrun2017 vcrun2015 vcrun2013 vcrun2012 vcrun2010 vcrun2008 vcrun2005

print_status "Installing .NET Framework 3.5..."
wine64 winetricks dotnet35

print_status "Installing .NET Framework 4.8..."
# Download .NET Framework 4.8
wget -O "$HOME/dotnet48.exe" "https://go.microsoft.com/fwlink/?LinkId=2085150"
wine64 "$HOME/dotnet48.exe" /quiet /norestart

# Clean up
rm "$HOME/dotnet48.exe"

print_success "Wine setup complete!"
print_status "Your Wine prefix is located at: $HOME/.wine"
print_status "You can now install Windows applications using: wine <application>.exe"
print_status "Use 'winecfg' to configure Wine settings"
print_status "Use 'winetricks' to install additional Windows components"

# Create desktop shortcuts
cat > "$HOME/Desktop/Wine-Configuration.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Wine Configuration
Comment=Configure Wine settings
Exec=wine64 winecfg
Icon=wine
Terminal=false
Categories=Wine;
EOF

chmod +x "$HOME/Desktop/Wine-Configuration.desktop"

cat > "$HOME/Desktop/Wine-Explorer.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Wine Explorer
Comment=Browse Wine C: drive
Exec=wine64 explorer
Icon=wine
Terminal=false
Categories=Wine;
EOF

chmod +x "$HOME/Desktop/Wine-Explorer.desktop"

print_success "Desktop shortcuts created!"
print_status "You can now run Windows applications with Wine!"