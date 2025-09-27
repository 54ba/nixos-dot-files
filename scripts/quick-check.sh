#!/usr/bin/env bash

# Quick NixOS Conflict Checker - Minimal version for fast checking

source .env 2>/dev/null || true
NIXOS_HOSTNAME=${NIXOS_HOSTNAME:-$(hostname)}

echo "🔍 Quick NixOS conflict check..."

# 1. Quick syntax check
echo -n "Flake check: "
if nix flake check . --no-build 2>/dev/null; then
    echo "✅ OK"
else
    echo "❌ FAILED"
    exit 1
fi

# 2. Evaluation check
echo -n "Config eval: "
if nixos-rebuild dry-run --flake .#${NIXOS_HOSTNAME} &>/dev/null; then
    echo "✅ OK"
else
    echo "❌ FAILED"
    exit 1
fi

# 3. Build check (without switching)
echo -n "Build test: "
if nixos-rebuild build --flake .#${NIXOS_HOSTNAME} &>/dev/null; then
    echo "✅ OK"
else
    echo "❌ FAILED"
    exit 1
fi

echo "✅ All quick checks passed! Safe to proceed with 'nixos-rebuild test' or 'switch'."
