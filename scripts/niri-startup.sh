#!/usr/bin/env bash
# ===== BEAUTIFUL NIRI STARTUP SCRIPT =====
# Auto-generated startup script for Niri with beautiful components

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[NIRI-STARTUP]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Wait for a process to be ready
wait_for_process() {
    local process_name="$1"
    local max_wait="${2:-10}"
    local count=0
    
    while ! pgrep -x "$process_name" >/dev/null && [ $count -lt $max_wait ]; do
        sleep 0.5
        ((count++))
    done
    
    if [ $count -ge $max_wait ]; then
        warn "Timed out waiting for $process_name"
        return 1
    fi
    
    log "$process_name is ready"
    return 0
}

# Kill existing processes safely
cleanup_existing() {
    local processes=("waybar" "dunst" "swww-daemon" "wl-paste")
    
    for proc in "${processes[@]}"; do
        if pgrep -x "$proc" >/dev/null; then
            info "Stopping existing $proc"
            pkill -x "$proc" || true
            sleep 0.2
        fi
    done
}

# Start a process with error handling
start_process() {
    local cmd="$1"
    local name="${2:-$1}"
    local wait_time="${3:-2}"
    
    if ! command_exists "$cmd"; then
        error "$cmd not found in PATH"
        return 1
    fi
    
    info "Starting $name..."
    if [[ "$cmd" == *"swww-daemon"* ]]; then
        # Special handling for swww-daemon
        swww-daemon &
    elif [[ "$cmd" == *"wl-paste"* ]]; then
        # Special handling for clipboard manager
        wl-paste --type text --watch cliphist store &
        wl-paste --type image --watch cliphist store &
    else
        $cmd &
    fi
    
    sleep "$wait_time"
    
    if [[ "$name" != "clipboard manager" ]]; then
        local process_name
        process_name=$(echo "$cmd" | cut -d' ' -f1)
        if wait_for_process "$process_name" 5; then
            log "$name started successfully"
        else
            warn "Failed to start $name properly"
            return 1
        fi
    else
        log "$name started successfully"
    fi
}

# Set up wallpaper
setup_wallpaper() {
    local wallpaper_path="${HOME}/Pictures/wallpaper.jpg"
    local fallback_wallpaper="/usr/share/backgrounds/default.jpg"
    
    info "Setting up wallpaper..."
    
    # Wait for swww-daemon to be ready
    if ! wait_for_process "swww-daemon" 10; then
        error "swww-daemon not ready, skipping wallpaper setup"
        return 1
    fi
    
    # Give swww-daemon a moment to fully initialize
    sleep 2
    
    # Check for wallpaper
    if [[ -f "$wallpaper_path" ]]; then
        info "Loading wallpaper: $wallpaper_path"
        swww img "$wallpaper_path" --transition-fps 60 --transition-type wipe --transition-duration 2 || {
            warn "Failed to load custom wallpaper, trying fallback"
            [[ -f "$fallback_wallpaper" ]] && swww img "$fallback_wallpaper" --transition-fps 60 --transition-type fade --transition-duration 1
        }
    elif [[ -f "$fallback_wallpaper" ]]; then
        info "Loading fallback wallpaper: $fallback_wallpaper"
        swww img "$fallback_wallpaper" --transition-fps 60 --transition-type fade --transition-duration 1
    else
        # Create a beautiful gradient background
        info "Creating gradient background"
        swww img <(convert -size 1920x1080 gradient:'#1e1e2e-#313244' png:-) --transition-fps 60 --transition-type fade --transition-duration 1 2>/dev/null || {
            warn "ImageMagick not available, using solid color"
            # Use swww to create a solid color if convert is not available
            swww clear '#1e1e2e' || warn "Failed to set background color"
        }
    fi
    
    log "Wallpaper setup completed"
}

# Create necessary directories
setup_directories() {
    local dirs=(
        "$HOME/Pictures/Screenshots"
        "$HOME/.config/waybar"
        "$HOME/.config/wofi"
        "$HOME/.config/dunst"
        "$HOME/.config/alacritty"
    )
    
    for dir in "${dirs[@]}"; do
        [[ ! -d "$dir" ]] && {
            info "Creating directory: $dir"
            mkdir -p "$dir"
        }
    done
}

# Copy configuration files if they don't exist
setup_configs() {
    local configs=(
        "/etc/nixos/dotfiles/waybar/config:$HOME/.config/waybar/config"
        "/etc/nixos/dotfiles/waybar/style.css:$HOME/.config/waybar/style.css"
        "/etc/nixos/dotfiles/wofi/config:$HOME/.config/wofi/config"
        "/etc/nixos/dotfiles/wofi/style.css:$HOME/.config/wofi/style.css"
        "/etc/nixos/dotfiles/dunst/dunstrc:$HOME/.config/dunst/dunstrc"
        "/etc/nixos/dotfiles/alacritty/alacritty.toml:$HOME/.config/alacritty/alacritty.toml"
    )
    
    for config in "${configs[@]}"; do
        local src="${config%:*}"
        local dst="${config#*:}"
        
        if [[ -f "$src" ]] && [[ ! -f "$dst" ]]; then
            info "Copying config: $(basename "$dst")"
            cp "$src" "$dst"
        fi
    done
}

# Main startup sequence
main() {
    log "Starting Beautiful Niri Desktop Environment"
    log "========================================"
    
    # Clean up any existing processes
    cleanup_existing
    
    # Setup directories and configs
    setup_directories
    setup_configs
    
    # Start core components
    info "Starting core components..."
    
    # Start wallpaper daemon first
    start_process "swww-daemon" "wallpaper daemon" 3
    
    # Start status bar
    start_process "waybar" "status bar" 2
    
    # Start notification daemon
    start_process "dunst" "notification daemon" 2
    
    # Start clipboard manager
    start_process "wl-paste --type text --watch cliphist store" "clipboard manager" 1
    
    # Set up wallpaper (after swww-daemon is ready)
    setup_wallpaper
    
    log "All components started successfully!"
    log "========================================"
    log "Beautiful Niri Desktop is ready to use!"
    log ""
    log "Key shortcuts:"
    log "  ${PURPLE}Mod+Return${NC} - Open terminal"
    log "  ${PURPLE}Mod+D${NC} - Application launcher"
    log "  ${PURPLE}Mod+Space${NC} - Application launcher (alternative)"
    log "  ${PURPLE}Mod+V${NC} - Clipboard history"
    log "  ${PURPLE}Print${NC} - Screenshot"
    log "  ${PURPLE}Mod+Print${NC} - Area screenshot"
    log "  ${PURPLE}Mod+Shift+S${NC} - Screenshot with annotation"
    log "  ${PURPLE}Mod+Q${NC} - Close window"
    log "  ${PURPLE}Mod+Shift+E${NC} - Exit Niri"
    log ""
    log "Enjoy your beautiful desktop! 🌟"
}

# Run the main function
main "$@"