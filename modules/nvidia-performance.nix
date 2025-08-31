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
    # NVIDIA driver configuration for hybrid graphics
    services.xserver.videoDrivers = [ "nvidia" ];

    # NVIDIA settings for hybrid graphics (Intel + NVIDIA)
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement = {
        enable = true;
        finegrained = true;   # Enable for hybrid graphics power management
      };
      prime = {
        # Enable NVIDIA Prime offloading for hybrid graphics
        offload = {
          enable = true;
          enableOffloadCmd = true;  # Enable nvidia-offload command
        };
        sync.enable = false;     # Don't use sync mode (offload is better for laptops)
        
        # Hardware-specific bus IDs for Lenovo S540 GTX 15IWL
        intelBusId = "PCI:0:2:0";    # Intel UHD Graphics 620
        nvidiaBusId = "PCI:2:0:0";   # NVIDIA GTX 1650 Mobile
      };
      open = false;  # Use proprietary drivers for better stability
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
