#!/run/current-system/sw/bin/bash

# Lenovo S540 GTX 15IWL Performance Management Script
# Optimizes performance for Lenovo laptop with NVIDIA GTX 1650

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

# Check if running on Lenovo S540
check_hardware() {
    if ! grep -q "Lenovo.*S540" /sys/class/dmi/id/product_name 2>/dev/null; then
        print_warning "This script is optimized for Lenovo S540 GTX 15IWL"
        print_warning "Running on: $(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'Unknown')"
    else
        print_success "Lenovo S540 detected"
    fi
}

# Function to set performance mode
set_performance_mode() {
    print_status "Setting Lenovo S540 performance mode..."

    # Set CPU governor to performance
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [ -f "$cpu" ]; then
            echo "performance" | sudo tee "$cpu" > /dev/null
        fi
    done

    # Set Intel GPU governor to performance
    if [ -d "/sys/class/devfreq/0000:00:02.0" ]; then
        echo "performance" | sudo tee "/sys/class/devfreq/0000:00:02.0/governor" > /dev/null 2>/dev/null || true
    fi

    # Set NVIDIA GPU to maximum performance
    if command -v nvidia-smi &> /dev/null; then
        sudo nvidia-smi -pm 1
        sudo nvidia-smi -pl 100
        sudo nvidia-smi -ac 5001,1590
    fi

    print_success "Performance mode enabled"
}

# Function to enable thermal management
enable_thermal_management() {
    print_status "Enabling thermal management..."

    # Start thermald service
    if systemctl is-enabled thermald &> /dev/null; then
        sudo systemctl start thermald
        print_success "Thermald service started"
    fi

    # Start thinkfan service
    if systemctl is-enabled thinkfan &> /dev/null; then
        sudo systemctl start thinkfan
        print_success "ThinkFan service started"
    fi

    # Start TLP service
    if systemctl is-enabled tlp &> /dev/null; then
        sudo systemctl start tlp
        print_success "TLP service started"
    fi
}

# Function to optimize storage
optimize_storage() {
    print_status "Optimizing storage performance..."

    # Enable TRIM for SSDs
    if command -v fstrim &> /dev/null; then
        sudo fstrim -v /
        print_success "TRIM operation completed"
    fi

    # Set I/O scheduler to BFQ for better performance
    for disk in /sys/block/sd*/queue/scheduler; do
        if [ -f "$disk" ]; then
            echo "bfq" | sudo tee "$disk" > /dev/null 2>/dev/null || true
        fi
    done

    # Set read-ahead for better performance
    for disk in /sys/block/sd*/queue/read_ahead_kb; do
        if [ -f "$disk" ]; then
            echo "2048" | sudo tee "$disk" > /dev/null 2>/dev/null || true
        fi
    done
}

# Function to optimize memory
optimize_memory() {
    print_status "Optimizing memory performance..."

    # Set swappiness to low value
    echo "10" | sudo tee /proc/sys/vm/swappiness > /dev/null

    # Set vfs cache pressure
    echo "50" | sudo tee /proc/sys/vm/vfs_cache_pressure > /dev/null

    # Set dirty ratios
    echo "15" | sudo tee /proc/sys/vm/dirty_ratio > /dev/null
    echo "5" | sudo tee /proc/sys/vm/dirty_background_ratio > /dev/null

    print_success "Memory optimizations applied"
}

# Function to optimize network
optimize_network() {
    print_status "Optimizing network performance..."

    # Set TCP congestion control to BBR
    echo "bbr" | sudo tee /proc/sys/net/ipv4/tcp_congestion_control > /dev/null

    # Enable TCP window scaling
    echo "1" | sudo tee /proc/sys/net/ipv4/tcp_window_scaling > /dev/null

    # Enable TCP timestamps
    echo "1" | sudo tee /proc/sys/net/ipv4/tcp_timestamps > /dev/null

    # Set TCP receive buffer size
    echo "134217728" | sudo tee /proc/sys/net/core/rmem_max > /dev/null
    echo "134217728" | sudo tee /proc/sys/net/core/wmem_max > /dev/null

    print_success "Network optimizations applied"
}

# Function to fix touchpad and gestures
fix_touchpad_gestures() {
    print_status "Fixing touchpad and gesture issues..."

    # Reload libinput modules
    if command -v modprobe &> /dev/null; then
        sudo modprobe -r libinput 2>/dev/null || true
        sudo modprobe libinput
        print_success "Libinput modules reloaded"
    fi

    # Restart X11 input services
    if systemctl is-active display-manager &> /dev/null; then
        sudo systemctl restart display-manager
        print_success "Display manager restarted"
    fi

    # Restart touchegg service
    if systemctl is-enabled touchegg &> /dev/null; then
        sudo systemctl restart touchegg
        print_success "Touchegg service restarted"
    fi

    # Set touchpad permissions
    if [ -d "/dev/input" ]; then
        sudo chmod 644 /dev/input/event*
        print_success "Touchpad permissions fixed"
    fi

    # Create touchpad configuration
    mkdir -p ~/.config/touchegg
    cat > ~/.config/touchegg/touchegg.conf << 'EOF'
# TouchEgg Configuration for Lenovo S540
# Touchpad and gesture settings

# General settings
General = {
    GestureBeginTimeout = 100
    GestureEndTimeout = 100
    GestureBeginTimeout = 100
    GestureEndTimeout = 100
}

# Two finger gestures
"2" = {
    Gesture = DRAG
    Action = MOVE_WINDOW
}

"2" = {
    Gesture = PINCH
    Action = RESIZE_WINDOW
}

"2" = {
    Gesture = ROTATE
    Action = ROTATE_WINDOW
}

# Three finger gestures
"3" = {
    Gesture = SWIPE
    Action = SWITCH_DESKTOP
}

"3" = {
    Gesture = TAP
    Action = MOUSE_CLICK
    MouseButton = 2
}

# Four finger gestures
"4" = {
    Gesture = SWIPE
    Action = SHOW_DESKTOP
}
EOF

    print_success "Touchpad and gesture fixes applied"
}

# Function to start monitoring
start_monitoring() {
    print_status "Starting performance monitoring..."

    # Start htop in background
    if command -v htop &> /dev/null; then
        htop &
        print_success "htop monitoring started"
    fi

    # Start nvtop for GPU monitoring
    if command -v nvtop &> /dev/null; then
        nvtop &
        print_success "nvtop GPU monitoring started"
    fi

    # Start powertop for power monitoring
    if command -v powertop &> /dev/null; then
        sudo powertop --auto-tune
        print_success "PowerTop optimizations applied"
    fi
}

# Function to show system status
show_system_status() {
    print_status "Lenovo S540 GTX 15IWL System Status:"
    echo "============================================="

    # CPU information
    echo "CPU Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
    echo "CPU Frequency: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) kHz"
    echo "CPU Temperature: $(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print $1/1000}' || echo 'N/A')°C"

    # Memory information
    echo "Memory Usage: $(free -h | awk '/^Mem:/ {print $3"/"$2}')"
    echo "Swappiness: $(cat /proc/sys/vm/swappiness)"

    # GPU information
    if command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA GPU: $(nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu --format=csv,noheader,nounits)"
    fi

    # Storage information
    echo "Storage I/O Scheduler: $(cat /sys/block/sda/queue/scheduler 2>/dev/null | grep -o '\[[^]]*\]' || echo 'N/A')"

    # Network information
    echo "TCP Congestion Control: $(cat /proc/sys/net/ipv4/tcp_congestion_control)"

    echo "============================================="
}

# Function to create performance profile
create_performance_profile() {
    print_status "Creating Lenovo performance profile..."

    # Create profile directory
    mkdir -p ~/.config/lenovo-performance

    # Create performance profile
    cat > ~/.config/lenovo-performance/performance-profile.sh << 'EOF'
#!/bin/bash
# Lenovo S540 GTX 15IWL Performance Profile
# Source this file to enable optimizations

echo "Loading Lenovo S540 Performance Profile..."

# Set CPU governor to performance
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [ -f "$cpu" ]; then
        echo "performance" | sudo tee "$cpu" > /dev/null
    fi
done

# Set memory optimizations
echo "10" | sudo tee /proc/sys/vm/swappiness > /dev/null
echo "50" | sudo tee /proc/sys/vm/vfs_cache_pressure > /dev/null

# Set network optimizations
echo "bbr" | sudo tee /proc/sys/net/ipv4/tcp_congestion_control > /dev/null

# Set NVIDIA GPU to performance
if command -v nvidia-smi &> /dev/null; then
    sudo nvidia-smi -pm 1
    sudo nvidia-smi -pl 100
fi

echo "Lenovo S540 Performance Profile loaded successfully!"
EOF

    chmod +x ~/.config/lenovo-performance/performance-profile.sh

    # Create desktop shortcut
    cat > ~/Desktop/Lenovo-Performance.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Lenovo Performance Profile
Comment=Load Lenovo S540 performance optimizations
Exec=bash -c "source ~/.config/lenovo-performance/performance-profile.sh && echo 'Performance profile loaded!'"
Icon=video-display
Terminal=true
Categories=System;Settings;
EOF

    chmod +x ~/Desktop/Lenovo-Performance.desktop

    print_success "Performance profile created at ~/.config/lenovo-performance/performance-profile.sh"
    print_success "Desktop shortcut created: Lenovo-Performance.desktop"
}

# Function to enable services
enable_services() {
    print_status "Enabling Lenovo performance services..."

    # Enable and start thermald
    if systemctl is-enabled thermald &> /dev/null; then
        sudo systemctl enable thermald
        sudo systemctl start thermald
        print_success "Thermald service enabled and started"
    fi

    # Enable and start thinkfan
    if systemctl is-enabled thinkfan &> /dev/null; then
        sudo systemctl enable thinkfan
        sudo systemctl start thinkfan
        print_success "ThinkFan service enabled and started"
    fi

    # Enable and start TLP
    if systemctl is-enabled tlp &> /dev/null; then
        sudo systemctl enable tlp
        sudo systemctl start tlp
        print_success "TLP service enabled and started"
    fi

    # Enable and start lenovo-performance service
    if systemctl is-enabled lenovo-performance &> /dev/null; then
        sudo systemctl enable lenovo-performance
        sudo systemctl start lenovo-performance
        print_success "Lenovo performance service enabled and started"
    fi
}

# Function to show help
show_help() {
    echo "Lenovo S540 GTX 15IWL Performance Management Script"
    echo "=================================================="
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  performance    - Enable maximum performance mode"
    echo "  thermal       - Enable thermal management"
    echo "  storage       - Optimize storage performance"
    echo "  memory        - Optimize memory performance"
    echo "  network       - Optimize network performance"
    echo "  touchpad      - Fix touchpad and gesture issues"
    echo "  monitor       - Start performance monitoring"
    echo "  status        - Show system status"
    echo "  profile       - Create performance profile"
    echo "  services      - Enable performance services"
    echo "  all           - Enable all optimizations"
    echo "  help          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 performance    # Enable performance mode"
    echo "  $0 thermal       # Enable thermal management"
    echo "  $0 all           # Enable all optimizations"
    echo ""
    echo "After setup, load the profile:"
    echo "  source ~/.config/lenovo-performance/performance-profile.sh"
}

# Main function
main() {
    check_root
    check_hardware

    case "${1:-all}" in
        "performance")
            set_performance_mode
            ;;
        "thermal")
            enable_thermal_management
            ;;
        "storage")
            optimize_storage
            ;;
        "memory")
            optimize_memory
            ;;
        "network")
            optimize_network
            ;;
        "touchpad")
            fix_touchpad_gestures
            ;;
        "monitor")
            start_monitoring
            ;;
        "status")
            show_system_status
            ;;
        "profile")
            create_performance_profile
            ;;
        "services")
            enable_services
            ;;
        "all")
            print_status "Enabling all Lenovo S540 GTX 15IWL optimizations..."
            set_performance_mode
            enable_thermal_management
            optimize_storage
            optimize_memory
            optimize_network
            fix_touchpad_gestures
            enable_services
            create_performance_profile
            print_success "All Lenovo optimizations enabled!"
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
    print_status "source ~/.config/lenovo-performance/performance-profile.sh"
    print_status "Or click the Lenovo-Performance desktop shortcut"
}

# Run main function with all arguments
main "$@"