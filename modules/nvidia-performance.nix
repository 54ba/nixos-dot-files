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
    # NVIDIA performance optimizations that extend AI services configuration
    # This module adds gaming-specific optimizations on top of the base AI services setup
    
    # Use mkMerge to handle both scenarios without conflicts
    hardware.nvidia = mkMerge [
      # When AI services are managing the drivers, just add Prime offloading
      (mkIf config.custom.ai-services.nvidia.enable {
        prime = {
          offload = {
            enable = true;
            enableOffloadCmd = true;  # Enable nvidia-offload command for gaming
          };
          sync.enable = false;     # Don't use sync mode (offload is better for laptops)
          
          # Hardware-specific bus IDs for Lenovo S540 GTX 15IWL
          intelBusId = "PCI:0:2:0";    # Intel UHD Graphics 620
          nvidiaBusId = "PCI:2:0:0";   # NVIDIA GTX 1650 Mobile
        };
      })
      
      # Standalone NVIDIA configuration if AI services are not enabled
      (mkIf (!config.custom.ai-services.nvidia.enable) {
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
      })
    ];
    
    # Video drivers - only set if not managed by AI services
    services.xserver.videoDrivers = mkIf (!config.custom.ai-services.nvidia.enable) [ "nvidia" ];

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

    # Environment variables for performance - merged with AI services variables
    environment.sessionVariables = {
      # NVIDIA gaming-specific optimizations
      __GL_SYNC_TO_VBLANK = mkDefault "0";            # Disable VSync for gaming
      __GL_THREADED_OPTIMIZATIONS = mkDefault "1";    # Enable threaded optimizations
      __GL_SHADER_DISK_CACHE = mkDefault "1";         # Enable shader caching
      __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = mkDefault "1";  # Keep shader cache
      
      # Vulkan configuration for gaming
      VK_DRIVER_FILES = mkDefault "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json";
      VK_ICD_FILENAMES = mkDefault "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json";
      
      # Performance mode settings
      __GL_GSYNC_ALLOWED = mkDefault "1";
      __GL_VRR_ALLOWED = mkDefault "1";
      
      # NVIDIA Prime offloading support
      __NV_PRIME_RENDER_OFFLOAD = mkDefault "1";
      __GLX_VENDOR_LIBRARY_NAME = mkDefault "nvidia";
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
