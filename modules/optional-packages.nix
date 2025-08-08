{ config, pkgs, lib, ... }:

with lib;

{
  imports = [
    ./pentest.nix
    ./security-services.nix
    ./virtualization.nix
    ./containers.nix
    ./boot-enhancements.nix
    ./system-services.nix
    ./user-security.nix
  ];

  options = {
    custom.packages = {
      # Minimal packages option - truly minimal system
      minimal.enable = mkEnableOption "minimal packages for basic system function only";
      
      # Essential packages option
      essential.enable = mkEnableOption "essential packages including development tools and system utilities";
      
      # Existing package options
      media.enable = mkEnableOption "media and graphics packages";
      development.enable = mkEnableOption "development packages";
      productivity.enable = mkEnableOption "productivity packages";
      gaming.enable = mkEnableOption "gaming packages";
      entertainment.enable = mkEnableOption "entertainment packages";
      popular.enable = mkEnableOption "popular packages collection";
      
      # Pentest packages option
      pentest.enable = mkEnableOption "penetration testing and security tools";
    };
  };

  config = {
    environment.systemPackages = 
      (optionals config.custom.packages.minimal.enable (import ../packages/minimal-packages.nix { inherit pkgs; })) ++
      (optionals config.custom.packages.essential.enable (import ../packages/essential-packages.nix { inherit pkgs; })) ++
      (optionals config.custom.packages.media.enable (import ../packages/media-packages.nix { inherit pkgs; })) ++
      (optionals config.custom.packages.development.enable (import ../packages/dev-packages.nix { inherit pkgs; })) ++
      (optionals config.custom.packages.productivity.enable (import ../packages/productivity-packages.nix { inherit pkgs; })) ++
      (optionals config.custom.packages.gaming.enable (import ../packages/gaming-packages.nix { inherit pkgs; })) ++
      (optionals config.custom.packages.entertainment.enable (import ../packages/entertainment-packages.nix { inherit pkgs; })) ++
      (optionals config.custom.packages.popular.enable (import ../packages/popular-packages.nix { inherit pkgs; })) ++
      (optionals config.custom.packages.pentest.enable (import ../packages/pentest-packages.nix { inherit pkgs; }));
  };
}

