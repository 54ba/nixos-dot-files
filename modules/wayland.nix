{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.wayland = {
      enable = mkEnableOption "Wayland environment variables and optimizations" // { default = true; };
    };
  };

  config = mkIf config.custom.wayland.enable {
    # Wayland and application environment variables
    environment.sessionVariables = {
      # Force Wayland for all applications
      WAYLAND_DISPLAY = "wayland-0";
      XDG_SESSION_TYPE = "wayland";
      
      # Enable Wayland support for various applications
      NIXOS_OZONE_WL = "1";  # Chromium/Electron apps
      MOZ_ENABLE_WAYLAND = "1";  # Firefox
      QT_QPA_PLATFORM = "wayland;xcb";  # Qt applications
      GDK_BACKEND = "wayland,x11";  # GTK applications
      SDL_VIDEODRIVER = "wayland,x11";  # SDL applications
      CLUTTER_BACKEND = "wayland";  # Clutter applications
      
      # XDG runtime directory
      XDG_RUNTIME_DIR = "/run/user/1000";
      
      # Chrome/Chromium optimizations
      CHROME_WRAPPER = "${pkgs.google-chrome}/bin/google-chrome-stable";
      CHROME_DESKTOP = "google-chrome";
      CHROME_FLAGS = "--enable-features=UseOzonePlatform --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --disable-dev-shm-usage";
      
      # Discord optimizations
      DISCORD_FLAGS = "--enable-features=UseOzonePlatform --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --disable-dev-shm-usage";
      
      # Electron applications optimizations
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      ELECTRON_FLAGS = "--enable-features=UseOzonePlatform --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --disable-dev-shm-usage";
      
      # VS Code optimizations
      VSCODE_FLAGS = "--enable-features=UseOzonePlatform --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox";
      
      # Memory optimizations for all applications
      MOZ_DISABLE_RDD_SANDBOX = "1";
      MOZ_DISABLE_CONTENT_SANDBOX = "1";
      
      # Disable hardware acceleration for problematic applications
      LIBGL_ALWAYS_SOFTWARE = "0";  # Enable hardware acceleration by default
      
      # Java applications Wayland support
      _JAVA_AWT_WM_NONREPARENTING = "1";
      
      # Terminal and shell optimizations
      TERM = "xterm-256color";
    };
    
    # Shell aliases for Wayland applications
    environment.shellAliases = {
      # Electron applications with Wayland support
      discord = "discord --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --disable-dev-shm-usage";
      code = "code --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --no-zygote";
      vscode = "code --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --no-zygote";
      slack = "slack --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --disable-dev-shm-usage --no-zygote";
      zoom = "zoom --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --disable-dev-shm-usage --no-zygote";
      
      # Chrome/Chromium with Wayland
      google-chrome = "google-chrome --enable-features=UseOzonePlatform --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --disable-dev-shm-usage";
      chrome = "google-chrome --enable-features=UseOzonePlatform --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --disable-dev-shm-usage";
      chromium = "chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --no-sandbox --disable-gpu-sandbox --disable-dev-shm-usage";
    };
  };
}
