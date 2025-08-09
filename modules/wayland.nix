{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.wayland = {
      enable = mkEnableOption "Wayland environment variables and optimizations" // { default = true; };
      
      electronApps = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable optimized Wayland support for Electron applications";
        };
        
        suppressWarnings = mkOption {
          type = types.bool;
          default = true;
          description = "Suppress Wayland protocol version warnings and errors";
        };
      };
      
      protocolSupport = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Install enhanced Wayland protocol support";
        };
      };
    };
  };

  config = mkIf config.custom.wayland.enable {
    # Enhanced Wayland protocols and compositor support
    environment.systemPackages = mkIf config.custom.wayland.protocolSupport.enable (with pkgs; [
      wayland-protocols          # Latest Wayland protocols
      wayland-utils             # Wayland utilities
      wl-clipboard              # Wayland clipboard support
      wlr-randr                 # Display management
      xwayland                  # X11 compatibility
      mesa                      # Graphics drivers
      libdrm                    # Direct Rendering Manager
    ]);

    # Core Wayland and application environment variables
    environment.sessionVariables = {
      # === CORE WAYLAND SETTINGS ===
      WAYLAND_DISPLAY = "wayland-0";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "gnome";  # Helps with protocol negotiations
      
      # === APPLICATION BACKEND PREFERENCES ===
      NIXOS_OZONE_WL = "1";                    # Chromium/Electron apps
      MOZ_ENABLE_WAYLAND = "1";               # Firefox
      QT_QPA_PLATFORM = "wayland;xcb";        # Qt applications
      GDK_BACKEND = "wayland,x11";            # GTK applications  
      SDL_VIDEODRIVER = "wayland,x11";        # SDL applications
      CLUTTER_BACKEND = "wayland";            # Clutter applications
      
      # === ELECTRON/CHROMIUM OPTIMIZATION ===
      ELECTRON_OZONE_PLATFORM_HINT = "auto";   # Let Electron choose best platform
      ELECTRON_IS_DEV = "0";                   # Production mode
      CHROME_DESKTOP = "chromium-browser";
      
      # === WAYLAND PROTOCOL ENHANCEMENTS ===
      WAYLAND_DEBUG = "0";                     # Disable debug output
      XDG_RUNTIME_DIR = "/run/user/1000";
      
      # === GRAPHICS AND PERFORMANCE ===
      LIBGL_ALWAYS_SOFTWARE = "0";            # Use hardware acceleration
      MESA_LOADER_DRIVER_OVERRIDE = "iris";    # Intel graphics optimization
      __GL_GSYNC_ALLOWED = "1";               # Enable G-Sync if available
      __GL_VRR_ALLOWED = "1";                 # Variable refresh rate
      
      # === MEMORY AND PROCESS OPTIMIZATION ===
      MALLOC_CHECK_ = "0";                    # Disable malloc debugging
      MALLOC_PERTURB_ = "0";                  # Disable malloc perturbation
      
      # === JAVA APPLICATIONS ===
      _JAVA_AWT_WM_NONREPARENTING = "1";
      _JAVA_OPTIONS = "-Dawt.useSystemAAFontSettings=on";
      
      # === TERMINAL OPTIMIZATION ===
      TERM = "xterm-256color";
      COLORTERM = "truecolor";
    } // (mkIf config.custom.wayland.electronApps.suppressWarnings {
      # === ELECTRON WARNING SUPPRESSION ===
      ELECTRON_ENABLE_LOGGING = "0";
      ELECTRON_DISABLE_SECURITY_WARNINGS = "1";
      CHROMIUM_FLAGS = "--disable-logging --log-level=3 --quiet --silent";
    });

    # === OPTIMIZED APPLICATION WRAPPERS ===
    environment.shellAliases = mkIf config.custom.wayland.electronApps.enable {
      # Void Editor (Cursor alternative) - Optimized wrapper
      void = lib.mkDefault ''void \
        --ozone-platform-hint=auto \
        --enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder,VaapiIgnoreDriverChecks \
        --disable-features=WaylandFractionalScaleV1 \
        --enable-wayland-ime \
        --disable-gpu-sandbox \
        --disable-software-rasterizer \
        --enable-zero-copy \
        --password-store=basic \
        --no-zygote \
        ${if config.custom.wayland.electronApps.suppressWarnings then "--disable-logging --log-level=3 --quiet" else ""}'';
        
      # Warp Terminal - Optimized wrapper  
      warp = lib.mkDefault ''warp-terminal \
        --ozone-platform-hint=auto \
        --enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder \
        --disable-features=WaylandFractionalScaleV1 \
        --enable-wayland-ime \
        --disable-gpu-sandbox \
        --enable-zero-copy \
        ${if config.custom.wayland.electronApps.suppressWarnings then "--disable-logging --log-level=3 --quiet" else ""}'';

      # VS Code - Enhanced Wayland support
      code = lib.mkDefault ''code \
        --ozone-platform-hint=auto \
        --enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder \
        --enable-wayland-ime \
        --disable-gpu-sandbox \
        --password-store=gnome \
        ${if config.custom.wayland.electronApps.suppressWarnings then "--disable-logging --log-level=3" else ""}'';
        
      # Discord - Optimized for Wayland
      discord = lib.mkDefault ''discord \
        --ozone-platform-hint=auto \
        --enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder \
        --enable-wayland-ime \
        --disable-gpu-sandbox \
        ${if config.custom.wayland.electronApps.suppressWarnings then "--disable-logging --log-level=3" else ""}'';

      # Chromium browsers - Enhanced support
      google-chrome = lib.mkDefault ''google-chrome \
        --ozone-platform-hint=auto \
        --enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder,VaapiIgnoreDriverChecks \
        --disable-features=UseChromeOSDirectVideoDecoder \
        --enable-wayland-ime \
        --disable-gpu-sandbox'';
        
      chrome = lib.mkDefault ''google-chrome \
        --ozone-platform-hint=auto \
        --enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder,VaapiIgnoreDriverChecks \
        --disable-features=UseChromeOSDirectVideoDecoder \
        --enable-wayland-ime \
        --disable-gpu-sandbox'';
        
      chromium = lib.mkDefault ''chromium \
        --ozone-platform-hint=auto \
        --enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder \
        --enable-wayland-ime \
        --disable-gpu-sandbox'';
    };

    # === WAYLAND COMPOSITOR OPTIMIZATIONS ===
    services.xserver = {
      enable = true;
      displayManager.gdm = {
        wayland = mkDefault true;
      };
    };

    # === XDG DESKTOP PORTAL CONFIGURATION ===
    xdg.portal = {
      enable = mkDefault true;
      wlr.enable = mkIf (config.services.xserver.displayManager.gdm.wayland) true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
    };

    # === ADDITIONAL WAYLAND OPTIMIZATIONS ===
    # Enable hardware video acceleration
    hardware.graphics = {
      enable = mkDefault true;
      enable32Bit = mkDefault true;
      extraPackages = with pkgs; [
        intel-media-driver  # For Intel graphics
        vaapiIntel         # VA-API Intel driver
        vaapiVdpau         # VDPAU backend for VA-API
        libvdpau-va-gl     # VDPAU driver with VA-API/OpenGL backend
      ];
    };
    
    # Kernel parameters for better Wayland performance
    boot.kernelParams = [
      "i915.enable_psr=0"           # Disable PSR to prevent flickering
      "i915.enable_fbc=1"           # Enable framebuffer compression
      "intel_pstate=active"         # Intel CPU power management
    ];

    # === SYSTEM-WIDE WAYLAND APPLICATION SUPPORT ===
    programs.sway.enable = mkDefault false;  # Disable if using GNOME
    
    # Enable DBus services for Wayland applications
    services.dbus.packages = with pkgs; [
      gcr
      gnome-keyring
    ];

    # === LOGGING AND DEBUG OPTIMIZATION ===
    environment.etc = mkIf config.custom.wayland.electronApps.suppressWarnings {
      "chromium-flags.conf".text = ''
        --disable-logging
        --log-level=3
        --quiet
        --disable-background-timer-throttling
        --disable-backgrounding-occluded-windows
        --disable-renderer-backgrounding
      '';
    };
  };
}
