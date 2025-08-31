{ config, pkgs, lib, ... }:

with lib;

let
  # Define extension categories for better organization
  extensionCategories = {
    # Essential productivity extensions
    productivity = [
      "dash-to-dock"
      # "blur-my-shell"    # DISABLED - Causes GNOME Shell crashes on this setup
      "caffeine"
      "clipboard-indicator"
      "desktop-icons-ng-ding"
    ];

    # System monitoring and information
    system = [
      "system-monitor"
      "system-monitor-next"
      "multicore-system-monitor"
      "status-icons"
    ];

    # Window management and navigation
    windows = [
      "auto-move-windows"
      "all-windows"
      "all-windows-saverestore-window-positions"
    ];

    # Application launchers and menus
    launchers = [
      "arc-menu"
      "activity-app-launcher"
      "alphabetical-app-grid"
    ];

    # Media and connectivity
    media = [
      "sound-output-device-chooser"
      "removable-drive-menu"
      "do-not-disturb-while-screen-sharing-or-recording"
    ];

    # Utilities and enhancements
    utilities = [
      "screenshot-window-sizer"
      "light-style"
      "compiz-windows-effect"
      "runcat"
      "slinger"
      "shyriiwook"
      "reading-strip"
    ];

    # Development and customization
    development = [
      "extension-list"
      "user-stylesheet-font"
    ];

    # Security and privacy
    security = [
      "lockscreen-extension"
      "primary-input-on-lockscreen"
    ];
  };

  # Windows migration extensions (familiar Windows-like experience)
  windowsMigrationExtensions = [
    "dash-to-dock"                       # Taskbar-like dock
    "arc-menu"                           # Start menu replacement
    "auto-move-windows"                  # Window snapping
    "clipboard-indicator"                # Clipboard history
    "caffeine"                           # Keep awake (like Windows)
    "desktop-icons-ng-ding"             # Desktop icons
  ];

  # macOS migration extensions (familiar macOS-like experience)
  macosMigrationExtensions = [
    "dash-to-dock"                       # Dock-like experience
    # "blur-my-shell"                    # DISABLED - Causes crashes
    "auto-move-windows"                  # Window management
    "caffeine"                           # Prevent sleep
    "clipboard-indicator"                # Clipboard management
    "desktop-icons-ng-ding"             # Desktop icons
  ];

  # Android integration extensions
  androidIntegrationExtensions = [
    "clipboard-indicator"                # Sync clipboard
    "desktop-icons-ng-ding"             # File sync
    "sound-output-device-chooser"       # Audio routing
  ];

  # Premium extensions from gnome-look.org and pling.com (placeholder for future)
  premiumExtensions = {
    gnomeLook = [];
    pling = [];
  };

  cfg = config.custom.gnome.extensions;

in {
  options.custom.gnome.extensions = {
    enable = mkEnableOption "Enable enhanced GNOME extensions management";

    categories = {
      productivity = mkEnableOption "Productivity extensions";
      system = mkEnableOption "System monitoring extensions";
      windows = mkEnableOption "Window management extensions";
      launchers = mkEnableOption "Application launcher extensions";
      media = mkEnableOption "Media and connectivity extensions";
      utilities = mkEnableOption "Utility extensions";
      development = mkEnableOption "Development extensions";
      security = mkEnableOption "Security extensions";
    };

    migration = {
      windows = mkEnableOption "Windows migration extensions";
      macos = mkEnableOption "macOS migration extensions";
      android = mkEnableOption "Android integration extensions";
    };

    premium = {
      enable = mkEnableOption "Enable premium extensions";
      gnomeLook = mkEnableOption "Extensions from gnome-look.org";
      pling = mkEnableOption "Extensions from pling.com";
    };

    settings = {
      enable = mkEnableOption "Enable extension settings";
      dashToDock = {
        position = mkOption {
          type = types.enum [ "left" "right" "bottom" "top" ];
          default = "bottom";
          description = "Dash to Dock position";
        };
        transparency = mkOption {
          type = types.enum [ "FIXED" "DYNAMIC" "ADAPTIVE" ];
          default = "DYNAMIC";
          description = "Dash to Dock transparency mode";
        };
        theme = mkOption {
          type = types.str;
          default = "default";
          description = "Dash to Dock theme";
        };
      };
      blurMyShell = {
        intensity = mkOption {
          type = types.int;
          default = 10;
          description = "Blur intensity (0-20)";
        };
        brightness = mkOption {
          type = types.int;
          default = 0;
          description = "Brightness adjustment (-10 to 10)";
        };
      };
      caffeine = {
        duration = mkOption {
          type = types.int;
          default = 300;
          description = "Caffeine duration in seconds";
        };
      };
    };

    performance = {
      enable = mkEnableOption "Enable performance optimizations";
    };

    list = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of GNOME extensions to install";
    };
  };

  config = mkIf cfg.enable {
    # Build the extension list based on enabled categories
    custom.gnome.extensions.list = let
      # Base extensions (always included)
      baseList = [
        "extension-list"
        "user-stylesheet-font"
      ];

      # Category-based extensions
      categoryExtensions =
        (if cfg.categories.productivity then extensionCategories.productivity else []) ++
        (if cfg.categories.system then extensionCategories.system else []) ++
        (if cfg.categories.windows then extensionCategories.windows else []) ++
        (if cfg.categories.launchers then extensionCategories.launchers else []) ++
        (if cfg.categories.media then extensionCategories.media else []) ++
        (if cfg.categories.utilities then extensionCategories.utilities else []) ++
        (if cfg.categories.development then extensionCategories.development else []) ++
        (if cfg.categories.security then extensionCategories.security else []);

      # Migration extensions
      migrationExtensions =
        (if cfg.migration.windows then windowsMigrationExtensions else []) ++
        (if cfg.migration.macos then macosMigrationExtensions else []) ++
        (if cfg.migration.android then androidIntegrationExtensions else []);

      # Premium extensions
      premiumExtensionsList = if cfg.premium.enable then
        (if cfg.premium.gnomeLook then premiumExtensions.gnomeLook else []) ++
        (if cfg.premium.pling then premiumExtensions.pling else [])
      else [];

      # Combine all lists and remove duplicates
      allExtensions = baseList ++ categoryExtensions ++ migrationExtensions ++ premiumExtensionsList;
    in lib.unique allExtensions;

    # Install GNOME extensions
    environment.systemPackages = with pkgs; [
      gnome-shell-extensions
    ] ++ (map (ext: gnomeExtensions.${ext}) cfg.list);

    # GSettings overrides for extensions
    services.xserver.desktopManager.gnome.extraGSettingsOverrides = mkIf cfg.settings.enable ''
      [org.gnome.shell]
      enabled-extensions=[${concatStringsSep ", " (map (ext: "'${ext}'") cfg.list)}]
      disable-user-extensions=false
      development-tools=true

      [org.gnome.shell.extensions.dash-to-dock]
      dock-position='${cfg.settings.dashToDock.position}'
      dock-fixed=false
      transparency-mode='${cfg.settings.dashToDock.transparency}'
      running-indicator-style='DOTS'
      show-favorites=true
      show-running=true
      show-windows-preview=true
      click-action='cycle-windows'
      scroll-action='cycle-windows'
      theme='${cfg.settings.dashToDock.theme}'

      [org.gnome.shell.extensions.blur-my-shell]
      blur-dash=true
      blur-panel=true
      blur-overview=true
      blur-intensity=${toString cfg.settings.blurMyShell.intensity}
      brightness=${toString cfg.settings.blurMyShell.brightness}

      [org.gnome.shell.extensions.caffeine]
      enable-fullscreen=true
      restore-state=true
      duration=${toString cfg.settings.caffeine.duration}
    '';
  };
}
