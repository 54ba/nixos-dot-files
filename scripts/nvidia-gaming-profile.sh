#!/usr/bin/env bash

# NVIDIA Gaming Profile Script
# Optimizes NVIDIA GPU for maximum gaming performance

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        exit 1
    fi
}

# Check if NVIDIA GPU is available
check_nvidia_gpu() {
    if ! command -v nvidia-smi &> /dev/null; then
        print_error "NVIDIA GPU not detected or drivers not installed"
        exit 1
    fi

    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits)
    print_success "NVIDIA GPU detected: $GPU_NAME"
}

# Function to create gaming profile
create_gaming_profile() {
    print_status "Creating NVIDIA gaming profile..."

    # Create profile directory
    mkdir -p ~/.config/nvidia-gaming

    # Create gaming profile
    cat > ~/.config/nvidia-gaming/gaming-profile.sh << 'EOF'
#!/usr/bin/env bash
# NVIDIA Gaming Performance Profile
# Source this file before gaming for optimal performance

echo "Loading NVIDIA Gaming Profile..."

# NVIDIA Performance Settings
export __GL_SYNC_TO_VBLANK=0
export __GL_THREADED_OPTIMIZATIONS=1
export __GL_YIELD=NOTHING
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH=~/.cache/nvidia-shaders

# Gaming Performance
export DXVK_HUD=1
export DXVK_STATE_CACHE=1
export DXVK_STATE_CACHE_PATH=~/.cache/dxvk
export VKD3D_CONFIG=dxr,dxr11
export VKD3D_SHADER_CACHE_PATH=~/.cache/vkd3d

# Wine Optimizations
export WINEDLLOVERRIDES=dxgi=n
export WINE_LARGE_ADDRESS_AWARE=1
export WINE_PULSE_LATENCY=60
export WINE_ESYNC=1
export WINE_FSYNC=1

# Vulkan Optimizations
export VK_DRIVER_FILES="/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json"
export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json"
export VK_LAYER_NV_optimus=NVIDIA_only

# GameMode
export LD_PRELOAD="libgamemode.so.0"

# Performance Monitoring
export MANGOHUD=1
export MANGOHUD_CONFIG="fps_limit=0,no_display,position=top-right"

echo "NVIDIA Gaming Profile loaded successfully!"
echo "Performance optimizations enabled for gaming."
EOF

    chmod +x ~/.config/nvidia-gaming/gaming-profile.sh

    # Create desktop shortcut for gaming profile
    cat > ~/Desktop/NVIDIA-Gaming-Profile.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=NVIDIA Gaming Profile
Comment=Load NVIDIA gaming performance profile
Exec=bash -c "source ~/.config/nvidia-gaming/gaming-profile.sh && echo 'Gaming profile loaded!'"
Icon=video-display
Terminal=true
Categories=System;Settings;
EOF

    chmod +x ~/Desktop/NVIDIA-Gaming-Profile.desktop

    print_success "Gaming profile created at ~/.config/nvidia-gaming/gaming-profile.sh"
    print_success "Desktop shortcut created: NVIDIA-Gaming-Profile.desktop"
}

# Function to apply gaming optimizations
apply_gaming_optimizations() {
    print_status "Applying gaming optimizations..."

    # Set PowerMizer to maximum performance
    sudo nvidia-smi -pm 1
    sudo nvidia-smi -pl 100

    # Set GPU to maximum performance
    sudo nvidia-smi -ac 5001,1590

    # Enable DSR for better upscaling
    sudo nvidia-settings -a "DSRFactor=2.0"
    sudo nvidia-settings -a "DSRSmoothing=0.5"

    # Set anisotropic filtering
    sudo nvidia-settings -a "AnisotropicFiltering=16"

    # Set antialiasing
    sudo nvidia-settings -a "AntialiasingMode=1"
    sudo nvidia-settings -a "AntialiasingLevel=8"

    # Enable shader cache
    sudo nvidia-settings -a "ShaderCache=1"

    # Set texture quality to performance
    sudo nvidia-settings -a "TextureQuality=2"

    print_success "Gaming optimizations applied"
}

# Function to create game-specific profiles
create_game_profiles() {
    print_status "Creating game-specific profiles..."

    # Create profiles directory
    mkdir -p ~/.config/nvidia-gaming/game-profiles

    # Steam profile
    cat > ~/.config/nvidia-gaming/game-profiles/steam.sh << 'EOF'
#!/usr/bin/env bash
# Steam Gaming Profile

# Load base gaming profile
source ~/.config/nvidia-gaming/gaming-profile.sh

# Steam-specific optimizations
export STEAM_RUNTIME=1
export STEAM_RUNTIME_HEAVY=1

# Steam shader cache
export STEAM_SHADER_CACHE=1
export STEAM_SHADER_CACHE_PATH=~/.cache/steam-shaders

echo "Steam gaming profile loaded!"
EOF

    # Wine profile
    cat > ~/.config/nvidia-gaming/game-profiles/wine.sh << 'EOF'
#!/usr/bin/env bash
# Wine Gaming Profile

# Load base gaming profile
source ~/.config/nvidia-gaming/gaming-profile.sh

# Wine-specific optimizations
export WINEDEBUG=-all
export WINEPREFIX=~/.wine-games

# Wine performance
export WINE_PULSE_LATENCY=60
export WINE_ESYNC=1
export WINE_FSYNC=1

echo "Wine gaming profile loaded!"
EOF

    # Lutris profile
    cat > ~/.config/nvidia-gaming/game-profiles/lutris.sh << 'EOF'
#!/usr/bin/env bash
# Lutris Gaming Profile

# Load base gaming profile
source ~/.config/nvidia-gaming/gaming-profile.sh

# Lutris-specific optimizations
export LUTRIS_SKIP_INSTALLER=1
export LUTRIS_SKIP_LAUNCHER=1

# GameMode integration
export LD_PRELOAD="libgamemode.so.0"

echo "Lutris gaming profile loaded!"
EOF

    chmod +x ~/.config/nvidia-gaming/game-profiles/*.sh

    print_success "Game-specific profiles created"
}

# Function to enable GameMode
enable_gamemode() {
    print_status "Enabling GameMode..."

    if command -v gamemoded &> /dev/null; then
        systemctl --user enable gamemoded
        systemctl --user start gamemoded
        print_success "GameMode enabled and started"
    else
        print_warning "GameMode not installed"
    fi
}

# Function to show gaming profile help
show_help() {
    echo "NVIDIA Gaming Profile Script"
    echo "============================"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  create        - Create gaming profile and desktop shortcut"
    echo "  optimize      - Apply gaming optimizations"
    echo "  games         - Create game-specific profiles"
    echo "  gamemode      - Enable GameMode"
    echo "  all           - Create complete gaming setup"
    echo "  help          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 create     # Create gaming profile"
    echo "  $0 optimize   # Apply optimizations"
    echo "  $0 all        # Complete setup"
    echo ""
    echo "After setup, load the profile before gaming:"
    echo "  source ~/.config/nvidia-gaming/gaming-profile.sh"
}

# Main function
main() {
    check_root
    check_nvidia_gpu

    case "${1:-all}" in
        "create")
            create_gaming_profile
            ;;
        "optimize")
            apply_gaming_optimizations
            ;;
        "games")
            create_game_profiles
            ;;
        "gamemode")
            enable_gamemode
            ;;
        "all")
            print_status "Creating complete NVIDIA gaming setup..."
            create_gaming_profile
            apply_gaming_optimizations
            create_game_profiles
            enable_gamemode
            print_success "Complete gaming setup created!"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac

    print_status "Setup complete!"
    print_status "To load gaming profile before gaming, run:"
    print_status "source ~/.config/nvidia-gaming/gaming-profile.sh"
    print_status "Or click the NVIDIA-Gaming-Profile desktop shortcut"
}

# Run main function with all arguments
main "$@"