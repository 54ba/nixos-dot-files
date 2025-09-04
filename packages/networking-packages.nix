{ pkgs, config ? {}, lib ? pkgs.lib }:

with pkgs; 
let
  # Use optionals with lib if available, otherwise provide a fallback
  optionals = if lib ? optionals then lib.optionals else (cond: list: if cond then list else []);
  # Check if config has the firewall option, default to false
  firewallEnabled = if config ? custom && config.custom ? networking && config.custom.networking ? firewall then config.custom.networking.firewall.enable else false;
  # Check if WiFi tools are enabled
  wifiEnabled = if config ? custom && config.custom ? networking && config.custom.networking ? wifi then config.custom.networking.wifi.enable else false;
  wifiCommandLine = if config ? custom && config.custom ? networking && config.custom.networking ? wifi then config.custom.networking.wifi.commandLineTools else true;
  wifiAdvanced = if config ? custom && config.custom ? networking && config.custom.networking ? wifi then config.custom.networking.wifi.advancedTools else true;
in
[
  # Core Network utilities
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
  whois
  
  # Basic networking tools
  iputils  # includes ping
  traceroute
  mtr  # Better traceroute
  iperf3  # Network performance testing
  speedtest-cli
  
  # Network interface tools
  ethtool
  bridge-utils
  iproute2
  
  # VPN support
  openvpn
  wireguard-tools
  
  # Remote access
  openssh
  rsync
] ++ (optionals wifiEnabled [
  # Core WiFi utilities
  iw
  wirelesstools
  wpa_supplicant
  wpa_supplicant_gui
]) ++ (optionals (wifiEnabled && wifiCommandLine) [
  # Command-line WiFi management tools
  # iwgtk  # Lightweight wireless networking for iwd (not available in nixpkgs)
  # nmtui and nmcli come with networkmanager
  wavemon  # Wireless network monitor
  # horst   # Lightweight IEEE 802.11 wireless LAN analyzer (not available)
]) ++ (optionals (wifiEnabled && wifiAdvanced) [
  # Advanced wireless analysis tools
  aircrack-ng  # WiFi security testing suite
  kismet       # Wireless network detector
  wireshark    # Network protocol analyzer
  tcpdump      # Network packet analyzer
  # reaver       # WPS security testing (if needed)
  # hashcat      # Password recovery (if needed)
]) ++ (optionals firewallEnabled [
  # Firewall management tools
  iptables
  ipset
  # ufw  # Uncomplicated Firewall (not available in nixpkgs)
])
