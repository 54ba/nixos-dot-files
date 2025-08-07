{ pkgs, config ? {}, lib ? pkgs.lib }:

with pkgs; 
let
  # Use optionals with lib if available, otherwise provide a fallback
  optionals = if lib ? optionals then lib.optionals else (cond: list: if cond then list else []);
  # Check if config has the firewall option, default to false
  firewallEnabled = if config ? custom && config.custom ? networking && config.custom.networking ? firewall then config.custom.networking.firewall.enable else false;
in
[
  # Network utilities
  wget
  curl
  networkmanager
  networkmanagerapplet
  
  # Network monitoring and analysis
  nmap
  netcat-gnu
  socat
  
  # DNS utilities
  dig
  host
  
  # Wireless utilities (if applicable)
  iw
  wirelesstools
  
  # VPN support
  openvpn
  wireguard-tools
] ++ (optionals firewallEnabled [
  # Firewall management tools
  iptables
  ipset
])
