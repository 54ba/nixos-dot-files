{ config, pkgs, lib, ... }:

{
  # This module is preserved for backward compatibility
  # Package definitions are now handled by optional.nix
  
  # Allow unfree packages globally
  nixpkgs.config.allowUnfree = true;
  
  # Basic system configuration that was in core
  # Additional packages are handled by the package modules
}
