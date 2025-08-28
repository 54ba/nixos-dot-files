#!/usr/bin/env bash

# Setup Home Manager for user mahmoud
# This script sets up home-manager to run as a user service instead of system service

echo "Setting up Home Manager for user mahmoud..."

# Switch to mahmoud user and setup home-manager
sudo -u mahmoud bash -c '
# Create home-manager config directory
mkdir -p ~/.config/nixpkgs

# Copy the home-manager configuration
cp /etc/nixos/home-manager.nix ~/.config/nixpkgs/home.nix

# Initialize home-manager for the user
home-manager switch -f ~/.config/nixpkgs/home.nix
'

echo "Home Manager setup completed successfully!"
echo "The user can now run 'home-manager switch' to update their configuration."
