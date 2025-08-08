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
    # Ollama Configuration with GPU Acceleration
    services.ollama = mkIf config.custom.ai-services.ollama.enable {
      enable = true;
      acceleration = mkForce config.custom.ai-services.ollama.acceleration;
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

    # AI Development packages
    environment.systemPackages = mkIf (config.custom.ai-services.enable && config.custom.ai-services.packages.enable) (with pkgs; [
      # Python AI/ML ecosystem
      python311
      python311Packages.pip
      python311Packages.virtualenv
      python311Packages.numpy
      python311Packages.pandas
      python311Packages.scikit-learn
      python311Packages.matplotlib
      python311Packages.jupyter
    ]);

    # Environment variables for AI development
    environment.sessionVariables = mkIf (config.custom.ai-services.enable && config.custom.ai-services.packages.enable) {
      CUDA_PATH = "${pkgs.cudatoolkit}";
      CUDA_HOME = "${pkgs.cudatoolkit}";
      LD_LIBRARY_PATH = "${pkgs.cudatoolkit}/lib:$LD_LIBRARY_PATH";
    };

    # System optimization for AI workloads
    systemd.services.ai-performance-tuning = mkIf config.custom.ai-services.enable {
      description = "Optimize system for AI workloads";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "ai-performance-tuning" ''
          #!/bin/bash
          # Set GPU performance mode
          echo performance > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
          
          # Increase shared memory for AI workloads
          echo 'kernel.shmmax = 68719476736' >> /etc/sysctl.conf 2>/dev/null || true
          echo 'kernel.shmall = 4294967296' >> /etc/sysctl.conf 2>/dev/null || true
        '';
        RemainAfterExit = true;
      };
    };
  }
  
  # nixai configuration
  // (mkIf config.custom.ai-services.nixai.enable {
    # Install nixai packages
    environment.systemPackages = with pkgs; [
      # AI and machine learning tools
      jq
      yq-go
      curl
      wget
      
      # Additional AI tools that may be useful with nixai
      python311Packages.openai
      python311Packages.requests
    ];
    
    # Create nixai configuration directory and file
    environment.etc."nixai/nixai-config.yaml" = {
      source = ../packages/nixai-config.yaml;
      mode = "0644";
    };
    
    # Create symlink for easier access
    environment.etc."nixai-config.yaml" = {
      source = config.custom.ai-services.nixai.configPath;
    };
  });
}
