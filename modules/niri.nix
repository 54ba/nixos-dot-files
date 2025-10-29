{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.niri = {
      enable = mkEnableOption "Beautiful Niri scrollable-tiling Wayland compositor";
      
      startupPrograms = mkOption {
        type = types.listOf types.str;
        default = [
          "waybar"
          "dunst"
          "swww-daemon"
          "wl-paste --watch cliphist store"
        ];
        description = "Programs to start automatically with Niri";
      };
      
      enableGdm = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GDM integration for Niri session";
      };
      
      defaultTerminal = mkOption {
        type = types.str;
        default = "alacritty";
        description = "Default terminal emulator for Niri";
      };
      
      theme = mkOption {
        type = types.str;
        default = "catppuccin-mocha";
        description = "Theme to use for Niri and components";
      };
      
      wallpaper = mkOption {
        type = types.str;
        default = "~/Pictures/wallpaper.jpg";
        description = "Default wallpaper path";
      };
    };
  };

  config = mkIf config.custom.niri.enable {
    # Install beautiful Niri package with enhanced tools
    environment.systemPackages = with pkgs; [
      niri
      
      # Essential beautiful tools
      alacritty          # Modern GPU-accelerated terminal
      waybar             # Beautiful status bar
      wofi               # Elegant application launcher
      dunst              # Beautiful notification daemon
      swww               # Smooth wallpaper daemon
      
      # Clipboard and utilities
      wl-clipboard       # Wayland clipboard utilities
      cliphist           # Clipboard history manager
      
      # Screenshots and screen tools
      grim               # Screenshots
      slurp              # Screen area selection
      satty              # Screenshot annotation tool
      
      # System tools
      swayidle           # Idle management
      swaylock-effects   # Beautiful screen locker with effects
      brightnessctl      # Brightness control
      pamixer            # Audio control
      playerctl          # Media player control
      
      # File management and utilities
      xdg-utils          # XDG utilities
      nautilus           # File manager
      networkmanagerapplet # Network management
      
      # Fonts for beauty
      nerd-fonts.fira-code  # Icon fonts
      font-awesome       # Icon font
      
      # Theme tools
      lxappearance       # GTK theme manager
      libsForQt5.qt5ct    # Qt5 theme manager
      
      # Additional beauty tools
      rofi-wayland       # Alternative launcher
      eww                # Widget system (optional)
    ];

    # Enable GDM session if requested
    services.xserver = mkIf config.custom.niri.enableGdm {
      enable = true;
      displayManager.gdm.enable = true;
      displayManager.gdm.wayland = true;
    };

    # Register beautiful Niri session with GDM
    services.displayManager.sessionPackages = mkIf config.custom.niri.enableGdm [
      (pkgs.runCommand "niri-session" {
        passthru.providedSessions = [ "niri" ];
      } ''
        mkdir -p $out/share/wayland-sessions
        cat > $out/share/wayland-sessions/niri.desktop << 'DESKTOP'
        [Desktop Entry]
        Name=Niri (Beautiful)
        Comment=Beautiful scrollable-tiling Wayland compositor
        Exec=niri-session
        Type=Application
        DesktopNames=niri
        DESKTOP
      '')
    ];

    # Beautiful Niri configuration with modern aesthetics
    environment.etc."niri/config.kdl" = {
      text = ''
        // ===== BEAUTIFUL NIRI CONFIGURATION =====
        // Modern, aesthetic setup with smooth animations and beautiful theming

        input {
            keyboard {
                xkb {
                    layout "us"
                    options "compose:ralt,caps:escape"
                }
                repeat-delay 600
                repeat-rate 25
                track-layout "global"
            }
            
            touchpad {
                tap
                natural-scroll
                dwt
                dwtp
                accel-speed 0.3
                accel-profile "adaptive"
                tap-button-map "left-right-middle"
                disabled-on-external-mouse
            }

            mouse {
                accel-speed 0.0
                accel-profile "flat"
                left-handed false
            }

            tablet {
                map-to-output "eDP-1"
            }

            touch {
                map-to-output "eDP-1"
            }
        }

        output "eDP-1" {
            mode "1920x1080@60.000"
            scale 1.0
            transform "normal"
            position x=0 y=0
        }

        layout {
            gaps 16
            center-focused-column "never"
            preset-column-widths {
                proportion 0.33333
                proportion 0.5
                proportion 0.66667
            }
            default-column-width { proportion 0.5; }

            focus-ring {
                enable true
                width 4
                active-color "#cba6f7"
                inactive-color "#45475a"
                active-gradient from="#cba6f7" to="#89b4fa" angle=45
            }
            
            border {
                enable true
                width 2
                active-color "#cba6f7"
                inactive-color "#45475a"
                active-gradient from="#cba6f7" to="#89b4fa" angle=45
            }

            struts {
                left 0
                right 0
                top 0
                bottom 0
            }
        }

        prefer-no-csd

        screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

        hotkey-overlay {
            skip-at-startup
        }

        // Beautiful animations for smooth experience
        animations {
            slowdown 1.0
            workspace-switch {
                spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001
            }
            horizontal-view-movement {
                spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
            }
            window-open {
                duration-ms 150
                curve "ease-out-expo"
            }
            window-close {
                duration-ms 150
                curve "ease-out-expo"
            }
            window-movement {
                spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
            }
            window-resize {
                spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
            }
            config-notification-open-close {
                spring damping-ratio=0.6 stiffness=1000 epsilon=0.001
            }
        }

        // Startup programs for beautiful desktop
        ${concatMapStringsSep "\n" (prog: ''spawn-at-startup "${prog}"'') config.custom.niri.startupPrograms}
        spawn-at-startup "sleep 2 && swww img ${config.custom.niri.wallpaper} --transition-fps 60 --transition-type wipe --transition-duration 2"

        // Beautiful keybindings with logical groups
        binds {
            // ===== SYSTEM =====
            Mod+Shift+Slash { show-hotkey-overlay; }
            Mod+Shift+P { power-off-monitors; }
            
            // ===== APPLICATIONS =====
            Mod+Return { spawn "${config.custom.niri.defaultTerminal}"; }
            Mod+E { spawn "nautilus"; }
            Mod+B { spawn "firefox"; }
            
            // Launchers
            Mod+D { spawn "wofi" "--show=drun" "--allow-markup" "--allow-images" "--insensitive" "--prompt=Launch"; }
            Mod+Space { spawn "wofi" "--show=drun" "--allow-markup" "--allow-images" "--insensitive" "--prompt=Launch"; }
            Mod+Tab { spawn "wofi" "--show=window" "--allow-markup" "--insensitive" "--prompt=Switch"; }
            
            // ===== SCREENSHOTS =====
            Print { spawn "grim" "~/Pictures/Screenshots/screenshot-$(date '+%Y-%m-%d_%H-%M-%S').png"; }
            Mod+Print { spawn "grim" "-g" "$(slurp)" "~/Pictures/Screenshots/screenshot-$(date '+%Y-%m-%d_%H-%M-%S').png"; }
            Mod+Shift+S { spawn "grim" "-g" "$(slurp)" "- | satty --filename - --fullscreen --output-filename ~/Pictures/Screenshots/screenshot-$(date '+%Y-%m-%d_%H-%M-%S').png"; }
            
            // ===== SYSTEM CONTROLS =====
            XF86MonBrightnessUp { spawn "brightnessctl" "set" "5%+"; }
            XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }
            XF86AudioRaiseVolume { spawn "pamixer" "-i" "5"; }
            XF86AudioLowerVolume { spawn "pamixer" "-d" "5"; }
            XF86AudioMute { spawn "pamixer" "-t"; }
            XF86AudioPlay { spawn "playerctl" "play-pause"; }
            XF86AudioNext { spawn "playerctl" "next"; }
            XF86AudioPrev { spawn "playerctl" "previous"; }
            
            // ===== CLIPBOARD =====
            Mod+V { spawn "cliphist" "list" "|" "wofi" "--dmenu" "--prompt=Clipboard" "|" "cliphist" "decode" "|" "wl-copy"; }
            
            // ===== WINDOW MANAGEMENT =====
            Mod+Left { focus-column-left; }
            Mod+Down { focus-window-down; }
            Mod+Up { focus-window-up; }
            Mod+Right { focus-column-right; }
            Mod+H { focus-column-left; }
            Mod+J { focus-window-down; }
            Mod+K { focus-window-up; }
            Mod+L { focus-column-right; }
            
            Mod+Ctrl+Left { move-column-left; }
            Mod+Ctrl+Down { move-window-down; }
            Mod+Ctrl+Up { move-window-up; }
            Mod+Ctrl+Right { move-column-right; }
            Mod+Ctrl+H { move-column-left; }
            Mod+Ctrl+J { move-window-down; }
            Mod+Ctrl+K { move-window-up; }
            Mod+Ctrl+L { move-column-right; }
            
            Mod+Home { focus-column-first; }
            Mod+End { focus-column-last; }
            Mod+Ctrl+Home { move-column-to-first; }
            Mod+Ctrl+End { move-column-to-last; }
            
            // ===== WINDOW ACTIONS =====
            Mod+Q { close-window; }
            Mod+W { close-window; }
            Mod+F { maximize-column; }
            Mod+Shift+F { fullscreen-window; }
            Mod+C { center-column; }
            
            // ===== LAYOUTS =====
            Mod+R { switch-preset-column-width; }
            Mod+Shift+R { reset-window-height; }
            Mod+Ctrl+R { toggle-window-height; }
            
            // Column width
            Mod+Plus { set-column-width "+10%"; }
            Mod+Minus { set-column-width "-10%"; }
            Mod+Equal { set-column-width "+10%"; }
            
            // Window height  
            Mod+Shift+Plus { set-window-height "+10%"; }
            Mod+Shift+Minus { set-window-height "-10%"; }
            Mod+Shift+Equal { set-window-height "+10%"; }
            
            // ===== WORKSPACES =====
            Mod+1 { focus-workspace 1; }
            Mod+2 { focus-workspace 2; }
            Mod+3 { focus-workspace 3; }
            Mod+4 { focus-workspace 4; }
            Mod+5 { focus-workspace 5; }
            Mod+6 { focus-workspace 6; }
            Mod+7 { focus-workspace 7; }
            Mod+8 { focus-workspace 8; }
            Mod+9 { focus-workspace 9; }
            Mod+0 { focus-workspace 10; }
            
            Mod+Ctrl+1 { move-column-to-workspace 1; }
            Mod+Ctrl+2 { move-column-to-workspace 2; }
            Mod+Ctrl+3 { move-column-to-workspace 3; }
            Mod+Ctrl+4 { move-column-to-workspace 4; }
            Mod+Ctrl+5 { move-column-to-workspace 5; }
            Mod+Ctrl+6 { move-column-to-workspace 6; }
            Mod+Ctrl+7 { move-column-to-workspace 7; }
            Mod+Ctrl+8 { move-column-to-workspace 8; }
            Mod+Ctrl+9 { move-column-to-workspace 9; }
            Mod+Ctrl+0 { move-column-to-workspace 10; }
            
            Mod+Shift+1 { move-window-to-workspace 1; }
            Mod+Shift+2 { move-window-to-workspace 2; }
            Mod+Shift+3 { move-window-to-workspace 3; }
            Mod+Shift+4 { move-window-to-workspace 4; }
            Mod+Shift+5 { move-window-to-workspace 5; }
            Mod+Shift+6 { move-window-to-workspace 6; }
            Mod+Shift+7 { move-window-to-workspace 7; }
            Mod+Shift+8 { move-window-to-workspace 8; }
            Mod+Shift+9 { move-window-to-workspace 9; }
            Mod+Shift+0 { move-window-to-workspace 10; }
            
            // Workspace navigation
            Mod+Page_Down { focus-workspace-down; }
            Mod+Page_Up { focus-workspace-up; }
            Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
            Mod+Ctrl+Page_Up { move-column-to-workspace-up; }
            Mod+Shift+Page_Down { move-window-to-workspace-down; }
            Mod+Shift+Page_Up { move-window-to-workspace-up; }
            
            // Mouse workspace switching  
            Mod+WheelScrollDown { focus-workspace-down; }
            Mod+WheelScrollUp { focus-workspace-up; }
            Mod+Ctrl+WheelScrollDown { move-column-to-workspace-down; }
            Mod+Ctrl+WheelScrollUp { move-column-to-workspace-up; }
            
            // ===== MONITORS =====
            Mod+Shift+Left { focus-monitor-left; }
            Mod+Shift+Right { focus-monitor-right; }
            Mod+Shift+Up { focus-monitor-up; }
            Mod+Shift+Down { focus-monitor-down; }
            Mod+Shift+H { focus-monitor-left; }
            Mod+Shift+L { focus-monitor-right; }
            Mod+Shift+K { focus-monitor-up; }
            Mod+Shift+J { focus-monitor-down; }
            
            Mod+Alt+Left { move-column-to-monitor-left; }
            Mod+Alt+Right { move-column-to-monitor-right; }
            Mod+Alt+Up { move-column-to-monitor-up; }
            Mod+Alt+Down { move-column-to-monitor-down; }
            Mod+Alt+H { move-column-to-monitor-left; }
            Mod+Alt+L { move-column-to-monitor-right; }
            Mod+Alt+K { move-column-to-monitor-up; }
            Mod+Alt+J { move-column-to-monitor-down; }
            
            // ===== SESSION =====
            Mod+Shift+E { quit; }
            Mod+Shift+Q { quit; }
            
            // ===== DEBUGGING (remove in production) =====
            Mod+Shift+Ctrl+T { toggle-debug-tint; }
        }

        // Beautiful window rules for specific applications
        window-rule {
            match app-id="firefox" {
                default-column-width { proportion 0.75; }
                min-width 800
                min-height 600
            }
        }
        
        window-rule {
            match app-id="Alacritty" {
                default-column-width { proportion 0.5; }
                min-width 400
                min-height 300
            }
        }
        
        window-rule {
            match app-id="nautilus" {
                default-column-width { proportion 0.6; }
                min-width 600
                min-height 400
            }
        }
        
        window-rule {
            match app-id="gnome-calculator" {
                default-column-width { fixed 400; }
                min-width 300
                min-height 400
            }
        }
        
        window-rule {
            match app-id="pavucontrol" {
                default-column-width { proportion 0.4; }
                min-width 500
                min-height 400
            }
        }
      '';
    };

    # System services and environment for beautiful Niri
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

    # Beautiful environment variables for Niri session
    environment.sessionVariables = {
      NIXOS_OZONE_WL = mkDefault "1";
      MOZ_ENABLE_WAYLAND = mkDefault "1";
      QT_QPA_PLATFORM = mkDefault "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = mkDefault "1";
      GDK_BACKEND = mkDefault "wayland,x11";
      CLUTTER_BACKEND = mkDefault "wayland";
      XDG_CURRENT_DESKTOP = mkForce "niri";
      XDG_SESSION_DESKTOP = mkDefault "niri";
      XDG_SESSION_TYPE = mkDefault "wayland";
      WLR_NO_HARDWARE_CURSORS = mkDefault "1";
      _JAVA_AWT_WM_NONREPARENTING = mkDefault "1";
    };

    # Security and permissions
    security.polkit.enable = mkDefault true;
    security.pam.services.swaylock = mkDefault {};

    # Beautiful audio support with low latency
    services.pipewire = {
      enable = mkDefault true;
      pulse.enable = mkDefault true;
      jack.enable = mkDefault true;
      alsa.enable = mkDefault true;
      alsa.support32Bit = mkDefault true;
      wireplumber.enable = mkDefault true;
    };
    security.rtkit.enable = mkDefault true;

    # Beautiful fonts for the desktop
    fonts = {
      packages = with pkgs; [
        # Modern beautiful fonts
        inter
        lexend
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        
        # Programming fonts
        fira-code
        fira-code-symbols
        jetbrains-mono
        cascadia-code
        
        # Icon fonts for beauty
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        nerd-fonts.caskaydia-cove
        font-awesome
        material-icons
        
        # Additional beautiful fonts  
        liberation_ttf
        dejavu_fonts
        ubuntu_font_family
      ];
      
      fontconfig = {
        enable = true;
        defaultFonts = {
          serif = [ "Noto Serif" ];
          sansSerif = [ "Inter" "Noto Sans" ];
          monospace = [ "JetBrains Mono" "Fira Code" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };
  };
}