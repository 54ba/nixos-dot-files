{ config, pkgs, lib, ... }:

with lib;

let
  # ===== BEAUTIFUL & USEFUL GNOME EXTENSIONS =====
  # Curated collection from extensions.gnome.org
  
  extensionCategories = {
    # ===== VISUAL ENHANCEMENTS & BEAUTY =====
    beauty = [
      "blur-my-shell"              # Beautiful blur effects for shell (use with caution)
      "compiz-alike-magic-lamp-effect"  # Beautiful minimize effect
      "compiz-windows-effect"      # Wobbly windows animation
      "burn-my-windows"            # Beautiful window open/close effects
      "desktop-cube"               # 3D desktop cube effect
      "coverflow-alt-tab"          # Beautiful alt-tab switcher
      "透明top-bar"                  # Transparent top bar (Dynamic transparency)
    ];

    # ===== ESSENTIAL PRODUCTIVITY =====
    productivity = [
      "dash-to-dock"               # Essential dock (like macOS/Windows taskbar)
      "dash-to-panel"              # Alternative: Panel with integrated taskbar
      "appindicator"               # Tray icons support (AppIndicator/KStatusNotifierItem)
      "caffeine"                   # Prevent auto-suspend
      "clipboard-indicator"        # Clipboard history manager
      "clipboard-history"          # Alternative clipboard manager
      "desktop-icons-ng-ding"      # Desktop icons support
      "just-perfection"            # Customize GNOME Shell (highly recommended)
      "pop-shell"                  # Tiling window management (from System76)
      "unite"                      # Remove title bars and merge with top bar
    ];

    # ===== WORKSPACE & WINDOW MANAGEMENT =====
    windows = [
      "space-bar"                  # Beautiful workspace indicator
      "workspace-indicator"        # Alternative workspace indicator  
      "workspace-matrix"           # 2D workspace grid
      "window-list"                # Windows list in panel
      "window-is-ready-remover"    # Remove "Window is Ready" notification
      "gtile"                      # Advanced window tiling
      "tiling-assistant"           # Smart tiling assistant
      "auto-move-windows"          # Move apps to specific workspaces
    ];

    # ===== SYSTEM MONITORING =====
    system = [
      "vitals"                     # Beautiful system monitor in top bar
      "system-monitor-next"        # Advanced system monitoring
      "tophat"                     # Resource monitor with beautiful design
      "cpu-power-manager"          # CPU power management
      "gpu-profile-selector"       # GPU profile switcher (for NVIDIA/AMD)
      "freon"                      # Temperature sensor
    ];

    # ===== USER INTERFACE ENHANCEMENTS =====
    interface = [
      "arc-menu"                   # Beautiful application menu
      "applications-menu"          # Alternative app menu
      "user-themes"                # Custom shell themes support
      "rounded-window-corners"     # Rounded corners for windows
      "bluetooth-quick-connect"    # Quick Bluetooth management
      "quick-settings-tweaker"     # Customize quick settings panel
      "panel-corners"              # Rounded panel corners
      "logo-menu"                  # Replace Activities with logo
    ];

    # ===== MEDIA & AUDIO =====
    media = [
      "media-controls"             # Media player controls in panel
      "sound-output-device-chooser"  # Quick audio device switcher
      "volume-mixer"               # Individual app volume control
    ];

    # ===== NOTIFICATIONS & INDICATORS =====
    notifications = [
      "notification-banner-reloaded"  # Better notification positioning
      "do-not-disturb-button"      # Quick DND toggle
      "night-theme-switcher"       # Auto dark/light theme switching
    ];

    # ===== UTILITIES =====
    utilities = [
      "gsconnect"                  # KDE Connect for Android integration
      "emoji-copy"                 # Emoji picker
      "clipboard-indicator"        # Clipboard manager
      "espresso"                   # Alternative to Caffeine
      "removable-drive-menu"       # USB drive manager
      "screenshot-tool"            # Enhanced screenshot tool
      "weather-oclock"             # Weather in clock
      "vitals"                     # System vitals
    ];

    # ===== DEVELOPMENT =====
    development = [
      "extension-list"             # Manage extensions
      "looking-glass-button"       # Quick access to Looking Glass
      "gamemode"                   # GameMode indicator
    ];

    # ===== POWER & BATTERY =====
    power = [
      "battery-health-charging"    # Battery health management
      "power-profile-switcher"     # Quick power profile switching
    ];

    # ===== SEARCH & LAUNCH =====
    search = [
      "app-hider"                  # Hide apps from overview
      "applications-overview-tooltip"  # Tooltips in overview
      "search-light"               # Better search experience
    ];
  };

  # ===== PRESET CONFIGURATIONS =====
  
  # Minimal & Fast (performance-focused)
  minimalPreset = [
    "appindicator"
    "dash-to-dock"
    "user-themes"
    "caffeine"
  ];

  # Beautiful Desktop (aesthetics-focused)
  beautifulPreset = [
    "blur-my-shell"
    "burn-my-windows"
    "compiz-alike-magic-lamp-effect"
    "coverflow-alt-tab"
    "dash-to-dock"
    "rounded-window-corners"
    "panel-corners"
    "just-perfection"
    "vitals"
    "media-controls"
    "user-themes"
    "appindicator"
  ];

  # Productivity Powerhouse
  productivityPreset = [
    "dash-to-panel"              # Panel with taskbar
    "pop-shell"                  # Tiling
    "clipboard-indicator"
    "vitals"
    "gsconnect"
    "just-perfection"
    "tiling-assistant"
    "appindicator"
    "bluetooth-quick-connect"
    "window-list"
  ];

  # macOS-like Experience
  macosPreset = [
    "dash-to-dock"               # Dock
    "blur-my-shell"
    "rounded-window-corners"
    "unite"                      # Remove title bars
    "coverflow-alt-tab"
    "just-perfection"
    "user-themes"
    "appindicator"
    "media-controls"
  ];

  # Windows-like Experience  
  windowsPreset = [
    "dash-to-panel"              # Taskbar in panel
    "arc-menu"                   # Start menu
    "window-list"
    "desktop-icons-ng-ding"
    "appindicator"
    "clipboard-indicator"
    "quick-settings-tweaker"
  ];

  # Gaming Setup
  gamingPreset = [
    "gamemode"
    "caffeine"
    "gpu-profile-selector"
    "cpu-power-manager"
    "vitals"
    "appindicator"
    "just-perfection"
  ];

  cfg = config.custom.gnome.extensions;

in {
  options.custom.gnome.extensions = {
    enable = mkEnableOption "Enable beautiful GNOME extensions";

    # ===== PRESET SELECTION =====
    preset = mkOption {
      type = types.enum [ "custom" "minimal" "beautiful" "productivity" "macos" "windows" "gaming" ];
      default = "custom";
      description = "Choose a preset configuration";
    };

    # ===== CATEGORY TOGGLES =====
    categories = {
      beauty = mkEnableOption "Visual enhancement extensions" // { default = true; };
      productivity = mkEnableOption "Productivity extensions" // { default = true; };
      windows = mkEnableOption "Window management extensions" // { default = true; };
      system = mkEnableOption "System monitoring extensions" // { default = true; };
      interface = mkEnableOption "UI enhancement extensions" // { default = true; };
      media = mkEnableOption "Media extensions" // { default = false; };
      notifications = mkEnableOption "Notification extensions" // { default = false; };
      utilities = mkEnableOption "Utility extensions" // { default = true; };
      development = mkEnableOption "Development extensions" // { default = false; };
      power = mkEnableOption "Power management extensions" // { default = true; };
      search = mkEnableOption "Search enhancement extensions" // { default = false; };
    };

    # ===== EXTENSION SETTINGS =====
    settings = {
      enable = mkEnableOption "Apply extension settings" // { default = true; };
      
      dashToDock = {
        enable = mkEnableOption "Configure Dash to Dock" // { default = true; };
        position = mkOption {
          type = types.enum [ "LEFT" "RIGHT" "BOTTOM" "TOP" ];
          default = "BOTTOM";
        };
        iconSize = mkOption {
          type = types.int;
          default = 48;
          description = "Icon size (16-64)";
        };
        transparency = mkOption {
          type = types.enum [ "FIXED" "DYNAMIC" "ADAPTIVE" ];
          default = "DYNAMIC";
        };
      };

      blurMyShell = {
        enable = mkEnableOption "Configure Blur My Shell" // { default = false; };
        intensity = mkOption {
          type = types.int;
          default = 30;
          description = "Blur intensity (0-100)";
        };
      };

      justPerfection = {
        enable = mkEnableOption "Configure Just Perfection" // { default = true; };
        hideTopBarActivities = mkOption {
          type = types.bool;
          default = false;
        };
        showApplicationsButton = mkOption {
          type = types.bool;
          default = true;
        };
      };

      vitals = {
        enable = mkEnableOption "Configure Vitals" // { default = true; };
        showCpu = mkOption {
          type = types.bool;
          default = true;
        };
        showMemory = mkOption {
          type = types.bool;
          default = true;
        };
        showTemperature = mkOption {
          type = types.bool;
          default = true;
        };
      };
    };

    # Custom extension list
    customList = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional custom extensions";
    };
  };

  config = mkIf cfg.enable {
    # Build extension list based on preset or categories
    environment.systemPackages = with pkgs.gnomeExtensions; let
      # Select extensions based on preset
      presetExtensions = {
        minimal = minimalPreset;
        beautiful = beautifulPreset;
        productivity = productivityPreset;
        macos = macosPreset;
        windows = windowsPreset;
        gaming = gamingPreset;
        custom = [];
      }.${cfg.preset};

      # Category-based extensions for custom preset
      categoryExtensions = if cfg.preset == "custom" then
        (optionals cfg.categories.beauty extensionCategories.beauty) ++
        (optionals cfg.categories.productivity extensionCategories.productivity) ++
        (optionals cfg.categories.windows extensionCategories.windows) ++
        (optionals cfg.categories.system extensionCategories.system) ++
        (optionals cfg.categories.interface extensionCategories.interface) ++
        (optionals cfg.categories.media extensionCategories.media) ++
        (optionals cfg.categories.notifications extensionCategories.notifications) ++
        (optionals cfg.categories.utilities extensionCategories.utilities) ++
        (optionals cfg.categories.development extensionCategories.development) ++
        (optionals cfg.categories.power extensionCategories.power) ++
        (optionals cfg.categories.search extensionCategories.search)
      else [];

      # Combine all extension names
      allExtensionNames = unique (presetExtensions ++ categoryExtensions ++ cfg.customList);

      # Convert extension names to packages (with error handling)
      extensionPackages = filter (x: x != null) (map (name:
        if hasAttr name pkgs.gnomeExtensions
        then getAttr name pkgs.gnomeExtensions
        else (warn "Extension '${name}' not found in nixpkgs" null)
      ) allExtensionNames);

    in [
      pkgs.gnome-shell-extensions
      pkgs.gnome-tweaks
    ] ++ extensionPackages;

    # Enable GNOME Shell extensions
    services.xserver.desktopManager.gnome = {
      extraGSettingsOverrides = mkIf cfg.settings.enable (concatStringsSep "\n" (filter (x: x != "") [
        # Enable extensions
        "[org.gnome.shell]"
        "disable-user-extensions=false"
        
        # Dash to Dock settings
        (optionalString cfg.settings.dashToDock.enable ''
          [org.gnome.shell.extensions.dash-to-dock]
          dock-position='${cfg.settings.dashToDock.position}'
          dash-max-icon-size=${toString cfg.settings.dashToDock.iconSize}
          transparency-mode='${cfg.settings.dashToDock.transparency}'
          dock-fixed=false
          extend-height=false
          show-favorites=true
          show-running=true
          show-windows-preview=true
          click-action='cycle-windows'
          scroll-action='cycle-windows'
          running-indicator-style='DOTS'
        '')

        # Blur My Shell settings
        (optionalString (cfg.settings.blurMyShell.enable && cfg.categories.beauty) ''
          [org.gnome.shell.extensions.blur-my-shell]
          blur-dash=true
          blur-panel=true
          blur-overview=true
          blur-appfolder=true
          brightness=0.6
          sigma=${toString cfg.settings.blurMyShell.intensity}
        '')

        # Just Perfection settings
        (optionalString cfg.settings.justPerfection.enable ''
          [org.gnome.shell.extensions.just-perfection]
          activities-button=${if cfg.settings.justPerfection.hideTopBarActivities then "false" else "true"}
          app-menu=true
          window-demands-attention-focus=true
          workspace-switcher-should-show=true
          world-clock=false
        '')

        # Vitals settings
        (optionalString cfg.settings.vitals.enable ''
          [org.gnome.shell.extensions.vitals]
          show-storage=false
          show-network=false
          show-processor=${if cfg.settings.vitals.showCpu then "true" else "false"}
          show-memory=${if cfg.settings.vitals.showMemory then "true" else "false"}
          show-temperature=${if cfg.settings.vitals.showTemperature then "true" else "false"}
          position-in-panel=2
        '')
      ]));
    };

    # Install extension management tools
    programs.dconf.enable = true;
  };
}
