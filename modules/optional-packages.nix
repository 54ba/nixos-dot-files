{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.packages = {
      media.enable = mkEnableOption "media and graphics packages";
      development.enable = mkEnableOption "development packages";
      productivity.enable = mkEnableOption "productivity packages";
      gaming.enable = mkEnableOption "gaming packages";
      entertainment.enable = mkEnableOption "entertainment packages";
      popular.enable = mkEnableOption "popular packages collection";
    };
  };

  config = {
    environment.systemPackages = 
      (optionals config.custom.packages.media.enable (import ../packages/media-packages.nix { inherit pkgs; })) ++
      (optionals config.custom.packages.development.enable (import ../packages/dev-packages.nix { inherit pkgs; })) ++
      (optionals config.custom.packages.productivity.enable (import ../packages/productivity-packages.nix { inherit pkgs; })) ++
      (optionals config.custom.packages.gaming.enable (import ../packages/gaming-packages.nix { inherit pkgs; })) ++
      (optionals config.custom.packages.entertainment.enable (import ../packages/entertainment-packages.nix { inherit pkgs; })) ++
      (optionals config.custom.packages.popular.enable (import ../packages/popular-packages.nix { inherit pkgs; }));
  };
}

