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
      gtk3.dev
      gtk4
      gtk4.dev
      glib
      glib.dev
      cairo
      cairo.dev
      pango
      pango.dev
      gdk-pixbuf
      gdk-pixbuf.dev
      atk
      atk.dev
      
      # X11 development libraries (including .dev variants where available)
      xorg.libX11
      xorg.libX11.dev
      xorg.libXext
      xorg.libXrender
      xorg.libXrandr
      xorg.libXi
      xorg.libXfixes
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXcomposite
      xorg.libXtst
      xorg.libXinerama
      xorg.libXxf86vm
      xorg.libXScrnSaver
      xorg.xorgproto
      xorg.libXxf86vm
      xorg.libXScrnSaver
      
      # Mesa and OpenGL for graphics
      mesa
      libGL
      libGLU
      libepoxy
      
      # Font libraries
      fontconfig
      freetype
      harfbuzz
      
      # Additional system libraries for Flutter development
      libsepol
      libsecret
      libsecret.dev
      pcre2
      pcre2.dev
      util-linux.dev
      libselinux
      libselinux.dev
      libthai.dev
      libdatrie.dev
      sysprof  # provides libsysprof-capture
      sysprof.dev
      
      # Additional Flutter Linux development dependencies
      libinput
      libinput.dev
      udev
      systemd.dev  # Provides libudev.so
      mtdev
      libevdev      # evdev library
      libgudev
      gsettings-desktop-schemas
      json-glib
      json-glib.dev
      
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
      # Note: PKG_CONFIG_PATH and CMAKE paths are handled by development-libraries module

      # Enhanced compiler and linker flags for Flutter development
      NIX_CFLAGS_COMPILE = lib.mkAfter (lib.concatStringsSep " " [
        "-I${pkgs.libepoxy.dev}/include"
        "-I${pkgs.fontconfig.dev}/include"
        "-I${pkgs.gtk3.dev}/include/gtk-3.0"
        "-I${pkgs.gtk4.dev}/include/gtk-4.0"
        "-I${pkgs.glib.dev}/include/glib-2.0"
        "-I${pkgs.glib.dev}/lib/glib-2.0/include"
        "-I${pkgs.cairo.dev}/include/cairo"
        "-I${pkgs.pango.dev}/include/pango-1.0"
        "-I${pkgs.gdk-pixbuf.dev}/include/gdk-pixbuf-2.0"
        "-I${pkgs.atk.dev}/include/atk-1.0"
        "-I${pkgs.libinput.dev}/include"
        "-I${pkgs.json-glib.dev}/include/json-glib-1.0"
      ]);
      
      NIX_LDFLAGS = lib.mkAfter (lib.concatStringsSep " " [
        "-L${pkgs.libepoxy}/lib"
        "-L${pkgs.fontconfig.lib}/lib"
        "-L${pkgs.gtk3}/lib"
        "-L${pkgs.gtk4}/lib"
        "-L${pkgs.glib}/lib"
        "-L${pkgs.cairo}/lib"
        "-L${pkgs.pango}/lib"
        "-L${pkgs.gdk-pixbuf}/lib"
        "-L${pkgs.atk}/lib"
        "-L${pkgs.libinput}/lib"
        "-L${pkgs.json-glib}/lib"
        "-lepoxy -lfontconfig -lgtk-3 -lgtk-4 -lglib-2.0 -lcairo -lpango-1.0 -lgdk_pixbuf-2.0 -latk-1.0"
      ]);

      # Flutter and Dart configuration
      FLUTTER_ROOT = "${pkgs.flutter}";
      DART_ROOT = "${pkgs.dart}";
      
      # Additional Flutter environment variables
      FLUTTER_ENGINE_SWITCHES = "--enable-software-rendering";
      PUB_CACHE = "$HOME/.pub-cache";
      
      # Chrome executable for Flutter web development
      CHROME_EXECUTABLE = mkIf cfg.webDevelopment "${pkgs.chromium}/bin/chromium";
      
      # GTK and desktop integration
      GTK_A11Y = "none";  # Disable accessibility to avoid potential issues
      GDK_PIXBUF_MODULE_FILE = "${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
    };

    # Session-level variables that get set in user sessions
    environment.sessionVariables = {
      # Ensure flutter and dart are easily accessible on PATH for all users
      PATH = lib.mkAfter "${pkgs.flutter}/bin:${pkgs.dart}/bin";
      
      # Flutter development environment variables
      FLUTTER_STORAGE_BASE_URL = "https://storage.googleapis.com";
      PUB_HOSTED_URL = "https://pub.dev";
      PUB_ENVIRONMENT = "nixos:flutter";
      
      # PKG_CONFIG_PATH for Flutter Linux development
      PKG_CONFIG_PATH = lib.mkAfter (lib.concatStringsSep ":" [
        "${pkgs.gtk3.dev}/lib/pkgconfig"
        "${pkgs.gtk4.dev}/lib/pkgconfig"
        "${pkgs.glib.dev}/lib/pkgconfig"
        "${pkgs.cairo.dev}/lib/pkgconfig"
        "${pkgs.pango.dev}/lib/pkgconfig"
        "${pkgs.gdk-pixbuf.dev}/lib/pkgconfig"
        "${pkgs.atk.dev}/lib/pkgconfig"
        "${pkgs.libepoxy.dev}/lib/pkgconfig"
        "${pkgs.fontconfig.dev}/lib/pkgconfig"
        "${pkgs.libinput.dev}/lib/pkgconfig"
        "${pkgs.json-glib.dev}/lib/pkgconfig"
      ]);
      
      # Note: LD_LIBRARY_PATH is handled by other modules in the system
    };

    # Add udev rules for Android development
    services.udev.packages = mkIf cfg.androidDevelopment [
      pkgs.android-udev-rules
    ];

    # Add main user to necessary groups for development
    users.users.${config.custom.users.mainUser.name or "mahmoud"} = mkIf cfg.androidDevelopment {
      extraGroups = [ "plugdev" "adbusers" ];  # For Android device and ADB access
    };

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
