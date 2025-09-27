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
        default = false;
        description = "Enable GPU monitoring tools (system-wide)";
      };
      
      autoStart = mkOption {
        type = types.bool;
        default = false;
        description = "Automatically start monitoring service on boot";
      };
      
      tools = {
        nvitop = mkOption {
          type = types.bool;
          default = true;
          description = "Enable nvitop GPU monitoring tool";
        };
        
        nvtop = mkOption {
          type = types.bool;
          default = true;
          description = "Enable nvtop GPU monitoring tool";
        };
        
        gpustat = mkOption {
          type = types.bool;
          default = true;
          description = "Enable gpustat GPU monitoring tool";
        };
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

    # System packages for NVIDIA performance and gaming
    environment.systemPackages = with pkgs; ([
      # Gaming utilities (always enabled when NVIDIA performance is enabled)
      gamemode
      mangohud
      glxinfo
      vulkan-tools
      
      # NVIDIA utilities (nvidia-offload is created by hardware.nvidia.prime.offload)
      config.hardware.nvidia.package  # NVIDIA driver package
    ] 
    # GPU Monitoring tools (conditional)
    ++ lib.optionals cfg.monitoring.enable (lib.flatten [
      (lib.optional cfg.monitoring.tools.nvitop nvitop)
      # nvtop package may not be available in current nixpkgs
      # (lib.optional cfg.monitoring.tools.nvtop nvtop)
      (lib.optional cfg.monitoring.tools.gpustat python3Packages.gpustat)
    ])
    # Wine packages moved to wine-support.nix module to avoid conflicts
    );

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

    # System-wide GPU monitoring services
    systemd.services.nvidia-smi-logger = mkIf (cfg.monitoring.enable && cfg.monitoring.autoStart) {
      description = "NVIDIA GPU Statistics Logger";
      wantedBy = [ "multi-user.target" ];
      path = [ config.hardware.nvidia.package ];
      serviceConfig = {
        Type = "simple";
        User = "root";
        ExecStart = "${pkgs.writeShellScript "nvidia-smi-logger" ''
          #!/bin/sh
          while true; do
            nvidia-smi --query-gpu=timestamp,name,pci.bus_id,driver_version,pstate,pcie.link.gen.max,pcie.link.gen.current,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used --format=csv -l 30
          done
        ''}";
        Restart = "always";
        RestartSec = "10";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
    
    # Enable NVIDIA persistence daemon for better performance (if available)
    # Note: nvidia-persistenced may not be available in all NVIDIA driver versions
    systemd.services.nvidia-persistenced = mkIf (cfg.enable && false) {  # Disabled for now
      description = "NVIDIA Persistence Daemon";
      wantedBy = [ "multi-user.target" ];
      path = [ config.hardware.nvidia.package ];
      serviceConfig = {
        Type = "forking";
        PIDFile = "/var/run/nvidia-persistenced/nvidia-persistenced.pid";
        Restart = "always";
        ExecStart = "nvidia-persistenced --verbose";
        ExecStopPost = "/bin/rm -rf /var/run/nvidia-persistenced";
        User = "root";
      };
      preStart = "mkdir -p /var/run/nvidia-persistenced";
    };
    
    # Additional GPU monitoring tools as system services (optional)
    systemd.services.gpu-monitor-web = mkIf (cfg.monitoring.enable && cfg.monitoring.tools.nvitop) {
      description = "GPU Monitoring Web Interface";
      wantedBy = mkIf cfg.monitoring.autoStart [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "nobody";
        Group = "nogroup";
        ExecStart = "${pkgs.writeShellScript "gpu-monitor-web" ''
          #!/bin/sh
          # Simple GPU monitoring accessible via command line
          echo "GPU monitoring tools available:"
          echo "  nvitop - Interactive GPU process monitor"
          echo "  nvidia-smi - NVIDIA system management interface"
          echo "  vulkan-tools - Vulkan debugging and info"
          sleep infinity
        ''}";
        Restart = "no";
      };
    };
  };
}
