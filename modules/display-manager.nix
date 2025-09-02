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
            autoSuspend = false;
            debug = false;
          };
          # defaultSession = "gnome";  # Removed - deprecated option
          # Ensure proper session handling
          sessionCommands = ''
            # Fix potential TTY issues
            ${pkgs.kbd}/bin/setfont ter-v16n || true
            
            # Ensure proper environment for GNOME session
            export XDG_SESSION_TYPE="wayland"
            export GDK_BACKEND="wayland"
            export QT_QPA_PLATFORM="wayland"
            export CLUTTER_BACKEND="wayland"
            export SDL_VIDEODRIVER="wayland"
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
        # Ensure AccountsService is running for GDM
        accounts-daemon.enable = true;
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

    })

    # GNOME desktop environment configuration
    (mkIf config.custom.desktop.gnome.enable {
      # Enable GNOME Desktop Manager (which provides session files)
      services.xserver.desktopManager.gnome = {
        enable = true;
        extraGSettingsOverrides = mkIf config.custom.desktop.gnome.theme.enable ''
          [org.gnome.desktop.interface]
          gtk-theme='${config.custom.desktop.gnome.theme.gtkTheme}'
          icon-theme='${config.custom.desktop.gnome.theme.iconTheme}'
          cursor-theme='${config.custom.desktop.gnome.theme.cursorTheme}'
          enable-animations=true
          enable-hot-corners=false

          [org.gnome.desktop.wm.preferences]
          theme='${config.custom.desktop.gnome.theme.gtkTheme}'
          button-layout='appmenu:minimize,maximize,close'

          [org.gnome.shell]
          enabled-extensions=[]
          disable-user-extensions=false
          
          [org.gnome.desktop.session]
          idle-delay=300
          
          [org.gnome.mutter]
          dynamic-workspaces=true
          workspaces-only-on-primary=false
          experimental-features=['scale-monitor-framebuffer']
          
          [org.gnome.desktop.wm.keybindings]
          show-desktop=['<Super>d']
          
          [org.gnome.desktop.background]
          picture-options='zoom'
          primary-color='#023c88'
          secondary-color='#5789ca'
          
          [org.gnome.desktop.screensaver]
          picture-options='zoom'
          primary-color='#023c88'
          secondary-color='#5789ca'
        '';
      };

      # Essential GNOME packages (extensions disabled to prevent warnings)
      environment.systemPackages = with pkgs; [
        gnome-tweaks
        # gnome-shell-extensions  # DISABLED - Causes stage view allocation warnings
        dconf-editor
        nautilus
        gnome-terminal
        papirus-icon-theme
        adwaita-icon-theme
        gnome-themes-extra
        gjs  # REQUIRED - GNOME JavaScript interpreter for extensions
        gtk3  # REQUIRED - GTK3 runtime
        gtk3.dev  # REQUIRED - GTK3 development files
        gobject-introspection  # REQUIRED - GObject introspection
        gnome-desktop
        gsettings-desktop-schemas
      ];

      # Enable GNOME keyring PAM integration
      # Disable conflicting polkit authentication agent
      # systemd.user.services.polkit-gnome-authentication-agent-1.enable = false;
      # Ensure polkit authentication agent is running
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
      security.pam.services = {
        gdm.enableGnomeKeyring = true;
        gdm-password.enableGnomeKeyring = true;
        login.enableGnomeKeyring = true;
      };
    })
  ];
}
