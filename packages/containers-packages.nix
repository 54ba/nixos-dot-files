{ pkgs, config ? {}, lib ? pkgs.lib }:

with pkgs; 
let
  # Use optionals with lib if available, otherwise provide a fallback
  optionals = if lib ? optionals then lib.optionals else (cond: list: if cond then list else []);
  # Check config for container options, default to false
  podmanEnabled = if config ? custom && config.custom ? containers && config.custom.containers ? podman then config.custom.containers.podman.enable else false;
  dockerEnabled = if config ? custom && config.custom ? containers && config.custom.containers ? docker then config.custom.containers.docker.enable else false;
in
  (optionals podmanEnabled [
    podman-compose  # Docker-compose equivalent for Podman
    podman-tui     # Terminal UI for Podman
  ]) ++
  (optionals dockerEnabled [
    docker-compose  # Docker compose
  ])
