{ config, pkgs, lib, ... }:

with lib;

{
  options.custom.screen-sharing = {
    enable = mkEnableOption "enhanced screen sharing support with PipeWire and XDG portals";
    
    pipewire = {
      enhance = mkOption {
        type = types.bool;
        default = true;
        description = "Enable enhanced PipeWire configuration for screen sharing";
      };
    };
    
    portals = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable XDG desktop portals for screen sharing";
      };
    };
    
    gnome = {
      remoteDesktop = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GNOME Remote Desktop service";
      };
    };
  };

  config = mkIf config.custom.screen-sharing.enable {
    
    # Enable PipeWire for screen sharing and audio
    services.pipewire = mkIf config.custom.screen-sharing.pipewire.enhance {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      
      # Enable WirePlumber session manager
      wireplumber.enable = true;
      
      # PipeWire configuration for screen sharing
      extraConfig.pipewire = {
        "context.properties" = {
          "link.max-buffers" = 16;
          "log.level" = 2;
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 8192;
          "core.daemon" = true;
          "core.name" = "pipewire-0";
        };
        "context.modules" = [
          {
            name = "libpipewire-module-rtkit";
            args = {
              "nice.level" = -15;
              "rt.prio" = 88;
              "rt.time.soft" = 200000;
              "rt.time.hard" = 200000;
            };
            flags = [ "ifexists" "nofail" ];
          }
          { name = "libpipewire-module-protocol-native"; }
          { name = "libpipewire-module-profiler"; }
          { name = "libpipewire-module-metadata"; }
          { name = "libpipewire-module-spa-device-factory"; }
          { name = "libpipewire-module-spa-node-factory"; }
          { name = "libpipewire-module-client-node"; }
          { name = "libpipewire-module-client-device"; }
          {
            name = "libpipewire-module-portal";
            flags = [ "ifexists" "nofail" ];
          }
          {
            name = "libpipewire-module-access";
            args = {};
          }
          { name = "libpipewire-module-adapter"; }
          { name = "libpipewire-module-link-factory"; }
          { name = "libpipewire-module-session-manager"; }
        ];
      };
    };
    
    # Disable PulseAudio since we're using PipeWire
    services.pulseaudio.enable = false;
    
    # Enable real-time scheduling for audio
    security.rtkit.enable = true;
    
    # Enable GNOME Remote Desktop for screen sharing
    services.gnome.gnome-remote-desktop.enable = mkIf config.custom.screen-sharing.gnome.remoteDesktop true;
    
    # XDG Desktop Portal configuration for screen sharing
    xdg.portal = mkIf config.custom.screen-sharing.portals.enable {
      enable = mkForce true;
      wlr.enable = mkForce false;  # Disable wlr portal as we're using GNOME
      extraPortals = mkForce (with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
        xdg-desktop-portal-wlr  # Include for compatibility but GNOME will have priority
      ]);
      config = mkForce {
        common = {
          default = [ "gnome" "gtk" ];
          "org.freedesktop.impl.portal.Screencast" = [ "gnome" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
          "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gnome" "gtk" ];
          "org.freedesktop.impl.portal.AppChooser" = [ "gnome" "gtk" ];
        };
        gnome = {
          default = [ "gnome" "gtk" ];
          "org.freedesktop.impl.portal.Screencast" = [ "gnome" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
          "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gnome" "gtk" ];
          "org.freedesktop.impl.portal.AppChooser" = [ "gnome" "gtk" ];
        };
        x11 = {
          default = [ "gtk" ];
          "org.freedesktop.impl.portal.Screencast" = [ "gtk" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
        };
      };
    };

    # Critical screen sharing packages
    environment.systemPackages = with pkgs; [
      # CRITICAL SCREEN SHARING PACKAGES
      gst_all_1.gstreamer         # GStreamer 1.x multimedia framework
      gst_all_1.gst-plugins-base  # Base GStreamer plugins
      gst_all_1.gst-plugins-good  # Good quality GStreamer plugins
      gst_all_1.gst-plugins-bad   # Additional GStreamer plugins
      gst_all_1.gst-plugins-ugly  # Additional GStreamer plugins
      pipewire                     # Audio/video server (includes GStreamer plugin)
      wireplumber                  # PipeWire session manager
      
      # Enhanced XDG and desktop integration - CRITICAL FOR SCREEN SHARING
      xdg-desktop-portal           # Desktop portal framework for sandboxed apps
      xdg-desktop-portal-gnome     # GNOME implementation of desktop portals
      xdg-desktop-portal-gtk       # GTK implementation of desktop portals
      xdg-desktop-portal-wlr       # wlroots implementation for additional support
    ];

    # Screen sharing environment variables
    environment.sessionVariables = {
      # Ensure Wayland display is available for screen sharing
      WAYLAND_DISPLAY = mkForce "wayland-0";
      # Critical for portal detection - use mkForce to override conflicts
      XDG_SESSION_TYPE = mkForce "wayland";
      # PipeWire runtime directory
      PIPEWIRE_RUNTIME_DIR = mkForce "/run/user/$(id -u)";
    };
  };
}
