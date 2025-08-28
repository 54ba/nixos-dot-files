{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.lenovoS540Gtx15iwl;
in {
  options.custom.lenovoS540Gtx15iwl = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Lenovo S540 GTX 15IWL specific optimizations";
    };

    performance = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable performance optimizations";
      };

      cpuGovernor = mkOption {
        type = types.enum [ "performance" "powersave" "ondemand" "conservative" "schedutil" ];
        default = "performance";
        description = "CPU frequency governor for maximum performance";
      };

      thermalManagement = mkOption {
        type = types.bool;
        default = true;
        description = "Enable advanced thermal management";
      };

      powerManagement = mkOption {
        type = types.bool;
        default = true;
        description = "Enable power management optimizations";
      };
    };
  };

  config = mkIf cfg.enable {
    # ThinkFan configuration
    services.thinkfan = mkIf cfg.performance.thermalManagement {
      enable = true;
      sensors = [{
        type = "hwmon";
        query = "/sys/class/hwmon";
        indices = [ 1 ];  # Using integer instead of string
      }];
      fans = [{
        type = "tpacpi";
        query = "/proc/acpi/ibm/fan";
      }];
      levels = [
        [ 0    0  42 ]
        [ 1   40  47 ]
        [ 2   45  52 ]
        [ 3   50  57 ]
        [ 4   55  62 ]
        [ 5   60  67 ]
        [ 7   65  72 ]
        [ 127 70  32767 ]
      ];
    };

    # Required packages for thermal management
    environment.systemPackages = with pkgs; [
      lm_sensors
      thinkfan
    ];

    # Kernel modules for thermal management
    boot.kernelModules = [ "coretemp" "thinkpad_acpi" ];
    boot.extraModprobeConfig = ''
      options thinkpad_acpi fan_control=1
    '';

    # Enable thermal services
    services.thermald.enable = mkIf cfg.performance.thermalManagement true;
  };
}
