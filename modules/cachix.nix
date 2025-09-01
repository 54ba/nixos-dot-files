{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.cachix = {
      enable = mkEnableOption "Cachix binary cache management";
      
      caches = mkOption {
        type = types.listOf types.str;
        default = [
          "nix-community"
          "devenv"
          "nixpkgs-unfree"
          "cuda-maintainers"
          "hyprland"
        ];
        description = "List of Cachix caches to enable";
      };
      
      installCachix = mkOption {
        type = types.bool;
        default = true;
        description = "Install cachix command-line tool";
      };
      
      trustedUsers = mkOption {
        type = types.listOf types.str;
        default = [ "root" "@wheel" ];
        description = "Users allowed to use cachix";
      };
    };
  };

  config = mkIf config.custom.cachix.enable {
    # Install cachix for binary cache management
    environment.systemPackages = mkIf config.custom.cachix.installCachix [
      pkgs.cachix
    ];

    # Configure binary caches with proper fallbacks
    nix.settings = {
      # Core binary caches with fallbacks
      substituters = [
        "https://cache.nixos.org/"
      ] ++ (map (cache: "https://${cache}.cachix.org/") config.custom.cachix.caches) ++ [
        # Add fallback caches
        "https://nix-serve.cachix.org/"
        "https://pre-commit-hooks.cachix.org/"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPiCgBV8vQQGjqozR5lnLBcBJKqKzR6bE="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3rkCI6Vd0HQRSIo3VbK+LSnRVQCQ="
        "nix-serve.cachix.org-1:R7dU6qhepE4TRoWNAiNcAXqmIl8Ua2e8fTZpSLo0B5Q="
        "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
      ];

      # Optimize cache usage
      builders-use-substitutes = true;
      substitute = true;
      max-substitution-jobs = 8;
      connect-timeout = 30;
      stalled-download-timeout = 300;
      
      # Trust users for cachix operations
      trusted-users = config.custom.cachix.trustedUsers;
    };

    # System service to automatically use cachix for builds
    systemd.services.cachix-watch-store = mkIf config.custom.cachix.installCachix {
      description = "Cachix binary cache optimization";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "cachix-optimize" ''
          #!/bin/bash
          # Optimize nix store for binary cache usage
          ${pkgs.nix}/bin/nix-store --optimise 2>/dev/null || true
          
          # Clean up old cache entries
          ${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 3d 2>/dev/null || true
        '';
        RemainAfterExit = true;
      };
    };

    # Environment variables for cachix
    environment.sessionVariables = mkIf config.custom.cachix.installCachix {
      CACHIX_AUTH_TOKEN = mkDefault ""; # Users should set this if they have a token
    };
  };
}
