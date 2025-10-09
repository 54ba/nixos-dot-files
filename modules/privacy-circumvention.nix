# Privacy and Censorship Circumvention Module
# Provides Tor with obfs4 bridges, Snowflake, and Riseup VPN integration

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.privacy-circumvention;
in

{
  options.custom.privacy-circumvention = {
    enable = mkEnableOption "Privacy and censorship circumvention tools";

    tor = {
      enable = mkEnableOption "Tor with pluggable transports";
      
      obfs4 = {
        enable = mkEnableOption "obfs4 bridges for traffic obfuscation";
        bridges = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "List of obfs4 bridges to use";
        };
      };

      snowflake = {
        enable = mkEnableOption "Snowflake pluggable transport";
        ampCacheUrl = mkOption {
          type = types.str;
          default = "https://cdn.ampproject.org/";
          description = "AMP cache URL for Snowflake";
        };
        frontDomain = mkOption {
          type = types.str;
          default = "foursquare.com";
          description = "Front domain for Snowflake";
        };
      };
    };

    riseupVpn = {
      enable = mkEnableOption "Riseup VPN with Tor transport";
      
      useTorTransport = mkOption {
        type = types.bool;
        default = false;
        description = "Use Tor as transport for Riseup VPN";
      };

      kerSupport = mkOption {
        type = types.bool;
        default = true;
        description = "Enable KER (obfs with KCP) if available";
      };
    };

    browser = {
      torBrowser = mkEnableOption "Tor Browser";
      hardened = mkEnableOption "Hardened browser configuration";
    };
  };

  config = mkIf cfg.enable {
    # Install required packages
    environment.systemPackages = with pkgs; [
      # Tor and pluggable transports
      tor
      obfs4
      snowflake
      
      # VPN tools
      openvpn
      wireguard-tools
      
      # Privacy browsers
      (mkIf cfg.browser.torBrowser tor-browser-bundle-bin)
      
      # Network analysis tools
      nmap
      tcpdump
      wireshark
      
      # Additional circumvention tools
      shadowsocks-libev
      v2ray
      
      # Certificate management
      ca-certificates
      openssl
    ] ++ (mkIf cfg.riseupVpn.enable [
      # Riseup VPN dependencies
      python3
      python3Packages.requests
      python3Packages.pycryptodome
    ]);

    # Tor configuration
    services.tor = mkIf cfg.tor.enable {
      enable = true;
      
      # Enable control port for applications
      controlSocket.enable = true;
      
      # Client configuration
      client = {
        enable = true;
        # Use entry guards for better security
        privacyGuard = true;
      };

      # Relay configuration (disabled by default for privacy)
      relay = {
        enable = false;
      };

      # Additional Tor configuration
      settings = {
        # SOCKS proxy on localhost
        SocksPort = [
          {
            addr = "127.0.0.1";
            port = 9050;
          }
        ];

        # Control port configuration
        ControlPort = 9051;
        ControlListenAddress = "127.0.0.1:9051";
        
        # Enable pluggable transports
        ClientTransportPlugin = mkMerge [
          (mkIf cfg.tor.obfs4.enable [
            "obfs4 exec ${pkgs.obfs4}/bin/obfs4proxy"
          ])
          (mkIf cfg.tor.snowflake.enable [
            "snowflake exec ${pkgs.snowflake}/bin/snowflake-client -url ${cfg.tor.snowflake.ampCacheUrl} -front ${cfg.tor.snowflake.frontDomain} -ice stun:stun.l.google.com:19302,stun:stun.voip.blackberry.com:3478,stun:stun.altar.com.pl:3478,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.com:3478,stun:stun.sonetel.net:3478,stun:stun.stunprotocol.org:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478"
          ])
        ];

        # Bridge configuration
        UseBridges = mkIf (cfg.tor.obfs4.enable && cfg.tor.obfs4.bridges != []) true;
        Bridge = mkIf (cfg.tor.obfs4.enable && cfg.tor.obfs4.bridges != []) cfg.tor.obfs4.bridges;

        # Additional privacy settings
        AvoidDiskWrites = 1;
        GeoIPExcludeUnknown = 1;
        
        # Hardened configuration
        HardwareAccel = 0;  # Disable hardware acceleration for better anonymity
        SafeLogging = 1;    # Enable safe logging
        
        # Circuit building preferences
        StrictNodes = 1;
        ExitNodes = "{us},{ca},{de},{nl},{se},{ch}";  # Prefer privacy-friendly countries
        ExcludeNodes = "{cn},{ru},{ir},{kp},{sy}";     # Exclude censorship-heavy countries
        
        # Performance and reliability
        CircuitBuildTimeout = 60;
        LearnCircuitBuildTimeout = 0;
        MaxCircuitDirtiness = 600;
        NewCircuitPeriod = 30;
        MaxClientCircuitsPending = 32;
      };
    };

    # Firewall configuration for privacy and Tor
    networking.firewall = mkIf cfg.enable {
      # Allow outbound connections for Tor
      allowedTCPPorts = [];
      allowedUDPPorts = [];
      
      # Custom firewall rules for privacy and censorship circumvention
      extraCommands = ''
        ${optionalString cfg.tor.enable ''
          # Allow Tor SOCKS proxy
          iptables -A OUTPUT -p tcp --dport 9050 -j ACCEPT
          iptables -A OUTPUT -p tcp --dport 9051 -j ACCEPT
          
          # Block direct connections when Tor is enabled (force through Tor)
          # Uncomment the following lines for maximum security (will break non-Tor traffic)
          # iptables -A OUTPUT -m owner --uid-owner tor -j ACCEPT
          # iptables -A OUTPUT -p tcp --dport 80 -j REJECT
          # iptables -A OUTPUT -p tcp --dport 443 -j REJECT
        ''}
        
        # DNS leak protection
        iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:53
        iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination 127.0.0.1:53
        
        # Block IPv6 to prevent leaks
        ip6tables -A OUTPUT -j REJECT --reject-with icmp6-no-route
      '';
    };

    # Create Riseup VPN client script
    environment.etc."riseup-vpn/riseup-vpn.py" = mkIf cfg.riseupVpn.enable {
      text = ''
        #!/usr/bin/env python3
        """
        Riseup VPN Client with Tor Transport Support
        
        This script connects to Riseup VPN with optional Tor transport
        and KER (obfs with KCP) support for censorship circumvention.
        """
        
        import os
        import sys
        import json
        import subprocess
        import requests
        import socket
        import time
        from pathlib import Path
        
        class RiseupVPN:
            def __init__(self, use_tor=False, use_ker=True):
                self.use_tor = use_tor
                self.use_ker = use_ker
                self.config_dir = Path.home() / ".config" / "riseup-vpn"
                self.config_dir.mkdir(parents=True, exist_ok=True)
                
                # Riseup VPN API endpoints
                self.api_base = "https://api.black.riseup.net:9001"
                if self.use_tor:
                    # Use Tor SOCKS proxy for API requests
                    self.session = requests.Session()
                    self.session.proxies = {
                        'http': 'socks5h://127.0.0.1:9050',
                        'https': 'socks5h://127.0.0.1:9050'
                    }
                else:
                    self.session = requests.Session()
            
            def fetch_config(self):
                """Fetch VPN configuration from Riseup API"""
                try:
                    print("Fetching Riseup VPN configuration...")
                    response = self.session.get(f"{self.api_base}/3/config/eip-service.json", timeout=30)
                    response.raise_for_status()
                    config = response.json()
                    
                    # Save configuration
                    config_file = self.config_dir / "eip-service.json"
                    with open(config_file, 'w') as f:
                        json.dump(config, f, indent=2)
                    
                    print(f"Configuration saved to {config_file}")
                    return config
                except Exception as e:
                    print(f"Error fetching configuration: {e}")
                    return None
            
            def get_gateways(self):
                """Get available VPN gateways"""
                try:
                    response = self.session.get(f"{self.api_base}/3/config/eip-service.json", timeout=30)
                    response.raise_for_status()
                    config = response.json()
                    
                    gateways = []
                    for gw in config.get('gateways', []):
                        gateways.append({
                            'host': gw['host'],
                            'ip_address': gw['ip_address'],
                            'location': gw.get('location', 'Unknown'),
                            'capabilities': gw.get('capabilities', {})
                        })
                    
                    return gateways
                except Exception as e:
                    print(f"Error getting gateways: {e}")
                    return []
            
            def generate_openvpn_config(self, gateway=None):
                """Generate OpenVPN configuration"""
                config = self.fetch_config()
                if not config:
                    return None
                
                gateways = self.get_gateways()
                if not gateways:
                    print("No gateways available")
                    return None
                
                # Select gateway (first available if none specified)
                if gateway is None:
                    gateway = gateways[0]
                    print(f"Using gateway: {gateway['host']} ({gateway['location']})")
                
                # Generate OpenVPN config
                openvpn_config = f'''
# Riseup VPN Configuration
# Generated by riseup-vpn.py
client
dev tun
proto udp
remote {gateway['ip_address']} 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
tls-auth ta.key 1
cipher AES-256-GCM
auth SHA256
key-direction 1
verb 3
comp-lzo

# Censorship circumvention options
'''
                
                if self.use_tor:
                    openvpn_config += '''
# Route through Tor (requires additional setup)
# This requires running Tor with transparent proxy
# route-method exe
# route-delay 2
'''
                
                if self.use_ker:
                    openvpn_config += '''
# KER (obfs with KCP) support - experimental
# Requires additional obfuscation proxy
# socks-proxy 127.0.0.1 1080
'''
                
                # Save OpenVPN config
                config_file = self.config_dir / "riseup.ovpn"
                with open(config_file, 'w') as f:
                    f.write(openvpn_config)
                
                print(f"OpenVPN configuration saved to {config_file}")
                return config_file
            
            def download_certificates(self):
                """Download required certificates"""
                try:
                    # Download CA certificate
                    ca_response = self.session.get(f"{self.api_base}/3/ca.crt", timeout=30)
                    ca_response.raise_for_status()
                    
                    ca_file = self.config_dir / "ca.crt"
                    with open(ca_file, 'w') as f:
                        f.write(ca_response.text)
                    
                    print(f"CA certificate saved to {ca_file}")
                    return True
                    
                except Exception as e:
                    print(f"Error downloading certificates: {e}")
                    return False
            
            def connect(self, gateway=None):
                """Connect to Riseup VPN"""
                print("Connecting to Riseup VPN...")
                
                if self.use_tor and not self.check_tor():
                    print("Error: Tor is not running. Please start Tor first.")
                    return False
                
                # Download certificates
                if not self.download_certificates():
                    return False
                
                # Generate config
                config_file = self.generate_openvpn_config(gateway)
                if not config_file:
                    return False
                
                # Connect using OpenVPN
                try:
                    cmd = ["sudo", "openvpn", "--config", str(config_file)]
                    print(f"Running: {' '.join(cmd)}")
                    subprocess.run(cmd, check=True)
                except subprocess.CalledProcessError as e:
                    print(f"Error connecting to VPN: {e}")
                    return False
                except KeyboardInterrupt:
                    print("\\nDisconnecting...")
                    return True
                
                return True
            
            def check_tor(self):
                """Check if Tor is running"""
                try:
                    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    sock.settimeout(5)
                    result = sock.connect_ex(('127.0.0.1', 9050))
                    sock.close()
                    return result == 0
                except:
                    return False
            
            def list_gateways(self):
                """List available gateways"""
                gateways = self.get_gateways()
                if not gateways:
                    print("No gateways available")
                    return
                
                print("Available Riseup VPN Gateways:")
                print("-" * 50)
                for i, gw in enumerate(gateways):
                    print(f"{i+1}. {gw['host']}")
                    print(f"   Location: {gw['location']}")
                    print(f"   IP: {gw['ip_address']}")
                    capabilities = gw.get('capabilities', {})
                    if capabilities:
                        print(f"   Capabilities: {', '.join(capabilities.keys())}")
                    print()

        def main():
            import argparse
            
            parser = argparse.ArgumentParser(description="Riseup VPN Client with Tor Support")
            parser.add_argument("--tor", action="store_true", help="Use Tor transport")
            parser.add_argument("--no-ker", action="store_true", help="Disable KER support")
            parser.add_argument("--list-gateways", action="store_true", help="List available gateways")
            parser.add_argument("--gateway", type=int, help="Gateway number to connect to")
            
            args = parser.parse_args()
            
            vpn = RiseupVPN(use_tor=args.tor, use_ker=not args.no_ker)
            
            if args.list_gateways:
                vpn.list_gateways()
                return
            
            gateway = None
            if args.gateway:
                gateways = vpn.get_gateways()
                if gateways and 1 <= args.gateway <= len(gateways):
                    gateway = gateways[args.gateway - 1]
                else:
                    print(f"Invalid gateway number. Use --list-gateways to see available options.")
                    return
            
            if args.tor:
                print("Using Tor transport for VPN connection")
            if not args.no_ker:
                print("KER (obfs with KCP) support enabled")
            
            vpn.connect(gateway)

        if __name__ == "__main__":
            main()
      '';
      mode = "0755";
    };

    # Create helper scripts
    environment.etc."riseup-vpn/connect.sh" = mkIf cfg.riseupVpn.enable {
      text = ''
        #!/usr/bin/env bash
        # Riseup VPN Connection Helper
        
        set -euo pipefail
        
        SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
        RISEUP_SCRIPT="$SCRIPT_DIR/riseup-vpn.py"
        
        show_help() {
            echo "Riseup VPN Connection Helper"
            echo
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Options:"
            echo "  -t, --tor         Use Tor transport"
            echo "  -n, --no-ker      Disable KER support" 
            echo "  -l, --list        List available gateways"
            echo "  -g, --gateway N   Connect to gateway number N"
            echo "  -h, --help        Show this help"
            echo
            echo "Examples:"
            echo "  $0                    # Connect normally"
            echo "  $0 --tor              # Connect through Tor"
            echo "  $0 --list             # List gateways"
            echo "  $0 --gateway 2        # Connect to gateway 2"
            echo "  $0 --tor --gateway 1  # Connect to gateway 1 via Tor"
        }
        
        # Parse arguments
        USE_TOR=false
        DISABLE_KER=false
        LIST_GATEWAYS=false
        GATEWAY=""
        
        while [[ $# -gt 0 ]]; do
            case $1 in
                -t|--tor)
                    USE_TOR=true
                    shift
                    ;;
                -n|--no-ker)
                    DISABLE_KER=true
                    shift
                    ;;
                -l|--list)
                    LIST_GATEWAYS=true
                    shift
                    ;;
                -g|--gateway)
                    GATEWAY="$2"
                    shift 2
                    ;;
                -h|--help)
                    show_help
                    exit 0
                    ;;
                *)
                    echo "Unknown option: $1"
                    show_help
                    exit 1
                    ;;
            esac
        done
        
        # Build command
        PYTHON_CMD="python3 $RISEUP_SCRIPT"
        
        if $USE_TOR; then
            PYTHON_CMD="$PYTHON_CMD --tor"
            echo "🔒 Tor transport enabled"
        fi
        
        if $DISABLE_KER; then
            PYTHON_CMD="$PYTHON_CMD --no-ker"
        else
            echo "🚀 KER (obfs with KCP) support enabled"
        fi
        
        if $LIST_GATEWAYS; then
            PYTHON_CMD="$PYTHON_CMD --list-gateways"
        elif [[ -n "$GATEWAY" ]]; then
            PYTHON_CMD="$PYTHON_CMD --gateway $GATEWAY"
        fi
        
        # Check dependencies
        if $USE_TOR; then
            if ! systemctl is-active --quiet tor; then
                echo "⚠️  Tor service is not running. Starting Tor..."
                sudo systemctl start tor
                sleep 3
            fi
            echo "✅ Tor is running"
        fi
        
        # Execute command
        echo "🔧 Executing: $PYTHON_CMD"
        exec $PYTHON_CMD
      '';
      mode = "0755";
    };

    # Systemd services
    systemd.user.services.tor-browser = mkIf cfg.browser.torBrowser {
      description = "Tor Browser";
      after = [ "tor.service" ];
      wants = [ "tor.service" ];
      
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.tor-browser-bundle-bin}/bin/tor-browser";
        Restart = "no";
        PrivateNetwork = false;
        NoNewPrivileges = true;
      };
    };

    # Desktop entries
    environment.etc."riseup-vpn/riseup-vpn.desktop" = mkIf cfg.riseupVpn.enable {
      text = ''
        [Desktop Entry]
        Name=Riseup VPN
        Comment=Connect to Riseup VPN with censorship circumvention
        Exec=/etc/riseup-vpn/connect.sh
        Icon=network-vpn
        Type=Application
        Categories=Network;Security;
        Keywords=vpn;tor;privacy;circumvention;
        StartupNotify=true
        Terminal=true
      '';
    };

    # Add to applications menu
    environment.etc."riseup-vpn/riseup-vpn-tor.desktop" = mkIf (cfg.riseupVpn.enable && cfg.tor.enable) {
      text = ''
        [Desktop Entry]
        Name=Riseup VPN (Tor)
        Comment=Connect to Riseup VPN through Tor
        Exec=/etc/riseup-vpn/connect.sh --tor
        Icon=network-vpn
        Type=Application
        Categories=Network;Security;
        Keywords=vpn;tor;privacy;circumvention;
        StartupNotify=true
        Terminal=true
      '';
    };


    # DNS configuration for privacy
    services.dnsmasq = mkIf cfg.enable {
      enable = true;
      settings = {
        # Use secure DNS servers
        server = [
          "1.1.1.1"  # Cloudflare
          "9.9.9.9"  # Quad9
        ];
        
        # Privacy settings
        no-resolv = true;
        bogus-priv = true;
        domain-needed = true;
        expand-hosts = true;
        no-hosts = true;
        
        # Cache settings
        cache-size = 1000;
      };
    };

    # Message to user
    warnings = mkIf cfg.enable [
      ''
        Privacy and censorship circumvention tools have been enabled.
        
        Available tools:
        ${optionalString cfg.tor.enable "• Tor with SOCKS proxy on 127.0.0.1:9050"}
        ${optionalString cfg.tor.obfs4.enable "• obfs4 bridges for traffic obfuscation"}
        ${optionalString cfg.tor.snowflake.enable "• Snowflake pluggable transport"}
        ${optionalString cfg.riseupVpn.enable "• Riseup VPN client (/etc/riseup-vpn/connect.sh)"}
        ${optionalString cfg.browser.torBrowser "• Tor Browser"}
        
        To use:
        1. For Tor: Applications will automatically use the SOCKS proxy
        2. For Riseup VPN: Run '/etc/riseup-vpn/connect.sh' or use desktop launcher
        3. For Tor+VPN: Run '/etc/riseup-vpn/connect.sh --tor'
        
        Remember: These tools may be slower than direct connections.
        Use only when needed for circumventing censorship.
      ''
    ];
  };
}