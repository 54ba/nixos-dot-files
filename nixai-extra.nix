{ config, lib, ... }:
{
  services.nixai = lib.mkIf config.services.nixai.enable {
    # only override/extend, don't re-declare enable
    mcp.aiProvider = "claude";
    mcp.aiModel = "claude-3-5-sonnet-20241022";
    mcp.documentationSources = [
      "https://wiki.nixos.org/wiki/NixOS_Wiki"
      "https://nix.dev/manual/nix"
      "https://nixos.org/manual/nixpkgs/stable/"
      "https://nix.dev/manual/nix/2.28/language/"
      "https://nix-community.github.io/home-manager/"
      "https://github.com/NixOS/nixpkgs/tree/master/doc"
      "https://nixos.org/manual/nix/stable/"
    ];
    mcp.extraFlags = [ "--log-level=info" "--enable-debug" ];
    mcp.environment = {
      NIXAI_LOG_LEVEL = "info";
      NIXAI_DEBUG = "true";
    };
  };
}

