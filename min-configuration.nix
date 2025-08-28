{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
    };
  };

  # Basic system configuration
  system.stateVersion = "25.05";

  # Network configuration
  networking.hostName = "mahmoud-laptop";

  # Users
  users.users.root = {
    isNormalUser = false;
  };

  # Essential services
  services.sshd.enable = true;
}
