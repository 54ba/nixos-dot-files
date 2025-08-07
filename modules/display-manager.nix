{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.desktop = {
      enable = mkEnableOption "desktop environment with GDM and GNOME";
      wayland.enable = mkEnableOption "force Wayland session" // { default = true; };
    };
  };

  config = mkIf config.custom.desktop.enable {
    # X11 and Wayland configuration
    services.xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
      
      # Configure GDM display manager
      displayManager.gdm = {
        enable = true;
        wayland = config.custom.desktop.wayland.enable;
      };
      
    };
    
    # Enable additional GNOME services
    services.udev.packages = with pkgs; [ gnome-settings-daemon ];
    
    # Enable dconf for GNOME tools
    programs.dconf.enable = true;
    
    # XDG portals
    xdg = {
      portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
        config = {
          common = {
            default = [ "gnome" ];
          };
        };
      };
      mime = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "x-scheme-handler/chrome" = "firefox.desktop";
          "text/html" = "firefox.desktop";
          "application/x-extension-htm" = "firefox.desktop";
          "application/x-extension-html" = "firefox.desktop";
          "application/x-extension-shtml" = "firefox.desktop";
          "application/xhtml+xml" = "firefox.desktop";
          "application/x-extension-xhtml" = "firefox.desktop";
          "application/x-extension-xht" = "firefox.desktop";
          "inode/directory" = "org.gnome.Nautilus.desktop";
        };
      };
    };
  };
}
