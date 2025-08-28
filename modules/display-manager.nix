{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.desktop = {
      enable = mkEnableOption "desktop environment with GDM and GNOME";
      wayland.enable = mkEnableOption "force Wayland session";

      gnome = {
        enable = mkEnableOption "GNOME desktop environment with custom configuration";

        extensions.enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable GNOME Shell extensions";
        };

        excludeApps.enable = mkOption {
          type = types.bool;
          default = true;
          description = "Exclude unwanted GNOME applications";
        };

        theme = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable custom GNOME theming";
          };

          gtkTheme = mkOption {
            type = types.str;
            default = "Adwaita-dark";
            description = "GTK theme to use";
          };

          iconTheme = mkOption {
            type = types.str;
            default = "Papirus-Dark";
            description = "Icon theme to use";
          };

          cursorTheme = mkOption {
            type = types.str;
            default = "Adwaita";
            description = "Cursor theme to use";
          };
        };
      };
    };
  };

  config = mkMerge [
    (mkIf config.custom.desktop.enable {
      # X11 and Wayland configuration
      services.xserver = {
        enable = true;
        xkb = {
          layout = "us";
          variant = "";
        };

        # Configure GDM display manager
        displayManager = {
          gdm = {
            enable = true;
            wayland = config.custom.desktop.wayland.enable;
            debug = true;
          };
          # Ensure proper session handling
          sessionCommands = ''
            # Fix potential TTY issues
            ${pkgs.kbd}/bin/setfont ter-v16n
          '';
        };
      };

      # Enable additional GNOME services with fixes
      services = {
        udev.packages = with pkgs; [ gnome-settings-daemon ];
        dbus.packages = [ pkgs.dconf ];
        gnome = {
          core-apps.enable = true;
          core-shell.enable = true;
          gnome-keyring.enable = true;
          gnome-online-accounts.enable = true;
          evolution-data-server.enable = true;
          glib-networking.enable = true;
          gnome-settings-daemon.enable = true;
        };
      };

      # Fix TTY access
      console = {
        enable = true;
        keyMap = "us";
        font = "${pkgs.terminus_font}/share/consolefonts/ter-v16n.psf.gz";
      };

      # Enable dconf and required system services
      programs = {
        dconf.enable = true;
        gnome-terminal.enable = true;
      };

      # XDG portals with proper GNOME integration
      xdg = {
        portal = {
          enable = true;
          extraPortals = [ 
            pkgs.xdg-desktop-portal-gnome
            pkgs.xdg-desktop-portal-gtk 
          ];
          config = {
            common = {
              default = [ "gnome" "gtk" ];
            };
          };
        };
        mime.enable = true;
      };

      # Required system packages
      environment.systemPackages = with pkgs; [
        gnome-session
        ibus
        polkit_gnome
      ];

      # Ensure polkit authentication agent is running
      systemd = {
        user.services.polkit-gnome-authentication-agent-1 = {
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
      };
    })

    # GNOME desktop environment configuration
    (mkIf config.custom.desktop.gnome.enable {
      services.xserver.desktopManager.gnome = {
        enable = true;
        extraGSettingsOverrides = mkIf config.custom.desktop.gnome.theme.enable ''
          [org.gnome.desktop.interface]
          gtk-theme='${config.custom.desktop.gnome.theme.gtkTheme}'
          icon-theme='${config.custom.desktop.gnome.theme.iconTheme}'
          cursor-theme='${config.custom.desktop.gnome.theme.cursorTheme}'
          enable-animations=true
          enable-hot-corners=true

          [org.gnome.desktop.wm.preferences]
          theme='${config.custom.desktop.gnome.theme.gtkTheme}'
          button-layout='appmenu:minimize,maximize,close'

          [org.gnome.shell]
          enabled-extensions=['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com']

          [org.gnome.shell.extensions.dash-to-dock]
          dock-position='BOTTOM'
          transparency-mode='DYNAMIC'
          running-indicator-style='DOTS'

          [org.gnome.mutter]
          experimental-features=['scale-monitor-framebuffer']

          [org.gnome.desktop.session]
          idle-delay=300
        '';
      };

      # Essential GNOME packages
      environment.systemPackages = with pkgs; [
        gnome-tweaks
        gnome-shell-extensions
        dconf-editor
        nautilus
        gnome-terminal
        papirus-icon-theme
        adwaita-icon-theme
        gnome-themes-extra
      ];

      # Enable GNOME keyring PAM integration
      security.pam.services = {
        gdm.enableGnomeKeyring = true;
        gdm-password.enableGnomeKeyring = true;
        login.enableGnomeKeyring = true;
      };
    })
  ];
}
