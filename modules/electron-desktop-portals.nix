{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.electron-portals = {
      enable = mkEnableOption "Electron desktop portals configuration";
      
      apps = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Install Electron app compatibility packages";
        };
      };
      
      portals = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Configure XDG desktop portals for Electron apps";
        };
        
        timeout = mkOption {
          type = types.int;
          default = 30;
          description = "Timeout in seconds for portal readiness check";
        };
      };
      
      environment = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Set environment variables for Electron apps";
        };
      };
    };
  };

  config = mkIf config.custom.electron-portals.enable {
  # Desktop portal configuration for Electron apps on NixOS
  # This module provides enhanced XDG Desktop Portal support specifically for Electron applications
  
    # System packages needed for desktop portals and Electron app integration
    environment.systemPackages = mkIf config.custom.electron-portals.apps.enable (with pkgs; [
    # Core desktop portal packages
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
    
    # GTK and GNOME integration
    gsettings-desktop-schemas
    glib
    gtk3
    gtk4
    
    # Dialog and notification utilities for Electron apps
    zenity          # Native dialogs for web applications
    yad             # Advanced dialog tool
    
    # File manager integration
    nautilus        # Required for file picker integration
    
    # AppImage support for Electron apps distributed as AppImages
    appimage-run
    
      # Additional utilities for Electron app compatibility
      xdg-utils       # Desktop integration utilities
      desktop-file-utils  # Desktop file management
    ]);
  
    # Environment variables for enhanced Electron app integration
    environment.sessionVariables = mkIf config.custom.electron-portals.environment.enable {
    # Desktop environment identification for proper portal selection
    XDG_CURRENT_DESKTOP = "GNOME";
    XDG_SESSION_DESKTOP = "gnome";
    XDG_SESSION_TYPE = "wayland";
    
    # Force GTK portal usage for consistent behavior
    GTK_USE_PORTAL = "1";
    
    # GSETTINGS configuration for proper theme and settings integration
    GSETTINGS_SCHEMA_DIR = "/run/current-system/sw/share/gsettings-schemas/gsettings-desktop-schemas/glib-2.0/schemas";
    
    # Additional environment variables for Electron apps
    ELECTRON_DISABLE_SECURITY_WARNINGS = "true";  # Reduce console noise in development
    ELECTRON_ENABLE_LOGGING = "true";             # Enable logging for debugging
    
    # Ensure proper XDG directories are set
    XDG_DATA_DIRS = lib.mkDefault "/run/current-system/sw/share:/usr/share:/usr/local/share";
      XDG_CONFIG_DIRS = lib.mkDefault "/run/current-system/sw/etc/xdg:/etc/xdg";
    };
  
    # Additional portal configuration for Electron apps
    # Note: This supplements the main XDG portal configuration in configuration.nix
    # It provides fallback portal preferences specifically for Electron applications
    environment.etc."xdg/xdg-desktop-portal/electron-portals.conf" = mkIf config.custom.electron-portals.portals.enable {
      text = ''
    # Electron-specific portal preferences
    # This file provides fallback configurations for Electron applications
    
    [preferred]
    # Use GTK portal as primary choice for better Electron compatibility
    default=gtk;gnome
    
    # Specific portal assignments for common Electron app needs
    org.freedesktop.impl.portal.FileChooser=gtk;gnome
    org.freedesktop.impl.portal.AppChooser=gtk;gnome
    org.freedesktop.impl.portal.Print=gtk;gnome
    org.freedesktop.impl.portal.Notification=gnome;gtk
    org.freedesktop.impl.portal.Inhibit=gnome;gtk
    org.freedesktop.impl.portal.Access=gnome;gtk
    org.freedesktop.impl.portal.Account=gnome;gtk
    org.freedesktop.impl.portal.Email=gnome;gtk
    org.freedesktop.impl.portal.DynamicLauncher=gnome;gtk
    org.freedesktop.impl.portal.Lockdown=gnome;gtk
    org.freedesktop.impl.portal.Background=gnome;gtk
    org.freedesktop.impl.portal.Screenshot=gnome;gtk
    org.freedesktop.impl.portal.Wallpaper=gnome;gtk
        org.freedesktop.impl.portal.Settings=gnome;gtk
      '';
    };
  
    # Create desktop entries for common Electron apps with proper portal integration
    environment.etc."xdg/autostart/electron-portal-setup.desktop" = mkIf config.custom.electron-portals.portals.enable {
      text = ''
    [Desktop Entry]
    Name=Electron Portal Setup
    Comment=Setup desktop portals for Electron applications
    Type=Application
    Exec=${pkgs.coreutils}/bin/true
    Hidden=true
    NoDisplay=true
    X-GNOME-Autostart-Phase=Initialization
        X-GNOME-AutoRestart=false
      '';
    };
  
    # Systemd user service to ensure portals are ready for Electron apps
    systemd.user.services.electron-portal-ready = mkIf config.custom.electron-portals.portals.enable {
    description = "Wait for desktop portals to be ready for Electron applications";
    wantedBy = [ "default.target" ];
    after = [ "xdg-desktop-portal.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeScript "electron-portal-ready" ''
        #!/bin/bash
        # Wait for XDG desktop portal to be fully initialized
        timeout=${toString config.custom.electron-portals.portals.timeout}
        count=0
        
        while [ $count -lt $timeout ]; do
          if ${pkgs.dbus}/bin/dbus-send --session --dest=org.freedesktop.portal.Desktop --type=method_call --print-reply /org/freedesktop/portal/desktop org.freedesktop.DBus.Peer.Ping >/dev/null 2>&1; then
            echo "Desktop portals ready for Electron applications"
            exit 0
          fi
          sleep 1
          count=$((count + 1))
        done
        
        echo "Warning: Desktop portals not ready after $timeout seconds"
        exit 0  # Don't fail the service, just warn
      '';
        RemainAfterExit = true;
      };
    };
  };
}

