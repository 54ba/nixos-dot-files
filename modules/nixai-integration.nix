{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.nixaiIntegration = {
      enable = mkEnableOption "nixai integration";

      features = {
        cli = mkEnableOption "nixai CLI tools";
        gui = mkEnableOption "nixai GUI applications";
        development = mkEnableOption "nixai development tools";
        ai = mkEnableOption "nixai AI capabilities";
      };

      packages = {
        enable = mkEnableOption "nixai packages";
        core = mkEnableOption "core nixai packages";
        extras = mkEnableOption "extra nixai packages";
      };
    };
  };

  config = mkIf config.custom.nixaiIntegration.enable {
        # Install nixai packages
    environment.systemPackages = with pkgs; mkIf config.custom.nixaiIntegration.packages.enable [
      # Additional AI and development tools
      (mkIf config.custom.nixaiIntegration.features.ai pkgs.python3Packages.openai)
      (mkIf config.custom.nixaiIntegration.features.ai pkgs.python3Packages.anthropic)
      (mkIf config.custom.nixaiIntegration.features.development pkgs.python3Packages.jupyter)
    ];

    # Environment variables for nixai
    environment.variables = mkIf config.custom.nixaiIntegration.enable {
      NIXAI_ENABLE = "1";
      NIXAI_CONFIG_PATH = "/etc/nixos/packages/nixai-config.yaml";
    };
  };
}
