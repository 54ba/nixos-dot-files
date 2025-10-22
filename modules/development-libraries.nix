{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.development-libraries;
in
{
  options.custom.development-libraries = {
    enable = mkEnableOption "development libraries and shared objects";

    core = mkOption {
      type = types.bool;
      default = true;
      description = "Enable core development libraries (glibc, libstdc++, etc.)";
    };

    graphics = mkOption {
      type = types.bool;
      default = true;
      description = "Enable graphics development libraries (Mesa, Vulkan, etc.)";
    };

    multimedia = mkOption {
      type = types.bool;
      default = true;
      description = "Enable multimedia development libraries (FFmpeg, GStreamer, etc.)";
    };

    networking = mkOption {
      type = types.bool;
      default = true;
      description = "Enable networking development libraries (OpenSSL, curl, etc.)";
    };

    compression = mkOption {
      type = types.bool;
      default = true;
      description = "Enable compression libraries (zlib, bzip2, etc.)";
    };

    database = mkOption {
      type = types.bool;
      default = false;
      description = "Enable database development libraries (SQLite, PostgreSQL, etc.)";
    };

    gui = mkOption {
      type = types.bool;
      default = true;
      description = "Enable GUI development libraries (GTK, Qt, etc.)";
    };

    python = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Python development libraries";
    };

    nodejs = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Node.js development libraries";
    };

    java = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Java development libraries";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Core development libraries
    ] ++ optionals cfg.core [
      # Essential C/C++ libraries
      glibc.dev
      gcc-unwrapped.lib
      libgcc
      stdenv.cc.cc.lib
      binutils-unwrapped
      
      # Standard library components
      glib.dev
      glibc.static
      libiconv
      libffi.dev
      
      # Build tools and utilities
      pkg-config
      autoconf
      automake
      libtool
      cmake
      gnumake
      
      # Headers and development files
      linuxHeaders
      glibc.dev
    ] ++ optionals cfg.graphics [
      # Graphics libraries
      mesa
      libGL
      libGLU
      vulkan-loader
      vulkan-headers
      vulkan-validation-layers
      wayland
      wayland-protocols
      libxkbcommon
      xorg.libX11
      xorg.libXext
      xorg.libXrandr
      xorg.libXi
      xorg.libXcursor
      xorg.libxcb
    ] ++ optionals cfg.multimedia [
      # Multimedia libraries
      ffmpeg
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      alsa-lib
      pulseaudio
      pipewire
      libsndfile
      
      # Image and video libraries
      libjpeg
      libpng
      libtiff
      libwebp
      opencv
    ] ++ optionals cfg.networking [
      # Networking libraries
      openssl
      curl
      libssh
      libpcap
      
      # Protocol libraries
      protobuf
      grpc
    ] ++ optionals cfg.compression [
      # Compression libraries
      zlib
      bzip2
      xz
      lz4
      zstd
      libarchive
    ] ++ optionals cfg.database [
      # Database libraries
      sqlite
      postgresql
      mysql80
      unixODBC
    ] ++ optionals cfg.gui [
      # GUI libraries
      gtk3
      gtk4
      gdk-pixbuf
      cairo
      pango
      atk
      
      # Additional GUI libraries for Flutter/OpenGL
      libepoxy
      fontconfig
      
      # Additional system libraries for development
      libsepol
      libsecret
      pcre2
      util-linux.dev
      libselinux
      libthai.dev
      libdatrie.dev
      sysprof  # provides libsysprof-capture
      sysprof.dev
      
      # Qt libraries
      qt5.qtbase
      qt6.qtbase
      qt5.full
      qt6.full
    ] ++ optionals cfg.python [
      # Python development
      python3
      python3Packages.pip
      python3Packages.setuptools
      python3Packages.wheel
      python3Packages.cython
      python3Packages.numpy
    ] ++ optionals cfg.nodejs [
      # Node.js development
      nodejs
      nodePackages.npm
      nodePackages.yarn
      nodePackages.pnpm
    ] ++ optionals cfg.java [
      # Java development
      openjdk
      maven
      gradle
    ];

    # NOTE: Environment variables removed from this module to avoid conflicts with Flutter and other modules
    # The packages are installed and available via /run/current-system/sw/{lib,include,bin}
    # Use the env-inspector tool to view all environment variables and library paths

    # Create symbolic links for commonly expected library locations
    system.activationScripts.development-libraries = lib.mkIf cfg.core ''
      # Ensure /lib64 exists and contains the dynamic linker
      mkdir -p /lib64
      ln -sf ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 || true
      
      # Create /usr/lib symlinks for common libraries if they don't exist
      mkdir -p /usr/lib/x86_64-linux-gnu
      ln -sf ${pkgs.glibc}/lib/libc.so.6 /usr/lib/x86_64-linux-gnu/libc.so.6 || true
      ln -sf ${pkgs.gcc-unwrapped.lib}/lib/libgcc_s.so.1 /usr/lib/x86_64-linux-gnu/libgcc_s.so.1 || true
      ln -sf ${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/libstdc++.so.6 || true
    '';

    # Add development tools to shell environment
    programs.bash.shellAliases = mkIf cfg.enable {
      "dev-libs-info" = "echo 'Development libraries module enabled with: core=${toString cfg.core}, graphics=${toString cfg.graphics}, multimedia=${toString cfg.multimedia}, gui=${toString cfg.gui}'";
    };

    programs.zsh.shellAliases = mkIf cfg.enable {
      "dev-libs-info" = "echo 'Development libraries module enabled with: core=${toString cfg.core}, graphics=${toString cfg.graphics}, multimedia=${toString cfg.multimedia}, gui=${toString cfg.gui}'";
    };
  };
}
