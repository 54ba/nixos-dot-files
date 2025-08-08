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

    # Enable XDG desktop portal with proper backend configuration
    services.dbus.enable = true;
    
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
      
      config = {
        common = {
          default = [ "gnome" "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.Print" = [ "gtk" ];
          "org.freedesktop.impl.portal.Notification" = [ "gnome" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome" ];
          "org.freedesktop.impl.portal.Settings" = [ "gnome" ];
        };
        
        gnome = {
          default = [ "gnome" "gtk" ];
        };
      };
    };
    
    # System packages needed for desktop portals and Electron app integration
    # Replace both systemPackages definitions with:
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
  
  # Dialog and notification utilities
  zenity
  libnotify
  nautilus
  appimage-run
  xdg-utils
  desktop-file-utils
  shared-mime-info
  
  # Wrapper scripts
  (pkgs.writeScriptBin "discord-fixed" ''
    #!/bin/bash
    exec /etc/electron-wrappers/discord "$@"
  '')
  (pkgs.writeScriptBin "code-fixed" ''
    #!/bin/bash
    exec /etc/electron-wrappers/code "$@"
  '')
]);
  
    # Environment variables for enhanced Electron app integration
    environment.sessionVariables = mkIf config.custom.electron-portals.environment.enable {
      # Desktop environment identification for proper portal selection
      XDG_CURRENT_DESKTOP = "GNOME";
      XDG_SESSION_DESKTOP = "gnome";
      XDG_SESSION_TYPE = "wayland";
      
      # Force portal usage for file dialogs and other desktop integration
      GTK_USE_PORTAL = "1";
      
      # Electron-specific environment variables
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      
      # Ensure proper sandboxing while allowing portal access
      ELECTRON_DISABLE_SECURITY_WARNINGS = "1";  # Reduce console noise
      
      # XDG directories for proper desktop integration
      XDG_DATA_DIRS = lib.mkForce "/run/current-system/sw/share:/usr/share:/usr/local/share";
      XDG_CONFIG_DIRS = lib.mkForce "/run/current-system/sw/etc/xdg:/etc/xdg";
    };
    
    # Enable polkit for proper authentication in desktop apps
    security.polkit.enable = true;
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  
    # Systemd user services to ensure proper portal initialization
    systemd.user.services.xdg-desktop-portal = {
      description = "Portal service (Flatpak and others)";
      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.portal.Desktop";
        ExecStart = "${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal";
        Restart = "on-failure";
        RestartSec = 3;
      };
      wantedBy = [ "default.target" ];
    };
    
    systemd.user.services.xdg-desktop-portal-gnome = {
      description = "Portal service (GNOME implementation)";
      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.impl.portal.desktop.gnome";
        ExecStart = "${pkgs.xdg-desktop-portal-gnome}/libexec/xdg-desktop-portal-gnome";
        Restart = "on-failure";
        RestartSec = 3;
      };
      wantedBy = [ "default.target" ];
    };
    
    systemd.user.services.xdg-desktop-portal-gtk = {
      description = "Portal service (GTK/GNOME implementation)";
      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.impl.portal.desktop.gtk";
        ExecStart = "${pkgs.xdg-desktop-portal-gtk}/libexec/xdg-desktop-portal-gtk";
        Restart = "on-failure";
        RestartSec = 3;
      };
      wantedBy = [ "default.target" ];
    };
    
    # Shell aliases with proper sandbox flags for Electron apps
    environment.shellAliases = {
      # Discord with proper Wayland and sandbox flags
      discord = "discord --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --disable-dev-shm-usage --enable-wayland-ime";
      
      # VS Code with proper Wayland and sandbox flags
      code = "code --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --password-store=gnome";
      
      # Chrome with proper Wayland and sandbox flags
      google-chrome = "google-chrome --enable-features=UseOzonePlatform --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --disable-dev-shm-usage";
      chrome = "google-chrome --enable-features=UseOzonePlatform --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --disable-dev-shm-usage";
      
      # Slack with proper flags
      slack = "slack --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --disable-dev-shm-usage --no-zygote";
      
      # General Electron app launcher
      electron-app = "electron --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox";
    };
    
    # Create wrapper scripts for common Electron apps with proper flags
    environment.etc."electron-wrappers/discord" = {
      text = ''
        #!/bin/bash
        export XDG_CURRENT_DESKTOP="GNOME"
        export GTK_USE_PORTAL=1
        export ELECTRON_OZONE_PLATFORM_HINT=wayland
        exec discord \
          --enable-features=UseOzonePlatform,WaylandWindowDecorations \
          --ozone-platform=wayland \
          --no-sandbox \
          --disable-gpu-sandbox \
          --disable-dev-shm-usage \
          --enable-wayland-ime \
          --gtk-version=4 \
          "$@"
      '';
      mode = "0755";
    };
    
    environment.etc."electron-wrappers/code" = {
      text = ''
        #!/bin/bash
        export XDG_CURRENT_DESKTOP="GNOME"
        export GTK_USE_PORTAL=1
        export ELECTRON_OZONE_PLATFORM_HINT=wayland
        exec code \
          --enable-features=UseOzonePlatform,WaylandWindowDecorations \
          --ozone-platform=wayland \
          --no-sandbox \
          --disable-gpu-sandbox \
          --password-store=gnome \
          "$@"
      '';
      mode = "0755";
    };
  };
}
