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
      libstdcxx5
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
      linux-headers
      glibc.dev
    ] ++ optionals cfg.graphics [
      # Graphics libraries
      mesa.dev
      libGL
      libGLU
      vulkan-loader
      vulkan-headers
      vulkan-validation-layers
      libglvnd.dev
      wayland.dev
      wayland-protocols
      libxkbcommon.dev
      xorg.libX11.dev
      xorg.libXext.dev
      xorg.libXrandr.dev
      xorg.libXi.dev
      xorg.libXcursor.dev
      xorg.libxcb.dev
      libdrm.dev
    ] ++ optionals cfg.multimedia [
      # Multimedia libraries
      ffmpeg.dev
      gstreamer.dev
      gst_all_1.gstreamer.dev
      gst_all_1.gst-plugins-base.dev
      alsa-lib.dev
      pulseaudio.dev
      pipewire.dev
      libsndfile.dev
      
      # Image and video libraries
      libjpeg.dev
      libpng.dev
      libtiff.dev
      libwebp.dev
      opencv.dev
    ] ++ optionals cfg.networking [
      # Networking libraries
      openssl.dev
      curl.dev
      libssh.dev
      libpcap.dev
      
      # Protocol libraries
      protobuf.dev
      grpc.dev
    ] ++ optionals cfg.compression [
      # Compression libraries
      zlib.dev
      bzip2.dev
      xz.dev
      lz4.dev
      zstd.dev
      libarchive.dev
    ] ++ optionals cfg.database [
      # Database libraries
      sqlite.dev
      postgresql.lib
      mysql80.client
      unixODBC
    ] ++ optionals cfg.gui [
      # GUI libraries
      gtk3.dev
      gtk4.dev
      gdk-pixbuf.dev
      cairo.dev
      pango.dev
      atk.dev
      
      # Qt libraries
      qt5.qtbase.dev
      qt6.qtbase.dev
      qt5.full
      qt6.full
    ] ++ optionals cfg.python [
      # Python development
      python3.dev
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

    # Ensure all libraries are available in the system library path
    environment.variables = {
      # C/C++ compilation
      PKG_CONFIG_PATH = "${pkgs.pkg-config}/lib/pkgconfig:$PKG_CONFIG_PATH";
      CPATH = lib.makeSearchPathOutput "dev" "include" (with pkgs; [
        glibc.dev
        gcc-unwrapped.lib
        libffi.dev
      ] ++ optionals cfg.graphics [
        mesa.dev
        vulkan-headers
        wayland.dev
        libxkbcommon.dev
      ] ++ optionals cfg.multimedia [
        ffmpeg.dev
        gstreamer.dev
        alsa-lib.dev
      ] ++ optionals cfg.gui [
        gtk3.dev
        gtk4.dev
        cairo.dev
        qt5.qtbase.dev
      ]);
      
      LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [
        glibc
        gcc-unwrapped.lib
        libgcc
        stdenv.cc.cc.lib
      ] ++ optionals cfg.graphics [
        mesa
        libGL
        vulkan-loader
        wayland
      ] ++ optionals cfg.multimedia [
        ffmpeg
        gstreamer
        alsa-lib
        pulseaudio
      ] ++ optionals cfg.gui [
        gtk3
        gtk4
        cairo
        qt5.qtbase
      ]);
    };

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

  meta = {
    description = "Comprehensive development libraries module for NixOS";
    maintainers = [ "NixOS Configuration" ];
  };
}