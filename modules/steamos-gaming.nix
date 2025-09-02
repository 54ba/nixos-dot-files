{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.steamos-gaming;
in

{
  options.custom.steamos-gaming = {
    enable = mkEnableOption "SteamOS-like gaming environment";

    steam = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Steam gaming platform";
      };

      remotePlay = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Steam Remote Play";
      };

      hardware = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Steam hardware support (controllers, VR)";
      };

      bigPicture = mkOption {
        type = types.bool;
        default = true;
        description = "Optimize for Steam Big Picture mode";
      };

      proton = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Proton for Windows game compatibility";
        };

        ge = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Proton-GE (community version with extra fixes)";
        };
      };
    };

    compatibilityLayers = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable game compatibility layers";
      };

      lutris = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Lutris game manager";
      };

      heroicLauncher = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Heroic Games Launcher for Epic/GOG";
      };

      bottles = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Bottles for Wine management";
      };
    };

    performance = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable gaming performance optimizations";
      };

      gamemode = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Feral GameMode for automatic game optimizations";
      };

      mangohud = mkOption {
        type = types.bool;
        default = true;
        description = "Enable MangoHud for in-game performance overlay";
      };

      lowLatency = mkOption {
        type = types.bool;
        default = true;
        description = "Enable low-latency kernel and audio optimizations";
      };
    };

    hardware = {
      controllers = mkOption {
        type = types.bool;
        default = true;
        description = "Enable support for gaming controllers";
      };

      vr = mkOption {
        type = types.bool;
        default = false;
        description = "Enable VR support";
      };

      audio = mkOption {
        type = types.bool;
        default = true;
        description = "Enable optimized gaming audio";
      };
    };

    networking = {
      gaming = mkOption {
        type = types.bool;
        default = true;
        description = "Enable gaming-specific network optimizations";
      };

      ports = {
        steam = mkOption {
          type = types.listOf types.int;
          default = [ 27015 27036 ];
          description = "Steam networking ports";
        };

        custom = mkOption {
          type = types.listOf types.int;
          default = [];
          description = "Custom gaming ports to open";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable Steam with hardware support
    programs.steam = mkIf cfg.steam.enable {
      enable = true;
      remotePlay.openFirewall = cfg.steam.remotePlay;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = cfg.steam.bigPicture;
      extraCompatPackages = optionals cfg.steam.proton.ge [ pkgs.proton-ge-bin ];
    };

    # Enable GameScope for Steam Deck-like experience
    programs.gamescope = mkIf cfg.steam.bigPicture {
      enable = true;
      capSysNice = true;
      args = [
        "--rt"
        "--expose-wayland"
      ];
    };

    # Gaming performance optimizations - GameMode is handled by system-services.nix
    # Removed duplicate programs.gamemode configuration to avoid conflicts

    # System packages for gaming
    environment.systemPackages = with pkgs; [
      # Steam and gaming platforms
    ] ++ optionals cfg.steam.enable [
      steam
      steam-run
      steamcmd
    ] ++ optionals cfg.compatibilityLayers.enable [
      (mkIf cfg.compatibilityLayers.lutris lutris)
      (mkIf cfg.compatibilityLayers.heroicLauncher heroic)
      (mkIf cfg.compatibilityLayers.bottles bottles)
    ] ++ optionals cfg.performance.enable [
      (mkIf cfg.performance.gamemode gamemode)
      (mkIf cfg.performance.mangohud mangohud)
      (mkIf cfg.performance.mangohud goverlay) # MangoHud GUI
    ] ++ optionals cfg.hardware.controllers [
      # Controller support - kernel provides built-in support
    ] ++ optionals cfg.hardware.vr [
      # VR support
      opencomposite
      index_camera_passthrough
    ] ++ [
      # Gaming utilities
      wine-staging
      winetricks
      dxvk
      vkd3d
      protontricks
      
      # System monitoring
      htop
      nvtopPackages.full
      gpu-viewer
      
      # Audio
      pavucontrol
      helvum
      
      # Performance tools
      stress
      s-tui
      
      # Network tools
      iperf3
      mtr
    ];

    # Hardware support
    hardware = {
      # Enable graphics support for Steam and games
      graphics = {
        enable = true;
        enable32Bit = true;  # Enable 32-bit graphics support for games
      };
    };

    # Disable Pulseaudio in favor of PipeWire for gaming
    services.pulseaudio.enable = false;

    # PipeWire configuration for gaming audio
    services.pipewire = mkIf cfg.hardware.audio {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      
      # Low-latency configuration
      extraConfig.pipewire."10-gaming" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 32;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 8192;
        };
      };
    };

    # Enable udev rules for controllers - Steam handles this automatically
    services.udev.packages = with pkgs; optionals cfg.hardware.controllers [
      # Steam provides its own udev rules for controllers
    ];

    # Kernel parameters for gaming
    boot.kernel.sysctl = mkIf cfg.performance.enable {
      # Network optimizations
      "net.core.rmem_default" = 262144;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_default" = 262144;
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_rmem" = "4096 131072 6291456";
      "net.ipv4.tcp_wmem" = "4096 65536 4194304";
      
      # Gaming performance
      "vm.max_map_count" = 2147483642;
      "fs.file-max" = 2097152;
    };

    # Gaming-specific firewall rules
    networking.firewall = mkIf cfg.networking.gaming {
      allowedTCPPorts = cfg.networking.ports.steam ++ cfg.networking.ports.custom;
      allowedUDPPorts = cfg.networking.ports.steam ++ cfg.networking.ports.custom ++ [
        # Additional UDP ports for gaming
        3478 4379 4380  # Steam voice chat
        27000 27001 27002 27003 27004 27005 27006 27007 27008 27009 27010
        27011 27012 27013 27014 27015 27016 27017 27018 27019 27020 27021
        27022 27023 27024 27025 27026 27027 27028 27029 27030
      ];
    };

    # Enable necessary services
    services = {
      # Input device support
      udev.enable = true;
      
      # Display management
      xserver = {
        enable = true;
        excludePackages = [ pkgs.xterm ];
      };
    };

    # Fonts for gaming UI
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      liberation_ttf
      dejavu_fonts
      source-code-pro
    ];

    # User groups for gaming
    users.groups = {
      gamemode = {};
      input = {};
    };

    # Environment variables for gaming
    environment.sessionVariables = {
      # Steam
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/mahmoud/.steam/root/compatibilitytools.d";
      
      # Gaming performance
      __GL_THREADED_OPTIMIZATIONS = "1";
      __GL_SHADER_DISK_CACHE = "1";
      __GL_SHADER_DISK_CACHE_PATH = "/tmp";
      
      # MangoHud
      MANGOHUD = mkIf cfg.performance.mangohud "1";
      MANGOHUD_DLSYM = mkIf cfg.performance.mangohud "1";
    };

    # GameMode is handled by programs.gamemode in system-services.nix
    # Removed duplicate systemd service definition to avoid conflicts

    # Polkit rules for GameMode
    security.polkit.extraConfig = mkIf cfg.performance.gamemode ''
      polkit.addRule(function(action, subject) {
          if ((action.id == "com.feralinteractive.GameMode.govern-cpu" ||
               action.id == "com.feralinteractive.GameMode.govern-gpu") &&
              subject.isInGroup("wheel")) {
              return polkit.Result.YES;
          }
      });
    '';

    # Gaming-specific system configuration
    system.activationScripts.steamosGaming = mkIf cfg.enable ''
      # Create Steam compatibility tools directory
      mkdir -p /home/mahmoud/.steam/root/compatibilitytools.d
      chown -R mahmoud:users /home/mahmoud/.steam 2>/dev/null || true
      
      # Create MangoHud config directory
      mkdir -p /home/mahmoud/.config/MangoHud
      chown -R mahmoud:users /home/mahmoud/.config/MangoHud 2>/dev/null || true
      
      # Set gaming-specific permissions
      echo 'Adding user to gaming groups...'
    '';
  };
}
