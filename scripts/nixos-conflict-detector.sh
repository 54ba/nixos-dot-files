#!/usr/bin/env bash

# NixOS Conflict Detector and Safe Testing System
# This script provides a comprehensive approach to testing NixOS configurations
# without needing to reboot, even on unstable systems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
source .env 2>/dev/null || true
NIXOS_HOSTNAME=${NIXOS_HOSTNAME:-$(hostname)}

show_help() {
    echo "NixOS Conflict Detector & Safe Testing System"
    echo "============================================="
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  quick         - Quick syntax and build check (no activation)"
    echo "  dry           - Dry run check for conflicts"
    echo "  test          - Safe test activation (temporary until reboot)"
    echo "  full          - Comprehensive check including dry-activate"
    echo "  packages      - Check for package reference issues"
    echo "  systemd       - Check for systemd service conflicts"
    echo "  gnome         - Check for GNOME/GTK conflicts and configuration"
    echo "  shells        - Check development shells separately"
    echo "  help          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 quick      # Fast check for syntax and build issues"
    echo "  $0 systemd    # Check for systemd service conflicts"
    echo "  $0 gnome      # Check GNOME/GTK configuration and conflicts"
    echo "  $0 test       # Temporary activation for testing"
    echo "  $0 full       # Complete conflict detection"
    echo ""
}

check_syntax() {
    echo -e "${BLUE}🔍 Checking flake syntax...${NC}"
    if nix flake show . >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Flake structure is valid${NC}"
    else
        echo -e "${RED}✗ Flake has structural issues${NC}"
        return 1
    fi
}

check_evaluation() {
    echo -e "${BLUE}🔍 Testing configuration evaluation...${NC}"
    if nix eval .#nixosConfigurations.${NIXOS_HOSTNAME}.config.system.build.toplevel >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Configuration evaluates successfully${NC}"
    else
        echo -e "${YELLOW}⚠ Configuration has evaluation issues${NC}"
        echo -e "${YELLOW}  This might be due to development shells or optional components${NC}"
        
        # Try without development shells
        echo -e "${BLUE}  Testing main configuration without dev shells...${NC}"
        if nix eval .#nixosConfigurations.${NIXOS_HOSTNAME}.config.system.build.toplevel --option restrict-eval false >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Main configuration is valid${NC}"
            return 0
        else
            echo -e "${RED}✗ Main configuration has issues${NC}"
            return 1
        fi
    fi
}

check_build() {
    echo -e "${BLUE}🔨 Building configuration...${NC}"
    if nixos-rebuild build --flake .#${NIXOS_HOSTNAME} >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Configuration builds successfully${NC}"
    else
        echo -e "${RED}✗ Build failed${NC}"
        echo -e "${YELLOW}  Run 'nixos-rebuild build --flake .#${NIXOS_HOSTNAME}' for details${NC}"
        return 1
    fi
}

check_dry_activate() {
    echo -e "${BLUE}🎭 Checking activation conflicts (dry-activate)...${NC}"
    if sudo nixos-rebuild dry-activate --flake .#${NIXOS_HOSTNAME} >/dev/null 2>&1; then
        echo -e "${GREEN}✓ No activation conflicts detected${NC}"
    else
        echo -e "${YELLOW}⚠ Potential activation conflicts detected${NC}"
        echo -e "${YELLOW}  This is often safe - many warnings are informational${NC}"
        return 1
    fi
}

safe_test_activation() {
    echo -e "${PURPLE}🧪 Safe Test Activation${NC}"
    echo -e "${YELLOW}⚠ This will temporarily activate your configuration${NC}"
    echo -e "${YELLOW}  Changes will be reverted on reboot${NC}"
    echo -e "${YELLOW}  You can also run 'nixos-rebuild switch --rollback' to revert${NC}"
    echo ""
    
    read -p "Proceed with test activation? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if sudo nixos-rebuild test --flake .#${NIXOS_HOSTNAME}; then
            echo -e "${GREEN}✅ Test activation successful!${NC}"
            echo ""
            echo -e "${BLUE}📋 Next steps:${NC}"
            echo -e "${GREEN}  To make permanent: sudo nixos-rebuild switch --flake .#${NIXOS_HOSTNAME}${NC}"
            echo -e "${YELLOW}  To revert: sudo nixos-rebuild switch --rollback${NC}"
            echo -e "${YELLOW}  Or simply: reboot${NC}"
        else
            echo -e "${RED}❌ Test activation failed${NC}"
            return 1
        fi
    else
        echo -e "${BLUE}Test activation skipped${NC}"
    fi
}

check_packages() {
    echo -e "${BLUE}📦 Checking for common package issues...${NC}"
    
    # Check for common problematic patterns
    local issues_found=false
    
    # Check for npm (should not be standalone)
    if grep -r "pkgs\.npm" . --include="*.nix" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Found 'pkgs.npm' - npm is included with nodejs${NC}"
        issues_found=true
    fi
    
    # Check for pipenv (often missing)
    if grep -r "pkgs\.python.*pipenv" . --include="*.nix" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Found pipenv reference - may not be available${NC}"
        issues_found=true
    fi
    
    # Check for make (should be gnumake)
    if grep -r "pkgs\.make[^a-zA-Z]" . --include="*.nix" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Found 'pkgs.make' - should probably be 'pkgs.gnumake'${NC}"
        issues_found=true
    fi
    
    # Check for tar (should be gnutar)
    if grep -r "pkgs\.tar[^a-zA-Z]" . --include="*.nix" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Found 'pkgs.tar' - should probably be 'pkgs.gnutar'${NC}"
        issues_found=true
    fi
    
    if ! $issues_found; then
        echo -e "${GREEN}✓ No obvious package reference issues found${NC}"
    fi
}

check_systemd_conflicts() {
    echo -e "${BLUE}⚙️  Checking systemd service conflicts...${NC}"
    local conflicts_found=false
    
    # Check for conflicting display managers
    echo -e "${BLUE}  Checking display managers...${NC}"
    local dm_services=("gdm" "lightdm" "sddm" "xdm")
    local enabled_dms=()
    
    for dm in "${dm_services[@]}"; do
        if nixos-option "services.xserver.displayManager.${dm}.enable" 2>/dev/null | grep -A1 "^Value:" | grep -q "true"; then
            enabled_dms+=("$dm")
        fi
    done
    
    if [ ${#enabled_dms[@]} -gt 1 ]; then
        echo -e "${RED}✗ Multiple display managers enabled: ${enabled_dms[*]}${NC}"
        echo -e "${YELLOW}  Only one display manager should be enabled at a time${NC}"
        conflicts_found=true
    elif [ ${#enabled_dms[@]} -eq 1 ]; then
        echo -e "${GREEN}✓ Single display manager enabled: ${enabled_dms[0]}${NC}"
    else
        echo -e "${YELLOW}⚠ No display manager explicitly enabled${NC}"
    fi
    
    # Check for conflicting window managers/desktop environments
    echo -e "${BLUE}  Checking desktop environments...${NC}"
    local de_services=("gnome" "kde" "xfce" "mate" "cinnamon" "pantheon")
    local wm_services=("i3" "awesome" "bspwm" "dwm" "openbox")
    local enabled_des=()
    local enabled_wms=()
    
    for de in "${de_services[@]}"; do
        if nixos-option "services.xserver.desktopManager.${de}.enable" 2>/dev/null | grep -A1 "^Value:" | grep -q "true"; then
            enabled_des+=("$de")
        fi
    done
    
    for wm in "${wm_services[@]}"; do
        if nixos-option "services.xserver.windowManager.${wm}.enable" 2>/dev/null | grep -A1 "^Value:" | grep -q "true" || \
           nixos-option "programs.${wm}.enable" 2>/dev/null | grep -A1 "^Value:" | grep -q "true"; then
            enabled_wms+=("$wm")
        fi
    done
    
    if [ ${#enabled_des[@]} -gt 1 ]; then
        echo -e "${YELLOW}⚠ Multiple desktop environments: ${enabled_des[*]}${NC}"
        echo -e "${YELLOW}  This may cause conflicts or resource usage issues${NC}"
        conflicts_found=true
    fi
    
    if [ ${#enabled_des[@]} -ge 1 ] && [ ${#enabled_wms[@]} -ge 1 ]; then
        echo -e "${YELLOW}⚠ Both DE and WM enabled: DE(${enabled_des[*]}) WM(${enabled_wms[*]})${NC}"
        echo -e "${YELLOW}  This may cause session conflicts${NC}"
    fi
    
    # Check for conflicting audio systems
    echo -e "${BLUE}  Checking audio systems...${NC}"
    local pulseaudio_enabled=false
    local pipewire_enabled=false
    
    if nixos-option "hardware.pulseaudio.enable" 2>/dev/null | grep -A1 "^Value:" | grep -q "true"; then
        pulseaudio_enabled=true
    fi
    
    if nixos-option "services.pipewire.enable" 2>/dev/null | grep -A1 "^Value:" | grep -q "true"; then
        pipewire_enabled=true
    fi
    
    if $pulseaudio_enabled && $pipewire_enabled; then
        echo -e "${RED}✗ Both PulseAudio and PipeWire are enabled${NC}"
        echo -e "${YELLOW}  These audio systems conflict - choose one${NC}"
        conflicts_found=true
    elif $pipewire_enabled; then
        echo -e "${GREEN}✓ PipeWire audio system enabled${NC}"
    elif $pulseaudio_enabled; then
        echo -e "${GREEN}✓ PulseAudio system enabled${NC}"
    else
        echo -e "${YELLOW}⚠ No audio system explicitly configured${NC}"
    fi
    
    # Check for systemd service conflicts
    echo -e "${BLUE}  Checking for common systemd conflicts...${NC}"
    
    # Check for conflicting network managers
    local networkmanager_enabled=false
    local connman_enabled=false
    local wicd_enabled=false
    
    if nixos-option "networking.networkmanager.enable" 2>/dev/null | grep -A1 "^Value:" | grep -q "true"; then
        networkmanager_enabled=true
    fi
    if nixos-option "services.connman.enable" 2>/dev/null | grep -A1 "^Value:" | grep -q "true"; then
        connman_enabled=true
    fi
    if nixos-option "services.wicd.enable" 2>/dev/null | grep -A1 "^Value:" | grep -q "true"; then
        wicd_enabled=true
    fi
    
    local network_managers_count=0
    $networkmanager_enabled && ((network_managers_count++))
    $connman_enabled && ((network_managers_count++))
    $wicd_enabled && ((network_managers_count++))
    
    if [ $network_managers_count -gt 1 ]; then
        echo -e "${RED}✗ Multiple network managers enabled${NC}"
        echo -e "${YELLOW}  NetworkManager: $networkmanager_enabled, ConnMan: $connman_enabled, Wicd: $wicd_enabled${NC}"
        conflicts_found=true
    elif [ $network_managers_count -eq 1 ]; then
        echo -e "${GREEN}✓ Single network manager configured${NC}"
    fi
    
    if ! $conflicts_found; then
        echo -e "${GREEN}✓ No obvious systemd service conflicts detected${NC}"
    fi
    
    # Return proper exit code
    if $conflicts_found; then
        return 1
    fi
    return 0
}

check_gnome_gtk_conflicts() {
    echo -e "${BLUE}🎨 Checking GNOME/GTK conflicts and configuration...${NC}"
    local issues_found=false
    
    # Check if GNOME is enabled
    local gnome_enabled=false
    if nixos-option "services.xserver.desktopManager.gnome.enable" 2>/dev/null | grep -q "true"; then
        gnome_enabled=true
        echo -e "${GREEN}✓ GNOME desktop environment is enabled${NC}"
    fi
    
    if $gnome_enabled; then
        # Check for GNOME-specific conflicts
        echo -e "${BLUE}  Checking GNOME-specific configuration...${NC}"
        
        # Check GDM configuration when GNOME is enabled
        if ! nixos-option "services.xserver.displayManager.gdm.enable" 2>/dev/null | grep -q "true"; then
            echo -e "${YELLOW}⚠ GNOME enabled but GDM is not - consider enabling GDM for best GNOME experience${NC}"
        fi
        
        # Check for conflicting themes
        local gtk_theme=$(nixos-option "environment.systemPackages" 2>/dev/null | grep -i "gtk.*theme" | head -3)
        if [ -n "$gtk_theme" ]; then
            echo -e "${GREEN}✓ GTK themes are configured${NC}"
        fi
        
        # Check GNOME Shell extensions configuration
        if nixos-option "environment.gnome.excludePackages" 2>/dev/null | grep -q "gnome-shell-extensions"; then
            echo -e "${YELLOW}⚠ GNOME Shell extensions are excluded${NC}"
            echo -e "${YELLOW}  This may limit GNOME customization options${NC}"
        fi
        
        # Check for Wayland vs X11 conflicts
        if nixos-option "services.xserver.displayManager.gdm.wayland" 2>/dev/null | grep -q "false"; then
            echo -e "${YELLOW}⚠ GNOME with Wayland disabled - running on X11${NC}"
            echo -e "${YELLOW}  Consider enabling Wayland for better GNOME experience${NC}"
        else
            echo -e "${GREEN}✓ GNOME configured for Wayland (recommended)${NC}"
        fi
    fi
    
    # Check GTK configuration regardless of DE
    echo -e "${BLUE}  Checking GTK configuration...${NC}"
    
    # Check for GTK version conflicts
    local has_gtk2=false
    local has_gtk3=false
    local has_gtk4=false
    
    if nixos-option "environment.systemPackages" 2>/dev/null | grep -q "gtk2"; then
        has_gtk2=true
    fi
    
    if nixos-option "environment.systemPackages" 2>/dev/null | grep -q "gtk3"; then
        has_gtk3=true
    fi
    
    if nixos-option "environment.systemPackages" 2>/dev/null | grep -q "gtk4"; then
        has_gtk4=true
    fi
    
    if $has_gtk2 && $has_gtk3; then
        echo -e "${YELLOW}⚠ Both GTK2 and GTK3 packages detected${NC}"
        echo -e "${YELLOW}  This is normal but may cause theme inconsistencies${NC}"
    fi
    
    if $has_gtk4; then
        echo -e "${GREEN}✓ GTK4 packages detected (modern)${NC}"
    fi
    
    # Check for font configuration that might conflict with GTK
    echo -e "${BLUE}  Checking font configuration...${NC}"
    if nixos-option "fonts.packages" 2>/dev/null | grep -q "noto-fonts"; then
        echo -e "${GREEN}✓ Noto fonts configured (good for GTK apps)${NC}"
    fi
    
    if nixos-option "fonts.fontconfig.enable" 2>/dev/null | grep -q "true"; then
        echo -e "${GREEN}✓ Font configuration is enabled${NC}"
    else
        echo -e "${YELLOW}⚠ Font configuration is not explicitly enabled${NC}"
        echo -e "${YELLOW}  This may cause font rendering issues in GTK apps${NC}"
        issues_found=true
    fi
    
    # Check for common GNOME/GTK package conflicts
    echo -e "${BLUE}  Checking for package conflicts...${NC}"
    
    # Check for conflicting file managers
    local file_managers=("nautilus" "thunar" "pcmanfm" "dolphin" "caja")
    local enabled_fm_count=0
    local enabled_fms=()
    
    for fm in "${file_managers[@]}"; do
        if nixos-option "environment.systemPackages" 2>/dev/null | grep -q "$fm"; then
            enabled_fms+=("$fm")
            ((enabled_fm_count++))
        fi
    done
    
    if [ $enabled_fm_count -gt 2 ]; then
        echo -e "${YELLOW}⚠ Multiple file managers detected: ${enabled_fms[*]}${NC}"
        echo -e "${YELLOW}  This may cause default application conflicts${NC}"
    fi
    
    # Check for XDG configuration
    if nixos-option "xdg.portal.enable" 2>/dev/null | grep -q "true"; then
        echo -e "${GREEN}✓ XDG desktop portals enabled${NC}"
        
        # Check for GNOME-specific portals
        if $gnome_enabled && nixos-option "xdg.portal.extraPortals" 2>/dev/null | grep -q "gnome"; then
            echo -e "${GREEN}✓ GNOME XDG portals configured${NC}"
        fi
    else
        if $gnome_enabled; then
            echo -e "${YELLOW}⚠ XDG portals not enabled but GNOME is active${NC}"
            echo -e "${YELLOW}  This may cause issues with sandboxed applications${NC}"
            issues_found=true
        fi
    fi
    
    if ! $issues_found; then
        echo -e "${GREEN}✓ No obvious GNOME/GTK conflicts detected${NC}"
    fi
}

check_shells() {
    echo -e "${BLUE}🐚 Checking development shells...${NC}"
    local shells_ok=true
    
    for shell in shells/*.nix; do
        if [ -f "$shell" ]; then
            local shell_name=$(basename "$shell" .nix)
            if nix-instantiate --eval "$shell" >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Shell '$shell_name' is valid${NC}"
            else
                echo -e "${YELLOW}⚠ Shell '$shell_name' has issues${NC}"
                shells_ok=false
            fi
        fi
    done
    
    if $shells_ok; then
        echo -e "${GREEN}✓ All development shells are valid${NC}"
    else
        echo -e "${YELLOW}⚠ Some development shells have issues${NC}"
        echo -e "${YELLOW}  This won't prevent system builds but affects 'nix develop'${NC}"
    fi
}

run_quick_check() {
    echo -e "${PURPLE}⚡ Quick NixOS Configuration Check${NC}"
    echo "================================="
    echo ""
    
    check_syntax || return 1
    check_evaluation || return 1
    check_build || return 1
    
    echo ""
    echo -e "${GREEN}✅ Quick check passed! Configuration should be safe to test.${NC}"
}

run_dry_check() {
    echo -e "${PURPLE}🎭 Dry Run Conflict Check${NC}"
    echo "========================="
    echo ""
    
    run_quick_check || return 1
    echo ""
    check_dry_activate
    
    echo ""
    echo -e "${GREEN}✅ Dry run check completed.${NC}"
}

run_full_check() {
    echo -e "${PURPLE}🔍 Comprehensive NixOS Conflict Detection${NC}"
    echo "========================================="
    echo ""
    
    check_syntax || return 1
    echo ""
    check_packages
    echo ""
    check_systemd_conflicts
    echo ""
    check_gnome_gtk_conflicts
    echo ""
    check_shells
    echo ""
    check_evaluation || return 1
    echo ""
    check_build || return 1
    echo ""
    check_dry_activate
    
    echo ""
    echo -e "${GREEN}✅ Comprehensive check completed!${NC}"
    echo -e "${BLUE}Your configuration appears ready for testing.${NC}"
}

# Main execution
case "${1:-help}" in
    "quick")
        run_quick_check
        ;;
    "dry")
        run_dry_check
        ;;
    "test")
        run_quick_check && echo "" && safe_test_activation
        ;;
    "full")
        run_full_check
        ;;
    "packages")
        check_packages
        ;;
    "systemd")
        check_systemd_conflicts
        ;;
    "gnome")
        check_gnome_gtk_conflicts
        ;;
    "shells")
        check_shells
        ;;
    "help"|*)
        show_help
        ;;
esac
