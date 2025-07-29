{ config, pkgs, lib, ... }:

{
  # Desktop portal configuration for Electron apps on NixOS
  services.dbus.enable = true;
  
  # XDG Desktop Portal configuration
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config = {
      common = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.Print" = [ "gtk" ];
        "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
        "org.freedesktop.impl.portal.Inhibit" = [ "gtk" ];
        "org.freedesktop.impl.portal.Access" = [ "gtk" ];
        "org.freedesktop.impl.portal.Account" = [ "gtk" ];
        "org.freedesktop.impl.portal.Email" = [ "gtk" ];
        "org.freedesktop.impl.portal.DynamicLauncher" = [ "gtk" ];
        "org.freedesktop.impl.portal.Lockdown" = [ "gtk" ];
        "org.freedesktop.impl.portal.Background" = [ "gtk" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gtk" ];
        "org.freedesktop.impl.portal.Wallpaper" = [ "gtk" ];
      };
    };
  };
  
  # System packages needed for desktop portals
  environment.systemPackages = with pkgs; [
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
    gsettings-desktop-schemas
    glib
    gtk3
    zenity
    yad
    nautilus
    appimage-run
  ];
  
  # Environment variables for Electron apps
  environment.sessionVariables = {
    # Desktop portal configuration
    XDG_CURRENT_DESKTOP = "GNOME";
    XDG_SESSION_DESKTOP = "gnome";
    XDG_SESSION_TYPE = "wayland";
    GTK_USE_PORTAL = "1";
    
    # GSETTINGS configuration
    GSETTINGS_SCHEMA_DIR = "/run/current-system/sw/share/gsettings-schemas/gsettings-desktop-schemas/glib-2.0/schemas";
  };
  
  # Systemd user services for desktop portals
  systemd.user.services = {
    xdg-desktop-portal = {
      description = "Desktop Portal";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.portal.Desktop";
        ExecStart = "${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal";
        Restart = "on-failure";
        Environment = [
          "XDG_CURRENT_DESKTOP=GNOME"
          "XDG_SESSION_DESKTOP=gnome"
          "GTK_USE_PORTAL=1"
        ];
      };
    };
    
    xdg-desktop-portal-gtk = {
      description = "GTK Desktop Portal";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "xdg-desktop-portal.service" ];
      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.impl.portal.desktop.gtk";
        ExecStart = "${pkgs.xdg-desktop-portal-gtk}/libexec/xdg-desktop-portal-gtk";
        Restart = "on-failure";
        Environment = [
          "XDG_CURRENT_DESKTOP=GNOME"
          "XDG_SESSION_DESKTOP=gnome"
          "GTK_USE_PORTAL=1"
        ];
      };
    };
  };
  
  # Create system-wide portals configuration
  environment.etc."xdg/xdg-desktop-portal/portals.conf".text = ''
    [preferred]
    default=gtk
    org.freedesktop.impl.portal.FileChooser=gtk
    org.freedesktop.impl.portal.AppChooser=gtk
    org.freedesktop.impl.portal.Print=gtk
    org.freedesktop.impl.portal.Notification=gtk
    org.freedesktop.impl.portal.Inhibit=gtk
    org.freedesktop.impl.portal.Access=gtk
    org.freedesktop.impl.portal.Account=gtk
    org.freedesktop.impl.portal.Email=gtk
    org.freedesktop.impl.portal.DynamicLauncher=gtk
    org.freedesktop.impl.portal.Lockdown=gtk
    org.freedesktop.impl.portal.Background=gtk
    org.freedesktop.impl.portal.Screenshot=gtk
    org.freedesktop.impl.portal.Wallpaper=gtk
  '';
}

