{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.dev-libs-test;
in
{
  options.custom.dev-libs-test = {
    enable = mkEnableOption "test development libraries";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      glibc.dev
      gcc-unwrapped.lib
      libstdcxx5
      pkg-config
    ];
  };
}