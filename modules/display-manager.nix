{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.desktop = {
      enable = mkEnableOption "desktop environment with GDM and GNOME";
      wayland.enable = mkEnableOption "force Wayland session" // { default = true; };
      
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
              default = lib.mkDefault [ "gnome" ];
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
    })
    
    # GNOME desktop environment configuration
    (mkIf config.custom.desktop.gnome.enable {
    # Enable GNOME desktop environment
    services.xserver.desktopManager.gnome = {
      enable = true;
      # GNOME Shell configuration with custom theme
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
        enabled-extensions=['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com', 'blur-my-shell@aunetx', 'caffeine@patapon.info']
        
        [org.gnome.shell.extensions.dash-to-dock]
        dock-position='BOTTOM'
        transparency-mode='DYNAMIC'
        running-indicator-style='DOTS'
        
        [org.gnome.mutter]
        experimental-features=['scale-monitor-framebuffer']
        attach-modal-dialogs=true
        dynamic-workspaces=true
        workspaces-only-on-primary=false

        [org.gnome.desktop.session]
        idle-delay=300
      '';
    };
    
    # Ensure Wayland is the default session
    services.displayManager.defaultSession = "gnome";
    
    # Enable GNOME services
    services.gnome = {
      core-apps.enable = true;
      gnome-keyring.enable = true;
      gnome-online-accounts.enable = true;
      evolution-data-server.enable = true;
    };
    
    # GNOME appearance and behavior tweaks
    environment.gnome.excludePackages = mkIf config.custom.desktop.gnome.excludeApps.enable (with pkgs; [
      # Remove unwanted GNOME apps to keep system clean
      gnome-tour
      epiphany  # GNOME web browser
      geary     # Email client
      totem     # Video player (we have better alternatives)
    ]);
    
    # GNOME-specific system packages
    environment.systemPackages = with pkgs; [
      # GNOME utilities and tools
      gnome-tweaks
      gnome-shell-extensions
      dconf-editor
      
      # File manager integration
      nautilus
      file-roller  # Archive manager
      
      # Additional GNOME applications
      gnome-calculator
      gnome-calendar
      gnome-clocks
      gnome-weather
      gnome-maps
      
      # Theme and appearance
      papirus-icon-theme
      adwaita-icon-theme
      gnome-themes-extra
      
      # System integration
      xdg-utils
      xdg-user-dirs
    ];
  })
  ];
}
