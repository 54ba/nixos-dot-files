{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.containers = {
      enable = mkEnableOption "container services";
      podman.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Podman container runtime";
      };
      docker.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Docker container runtime (conflicts with Podman)";
      };
      dockerCompat = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Docker compatibility layer for Podman";
      };
    };
  };

  config = mkIf config.custom.containers.enable {
    # Enable container support - prefer Podman over Docker for better binary cache usage
    virtualisation.docker = mkIf config.custom.containers.docker.enable {
      enable = true;
      enableOnBoot = true;
      autoPrune.enable = true;
      daemon = {
        settings = {
          log-driver = "journald";
          storage-driver = "overlay2";
        };
      };
    };
    
    virtualisation.podman = mkIf config.custom.containers.podman.enable {
      enable = true;
      # Docker compatibility layer
      dockerCompat = config.custom.containers.dockerCompat;
      dockerSocket.enable = config.custom.containers.dockerCompat;
      # Required for containers under podman
      defaultNetwork.settings.dns_enabled = true;
      # Auto-update containers
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    # Container tools and utilities
    environment.systemPackages = import ../packages/containers-packages.nix { inherit pkgs config lib; };

    # Shell aliases for docker -> podman compatibility
    environment.shellAliases = mkIf (config.custom.containers.podman.enable && config.custom.containers.dockerCompat) {
      docker = "podman";
      docker-compose = "podman-compose";
    };

    # Ensure user groups exist
    users.groups = {
      docker = mkIf config.custom.containers.docker.enable {};
      podman = mkIf config.custom.containers.podman.enable {};
    };

    # Add users to container groups (this should be done in main config)
    # users.users.mahmoud.extraGroups will need to include these groups
  };
}
