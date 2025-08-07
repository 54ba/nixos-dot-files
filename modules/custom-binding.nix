{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.binding;
in
{
  options.custom.binding = {
    enable = mkEnableOption "custom SSD2 bind mounts";

    ssd2Path = mkOption {
      type = types.str;
      default = "/mnt/ssd2";
      description = "Path to the SSD2 mount point";
    };

    tmp = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable /tmp bind mount to SSD2";
      };

      path = mkOption {
        type = types.str;
        default = "tmp";
        description = "Subdirectory on SSD2 for tmp bind mount";
      };

      options = mkOption {
        type = types.listOf types.str;
        default = [ "bind" "noatime" ];
        description = "Mount options for /tmp bind mount";
      };
    };

    var = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable /var bind mount to SSD2";
      };

      path = mkOption {
        type = types.str;
        default = "var";
        description = "Subdirectory on SSD2 for var bind mount";
      };

      options = mkOption {
        type = types.listOf types.str;
        default = [ "bind" ];
        description = "Mount options for /var bind mount";
      };
    };

    createDirectories = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically create required directories on SSD2";
    };
  };

  config = mkIf cfg.enable {
    # Configure filesystem bind mounts
    fileSystems = mkMerge [
      # /tmp bind mount to SSD2
      (mkIf cfg.tmp.enable {
        "/tmp" = {
          device = "${cfg.ssd2Path}/${cfg.tmp.path}";
          fsType = "none";
          options = cfg.tmp.options;
        };
      })

      # /var bind mount to SSD2  
      (mkIf cfg.var.enable {
        "/var" = {
          device = "${cfg.ssd2Path}/${cfg.var.path}";
          fsType = "none";
          options = cfg.var.options;
        };
      })
    ];

    # Activation scripts for setup and debugging
    system.activationScripts = {
      # Create required directories on SSD2 if enabled
      customBindingSetup = mkIf cfg.createDirectories ''
        # Create directories on SSD2 for bind mounts
        ${optionalString cfg.tmp.enable ''
          mkdir -p ${cfg.ssd2Path}/${cfg.tmp.path}
        ''}
        ${optionalString cfg.var.enable ''
          mkdir -p ${cfg.ssd2Path}/${cfg.var.path}
        ''}
        # Note: /home directory creation handled by hardware configuration
      '';
      
      # Log configuration for debugging
      customBindingDebug = ''
        echo "Custom Binding Module Configuration:"
        echo "  SSD2 Path: ${cfg.ssd2Path}"
        ${optionalString cfg.tmp.enable ''
          echo "  /tmp -> ${cfg.ssd2Path}/${cfg.tmp.path} (options: ${concatStringsSep "," cfg.tmp.options})"
        ''}
        ${optionalString cfg.var.enable ''
          echo "  /var -> ${cfg.ssd2Path}/${cfg.var.path} (options: ${concatStringsSep "," cfg.var.options})"
        ''}
        echo "  /home -> /mnt/ssd2/home (configured in hardware-configuration.nix)"
      '';
    };
  };
}
