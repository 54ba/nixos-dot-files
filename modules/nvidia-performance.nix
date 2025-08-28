{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.nvidiaPerformance;
in {
  options.custom.nvidiaPerformance = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable NVIDIA performance optimizations and gaming enhancements";
    };

    gaming = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable gaming-specific optimizations";
      };

      dlss = mkOption {
        type = types.bool;
        default = true;
        description = "Enable DLSS support for AI-powered upscaling";
      };

      rayTracing = mkOption {
        type = types.bool;
        default = true;
        description = "Enable ray tracing support";
      };

      performanceMode = mkOption {
        type = types.enum [ "performance" "balanced" "quality" ];
        default = "performance";
        description = "Performance mode preference";
      };
    };

    monitoring = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GPU monitoring tools";
      };
    };
  };

  config = mkIf cfg.enable {
    # NVIDIA driver configuration
    services.xserver.videoDrivers = [ "nvidia" ];

    # NVIDIA settings
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement = {
        enable = true;
        finegrained = false;  # Disabled as it requires offload mode
      };
      prime = {
        offload.enable = false;  # Not using hybrid graphics
        sync.enable = false;
      };
      open = cfg.gaming.rayTracing;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Hardware acceleration
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
      ];
    };

    # Gaming optimizations
    environment.systemPackages = with pkgs; [
      # Performance monitoring tools
      nvitop
      
      # Gaming utilities
      gamemode
      mangohud
      
      # Wine and DirectX support if needed
      wineWowPackages.stable
      winetricks
    ];

    # Environment variables for performance
    environment.variables = {
      # NVIDIA specific
      __GL_SYNC_TO_VBLANK = "0";
      __GL_THREADED_OPTIMIZATIONS = "1";
      
      # Vulkan configuration
      VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json";
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json";
    };

    # Performance monitoring
    systemd.user.services.nvidia-monitor = mkIf cfg.monitoring.enable {
      description = "NVIDIA GPU Monitor";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.nvitop}/bin/nvitop";
        Restart = "always";
        RestartSec = "5";
      };
    };
  };
}
