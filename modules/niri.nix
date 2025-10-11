{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.niri = {
      enable = mkEnableOption "Niri scrollable-tiling Wayland compositor";
      
      startupPrograms = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Programs to start automatically with Niri";
      };
      
      enableGdm = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GDM integration for Niri session";
      };
      
      defaultTerminal = mkOption {
        type = types.str;
        default = "gnome-terminal";
        description = "Default terminal emulator for Niri";
      };
    };
  };

  config = mkIf config.custom.niri.enable {
    # Install Niri package
    environment.systemPackages = with pkgs; [
      niri
      # Essential tools for Niri
      waybar           # Status bar
      wofi             # Application launcher
      dunst            # Notification daemon
      wl-clipboard     # Wayland clipboard utilities
      grim             # Screenshots
      slurp            # Screen area selection
      swayidle         # Idle management
      swaylock         # Screen locker
      xdg-utils        # XDG utilities
    ];

    # Enable GDM session if requested
    services.xserver = mkIf config.custom.niri.enableGdm {
      enable = true;
      displayManager.gdm.enable = true;
      displayManager.gdm.wayland = true;
    };

    # Create Niri session desktop file for GDM
    environment.etc."xdg/wayland-sessions/niri.desktop" = mkIf config.custom.niri.enableGdm {
      text = ''
        [Desktop Entry]
        Name=Niri
        Comment=Scrollable-tiling Wayland compositor
        Exec=env XDG_CURRENT_DESKTOP=niri XDG_SESSION_DESKTOP=niri XDG_SESSION_TYPE=wayland niri --session
        Type=Application
        DesktopNames=niri
      '';
    };

    # Niri configuration directory and basic config
    environment.etc."niri/config.kdl" = {
      text = ''
        // Niri configuration file
        // See: https://github.com/YaLTeR/niri/wiki/Configuration:-Overview

        input {
            keyboard {
                xkb {
                    layout "us"
                }
            }
            
            touchpad {
                tap
                natural-scroll
                dwt
            }
        }

        layout {
            focus-ring {
                off
            }
            
            border {
                off
            }
        }

        spawn-at-startup "${config.custom.niri.defaultTerminal}"
        ${concatMapStringsSep "\n" (prog: ''spawn-at-startup "${prog}"'') config.custom.niri.startupPrograms}

        binds {
            Mod+Shift+Slash { show-hotkey-overlay; }
            
            // Terminal
            Mod+Return { spawn "${config.custom.niri.defaultTerminal}"; }
            
            // Application launcher
            Mod+D { spawn "wofi" "--show" "drun"; }
            
            // Screenshot
            Print { spawn "grim"; }
            Mod+Print { spawn "grim" "-g" "$(slurp)"; }
            
            // Window management
            Mod+H { focus-column-left; }
            Mod+L { focus-column-right; }
            Mod+J { focus-window-down; }
            Mod+K { focus-window-up; }
            
            Mod+Shift+H { move-column-left; }
            Mod+Shift+L { move-column-right; }
            Mod+Shift+J { move-window-down; }
            Mod+Shift+K { move-window-up; }
            
            // Close window
            Mod+Q { close-window; }
            
            // Workspace switching
            Mod+1 { focus-workspace 1; }
            Mod+2 { focus-workspace 2; }
            Mod+3 { focus-workspace 3; }
            Mod+4 { focus-workspace 4; }
            Mod+5 { focus-workspace 5; }
            Mod+6 { focus-workspace 6; }
            Mod+7 { focus-workspace 7; }
            Mod+8 { focus-workspace 8; }
            Mod+9 { focus-workspace 9; }
            
            Mod+Shift+1 { move-column-to-workspace 1; }
            Mod+Shift+2 { move-column-to-workspace 2; }
            Mod+Shift+3 { move-column-to-workspace 3; }
            Mod+Shift+4 { move-column-to-workspace 4; }
            Mod+Shift+5 { move-column-to-workspace 5; }
            Mod+Shift+6 { move-column-to-workspace 6; }
            Mod+Shift+7 { move-column-to-workspace 7; }
            Mod+Shift+8 { move-column-to-workspace 8; }
            Mod+Shift+9 { move-column-to-workspace 9; }
            
            // Layout
            Mod+Plus { set-column-width "+10%"; }
            Mod+Minus { set-column-width "-10%"; }
            Mod+R { switch-preset-column-width; }
            Mod+F { maximize-column; }
            Mod+Shift+F { fullscreen-window; }
            
            // Exit
            Mod+Shift+E { quit; }
        }

        // Window rules can be configured later
        // window-rule {
        //     match app-id="firefox" {
        //         default-column-width { proportion 0.75; }
        //     }
        // }
      '';
    };

    # System services and environment for Niri
    services.dbus.enable = true;
    xdg.portal = {
      enable = mkDefault true;
      wlr.enable = mkDefault true;
      extraPortals = mkDefault (with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ]);
      config.common.default = mkDefault [ "wlr" "gtk" ];
    };

    # Environment variables for Niri session
    # Note: XDG_CURRENT_DESKTOP will be set by the session file, not globally
    environment.sessionVariables = {
      NIXOS_OZONE_WL = mkDefault "1";
      MOZ_ENABLE_WAYLAND = mkDefault "1";
      QT_QPA_PLATFORM = mkDefault "wayland";
      GDK_BACKEND = mkDefault "wayland";
      WLR_NO_HARDWARE_CURSORS = mkDefault "1";
    };

    # Security and permissions
    security.polkit.enable = mkDefault true;
    security.pam.services.swaylock = mkDefault {};

    # Audio support
    services.pipewire = {
      enable = mkDefault true;
      pulse.enable = mkDefault true;
    };
    security.rtkit.enable = mkDefault true;

    # Fonts
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
    ];
  };
}