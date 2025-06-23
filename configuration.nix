{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./nixGL.nix
    ./modules/core-packages.nix
    ./modules/optional-packages.nix
    ./modules/pentest-packages.nix
    ./ai-services.nix
  ];

  # Boot loader configuration
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    devices = [ "nodev" ];
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable ZSH
  programs.zsh.enable = true;

  # User configuration
  users.users.mahmoud = {
    isNormalUser = true;
    home = "/home/mahmoud";
    description = "mahmoud";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    group = "users";
    shell = pkgs.zsh;
  };

  # System state version
  system.stateVersion = "25.05";
}
