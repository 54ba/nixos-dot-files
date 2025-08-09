{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.gnome = {
      enable = mkEnableOption "Enhanced GNOME desktop environment with Wayland optimizations";
      
      wayland = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Force Wayland session for GNOME";
        };
        
        fractionalScaling = mkOption {
          type = types.bool;
          default = true;
          description = "Enable experimental fractional scaling";
        };
        
        variableRefreshRate = mkOption {
          type = types.bool;
          default = true;
          description = "Enable variable refresh rate support";
        };
      };
      
      performance = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable performance optimizations";
        };
        
        animations = mkOption {
          type = types.bool;
          default = true;
          description = "Enable smooth animations";
        };
        
        gpu = {
          acceleration = mkOption {
            type = types.bool;
            default = true;
            description = "Enable GPU acceleration";
          };
          
          backend = mkOption {
            type = types.enum [ "auto" "opengl" "vulkan" ];
            default = "auto";
            description = "Graphics backend to use";
          };
        };
      };
      
      theming = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable enhanced theming support";
        };
        
        scheme = mkOption {
          type = types.enum [ "default" "dark" "light" ];
          default = "dark";
          description = "Color scheme preference";
        };
        
        gtkTheme = mkOption {
          type = types.str;
          default = "Adwaita-dark";
          description = "GTK theme name";
        };
        
        iconTheme = mkOption {
          type = types.str;
          default = "Papirus-Dark";
          description = "Icon theme name";
        };
        
        cursorTheme = mkOption {
          type = types.str;
          default = "Adwaita";
          description = "Cursor theme name";
        };
        
        fontSize = mkOption {
          type = types.int;
          default = 11;
          description = "Default font size";
        };
      };
      
      extensions = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable GNOME Shell extensions";
        };
        
        list = mkOption {
          type = types.listOf types.str;
          default = [
            "user-theme@gnome-shell-extensions.gcampax.github.com"
            "dash-to-dock@micxgx.gmail.com"
            "blur-my-shell@aunetx"
            "caffeine@patapon.info"
            "appindicatorsupport@rgcjonas.gmail.com"
            "gsconnect@andyholmes.github.io"
          ];
          description = "List of GNOME Shell extensions to enable";
        };
      };
      
      applications = {
        excludeDefault = mkOption {
          type = types.bool;
          default = true;
          description = "Exclude unwanted default GNOME applications";
        };
        
        development = mkOption {
          type = types.bool;
          default = true;
          description = "Include development-focused applications";
        };
      };
    };
  };

  config = mkIf config.custom.gnome.enable {
    # === CORE GNOME DESKTOP ===
    services.xserver = {
      enable = true;
      
      # Keyboard configuration
      xkb = {
        layout = "us";
        variant = "";
        options = "caps:escape"; # Map Caps Lock to Escape
      };
      
      # GDM Display Manager with Wayland
      displayManager.gdm = {
        enable = true;
        wayland = config.custom.gnome.wayland.enable;
        autoSuspend = false; # Prevent auto-suspend during login
      };
      
      # GNOME Desktop Environment
      desktopManager.gnome = {
        enable = true;
        
        # Enhanced GSettings configuration
        extraGSettingsOverrides = ''
          # === INTERFACE SETTINGS ===
          [org.gnome.desktop.interface]
          gtk-theme='${config.custom.gnome.theming.gtkTheme}'
          icon-theme='${config.custom.gnome.theming.iconTheme}'
          cursor-theme='${config.custom.gnome.theming.cursorTheme}'
          color-scheme='${if config.custom.gnome.theming.scheme == "dark" then "prefer-dark" else if config.custom.gnome.theming.scheme == "light" then "prefer-light" else "default"}'
          font-name='Cantarell ${toString config.custom.gnome.theming.fontSize}'
          document-font-name='Cantarell ${toString config.custom.gnome.theming.fontSize}'
          monospace-font-name='Source Code Pro ${toString config.custom.gnome.theming.fontSize}'
          enable-animations=${if config.custom.gnome.performance.animations then "true" else "false"}
          enable-hot-corners=true
          gtk-enable-primary-paste=true
          text-scaling-factor=1.0
          
          # === WINDOW MANAGER ===
          [org.gnome.desktop.wm.preferences]
          theme='${config.custom.gnome.theming.gtkTheme}'
          titlebar-font='Cantarell Bold ${toString config.custom.gnome.theming.fontSize}'
          button-layout='appmenu:minimize,maximize,close'
          focus-mode='click'
          auto-raise=false
          raise-on-click=true
          
          # === MUTTER (WAYLAND COMPOSITOR) ===
          [org.gnome.mutter]
          experimental-features=${if config.custom.gnome.wayland.fractionalScaling then "['scale-monitor-framebuffer']" else "[]"}
          attach-modal-dialogs=true
          dynamic-workspaces=true
          workspaces-only-on-primary=false
          center-new-windows=true
          ${if config.custom.gnome.wayland.variableRefreshRate then "variable-refresh-rate=true" else ""}
          
          # === SHELL CONFIGURATION ===
          [org.gnome.shell]
          enabled-extensions=[${concatStringsSep ", " (map (ext: "'${ext}'") config.custom.gnome.extensions.list)}]
          disable-user-extensions=false
          development-tools=true
          
          # === PRIVACY AND SECURITY ===
          [org.gnome.desktop.privacy]
          report-technical-problems=false
          send-software-usage-stats=false
          
          [org.gnome.desktop.search-providers]
          sort-order=['org.gnome.Contacts.desktop', 'org.gnome.Documents.desktop', 'org.gnome.Nautilus.desktop']
          disable-external=false
          
          # === INPUT DEVICES ===
          [org.gnome.desktop.peripherals.touchpad]
          two-finger-scrolling-enabled=true
          tap-to-click=true
          natural-scroll=true
          speed=0.3
          
          [org.gnome.desktop.peripherals.mouse]
          natural-scroll=false
          speed=0.0
          accel-profile='default'
          
          # === SESSION MANAGEMENT ===
          [org.gnome.desktop.session]
          idle-delay=300
          
          [org.gnome.settings-daemon.plugins.power]
          sleep-inactive-ac-timeout=1800
          sleep-inactive-battery-timeout=900
          
          # === NAUTILUS FILE MANAGER ===
          [org.gnome.nautilus.preferences]
          default-folder-viewer='list-view'
          search-filter-time-type='last_modified'
          show-hidden-files=false
          
          [org.gnome.nautilus.list-view]
          use-tree-view=true
          default-zoom-level='small'
          
          # === TERMINAL SETTINGS ===
          [org.gnome.Terminal.Legacy.Settings]
          theme-variant='dark'
          
        '' + optionalString config.custom.gnome.extensions.enable ''
          # === EXTENSION SETTINGS ===
          [org.gnome.shell.extensions.dash-to-dock]
          dock-position='BOTTOM'
          dock-fixed=false
          transparency-mode='DYNAMIC'
          running-indicator-style='DOTS'
          show-favorites=true
          show-running=true
          show-windows-preview=true
          click-action='cycle-windows'
          scroll-action='cycle-windows'
          
          [org.gnome.shell.extensions.blur-my-shell]
          blur-dash=true
          blur-panel=true
          blur-overview=true
          
          [org.gnome.shell.extensions.caffeine]
          enable-fullscreen=true
          restore-state=true
          
        '';
      };
    };

    # === DEFAULT SESSION ===
    services.displayManager.defaultSession = "gnome";
    
    # === GNOME SERVICES ===
    services.gnome = {
      core-apps.enable = true;
      core-utilities.enable = true;
      gnome-keyring.enable = true;
      gnome-online-accounts.enable = true;
      evolution-data-server.enable = true;
      gnome-user-share.enable = true;
      games.enable = false; # Disable games by default
      tracker.enable = true; # For file indexing
      tracker-miners.enable = true;
    };
    
    # === SYSTEM INTEGRATION ===
    # DBus services
    services.dbus.packages = with pkgs; [
      gcr
      gnome-keyring
      gnome-settings-daemon
    ];
    
    # UDev packages
    services.udev.packages = with pkgs; [
      gnome-settings-daemon
    ];
    
    # Enable dconf
    programs.dconf.enable = true;
    
    # === XDG PORTALS ===
    xdg.portal = {
      enable = true;
      wlr.enable = mkIf config.custom.gnome.wayland.enable true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
      config = {
        common = {
          default = [ "gnome" "gtk" ];
        };
        gnome = {
          default = [ "gnome" "gtk" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
      };
    };
    
    # === MIME TYPE ASSOCIATIONS ===
    xdg.mime = {
      enable = true;
      defaultApplications = {
        # Web browsing
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/chrome" = "firefox.desktop";
        "application/x-extension-htm" = "firefox.desktop";
        "application/x-extension-html" = "firefox.desktop";
        "application/xhtml+xml" = "firefox.desktop";
        
        # File management
        "inode/directory" = "org.gnome.Nautilus.desktop";
        
        # Text editing
        "text/plain" = "org.gnome.TextEditor.desktop";
        "text/markdown" = "void-editor.desktop"; # Use Void for markdown
        
        # Code editing
        "text/x-python" = "void-editor.desktop";
        "text/x-javascript" = "void-editor.desktop";
        "text/x-typescript" = "void-editor.desktop";
        "text/x-rust" = "void-editor.desktop";
        "text/x-go" = "void-editor.desktop";
        "text/x-c" = "void-editor.desktop";
        "text/x-cpp" = "void-editor.desktop";
        "application/json" = "void-editor.desktop";
        
        # Terminal
        "application/x-terminal-emulator" = "warp-terminal.desktop";
      };
    };
    
    # === FONT CONFIGURATION ===
    fonts = {
      packages = with pkgs; [
        cantarell-fonts          # GNOME default
        source-code-pro         # Monospace
        source-sans-pro         # Sans serif
        source-serif-pro        # Serif
        noto-fonts              # Unicode coverage
        noto-fonts-emoji        # Emoji support
        liberation_ttf          # MS font compatibility
        dejavu_fonts           # Fallback fonts
        font-awesome           # Icon font
      ];
      
      fontconfig = {
        enable = true;
        defaultFonts = {
          serif = [ "Source Serif Pro" "Noto Serif" ];
          sansSerif = [ "Cantarell" "Source Sans Pro" "Noto Sans" ];
          monospace = [ "Source Code Pro" "Noto Sans Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };
        hinting = {
          enable = true;
          style = "slight";
        };
        subpixel = {
          rgba = "rgb";
          lcdfilter = "default";
        };
      };
    };
    
    # === APPLICATION PACKAGES ===
    environment.systemPackages = with pkgs; [
      # === GNOME CORE UTILITIES ===
      gnome-tweaks
      gnome-shell-extensions
      dconf-editor
      
      # === FILE MANAGEMENT ===
      nautilus
      file-roller               # Archive manager
      sushi                    # File previewer
      
      # === GNOME APPLICATIONS ===
      gnome-calculator
      gnome-calendar
      gnome-clocks
      gnome-weather
      gnome-maps
      gnome-contacts
      gnome-notes              # Simple note taking
      
      # === SYSTEM TOOLS ===
      gnome-system-monitor
      gnome-disk-utility
      gnome-usage             # System resource usage
      
      # === THEMING AND APPEARANCE ===
      papirus-icon-theme
      adwaita-icon-theme
      gnome-themes-extra
      gtk-engine-murrine      # GTK2/3 theme engine
      
      # === DEVELOPMENT INTEGRATION ===
    ] ++ optionals config.custom.gnome.applications.development [
      gnome-builder           # GNOME IDE
      d-spy                   # DBus inspector
      
    ] ++ optionals config.custom.gnome.extensions.enable [
      gnomeExtensions.user-themes
      gnomeExtensions.dash-to-dock
      gnomeExtensions.blur-my-shell
      gnomeExtensions.caffeine
      gnomeExtensions.appindicator
      gnomeExtensions.gsconnect
    ];
    
    # === ENVIRONMENT OPTIMIZATION ===
    environment.sessionVariables = {
      # GTK settings
      GTK_THEME = config.custom.gnome.theming.gtkTheme;
      
      # GNOME-specific optimizations
      GNOME_SHELL_SLOWDOWN_FACTOR = "1";
      MUTTER_DEBUG_DUMMY_MODE_SPECS = "1920x1080";
      
      # Wayland-specific
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland;xcb";
      
      # Performance
      CLUTTER_VBLANK = "1";
      COGL_ATLAS_DEFAULT_BLIT_MODE = "framebuffer";
    } // optionalAttrs config.custom.gnome.performance.gpu.acceleration {
      # GPU acceleration
      LIBVA_DRIVER_NAME = "iHD";
      VDPAU_DRIVER = "va_gl";
    };
    
    # === EXCLUDED APPLICATIONS ===
    environment.gnome.excludePackages = mkIf config.custom.gnome.applications.excludeDefault (with pkgs; [
      # Web browsers (we prefer Firefox)
      epiphany
      
      # Simple applications with better alternatives
      gnome-tour
      gnome-connections     # Remote desktop viewer
      simple-scan          # We'll use specific scanning software
      
      # Games (can be enabled separately)
      gnome-chess
      iagno
      hitori
      atomix
      
      # Less commonly used
      tali
      four-in-a-row
      gnome-robots
      gnome-nibbles
      quadrapassel
      gnome-sudoku
      gnome-mahjongg
      gnome-mines
      
      # Communication (prefer dedicated apps)
      geary               # Email client
      
      # Media (prefer specialized apps)
      totem               # Video player
    ]);
    
    # === HARDWARE INTEGRATION ===
    # Enable location services for weather, calendar, etc.
    services.geoclue2.enable = true;
    
    # Bluetooth support
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };
    services.blueman.enable = true;
    
    # Sound with PipeWire
    sound.enable = false;  # Disable ALSA
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    
    # Network management
    networking.networkmanager = {
      enable = true;
      wifi.powersave = false;  # Better WiFi performance
    };
    
    # Printing support
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        gutenprint
        hplip
      ];
    };
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    
    # Scanner support
    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.hplipWithPlugin ];
    };
  };
}
