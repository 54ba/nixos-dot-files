{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.migrationAssistant = {
      enable = mkEnableOption "migration assistant";

      features = {
        backup = mkEnableOption "backup functionality";
        restore = mkEnableOption "restore functionality";
        validation = mkEnableOption "configuration validation";
        rollback = mkEnableOption "rollback functionality";
      };

      tools = {
        enable = mkEnableOption "migration tools";
        scripts = mkEnableOption "migration scripts";
        gui = mkEnableOption "migration GUI";
      };
    };
  };

  config = mkIf config.custom.migrationAssistant.enable {
    # Install migration tools
    environment.systemPackages = with pkgs; mkIf config.custom.migrationAssistant.tools.enable [
      # Backup and restore tools
      (mkIf config.custom.migrationAssistant.features.backup pkgs.rsync)
      (mkIf config.custom.migrationAssistant.features.backup pkgs.gnutar)
      (mkIf config.custom.migrationAssistant.features.backup pkgs.gzip)

      # System tools
      (mkIf config.custom.migrationAssistant.features.validation pkgs.nixos-option)
      (mkIf config.custom.migrationAssistant.features.rollback pkgs.nixos-rebuild)
    ];

    # Create migration scripts directory
    system.activationScripts.migration = mkIf config.custom.migrationAssistant.enable ''
      mkdir -p /etc/nixos/scripts/migration
      chmod 755 /etc/nixos/scripts/migration
    '';

    # Environment variables for migration
    environment.variables = mkIf config.custom.migrationAssistant.enable {
      MIGRATION_ENABLE = "1";
      MIGRATION_SCRIPTS_PATH = "/etc/nixos/scripts/migration";
    };
  };
}
