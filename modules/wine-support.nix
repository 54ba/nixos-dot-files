{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.wine = {
      enable = mkEnableOption "Enable Wine support for Windows applications";

      packages = {
        wine64 = mkEnableOption "Install Wine 64-bit";
        wine32 = mkEnableOption "Install Wine 32-bit (for 32-bit Windows apps)";
        winetricks = mkEnableOption "Install Winetricks for Wine configuration";
        playonlinux = mkEnableOption "Install PlayOnLinux for easy Wine management";
        lutris = mkEnableOption "Install Lutris for game management";
        dxvk = mkEnableOption "Install DXVK for DirectX 11/10 support";
        vkd3d = mkEnableOption "Install VKD3D for DirectX 12 support";
        mono = mkEnableOption "Install Wine Mono for .NET applications";
        gecko = mkEnableOption "Install Wine Gecko for web browser support";
      };

      performance = {
        enable = mkEnableOption "Enable Wine performance optimizations";
        esync = mkEnableOption "Enable Esync for better performance";
        fsync = mkEnableOption "Enable Fsync for better performance (requires kernel 5.16+)";
        gamemode = mkEnableOption "Enable Feral GameMode for performance";
        mangohud = mkEnableOption "Enable MangoHud for performance monitoring";
      };

      compatibility = {
        enable = mkEnableOption "Enable Wine compatibility features";
        virtualDesktop = mkEnableOption "Enable virtual desktop mode";
        dpiScaling = mkEnableOption "Enable DPI scaling support";
        audio = mkEnableOption "Enable enhanced audio support";
        networking = mkEnableOption "Enable enhanced networking support";
      };
    };
  };

  config = mkIf config.custom.wine.enable {
              # Wine packages - enhanced with .NET Framework support
  environment.systemPackages = with pkgs; [
          # Core Wine packages
      wine64
      wineWowPackages.stable
    winetricks
    playonlinux
    lutris

    # DirectX compatibility layers
    dxvk
    vkd3d

    # Performance tools
    gamemode
    mangohud

    # Additional tools
    cabextract
    p7zip
    unzip
    zip

    # Font support
    corefonts
    liberation_ttf
    dejavu_fonts

    # .NET Framework support
    mono
    dotnet-sdk

          # Additional Windows compatibility tools
      q4wine
      bottles

          # Registry and system tools (included with wine package)
  ];

    # Wine environment variables with NVIDIA GPU support
    environment.sessionVariables = {
      # Wine configuration
      WINEPREFIX = "$HOME/.wine";
      WINEARCH = "win64";

      # Performance optimizations
      WINEDEBUG = "-all";
      WINEDLLOVERRIDES = "mscoree,mshtml=";

      # DirectX compatibility with NVIDIA optimization
      DXVK_HUD = lib.mkForce "fps,memory,gpu";  # Override system-base setting
      DXVK_LOG_LEVEL = "warn";  # Reduce log verbosity for performance
      DXVK_CONFIG_FILE = "$HOME/.config/dxvk.conf";
      
      # NVIDIA GPU acceleration
      __GL_SHADER_DISK_CACHE = "1";
      __GL_SHADER_DISK_CACHE_PATH = "$HOME/.cache/nv_GLCache";
      __GL_THREADED_OPTIMIZATIONS = "1";
      __GL_SYNC_TO_VBLANK = "0";  # Disable VSync for better performance
      WINE_LARGE_ADDRESS_AWARE = "1";  # Enable 4GB memory support
      
      # Gaming performance
      WINE_CPU_TOPOLOGY = "4:2";  # 4 cores, 2 logical processors per core
      STAGING_WRITECOPY = "1";     # Enable staging writecopy optimization
      STAGING_SHARED_MEMORY = "1"; # Enable shared memory optimization

      # Audio configuration
      PULSE_LATENCY_MSEC = "30";   # Lower latency for gaming
      ALSA_PCM_CARD = "0";
      ALSA_PCM_DEVICE = "0";
      WINEPULSE_TIMING = "1";      # Enable PulseAudio timing
    };

    # Wine system configuration with NVIDIA optimizations
    systemd.user.services = {
      # Wine services for better integration
      "wine-prefix-update" = {
        description = "Update Wine prefix";
        wantedBy = ["default.target"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.bash}/bin/bash -c 'if [ -d $HOME/.wine ]; then wineboot --update; fi'";
          User = "mahmoud";
          Environment = [ "__GL_THREADED_OPTIMIZATIONS=1" "WINEDEBUG=-all" ];
        };
      };
      
      # DXVK cache optimization service
      "dxvk-cache-optimize" = {
        description = "Optimize DXVK cache for NVIDIA GPU";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p $HOME/.cache/nv_GLCache $HOME/.cache/dxvk'";
          User = "mahmoud";
        };
      };
    };

    # Wine registry settings
    environment.etc."wine/wine.conf".text = ''
      [wine]
      # Wine configuration
      Windows = "$HOME/.wine/drive_c/windows"
      System = "$HOME/.wine/drive_c/windows/system32"
      Temp = "$HOME/.wine/drive_c/windows/temp"

      # Performance settings
      [wine]
      # Enable Esync if supported
      ${lib.optionalString config.custom.wine.performance.esync "WINEFSYNC = 1"}

      # Enable Fsync if supported
      ${lib.optionalString config.custom.wine.performance.fsync "WINEFSYNC = 1"}

      # Audio settings
      [wine]
      # Use PulseAudio
      ${lib.optionalString config.custom.wine.compatibility.audio "AUDIODRIVER = pulse"}

      # Network settings
      [wine]
      # Enable network support
      ${lib.optionalString config.custom.wine.compatibility.networking "WINEDLLOVERRIDES = winhttp=native"}
    '';

    # Note: XDG MIME associations and desktop entries are configured in home-manager
    # for user-specific settings, while this module handles system-wide Wine configuration
  };
}