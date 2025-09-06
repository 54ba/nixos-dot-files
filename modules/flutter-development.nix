{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.flutter-development;
in
{
  options.custom.flutter-development = {
    enable = mkEnableOption "Flutter development environment";

    channel = mkOption {
      type = types.enum [ "stable" "beta" "dev" ];
      default = "stable";
      description = "Flutter release channel to use";
    };

    androidDevelopment = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Android development tools";
    };

    webDevelopment = mkOption {
      type = types.bool;
      default = true;
      description = "Enable web development tools";
    };

    linuxDevelopment = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Linux desktop development";
    };

    additionalPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages to install for Flutter development";
    };
  };

  config = mkIf cfg.enable {
    # Enable necessary system services
    programs.adb.enable = mkIf cfg.androidDevelopment true;

    # Add Flutter development packages
    environment.systemPackages = with pkgs; [
      # Flutter SDK
      flutter

      # Dart SDK (included with Flutter but available separately)
      dart

      # Essential build tools for Linux development
      pkg-config
      cmake
      ninja
      clang
      llvm
      
      # GTK development libraries for Linux Flutter apps
      gtk3
      gtk4
      glib
      cairo
      pango
      gdk-pixbuf
      atk
      
      # X11 development libraries
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      xorg.libXrandr
      xorg.libXi
      xorg.libXfixes
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXcomposite
      xorg.xorgproto
      
      # Additional X11 libraries that might be needed
      xorg.libXtst
      xorg.libXinerama
      xorg.libXxf86vm
      xorg.libXScrnSaver
      
      # Mesa and OpenGL for graphics
      mesa
      libGL
      libGLU
      
      # Font libraries
      fontconfig
      freetype
      harfbuzz
      
      # Audio libraries (for multimedia Flutter apps)
      alsa-lib
      pulseaudio
      pipewire
      
      # Additional development tools
      unzip
      zip
      curl
      wget
      git
      which
      file
      
    ] ++ optionals cfg.androidDevelopment [
      # Android development tools
      android-tools
      android-udev-rules
    ] ++ optionals cfg.webDevelopment [
      # Web development tools
      chromium
      firefox
    ] ++ cfg.additionalPackages;

    # Add development libraries to system
    environment.variables = {
      # Ensure pkg-config can find the libraries
      PKG_CONFIG_PATH = lib.makeSearchPath "lib/pkgconfig" (with pkgs; [
        gtk3.dev
        gtk4.dev
        glib.dev
        cairo.dev
        pango.dev
        gdk-pixbuf.dev
        atk.dev
        xorg.libX11.dev
        xorg.libXext.dev
        xorg.libXrender.dev
        xorg.libXrandr.dev
        fontconfig.dev
        freetype.dev
        harfbuzz.dev
        mesa.dev
      ]);
      
      # Flutter and Dart configuration
      FLUTTER_ROOT = "${pkgs.flutter}";
      DART_ROOT = "${pkgs.dart}";
      
      # Chrome executable for Flutter web development
      CHROME_EXECUTABLE = mkIf cfg.webDevelopment "${pkgs.chromium}/bin/chromium";
    };

    # Add udev rules for Android development
    services.udev.packages = mkIf cfg.androidDevelopment [
      pkgs.android-udev-rules
    ];

    # Add users to necessary groups for development
    users.users = lib.genAttrs (lib.attrNames config.users.users) (username: {
      extraGroups = lib.mkIf (config.users.users.${username}.isNormalUser or false) [
        "plugdev"  # For Android device access
        "adbusers" # For ADB access
      ];
    });

    # System-wide Flutter and Dart configuration
    environment.etc = {
      "flutter/flutter_root".text = "${pkgs.flutter}";
    };

    # Ensure proper permissions for development
    security.sudo.extraRules = [
      {
        users = [ config.custom.users.mainUser.name or "mahmoud" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/flutter";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
