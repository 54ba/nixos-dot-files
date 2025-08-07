{ pkgs }:

with pkgs; [
  # Core system packages that should always be available
  # These are essential packages loaded from essential-packages.nix
] ++ (import ./essential-packages.nix { inherit pkgs; })
