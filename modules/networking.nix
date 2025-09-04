{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.networking = {
      enable = mkEnableOption "enhanced networking configuration";

      hostName = mkOption {
        type = types.str;
        default = "nixos-laptop";
        description = "System hostname";
      };

      networkManager.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable NetworkManager for network management";
      };

      firewall = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable enhanced firewall configuration";
        };

        allowedTCPPorts = mkOption {
          type = types.listOf types.int;
          default = [ 22 80 443 ];
          description = "TCP ports to allow through firewall";
        };

        allowedUDPPorts = mkOption {
          type = types.listOf types.int;
          default = [ 53 123 68 ];
          description = "UDP ports to allow through firewall";
        };

        extraRules.enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable extra iptables rules for enhanced security";
        };
      };

      timeZone = mkOption {
        type = types.str;
        default = "UTC";
        description = "System timezone";
      };

      locale = mkOption {
        type = types.str;
        default = "en_US.UTF-8";
        description = "System locale";
      };

      # Network interfaces configuration
      interfaces = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            macAddress = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "MAC address for the interface. Use 'random' for randomization";
            };
          };
        });
        default = {};
        description = "Network interfaces configuration";
      };

      # SMB/Samba sharing options
      # WiFi and wireless connectivity options
      wifi = {
        enable = mkEnableOption "Enhanced WiFi connectivity tools";
        
        commandLineTools = mkOption {
          type = types.bool;
          default = true;
          description = "Install command-line WiFi management tools";
        };
        
        advancedTools = mkOption {
          type = types.bool;
          default = true;
          description = "Install advanced wireless analysis tools";
        };
      };

      samba = {
        enable = mkEnableOption "Samba/SMB file sharing";

        shares = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              path = mkOption {
                type = types.str;
                description = "Path to the directory to share";
              };
              browseable = mkOption {
                type = types.bool;
                default = true;
                description = "Whether the share is browseable";
              };
              writeable = mkOption {
                type = types.bool;
                default = true;
                description = "Whether the share is writeable";
              };
              readOnly = mkOption {
                type = types.bool;
                default = false;
                description = "Whether the share is read-only";
              };
              guestOk = mkOption {
                type = types.bool;
                default = true;
                description = "Allow guest access";
              };
              createMask = mkOption {
                type = types.str;
                default = "0664";
                description = "File creation mask";
              };
              directoryMask = mkOption {
                type = types.str;
                default = "0775";
                description = "Directory creation mask";
              };
              forceUser = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Force all file operations as this user";
              };
              forceGroup = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Force all file operations as this group";
              };
            };
          });
          default = {};
          description = "Samba shares configuration";
        };
      };
    };
  };

  config = mkIf config.custom.networking.enable {
    # Set hostname
    networking.hostName = config.custom.networking.hostName;

    # Enable network manager for GUI network management
    networking.networkmanager.enable = mkIf config.custom.networking.networkManager.enable true;

    # Disable iwd to avoid conflicts with NetworkManager
    networking.wireless.iwd.enable = lib.mkForce false;

    # Enhanced firewall configuration with iptables
    networking.firewall = mkIf config.custom.networking.firewall.enable {
      enable = true;
      # Allow essential services
      allowedTCPPorts = config.custom.networking.firewall.allowedTCPPorts ++
        (optionals config.custom.networking.samba.enable [ 139 445 ]);
      allowedUDPPorts = config.custom.networking.firewall.allowedUDPPorts ++
        (optionals config.custom.networking.samba.enable [ 137 138 ]);
      # Allow local network communication
      trustedInterfaces = [ "lo" ];
      # Log dropped packets
      logRefusedConnections = true;
      logRefusedPackets = true;
      # Additional firewall rules
      extraCommands = mkIf config.custom.networking.firewall.extraRules.enable ''
        # Allow local network communication
        iptables -A INPUT -s 192.168.0.0/16 -j ACCEPT
        iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT
        iptables -A INPUT -s 172.16.0.0/12 -j ACCEPT

        # Allow mDNS for service discovery
        iptables -A INPUT -p udp --dport 5353 -j ACCEPT

        # Allow KDE Connect if needed (comment out if not used)
        # iptables -A INPUT -p tcp --dport 1714:1764 -j ACCEPT
        # iptables -A INPUT -p udp --dport 1714:1764 -j ACCEPT

        # Rate limiting for SSH to prevent brute force
        iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH
        iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 --rttl --name SSH -j DROP
      '';
      extraStopCommands = mkIf config.custom.networking.firewall.extraRules.enable ''
        iptables -D INPUT -s 192.168.0.0/16 -j ACCEPT 2>/dev/null || true
        iptables -D INPUT -s 10.0.0.0/8 -j ACCEPT 2>/dev/null || true
        iptables -D INPUT -s 172.16.0.0/12 -j ACCEPT 2>/dev/null || true
      '';
    };

    # Samba configuration
    services.samba = mkIf config.custom.networking.samba.enable {
      enable = true;
      package = pkgs.samba4Full;
      openFirewall = true;

      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "NixOS Samba Server";
          "netbios name" = config.custom.networking.hostName;
          "security" = "user";
          "map to guest" = "bad user";
          "guest account" = "nobody";
          "dns proxy" = "no";
          "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=524288 SO_SNDBUF=524288";
          "max log size" = "50";
          "log level" = "1";
          "load printers" = "no";
          "printing" = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";
          "show add printer wizard" = "no";
          "create mask" = "0666";
          "directory mask" = "0777";
        };
      } // (mapAttrs (name: cfg:
        {
          "path" = cfg.path;
          "browseable" = if cfg.browseable then "yes" else "no";
          "writable" = if cfg.writeable then "yes" else "no";
          "read only" = if cfg.readOnly then "yes" else "no";
          "guest ok" = if cfg.guestOk then "yes" else "no";
          "create mask" = cfg.createMask;
          "directory mask" = cfg.directoryMask;
        } // (optionalAttrs (cfg.forceUser != null) {
          "force user" = cfg.forceUser;
        }) // (optionalAttrs (cfg.forceGroup != null) {
          "force group" = cfg.forceGroup;
        })
      ) config.custom.networking.samba.shares);
    };

    # Enable NetBIOS name resolution
    services.samba-wsdd = mkIf config.custom.networking.samba.enable {
      enable = true;
      openFirewall = true;
    };

    # Localization (handled by system-base.nix)

    # Hardware acceleration for graphics (handled by hardware.nix)

    # Networking packages
    environment.systemPackages = import ../packages/networking-packages.nix { inherit pkgs config lib; } ++
      (optionals config.custom.networking.samba.enable [ pkgs.cifs-utils ]);

    # Network-related systemd services
    systemd.services = {
      # Fix NetworkManager wait online timeout
      NetworkManager-wait-online.enable = false;
    };

    # Additional network configuration
    networking = {
      # Enable IPv6
      enableIPv6 = true;

      # DNS configuration
      nameservers = [ "1.1.1.1" "8.8.8.8" "8.8.4.4" ];

      # Disable automatic DHCP assignment (NetworkManager handles this)
      useDHCP = false;

      # Enable network interface hotplug
      interfaces = {};
    };

    # Additional network security settings
    boot.kernel.sysctl = {
      # Network security enhancements
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.conf.all.log_martians" = 1;
      "net.ipv4.conf.default.log_martians" = 1;
    };
  };
}
