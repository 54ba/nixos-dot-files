# Docker Configuration Fix
# Add this to your configuration.nix or update your containers module

{ config, pkgs, lib, ... }:

{
  # Option 1: Quick Fix - Use NixOS native Docker configuration
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    
    # Use iptables-legacy to avoid conflicts
    daemon.settings = {
      # Basic daemon settings
      log-driver = "json-file";
      log-opts = {
        max-size = "10m";
        max-file = "3";
      };
      
      # Storage driver (overlay2 is recommended)
      storage-driver = "overlay2";
      
      # Use iptables-legacy if having networking issues
      iptables = true;
      
      # IPv6 support (disable if not needed)
      ipv6 = false;
      
      # Default bridge network
      bridge = "docker0";
      
      # DNS settings (use system DNS)
      dns = [ "8.8.8.8" "8.8.4.4" ];
    };
    
    # Auto-prune old containers and images
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };
    
    # Root directory for Docker (change if using SSD2)
    # storageDriver = "overlay2";  # Deprecated, use daemon.settings instead
  };
  
  # Option 2: If you want Docker data on SSD2
  # Uncomment and configure this section
  /*
  systemd.services.docker = {
    serviceConfig = {
      ExecStart = lib.mkForce [
        ""  # Clear default
        "${pkgs.docker}/bin/dockerd --config-file=/etc/docker/daemon.json --data-root=/mnt/ssd2/docker"
      ];
    };
  };
  */
  
  # Ensure required kernel modules are loaded
  boot.kernelModules = [ "overlay" "br_netfilter" ];
  
  # Kernel parameters for Docker networking
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;
  };
  
  # Fix iptables backend (Docker prefers legacy)
  networking.nftables.enable = false;  # Use iptables-legacy
  
  # Ensure user is in docker group
  users.users.mahmoud.extraGroups = [ "docker" ];
  
  # Fix potential conflicts with your containers module
  # Make sure your custom.containers module doesn't conflict
  custom.containers = {
    enable = true;
    podman.enable = false;
    docker.enable = lib.mkForce false;  # Let virtualisation.docker handle it
    dockerCompat = false;
  };
  
  # Create Docker data directory on SSD2 if needed
  systemd.tmpfiles.rules = [
    "d /var/lib/docker 0710 root root -"
    # Uncomment if using SSD2:
    # "d /mnt/ssd2/docker 0710 root root -"
  ];
  
  # Optional: Docker Compose
  environment.systemPackages = with pkgs; [
    docker
    docker-compose
    docker-buildx
  ];
}
