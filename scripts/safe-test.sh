#!/usr/bin/env bash

# Safe NixOS Testing Script
# Tests configuration changes without permanent activation

set -e

source .env 2>/dev/null || true
NIXOS_HOSTNAME=${NIXOS_HOSTNAME:-$(hostname)}

echo "🧪 Safe NixOS Configuration Testing"
echo "===================================="
echo "Hostname: $NIXOS_HOSTNAME"
echo ""

# Step 1: Syntax and evaluation check
echo "1️⃣  Checking syntax and evaluation..."
if ! nix flake check . --no-build; then
    echo "❌ Flake syntax/evaluation failed!"
    exit 1
fi
echo "✅ Syntax and evaluation OK"
echo ""

# Step 2: Build test (no switching)
echo "2️⃣  Building configuration..."
if ! nixos-rebuild build --flake .#${NIXOS_HOSTNAME}; then
    echo "❌ Build failed!"
    exit 1
fi
echo "✅ Build successful"
echo ""

# Step 3: Dry activation (checks for conflicts)
echo "3️⃣  Checking for activation conflicts..."
if sudo nixos-rebuild dry-activate --flake .#${NIXOS_HOSTNAME}; then
    echo "✅ No activation conflicts detected"
else
    echo "⚠️  Potential activation conflicts found"
    echo "   This is usually safe - conflicts are often minor"
    read -p "   Continue with test activation? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted by user"
        exit 1
    fi
fi
echo ""

# Step 4: Test activation (temporary until reboot)
echo "4️⃣  Test activation (temporary until reboot)..."
echo "⚠️  This will activate changes temporarily"
echo "   Changes will be reverted on reboot"
echo "   You can also run 'nixos-rebuild switch --rollback' to revert"
echo ""
read -p "Proceed with temporary activation? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if sudo nixos-rebuild test --flake .#${NIXOS_HOSTNAME}; then
        echo "✅ Test activation successful!"
        echo ""
        echo "🔄 To make changes permanent:"
        echo "   sudo nixos-rebuild switch --flake .#${NIXOS_HOSTNAME}"
        echo ""
        echo "🔙 To revert changes:"
        echo "   sudo nixos-rebuild switch --rollback"
        echo "   or simply reboot"
    else
        echo "❌ Test activation failed!"
        echo "Check the error messages above for details"
        exit 1
    fi
else
    echo "Test activation skipped"
    echo ""
    echo "✅ All pre-activation checks passed!"
    echo "Your configuration should be safe to switch to"
    echo ""
    echo "To apply permanently:"
    echo "   sudo nixos-rebuild switch --flake .#${NIXOS_HOSTNAME}"
fi
