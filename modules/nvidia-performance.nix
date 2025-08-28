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

    overclocking = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable GPU overclocking support";
      };

      powerLimit = mkOption {
        type = types.int;
        default = 100;
        description = "Power limit percentage (100 = default)";
      };

      memoryOverclock = mkOption {
        type = types.int;
        default = 0;
        description = "Memory overclock in MHz";
      };

      coreOverclock = mkOption {
        type = types.int;
        default = 0;
        description = "Core overclock in MHz";
      };
    };

    monitoring = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GPU monitoring tools";
      };

      nvtop = mkOption {
        type = types.bool;
        default = true;
        description = "Enable nvtop for GPU monitoring";
      };

      greenWithEnvy = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GreenWithEnvy for advanced GPU control";
      };
    };

    optimization = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable performance optimizations";
      };

      powerMizer = mkOption {
        type = types.enum [ "adaptive" "prefer_maximum_performance" "auto" ];
        default = "prefer_maximum_performance";
        description = "PowerMizer mode for performance";
      };

      textureQuality = mkOption {
        type = types.enum [ "high_quality" "quality" "performance" "high_performance" ];
        default = "performance";
        description = "Texture quality preference";
      };

      shaderCache = mkOption {
        type = types.bool;
        default = true;
        description = "Enable shader cache for better performance";
      };
    };
  };

  config = mkIf cfg.enable {
    # NVIDIA driver configuration
    services.xserver.videoDrivers = [ "nvidia" ];

    # NVIDIA settings
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      open = cfg.gaming.rayTracing;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Hardware acceleration
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
      ];
    };

    # Gaming optimizations
    environment.systemPackages = with pkgs; [
      # Performance monitoring
      nvtopPackages.nvidia

      # Gaming utilities
      gamemode
      mangohud
      goverlay
      libstrangle
      vkbasalt

      # Wine and DirectX
      dxvk
      vkd3d
      wine64
      winetricks

      # Additional gaming tools
      steam
      lutris
      playonlinux
    ] ++ lib.optionals cfg.monitoring.enable [
      nvtopPackages.nvidia
    ];

    # NVIDIA persistence daemon - removed as package doesn't exist
    # systemd.services.nvidia-persistenced = {
    #   description = "NVIDIA Persistence Daemon";
    #   wantedBy = [ "multi-user.target" ];
    #   serviceConfig = {
    #     Type = "forking";
    #     ExecStart = "${pkgs.nvidia-persistenced}/bin/nvidia-persistenced --user root";
    #     Restart = "always";
    #   };
    # };

    # Performance tuning
    boot.kernelParams = [
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_RegistryDwords=OverrideMaxPerf=0x1"
      "nvidia.NVreg_EnablePCIeGen3=1"
      "nvidia.NVreg_UsePageAttributeTable=1"
      "nvidia.NVreg_EnableUnsupportedGpus=1"
      "nvidia.NVreg_EnablePCIeGen4=1"
    ] ++ lib.optionals cfg.optimization.enable [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia.NVreg_EnableResizableBar=1"
    ];

    # Environment variables for performance
    environment.variables = {
      # NVIDIA performance
      __GL_SYNC_TO_VBLANK = "0";
      __GL_THREADED_OPTIMIZATIONS = "1";
      __GL_YIELD = "NOTHING";

      # Gaming performance
      DXVK_HUD = "1";
      DXVK_STATE_CACHE = "1";
      VKD3D_CONFIG = "dxr,dxr11";

      # Wine optimizations
      WINEDLLOVERRIDES = lib.mkForce "dxgi=n";
      WINE_LARGE_ADDRESS_AWARE = "1";

      # Vulkan optimizations
      VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json";
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json";
    };

    # NVIDIA power management
    powerManagement.cpuFreqGovernor = "performance";

    # Gaming optimizations
    systemd.user.services.gamemode = lib.mkIf cfg.gaming.enable {
      description = "GameMode daemon";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.gamemode}/bin/gamemoded";
        Restart = "always";
        RestartSec = "1";
      };
    };

    # NVIDIA settings configuration
    environment.etc."nvidia/settings.conf" = {
      text = ''
        # NVIDIA Settings Configuration
        # Performance optimizations

        # PowerMizer settings
        [gpu:0]/PowerMizerEnable=1
        [gpu:0]/PowerMizerLevel=${toString (if cfg.optimization.powerMizer == "prefer_maximum_performance" then 1 else 0)}

        # Texture quality
        [gpu:0]/TextureQuality=${cfg.optimization.textureQuality}

        # Shader cache
        [gpu:0]/ShaderCache=${if cfg.optimization.shaderCache then "1" else "0"}

        # Performance mode
        [gpu:0]/PerfLevel=${if cfg.gaming.performanceMode == "performance" then "1" else "0"}

        # Memory allocation
        [gpu:0]/MemoryAllocationPolicy=2

        # GPU scaling
        [gpu:0]/GPUScaling=1

        # DSR factors
        [gpu:0]/DSRFactor=2.0
        [gpu:0]/DSRSmoothing=0.5

        # Anisotropic filtering
        [gpu:0]/AnisotropicFiltering=16

        # Antialiasing
        [gpu:0]/AntialiasingMode=1
        [gpu:0]/AntialiasingLevel=8

        # CUDA settings
        [gpu:0]/CUDAForceP2State=0

        # OpenGL settings
        [gpu:0]/OpenGLImageSettings=1
        [gpu:0]/OpenGLThreadControl=1

        # Vulkan settings
        [gpu:0]/VulkanAsyncCompute=1
        [gpu:0]/VulkanPreferGpuCompute=1
      '';
    };

    # Gaming profile for better performance
    environment.etc."gamemode.ini" = lib.mkForce (lib.mkIf cfg.gaming.enable {
      text = ''
        [general]
        # GameMode configuration for NVIDIA performance

        # CPU optimizations
        renice_cpu = 1
        cpu_governor = performance
        cpu_cores = 0,1,2,3,4,5,6,7

        # GPU optimizations
        gpu_apply_optimisations = 1
        gpu_memory_freq = 1000
        gpu_core_freq = 2000

        # I/O optimizations
        ioprio = 0
        ioprio_class = 1

        # Memory optimizations
        vm_compaction = 1
        vm_swappiness = 10

        # Network optimizations
        network_priority = 1

        # Process optimizations
        soft_realtime = 1
        reaper = 1

        # Wine optimizations
        wine_optimisations = 1
        wine_nice = -5
      '';
    });

    # NVIDIA container support
    hardware.nvidia-container-toolkit.enable = cfg.monitoring.enable;

    # Performance monitoring
    systemd.user.services.nvidia-monitor = lib.mkIf cfg.monitoring.enable {
      description = "NVIDIA GPU Monitor";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.nvtopPackages.nvidia}/bin/nvtop";
        Restart = "always";
        RestartSec = "5";
      };
    };
  };
}