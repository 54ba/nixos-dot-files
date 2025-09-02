{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.ai-services = {
      enable = mkEnableOption "AI services and tools";
      
      ollama = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Ollama AI service";
        };
        acceleration = mkOption {
          type = types.enum [ "cpu" "cuda" "rocm" ];
          default = "cuda";
          description = "AI acceleration backend";
        };
      };
      
      nvidia = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable NVIDIA GPU support for AI workloads";
        };
        package = mkOption {
          type = types.str;
          default = "stable";
          description = "NVIDIA driver package variant (stable, beta, legacy)";
        };
        powerManagement = mkOption {
          type = types.bool;
          default = false;
          description = "Enable NVIDIA power management";
        };
      };
      
      packages = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Install AI development packages";
        };
      };
      
      nixai = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable nixai configuration and tools";
        };
        configPath = mkOption {
          type = types.str;
          default = "/etc/nixai/nixai-config.yaml";
          description = "Path to nixai configuration file";
        };
      };
    };
  };

  config = mkIf config.custom.ai-services.enable {
    # Enable OpenGL drivers for NVIDIA/CUDA
    hardware.graphics.enable = true;
    
    # Ollama Configuration with GPU Acceleration
    services.ollama = mkIf config.custom.ai-services.ollama.enable {
      enable = true;
      acceleration = config.custom.ai-services.ollama.acceleration;
      host = "0.0.0.0";  # Allow access from all interfaces
      port = 11434;
    };

    # NVIDIA Configuration for AI Workloads
    hardware.nvidia = mkIf config.custom.ai-services.nvidia.enable {
      package = if config.custom.ai-services.nvidia.package == "stable" then
        config.boot.kernelPackages.nvidiaPackages.stable
      else if config.custom.ai-services.nvidia.package == "beta" then
        config.boot.kernelPackages.nvidiaPackages.beta
      else
        config.boot.kernelPackages.nvidiaPackages.legacy_470;
      
      modesetting.enable = true;
      powerManagement.enable = config.custom.ai-services.nvidia.powerManagement;
      open = false;
      nvidiaSettings = true;
    };
    
    # Enable NVIDIA driver in xserver and wayland
    services.xserver.videoDrivers = mkIf config.custom.ai-services.nvidia.enable [ "nvidia" ];
    
    # Blacklist nouveau driver to avoid conflicts with NVIDIA
    boot.blacklistedKernelModules = mkIf config.custom.ai-services.nvidia.enable [ "nouveau" ];
    
    # Force load NVIDIA modules
    boot.kernelModules = mkIf config.custom.ai-services.nvidia.enable [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

    # AI Development and nixai packages combined
    environment.systemPackages = 
      (optionals (config.custom.ai-services.enable && config.custom.ai-services.packages.enable) (with pkgs; [
        # NVIDIA CUDA Toolkit and drivers
        cudatoolkit
        nvidia-vaapi-driver
        
        # Python AI/ML ecosystem
        python311
        python311Packages.pip
        python311Packages.virtualenv
        python311Packages.numpy
        python311Packages.pandas
        python311Packages.scikit-learn
        python311Packages.matplotlib
        python311Packages.jupyter
        python311Packages.torch
        python311Packages.torchvision
        python311Packages.transformers
        
        # GPU monitoring and testing tools
        nvtopPackages.nvidia
        clinfo
        vulkan-tools
      ])) ++
      (optionals config.custom.ai-services.nixai.enable (with pkgs; [
        # AI and machine learning tools
        jq
        yq-go
        curl
        wget
        
        # Additional AI tools that may be useful with nixai
        python311Packages.openai
        python311Packages.requests
      ]));

    # Environment variables for AI development
    environment.sessionVariables = mkIf (config.custom.ai-services.enable && config.custom.ai-services.packages.enable) {
      CUDA_PATH = "${pkgs.cudatoolkit}";
      CUDA_HOME = "${pkgs.cudatoolkit}";
      LD_LIBRARY_PATH = mkBefore [ "${pkgs.cudatoolkit}/lib" ];
    };

    # System optimization for AI workloads - Use proper sysctl configuration
    boot.kernel.sysctl = mkIf config.custom.ai-services.enable {
      # Increase shared memory for AI workloads
      "kernel.shmmax" = 68719476736;  # 64GB shared memory max
      "kernel.shmall" = 4294967296;   # 16GB shared memory all
    };
    
    # GPU performance tuning service (safer approach)
    systemd.services.ai-performance-tuning = mkIf config.custom.ai-services.enable {
      description = "Optimize system for AI workloads";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "ai-performance-tuning" ''
          # Set GPU performance mode (only if GPU exists)
          if [ -f /sys/class/drm/card0/device/power_dpm_force_performance_level ]; then
            echo performance > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
          fi
          
          # Log that AI optimizations are active
          echo "AI performance optimizations applied" | systemd-cat -t ai-performance-tuning
        '';
        RemainAfterExit = true;
      };
    };
    
    # Create nixai configuration directory and file
    environment.etc."nixai/nixai-config.yaml" = mkIf config.custom.ai-services.nixai.enable {
      source = ../packages/nixai-config.yaml;
      mode = "0644";
    };
    
    # Create symlink for easier access
    environment.etc."nixai-config.yaml" = mkIf config.custom.ai-services.nixai.enable {
      source = config.custom.ai-services.nixai.configPath;
    };
  };
}
