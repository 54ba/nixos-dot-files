#!/run/current-system/sw/bin/bash

# Windows Applications Setup Script for NixOS
# This script helps set up Wine prefixes and install popular Windows applications

set -e

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    exit 1
fi

# Check if Wine is installed
if ! command -v wine &> /dev/null; then
    print_error "Wine is not installed. Please install it first via NixOS configuration."
    exit 1
fi

# Create Wine prefixes directory
WINE_PREFIXES_DIR="$HOME/.wine-prefixes"
mkdir -p "$WINE_PREFIXES_DIR"

print_status "Setting up Windows application compatibility..."

# Function to create Wine prefix
create_wine_prefix() {
    local prefix_name=$1
    local prefix_path="$WINE_PREFIXES_DIR/$prefix_name"

    print_status "Creating Wine prefix: $prefix_name"

        export WINEPREFIX="$prefix_path"
    export WINEARCH="win64"

    # Remove existing prefix if it exists
    if [ -d "$prefix_path" ]; then
        rm -rf "$prefix_path"
    fi

    # Initialize Wine prefix
    wineboot --init

    # Wait for Wine to finish
    sleep 5

    # Kill any remaining Wine processes
    wineserver -k

    print_success "Created Wine prefix: $prefix_name"
}

# Function to install .NET Framework
install_dotnet() {
    local prefix_path=$1
    local version=$2

    print_status "Installing .NET Framework $version in $prefix_path"

    export WINEPREFIX="$prefix_path"

    case $version in
        "4.8")
            # Download and install .NET Framework 4.8
            wget -O "$prefix_path/dotnet48.exe" "https://go.microsoft.com/fwlink/?LinkId=2085150"
            wine "$prefix_path/dotnet48.exe" /quiet /norestart
            ;;
        "3.5")
            # Install .NET Framework 3.5 via winetricks
            winetricks dotnet35
            ;;
        *)
            print_warning "Unknown .NET Framework version: $version"
            return 1
            ;;
    esac

    print_success "Installed .NET Framework $version"
}

# Function to install Windows components
install_windows_components() {
    local prefix_path=$1

    print_status "Installing Windows components in $prefix_path"

    export WINEPREFIX="$prefix_path"

    # Install common Windows components
    winetricks corefonts vcrun2019 vcrun2017 vcrun2015 vcrun2013 vcrun2012 vcrun2010 vcrun2008 vcrun2005

    print_success "Installed Windows components"
}

# Create different Wine prefixes for different application categories
print_status "Creating Wine prefixes for different application categories..."

# Office applications prefix
create_wine_prefix "office"
install_windows_components "$WINE_PREFIXES_DIR/office"
install_dotnet "$WINE_PREFIXES_DIR/office" "4.8"

# Development tools prefix
create_wine_prefix "development"
install_windows_components "$WINE_PREFIXES_DIR/development"
install_dotnet "$WINE_PREFIXES_DIR/development" "4.8"
install_dotnet "$WINE_PREFIXES_DIR/development" "3.5"

# Design applications prefix
create_wine_prefix "design"
install_windows_components "$WINE_PREFIXES_DIR/design"
install_dotnet "$WINE_PREFIXES_DIR/design" "4.8"

# Gaming prefix
create_wine_prefix "gaming"
install_windows_components "$WINE_PREFIXES_DIR/gaming"

# Business applications prefix
create_wine_prefix "business"
install_windows_components "$WINE_PREFIXES_DIR/business"
install_dotnet "$WINE_PREFIXES_DIR/business" "4.8"

# Create desktop shortcuts for Wine prefixes
print_status "Creating desktop shortcuts..."

# Function to create desktop shortcut
create_desktop_shortcut() {
    local prefix_name=$1
    local prefix_path="$WINE_PREFIXES_DIR/$prefix_name"
    local desktop_file="$HOME/Desktop/Wine-$prefix_name.desktop"

    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Wine $prefix_name
Comment=Launch applications in $prefix_name Wine prefix
Exec=env WINEPREFIX="$prefix_path" winecfg
Icon=wine
Terminal=false
Categories=Wine;
EOF

    chmod +x "$desktop_file"
}

create_desktop_shortcut "office"
create_desktop_shortcut "development"
create_desktop_shortcut "design"
create_dine_shortcut "gaming"
create_desktop_shortcut "business"

# Create configuration script
print_status "Creating Wine configuration script..."

CONFIG_SCRIPT="$HOME/.local/bin/wine-config"
mkdir -p "$(dirname "$CONFIG_SCRIPT")"

cat > "$CONFIG_SCRIPT" << 'EOF'
#!/run/current-system/sw/bin/bash

# Wine Configuration Script
# Usage: wine-config <prefix_name> <command>

if [ $# -lt 2 ]; then
    echo "Usage: wine-config <prefix_name> <command>"
    echo "Prefix names: office, development, design, gaming, business"
    echo "Commands: winecfg, explorer, cmd, regedit"
    exit 1
fi

PREFIX_NAME=$1
COMMAND=$2
PREFIX_PATH="$HOME/.wine-prefixes/$PREFIX_NAME"

if [ ! -d "$PREFIX_PATH" ]; then
    echo "Error: Wine prefix '$PREFIX_NAME' not found at $PREFIX_PATH"
    exit 1
fi

export WINEPREFIX="$PREFIX_PATH"
export WINEARCH="win64"

case $COMMAND in
    winecfg)
        winecfg
        ;;
    explorer)
        wine explorer
        ;;
    cmd)
        wine cmd
        ;;
    regedit)
        wine regedit
        ;;
    *)
        echo "Unknown command: $COMMAND"
        echo "Available commands: winecfg, explorer, cmd, regedit"
        exit 1
        ;;
esac
EOF

chmod +x "$CONFIG_SCRIPT"

# Create application installation guide
print_status "Creating application installation guide..."

GUIDE_FILE="$HOME/Desktop/Windows-Apps-Guide.txt"
cat > "$GUIDE_FILE" << 'EOF'
WINDOWS APPLICATIONS SETUP GUIDE
================================

Wine Prefixes Created:
- Office: ~/.wine-prefixes/office
- Development: ~/.wine-prefixes/development
- Design: ~/.wine-prefixes/design
- Gaming: ~/.wine-prefixes/gaming
- Business: ~/.wine-prefixes/business

.NET Framework Installed:
- .NET Framework 4.8 in office, development, design, business
- .NET Framework 3.5 in development

How to Use:
1. Use 'wine-config <prefix> <command>' to manage prefixes
2. Example: wine-config office winecfg
3. Install applications in appropriate prefixes

Popular Windows Applications to Install:

OFFICE APPLICATIONS:
- Microsoft Office 2016/2019 (use office prefix)
- Alternative: LibreOffice (already installed)

DEVELOPMENT TOOLS:
- Visual Studio Community (use development prefix)
- Alternative: VS Code (already installed)

DESIGN APPLICATIONS:
- Adobe Photoshop CS6 (use design prefix)
- Adobe Illustrator CS6 (use design prefix)
- Alternative: GIMP, Inkscape (already installed)

GAMING:
- Use gaming prefix for Windows games
- Use Lutris for easy game management

BUSINESS SOFTWARE:
- QuickBooks (use business prefix)
- Alternative: GnuCash (already installed)

Tips:
- Keep applications in separate prefixes for stability
- Use winetricks for additional Windows components
- Monitor Wine compatibility at appdb.winehq.org
EOF

print_success "Windows application compatibility setup complete!"
print_status "Check the guide at: $GUIDE_FILE"
print_status "Use 'wine-config <prefix> <command>' to manage Wine prefixes"
print_status "Desktop shortcuts have been created for each prefix"

# Show next steps
echo
print_status "Next steps:"
echo "1. Install your Windows applications in the appropriate prefixes"
echo "2. Use 'wine-config <prefix> winecfg' to configure each prefix"
echo "3. Check Wine compatibility database for specific applications"
echo "4. Consider using Lutris for game management"
echo "5. Use PlayOnLinux for easy Wine application management"