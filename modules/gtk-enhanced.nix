{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.gtk = {
      enable = mkEnableOption "Enhanced GTK theming and application support";
      
      version = mkOption {
        type = types.enum [ "3" "4" "both" ];
        default = "both";
        description = "GTK version support";
      };
      
      theming = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable system-wide GTK theming";
        };
        
        theme = mkOption {
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
        
        cursorSize = mkOption {
          type = types.int;
          default = 24;
          description = "Cursor size in pixels";
        };
        
        fontName = mkOption {
          type = types.str;
          default = "Cantarell 11";
          description = "Default font name and size";
        };
      };
      
      wayland = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Wayland-specific GTK optimizations";
        };
        
        fractionalScaling = mkOption {
          type = types.bool;
          default = true;
          description = "Enable fractional scaling support";
        };
        
        touchScrolling = mkOption {
          type = types.bool;
          default = true;
          description = "Enable touch scrolling optimizations";
        };
      };
      
      performance = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable GTK performance optimizations";
        };
        
        animations = mkOption {
          type = types.bool;
          default = true;
          description = "Enable smooth animations";
        };
        
        rendering = mkOption {
          type = types.enum [ "auto" "cairo" "gl" ];
          default = "auto";
          description = "GTK rendering backend";
        };
      };
      
      applications = {
        fileChooser = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable enhanced file chooser";
          };
          
          thumbnails = mkOption {
            type = types.bool;
            default = true;
            description = "Enable thumbnails in file chooser";
          };
        };
        
        integration = mkOption {
          type = types.bool;
          default = true;
          description = "Enable desktop integration features";
        };
      };
    };
  };

  config = mkIf config.custom.gtk.enable {
    # === GTK THEMING CONFIGURATION ===
    environment.sessionVariables = {
      # GTK theme settings
      GTK_THEME = config.custom.gtk.theming.theme;
      GTK2_RC_FILES = "${pkgs.gtk2}/share/themes/${config.custom.gtk.theming.theme}/gtk-2.0/gtkrc";
      
      # Icon and cursor themes
      XCURSOR_THEME = config.custom.gtk.theming.cursorTheme;
      XCURSOR_SIZE = toString config.custom.gtk.theming.cursorSize;
      
      # GTK application preferences
      GTK_CSD = "1";                    # Enable client-side decorations
      GTK_USE_PORTAL = "1";            # Use XDG portals
      
    } // optionalAttrs config.custom.gtk.wayland.enable {
      # Wayland-specific GTK settings
      GDK_BACKEND = "wayland,x11";
      GDK_SCALE = "1";                 # Let GTK handle scaling
      GDK_DPI_SCALE = "1.0";
      
    } // optionalAttrs config.custom.gtk.wayland.fractionalScaling {
      # Fractional scaling support
      GDK_SCALE = "auto";
      
    } // optionalAttrs config.custom.gtk.performance.enable {
      # Performance optimizations
      GTK_DEBUG = "";                  # Disable debugging
      G_MESSAGES_DEBUG = "";           # Disable debug messages
      GOBJECT_DEBUG = "";              # Disable GObject debugging
      
    } // optionalAttrs (config.custom.gtk.performance.rendering != "auto") {
      # Rendering backend
      GSK_RENDERER = config.custom.gtk.performance.rendering;
    };
    
    # === GTK CONFIGURATION FILES ===
    environment.etc = mkMerge [
      # GTK 3 configuration
      (mkIf (config.custom.gtk.version == "3" || config.custom.gtk.version == "both") {
        "gtk-3.0/settings.ini".text = ''
          [Settings]
          gtk-theme-name=${config.custom.gtk.theming.theme}
          gtk-icon-theme-name=${config.custom.gtk.theming.iconTheme}
          gtk-cursor-theme-name=${config.custom.gtk.theming.cursorTheme}
          gtk-cursor-theme-size=${toString config.custom.gtk.theming.cursorSize}
          gtk-font-name=${config.custom.gtk.theming.fontName}
          gtk-application-prefer-dark-theme=${if hasSuffix "dark" (toLower config.custom.gtk.theming.theme) then "true" else "false"}
          gtk-enable-primary-paste=true
          gtk-recent-files-enabled=true
          gtk-recent-files-max-age=30
          gtk-enable-event-sounds=true
          gtk-enable-input-feedback-sounds=false
          ${optionalString config.custom.gtk.performance.animations "gtk-enable-animations=true"}
          ${optionalString (!config.custom.gtk.performance.animations) "gtk-enable-animations=false"}
          ${optionalString config.custom.gtk.applications.fileChooser.enable "gtk-dialogs-use-header=true"}
          ${optionalString config.custom.gtk.applications.fileChooser.thumbnails "gtk-file-chooser-backend=gio"}
        '';
        
        "gtk-3.0/gtk.css".text = ''
          /* === CUSTOM GTK 3 STYLING === */
          
          /* Window decorations */
          .titlebar {
            border-radius: 8px 8px 0 0;
          }
          
          /* Scrollbars */
          scrollbar {
            background: transparent;
          }
          
          scrollbar slider {
            background: alpha(@theme_fg_color, 0.3);
            border-radius: 6px;
            min-width: 8px;
            min-height: 8px;
          }
          
          scrollbar slider:hover {
            background: alpha(@theme_fg_color, 0.5);
          }
          
          /* File chooser enhancements */
          ${optionalString config.custom.gtk.applications.fileChooser.enable ''
            .file-chooser .sidebar {
              border-right: 1px solid alpha(@theme_fg_color, 0.1);
            }
            
            .file-chooser .view {
              background: @theme_base_color;
            }
          ''}
          
          /* Performance optimizations */
          ${optionalString config.custom.gtk.performance.enable ''
            * {
              -gtk-outline-radius: 2px;
            }
            
            .background {
              background-clip: padding-box;
            }
          ''}
        '';
      })
      
      # GTK 4 configuration
      (mkIf (config.custom.gtk.version == "4" || config.custom.gtk.version == "both") {
        "gtk-4.0/settings.ini".text = ''
          [Settings]
          gtk-theme-name=${config.custom.gtk.theming.theme}
          gtk-icon-theme-name=${config.custom.gtk.theming.iconTheme}
          gtk-cursor-theme-name=${config.custom.gtk.theming.cursorTheme}
          gtk-cursor-theme-size=${toString config.custom.gtk.theming.cursorSize}
          gtk-font-name=${config.custom.gtk.theming.fontName}
          gtk-application-prefer-dark-theme=${if hasSuffix "dark" (toLower config.custom.gtk.theming.theme) then "true" else "false"}
          gtk-primary-button-warps-slider=false
          gtk-overlay-scrolling=true
          gtk-enable-primary-paste=true
          gtk-recent-files-enabled=true
          gtk-recent-files-max-age=30
          ${optionalString config.custom.gtk.performance.animations "gtk-enable-animations=true"}
          ${optionalString (!config.custom.gtk.performance.animations) "gtk-enable-animations=false"}
        '';
        
        "gtk-4.0/gtk.css".text = ''
          /* === CUSTOM GTK 4 STYLING === */
          
          /* Modern window styling */
          window {
            background: @theme_base_color;
          }
          
          headerbar {
            border-radius: 12px 12px 0 0;
            background: @theme_bg_color;
            box-shadow: 0 1px 3px alpha(@theme_fg_color, 0.1);
          }
          
          /* Enhanced scrollbars */
          scrollbar {
            background: transparent;
            transition: all 200ms ease;
          }
          
          scrollbar slider {
            background: alpha(@theme_fg_color, 0.3);
            border-radius: 8px;
            min-width: 6px;
            min-height: 6px;
            margin: 2px;
            transition: all 200ms ease;
          }
          
          scrollbar slider:hover {
            background: alpha(@theme_fg_color, 0.5);
            min-width: 8px;
            min-height: 8px;
            margin: 1px;
          }
          
          /* File manager enhancements */
          ${optionalString config.custom.gtk.applications.fileChooser.enable ''
            filechooser .sidebar {
              border-right: 1px solid alpha(@theme_fg_color, 0.08);
              background: alpha(@theme_bg_color, 0.5);
            }
            
            filechooser .view {
              background: @theme_base_color;
            }
            
            filechooser button {
              border-radius: 8px;
            }
          ''}
          
          /* Touch-friendly sizing */
          ${optionalString config.custom.gtk.wayland.touchScrolling ''
            button {
              min-height: 32px;
              min-width: 32px;
            }
            
            entry {
              min-height: 32px;
            }
            
            .large-button {
              min-height: 40px;
              min-width: 40px;
            }
          ''}
        '';
      })
    ];
    
    # === GTK PACKAGES ===
    environment.systemPackages = with pkgs; [
      # === GTK RUNTIME LIBRARIES ===
    ] ++ optionals (config.custom.gtk.version == "3" || config.custom.gtk.version == "both") [
      gtk3
      gtk3.dev
      
    ] ++ optionals (config.custom.gtk.version == "4" || config.custom.gtk.version == "both") [
      gtk4
      gtk4.dev
      
    ] ++ optionals config.custom.gtk.theming.enable [
      # === THEMES ===
      adwaita-icon-theme
      papirus-icon-theme
      gnome-themes-extra
      gtk-engine-murrine
      arc-theme
      numix-gtk-theme
      
      # === THEME TOOLS ===
      lxappearance          # GTK theme manager
      dconf-editor          # For advanced GTK settings
      
    ] ++ optionals config.custom.gtk.applications.integration [
      # === INTEGRATION TOOLS ===
      xdg-utils
      xdg-user-dirs
      shared-mime-info
      desktop-file-utils
      
    ];
    
    # === XDG MIME CONFIGURATION ===
    xdg.mime.enable = mkIf config.custom.gtk.applications.integration true;
    
    # === FONT CONFIGURATION FOR GTK ===
    fonts.fontconfig = {
      enable = true;
      
      # GTK-specific font rendering
      defaultFonts = {
        sansSerif = [ "Cantarell" "Liberation Sans" "DejaVu Sans" ];
        serif = [ "Liberation Serif" "DejaVu Serif" ];
        monospace = [ "Source Code Pro" "Liberation Mono" "DejaVu Sans Mono" ];
      };
      
      # Optimize for GTK applications
      localConf = ''
        <!-- GTK application optimizations -->
        <alias>
          <family>system-ui</family>
          <prefer>
            <family>Cantarell</family>
            <family>Liberation Sans</family>
            <family>DejaVu Sans</family>
          </prefer>
        </alias>
        
        <!-- Better hinting for GUI applications -->
        <match target="font">
          <test name="prgname" compare="eq">
            <string>gtk</string>
          </test>
          <edit name="hintstyle" mode="assign">
            <const>hintslight</const>
          </edit>
          <edit name="antialias" mode="assign">
            <bool>true</bool>
          </edit>
        </match>
      '';
    };
    
    # === PORTAL CONFIGURATION ===
    xdg.portal = mkIf config.custom.gtk.applications.integration {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
      config = {
        common = {
          default = [ "gtk" ];
        };
      };
    };
    
    # === SERVICES FOR GTK APPLICATIONS ===
    services.dbus.packages = with pkgs; [
      gtk3
    ] ++ optionals (config.custom.gtk.version == "4" || config.custom.gtk.version == "both") [
      gtk4
    ];
    
    # === ENVIRONMENT OPTIMIZATIONS ===
    programs.dconf.enable = true;  # Required for GTK settings
    
    # === PERFORMANCE TUNING ===
    boot.kernel.sysctl = mkIf config.custom.gtk.performance.enable {
      # Memory management for GUI applications
      "vm.swappiness" = 10;                    # Reduce swap usage
      "vm.vfs_cache_pressure" = 50;           # Keep file system cache
      "kernel.sched_autogroup_enabled" = 1;   # Better desktop responsiveness
    };
    
    # === HOME MANAGER INTEGRATION ===
    # Note: These settings can be overridden by user-specific home-manager configs
    programs.bash.interactiveShellInit = ''
      # GTK application startup optimization
      export GTK_PATH="${pkgs.gtk3}/lib/gtk-3.0:${pkgs.gtk4}/lib/gtk-4.0"
      
      ${optionalString config.custom.gtk.wayland.enable ''
        # Wayland-specific GTK optimizations
        export GDK_BACKEND=wayland,x11
        export GDK_SCALE=1
      ''}
      
      ${optionalString config.custom.gtk.performance.enable ''
        # Performance optimizations
        export GTK_DEBUG=""
        export G_MESSAGES_DEBUG=""
      ''}
    '';
  };
}
