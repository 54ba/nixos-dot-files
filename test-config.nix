{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/boot.nix
    ./modules/lenovo-s540-gtx-15iwl.nix
  ];

  # Basic system configuration
  system.stateVersion = "25.05";

  # Enable custom modules
  custom = {
    boot.enable = true;
    lenovoS540Gtx15iwl.enable = true;
  };

  # Network configuration
  networking.hostName = "mahmoud-laptop";
  
  # Users configuration (minimum required)
  users.users.root = {
    isNormalUser = false;
  };

  # Basic system packages
  environment.systemPackages = with pkgs; [
    vim
  ];
}
