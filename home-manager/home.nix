{ config, lib, pkgs, ... }:
{
  imports = [
    ./zsh.nix
  ];

  home = {
    username = "mahmoud";
    homeDirectory = "/home/mahmoud";
    stateVersion = "25.05";

    packages = [ ];  # We will add packages later
  };

  programs = {
    home-manager.enable = true;
    direnv.enable = true;
    starship.enable = true;

    git = {
      enable = true;
      delta.enable = true;
    };
  };
}
