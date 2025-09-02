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
        timeout = mkOption {
          type = types.int;
          default = 5;
          description = "GRUB timeout in seconds";
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
        # Add memtest option to GRUB
        memtest86.enable = true;
        # Simple theme configuration without external packages
        backgroundColor = mkIf (config.custom.boot.grub.theme == "dark") "#2E3440";
        splashImage = mkIf (builtins.pathExists /boot/background.png) /boot/background.png;
      };
      timeout = config.custom.boot.grub.timeout;
    };
    
    # Boot configuration
    boot = {
      # Enable systemd in initrd
      initrd.systemd.enable = true;
      
      # Console configuration
      consoleLogLevel = 0;
      kernelParams = [
        "quiet"
        "rd.udev.log_level=3"
      ];
    };
    
    # Console settings
    console = {
      font = "${pkgs.terminus_font}/share/consolefonts/ter-v16n.psf.gz";
      keyMap = "us";
      useXkbConfig = false;
    };

    # Early boot messages (updated deprecated option)
    console.earlySetup = true;

    # System packages needed for boot
    environment.systemPackages = with pkgs; [
      terminus_font
      efibootmgr
      os-prober
    ];
  };
}
