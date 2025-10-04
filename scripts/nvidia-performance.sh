#!/usr/bin/env bash

# NVIDIA Performance and Gaming Optimization Script
# This script provides various NVIDIA performance optimizations similar to AMD FSR

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

    print_success "NVIDIA GPU detected: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits)"
}

# Function to set performance mode
set_performance_mode() {
    print_status "Setting NVIDIA performance mode..."

    # Set PowerMizer to maximum performance
    sudo nvidia-smi -pm 1
    sudo nvidia-smi -pl 100

    # Set GPU to maximum performance
    sudo nvidia-smi -ac 5001,1590

    print_success "Performance mode enabled"
}

# Function to enable gaming optimizations
enable_gaming_optimizations() {
    print_status "Enabling gaming optimizations..."

    # Set environment variables for better gaming performance
    export __GL_SYNC_TO_VBLANK=0
    export __GL_THREADED_OPTIMIZATIONS=1
    export __GL_YIELD=NOTHING

    # Enable DXVK optimizations
    export DXVK_HUD=1
    export DXVK_STATE_CACHE=1
    export VKD3D_CONFIG=dxr,dxr11

    # Wine optimizations
    export WINEDLLOVERRIDES=dxgi=n
    export WINE_LARGE_ADDRESS_AWARE=1

    print_success "Gaming optimizations enabled"
}

# Function to enable DLSS-like features
enable_dlss_features() {
    print_status "Enabling DLSS and upscaling features..."

    # Enable DSR (Dynamic Super Resolution) - NVIDIA's answer to FSR
    sudo nvidia-settings -a "AllowFlipping=1"
    sudo nvidia-settings -a "AllowIndirectGLXProtocol=1"
    sudo nvidia-settings -a "AllowIndirectGLXProtocol=1"

    # Set DSR factors for better upscaling
    sudo nvidia-settings -a "DSRFactor=2.0"
    sudo nvidia-settings -a "DSRSmoothing=0.5"

    print_success "DLSS-like features enabled (DSR, upscaling)"
}

# Function to optimize texture and shader settings
optimize_texture_settings() {
    print_status "Optimizing texture and shader settings..."

    # Set anisotropic filtering
    sudo nvidia-settings -a "AnisotropicFiltering=16"

    # Set antialiasing
    sudo nvidia-settings -a "AntialiasingMode=1"
    sudo nvidia-settings -a "AntialiasingLevel=8"

    # Enable shader cache
    sudo nvidia-settings -a "ShaderCache=1"

    # Set texture quality to performance
    sudo nvidia-settings -a "TextureQuality=2"

    print_success "Texture and shader optimizations applied"
}

# Function to enable ray tracing optimizations
enable_ray_tracing() {
    print_status "Enabling ray tracing optimizations..."

    # Enable Vulkan ray tracing
    export VK_DRIVER_FILES="/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json"
    export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json"

    # Set VKD3D ray tracing
    export VKD3D_CONFIG=dxr,dxr11

    print_success "Ray tracing optimizations enabled"
}

# Function to start performance monitoring
start_monitoring() {
    print_status "Starting performance monitoring..."

    # Start nvtop in background
    if command -v nvtop &> /dev/null; then
        nvtop &
        print_success "nvtop monitoring started"
    fi

    # Start GreenWithEnvy if available
    if command -v green-with-envy &> /dev/null; then
        green-with-envy &
        print_success "GreenWithEnvy started"
    fi
}

# Function to show current GPU status
show_gpu_status() {
    print_status "Current GPU Status:"
    echo "========================"
    nvidia-smi --query-gpu=name,driver_version,temperature.gpu,power.draw,utilization.gpu,memory.used,memory.total --format=csv,noheader
    echo "========================"
}

# Function to create performance profile
create_performance_profile() {
    print_status "Creating performance profile..."

    cat > ~/.config/nvidia-performance-profile.sh << 'EOF'
#!/usr/bin/env bash
# NVIDIA Performance Profile
# Source this file to enable optimizations

export __GL_SYNC_TO_VBLANK=0
export __GL_THREADED_OPTIMIZATIONS=1
export __GL_YIELD=NOTHING

export DXVK_HUD=1
export DXVK_STATE_CACHE=1
export VKD3D_CONFIG=dxr,dxr11

export WINEDLLOVERRIDES=dxgi=n
export WINE_LARGE_ADDRESS_AWARE=1

export VK_DRIVER_FILES="/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json"
export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json"

echo "NVIDIA Performance Profile loaded"
EOF

    chmod +x ~/.config/nvidia-performance-profile.sh
    print_success "Performance profile created at ~/.config/nvidia-performance-profile.sh"
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

# Function to show help
show_help() {
    echo "NVIDIA Performance and Gaming Optimization Script"
    echo "================================================"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  performance    - Enable maximum performance mode"
    echo "  gaming        - Enable gaming optimizations"
    echo "  dlss          - Enable DLSS-like features (DSR)"
    echo "  textures      - Optimize texture and shader settings"
    echo "  raytracing    - Enable ray tracing optimizations"
    echo "  monitor       - Start performance monitoring"
    echo "  status        - Show current GPU status"
    echo "  profile       - Create performance profile"
    echo "  gamemode      - Enable GameMode"
    echo "  all           - Enable all optimizations"
    echo "  help          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 performance    # Enable performance mode"
    echo "  $0 gaming        # Enable gaming optimizations"
    echo "  $0 all           # Enable all optimizations"
}

# Main function
main() {
    check_root
    check_nvidia_gpu

    case "${1:-all}" in
        "performance")
            set_performance_mode
            ;;
        "gaming")
            enable_gaming_optimizations
            ;;
        "dlss")
            enable_dlss_features
            ;;
        "textures")
            optimize_texture_settings
            ;;
        "raytracing")
            enable_ray_tracing
            ;;
        "monitor")
            start_monitoring
            ;;
        "status")
            show_gpu_status
            ;;
        "profile")
            create_performance_profile
            ;;
        "gamemode")
            enable_gamemode
            ;;
        "all")
            print_status "Enabling all NVIDIA performance optimizations..."
            set_performance_mode
            enable_gaming_optimizations
            enable_dlss_features
            optimize_texture_settings
            enable_ray_tracing
            enable_gamemode
            create_performance_profile
            print_success "All optimizations enabled!"
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

    print_status "Optimization complete!"
    print_status "To load performance profile in future sessions, run:"
    print_status "source ~/.config/nvidia-performance-profile.sh"
}

# Run main function with all arguments
main "$@"