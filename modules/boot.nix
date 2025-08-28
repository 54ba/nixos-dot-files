{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.boot = {
      enable = mkEnableOption "custom boot configuration" // { default = true; };
      grub = {
        theme = mkOption {
          type = types.str;
          default = "dark";
          description = "GRUB theme (dark/light)";
        };
        generations = mkOption {
          type = types.int;
          default = 10;
          description = "Number of generations to keep";
        };
      };
    };
  };

  config = mkIf config.custom.boot.enable {
    # Boot loader configuration for GRUB
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
        configurationLimit = config.custom.boot.grub.generations;
      };
      # Global timeout setting
      timeout = 10;
    };
    
    # Basic boot configuration  
    boot.initrd.systemd.enable = true;
    
    # Console settings
    boot.consoleLogLevel = 0;
    
    # Console font configuration
    console = {
      font = "${pkgs.terminus_font}/share/consolefonts/ter-v16n.psf.gz";
      keyMap = "us";
      useXkbConfig = false;  # Use console keyMap
    };
    
    # System packages needed for boot
    environment.systemPackages = import ../packages/boot-packages.nix { inherit pkgs; };

    # XDG Portal configuration
    xdg.portal = {
      enable = true;
      config.common.default = "*";
    };
  };
}
