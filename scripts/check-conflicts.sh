#!/usr/bin/env bash

# NixOS Configuration Conflict Checker
# This script helps identify build conflicts and issues without needing to reboot

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== NixOS Configuration Conflict Checker ===${NC}"

# Source environment variables
if [ -f ".env" ]; then
    source .env
    echo -e "${GREEN}✓ Loaded environment variables${NC}"
else
    echo -e "${YELLOW}⚠ No .env file found, using defaults${NC}"
fi

# Set default hostname if not set
NIXOS_HOSTNAME=${NIXOS_HOSTNAME:-$(hostname)}
echo -e "${BLUE}Using hostname: ${NIXOS_HOSTNAME}${NC}"

echo -e "\n${BLUE}1. Checking flake syntax and evaluation...${NC}"
if nix flake check .; then
    echo -e "${GREEN}✓ Flake syntax is valid${NC}"
else
    echo -e "${RED}✗ Flake syntax errors found${NC}"
    exit 1
fi

echo -e "\n${BLUE}2. Evaluating configuration (dry-run)...${NC}"
if nixos-rebuild dry-run --flake .#${NIXOS_HOSTNAME}; then
    echo -e "${GREEN}✓ Configuration evaluates successfully${NC}"
else
    echo -e "${RED}✗ Configuration evaluation failed${NC}"
    exit 1
fi

echo -e "\n${BLUE}3. Building configuration without switching...${NC}"
if nixos-rebuild build --flake .#${NIXOS_HOSTNAME}; then
    echo -e "${GREEN}✓ Configuration builds successfully${NC}"
else
    echo -e "${RED}✗ Configuration build failed${NC}"
    exit 1
fi

echo -e "\n${BLUE}4. Checking for activation conflicts (dry-activate)...${NC}"
if sudo nixos-rebuild dry-activate --flake .#${NIXOS_HOSTNAME}; then
    echo -e "${GREEN}✓ No activation conflicts detected${NC}"
else
    echo -e "${YELLOW}⚠ Activation conflicts detected - check output above${NC}"
fi

echo -e "\n${BLUE}5. Checking development shell dependencies...${NC}"
# Check if automation shell imports work
if [ -f "shells/automation-shell.nix" ]; then
    echo "  Checking automation shell imports..."
    if ! nix-instantiate --eval shells/automation-shell.nix >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Automation shell has dependency issues${NC}"
        echo "  You may want to run: ./scripts/fix-package-refs.sh"
    else
        echo -e "${GREEN}✓ Automation shell dependencies are valid${NC}"
    fi
fi

echo -e "\n${BLUE}6. Checking for duplicate packages...${NC}"
# Use nix-shell to temporarily access nixos-option
nix-shell -p nixos-option --run "
    echo 'Checking system packages for duplicates...'
    nixos-option environment.systemPackages | grep -E '\".*\"' | sort | uniq -d | head -10
" || echo -e "${GREEN}✓ No obvious package duplicates found${NC}"

echo -e "\n${BLUE}6. Checking for conflicting services...${NC}"
# Check for common service conflicts
CONFLICTS_FOUND=false

# Check for display manager conflicts
DM_COUNT=$(nix-shell -p nixos-option --run "
    nixos-option services.xserver.displayManager | grep -c 'enable.*true' || echo 0
")
if [ "$DM_COUNT" -gt 1 ]; then
    echo -e "${YELLOW}⚠ Multiple display managers might be enabled${NC}"
    CONFLICTS_FOUND=true
fi

# Check for desktop environment conflicts
DE_COUNT=$(nix-shell -p nixos-option --run "
    (nixos-option services.xserver.desktopManager | grep -c 'enable.*true' || echo 0)
")
if [ "$DE_COUNT" -gt 1 ]; then
    echo -e "${YELLOW}⚠ Multiple desktop environments might be enabled${NC}"
    CONFLICTS_FOUND=true
fi

if [ "$CONFLICTS_FOUND" = false ]; then
    echo -e "${GREEN}✓ No obvious service conflicts detected${NC}"
fi

echo -e "\n${BLUE}7. Testing configuration (without switching)...${NC}"
if sudo nixos-rebuild test --flake .#${NIXOS_HOSTNAME} --fast; then
    echo -e "${GREEN}✓ Configuration test successful${NC}"
    echo -e "${YELLOW}Note: Changes are active until reboot. Reboot to revert.${NC}"
else
    echo -e "${RED}✗ Configuration test failed${NC}"
    echo -e "${YELLOW}You may need to fix conflicts before proceeding${NC}"
    exit 1
fi

echo -e "\n${GREEN}=== All checks completed successfully! ===${NC}"
echo -e "${BLUE}Your configuration should be safe to switch to.${NC}"
echo -e "${YELLOW}Run 'sudo nixos-rebuild switch --flake .#${NIXOS_HOSTNAME}' to apply permanently.${NC}"
