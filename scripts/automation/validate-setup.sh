#!/usr/bin/env bash

# Automation System Validation Script
# Tests the basic functionality of the newly created automation system

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 NixOS Automation System Validation${NC}"
echo "=================================================="

# Check if automation module is properly imported
echo -n "✓ Checking automation module import... "
if grep -q "automation-workflow.nix" /etc/nixos/configuration.nix; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    exit 1
fi

# Check if automation scripts are executable
echo -n "✓ Checking automation scripts... "
if [[ -x /etc/nixos/scripts/automation/system-automation.sh && \
      -x /etc/nixos/scripts/automation/workflow-manager.py && \
      -x /etc/nixos/scripts/automation/test-framework.py ]]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED - Some scripts are not executable${NC}"
    exit 1
fi

# Check if automation shell exists
echo -n "✓ Checking automation shell... "
if [[ -f /etc/nixos/shells/automation-shell.nix ]]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    exit 1
fi

# Check if flake has automation shell
echo -n "✓ Checking flake development shells... "
if grep -q "automation" /etc/nixos/flake.nix; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    exit 1
fi

# Check if automation packages exist
echo -n "✓ Checking automation packages... "
if [[ -f /etc/nixos/packages/automation-packages.nix ]]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    exit 1
fi

# Check if documentation exists
echo -n "✓ Checking documentation... "
if [[ -f /etc/nixos/docs/automation-examples.md ]]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    exit 1
fi

# Test basic command availability
echo -n "✓ Testing basic commands... "
if command -v jq >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}WARNING - Some basic tools not available${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Automation System Validation Complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Rebuild your NixOS configuration:"
echo -e "   ${BLUE}sudo nixos-rebuild switch --flake .#mahmoud-laptop${NC}"
echo ""
echo "2. Enter the automation development environment:"
echo -e "   ${BLUE}nix develop .#automation${NC}"
echo ""
echo "3. Run the system health check:"
echo -e "   ${BLUE}./scripts/automation/system-automation.sh health-check${NC}"
echo ""
echo "4. Test the framework:"
echo -e "   ${BLUE}./scripts/automation/test-framework.py --suite services${NC}"
echo ""
echo "5. For n8n and Node-RED, enable them in configuration.nix and rebuild:"
echo -e "   ${BLUE}custom.automation-workflow.engines.n8n.enable = true;${NC}"
echo -e "   ${BLUE}custom.automation-workflow.engines.nodeRed.enable = true;${NC}"
