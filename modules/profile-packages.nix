{ config, pkgs, lib, ... }:

with lib;

{
  options.custom.profile-packages = {
    enable = mkEnableOption "packages migrated from nix profiles";
  };

  config = mkIf config.custom.profile-packages.enable {
    environment.systemPackages = with pkgs; [
      # Graphics and display libraries
      alsa-lib           # ALSA sound library
      glib              # GLib library
      gtk3              # GTK3 toolkit
      nss               # Network Security Services
      
      # X11 libraries and utilities
      xorg.libXScrnSaver  # X11 Screen Saver extension library
      xorg.libXtst        # X11 Testing extension library
      xorg.xauth          # X11 authorization utilities
      xvfb-run           # Virtual framebuffer X server runner
      
      # Development and system tools
      nix-index          # Nix package indexing for finding packages
      
      # LaTeX and document processing
      texlive.combined.scheme-full  # Complete TeXLive distribution
      tikzit             # TikZ diagram editor
      
      # Note: libnotify is already included in essential-packages.nix
    ];
    
    # Enable some services that these packages might need
    services.xserver.enable = mkDefault true;  # For X11 libraries
  };
}