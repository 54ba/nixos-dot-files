{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.boot = {
      enhancements.enable = mkEnableOption "boot enhancements including Plymouth splash";
      plymouth = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Plymouth boot splash";
        };
        theme = mkOption {
          type = types.str;
          default = "breeze";
          description = "Plymouth theme to use";
        };
      };
      quietBoot.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable quiet boot with minimal console output";
      };
    };
  };

  config = mkIf config.custom.boot.enhancements.enable {
    # Boot splash and kernel parameters for eye candy
    boot.initrd.systemd.enable = true;
    
    boot.plymouth = mkIf config.custom.boot.plymouth.enable {
      enable = true;
      theme = config.custom.boot.plymouth.theme;
    };
    
    # Kernel parameters moved to configuration.nix to prevent conflicts
    # All kernel parameters are now centrally managed to avoid duplicates
    
    # Console settings - fix console setup issues
    boot.consoleLogLevel = mkIf config.custom.boot.quietBoot.enable 0;
    
    # Add Plymouth packages if enabled
    environment.systemPackages = with pkgs; mkIf config.custom.boot.plymouth.enable [
      plymouth
    ];
  };
}
