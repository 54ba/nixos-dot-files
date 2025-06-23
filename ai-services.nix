{ config, lib, pkgs, ... }: {
  # Ollama Configuration with GPU Acceleration
  services.ollama = {
    enable = true;
    acceleration = lib.mkForce "cuda";
  };

  # NVIDIA Configuration for AI Workloads
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    nvidiaSettings = true;
  };
}
