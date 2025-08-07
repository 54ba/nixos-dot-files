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
    
    # Kernel parameters for better boot experience
    boot.kernelParams = mkIf config.custom.boot.quietBoot.enable [
      "quiet"          # Less verbose boot
      "splash"         # Show splash screen
      "rd.udev.log_level=3"  # Reduce udev log noise
      "vt.global_cursor_default=0"  # Hide cursor during boot
    ];
    
    # Console settings - fix console setup issues
    boot.consoleLogLevel = mkIf config.custom.boot.quietBoot.enable 0;
    
    # Add Plymouth packages if enabled
    environment.systemPackages = with pkgs; mkIf config.custom.boot.plymouth.enable [
      plymouth
    ];
  };
}
