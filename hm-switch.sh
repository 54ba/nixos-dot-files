#!/usr/bin/env bash

# Home Manager wrapper script
# This script handles the permission issues by running home-manager with sudo

echo "Switching Home Manager configuration..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "Error: This script should not be run as root."
    echo "Run it as the user 'mahmoud' instead."
    exit 1
fi

# Check if we're the mahmoud user
if [[ $(whoami) != "mahmoud" ]]; then
    echo "Error: This script should be run as user 'mahmoud'."
    echo "Current user: $(whoami)"
    exit 1
fi

# Run home-manager with proper permissions
echo "Running: home-manager switch --flake /etc/nixos#mahmoud"
sudo -E home-manager switch --flake /etc/nixos#mahmoud

echo "Home Manager switch completed!"
