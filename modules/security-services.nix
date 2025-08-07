{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.services.security = {
      enable = mkEnableOption "enhanced security services";
      
      firewall = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable firewall with custom rules";
        };
        
        allowedTCPPorts = mkOption {
          type = types.listOf types.port;
          default = [ 22 80 443 ];
          description = "TCP ports to allow through firewall";
        };
        
        allowedUDPPorts = mkOption {
          type = types.listOf types.port;
          default = [ 53 123 68 ];
          description = "UDP ports to allow through firewall";
        };
      };
      
      ssh = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable OpenSSH server";
        };
        
        passwordAuthentication = mkOption {
          type = types.bool;
          default = false;
          description = "Allow SSH password authentication";
        };
        
        permitRootLogin = mkOption {
          type = types.str;
          default = "no";
          description = "Permit root login via SSH";
        };
      };
      
      fail2ban.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable fail2ban intrusion prevention";
      };
      
      hardening.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable system hardening measures";
      };
    };
  };

  config = mkIf config.custom.services.security.enable {
    # Firewall configuration
    networking.firewall = mkIf config.custom.services.security.firewall.enable {
      enable = true;
      allowedTCPPorts = config.custom.services.security.firewall.allowedTCPPorts;
      allowedUDPPorts = config.custom.services.security.firewall.allowedUDPPorts;
      
      # Additional security rules
      extraCommands = ''
        # Drop invalid packets
        iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
        
        # Rate limit SSH connections
        iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
        iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
      '';
    };
    
    # SSH configuration
    services.openssh = mkIf config.custom.services.security.ssh.enable {
      enable = true;
      settings = {
        PasswordAuthentication = config.custom.services.security.ssh.passwordAuthentication;
        PermitRootLogin = config.custom.services.security.ssh.permitRootLogin;
        X11Forwarding = false;
        AllowUsers = [ "mahmoud" ];
      };
    };
    
    # Fail2ban intrusion prevention
    services.fail2ban = mkIf config.custom.services.security.fail2ban.enable {
      enable = true;
      bantime = "10m";
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h";
        overalljails = true;
      };
    };
    
    # System hardening (sysctl settings handled by networking module)
    # Additional security configurations can be added here if needed
    
    # Security packages
    environment.systemPackages = with pkgs; [
      fail2ban
      nftables
      iptables
      lynis        # Security auditing tool
    ];
  };
}
