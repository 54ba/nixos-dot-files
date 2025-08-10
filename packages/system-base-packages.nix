{ pkgs }:

with pkgs; [
  # Basic system packages
  git
  vim
  wget
  curl
  
  # Essential build and wrapping tools
  autoPatchelfHook         # Auto patcher for ELF binaries
  makeWrapper              # Create script wrappers
  wrapGAppsHook3          # GTK/GNOME app wrapping
  addDriverRunpath        # Add driver runpath for graphics
  patchelf                # ELF manipulation tool
  
  # Nix utilities
  nix-prefetch-git
]
