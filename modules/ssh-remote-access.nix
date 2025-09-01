{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.ssh-remote-access;
in

{
  options.custom.ssh-remote-access = {
    enable = mkEnableOption "Secure SSH remote access";

    server = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SSH server";
      };

      port = mkOption {
        type = types.int;
        default = 22;
        description = "SSH server port";
      };

      alternativePorts = mkOption {
        type = types.listOf types.int;
        default = [ 2222 ];
        description = "Alternative SSH ports for security";
      };

      passwordAuthentication = mkOption {
        type = types.bool;
        default = false;
        description = "Allow password authentication (less secure)";
      };

      permitRootLogin = mkOption {
        type = types.str;
        default = "no";
        description = "Permit root login (no/yes/prohibit-password)";
      };

      maxAuthTries = mkOption {
        type = types.int;
        default = 3;
        description = "Maximum authentication attempts";
      };

      clientAliveInterval = mkOption {
        type = types.int;
        default = 120;
        description = "Client alive interval in seconds";
      };
    };

    keys = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SSH key management";
      };

      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of authorized SSH public keys";
      };

      hostKeys = {
        generate = mkOption {
          type = types.bool;
          default = true;
          description = "Generate host keys automatically";
        };

        types = mkOption {
          type = types.listOf types.str;
          default = [ "rsa" "ed25519" ];
          description = "Host key types to generate";
        };
      };
    };

    security = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable enhanced SSH security";
      };

      fail2ban = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Fail2Ban for SSH protection";
      };

      allowedUsers = mkOption {
        type = types.listOf types.str;
        default = [ "mahmoud" ];
        description = "Users allowed to SSH";
      };

      deniedUsers = mkOption {
        type = types.listOf types.str;
        default = [ "root" ];
        description = "Users denied SSH access";
      };

      geoBlocking = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable geographic IP blocking";
        };

        allowedCountries = mkOption {
          type = types.listOf types.str;
          default = [ "EG" "US" "EU" ];
          description = "Allowed country codes";
        };
      };
    };

    tunneling = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SSH tunneling features";
      };

      forwarding = {
        tcp = mkOption {
          type = types.bool;
          default = true;
          description = "Allow TCP forwarding";
        };

        x11 = mkOption {
          type = types.bool;
          default = true;
          description = "Allow X11 forwarding";
        };

        agent = mkOption {
          type = types.bool;
          default = true;
          description = "Allow SSH agent forwarding";
        };
      };

      reverseProxy = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable reverse proxy capabilities";
        };

        ports = mkOption {
          type = types.listOf types.int;
          default = [ 8080 8443 ];
          description = "Ports available for reverse proxy";
        };
      };
    };

    monitoring = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SSH connection monitoring";
      };

      logging = mkOption {
        type = types.str;
        default = "INFO";
        description = "SSH logging level";
      };

      alerts = mkOption {
        type = types.bool;
        default = true;
        description = "Enable login alerts";
      };
    };

    mobileAccess = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Optimize for mobile SSH access";
      };

      keepAlive = mkOption {
        type = types.bool;
        default = true;
        description = "Enable keep-alive for mobile connections";
      };

      compression = mkOption {
        type = types.bool;
        default = true;
        description = "Enable compression for mobile connections";
      };
    };
  };

  config = mkIf cfg.enable {
    # Main SSH service configuration
    services.openssh = mkIf cfg.server.enable {
      enable = true;
      ports = [ cfg.server.port ] ++ cfg.server.alternativePorts;
      
      settings = {
        # Authentication settings
        PasswordAuthentication = cfg.server.passwordAuthentication;
        PermitRootLogin = cfg.server.permitRootLogin;
        PubkeyAuthentication = true;
        AuthenticationMethods = if cfg.server.passwordAuthentication 
          then "publickey,password" 
          else "publickey";
        MaxAuthTries = cfg.server.maxAuthTries;
        
        # Security settings
        Protocol = "2";
        Compression = cfg.mobileAccess.compression;
        ClientAliveInterval = cfg.server.clientAliveInterval;
        ClientAliveCountMax = 3;
        TCPKeepAlive = cfg.mobileAccess.keepAlive;
        
        # SSH Banner
        Banner = mkIf cfg.security.enable "/etc/ssh/banner";
        
        # Forwarding settings
        AllowTcpForwarding = mkIf cfg.tunneling.forwarding.tcp "yes";
        X11Forwarding = mkDefault cfg.tunneling.forwarding.x11;
        AllowAgentForwarding = cfg.tunneling.forwarding.agent;
        
        # User restrictions
        AllowUsers = mkIf (cfg.security.allowedUsers != []) 
          cfg.security.allowedUsers;
        DenyUsers = mkIf (cfg.security.deniedUsers != []) 
          cfg.security.deniedUsers;
        
        # Logging
        LogLevel = cfg.monitoring.logging;
        SyslogFacility = "AUTHPRIV";
        
        # Additional security
        LoginGraceTime = 30;
        MaxStartups = "10:30:100";
        MaxSessions = 10;
        StrictModes = true;
        IgnoreUserKnownHosts = true;
        HostbasedAuthentication = false;
        PermitEmptyPasswords = false;
        ChallengeResponseAuthentication = false;
        KerberosAuthentication = false;
        GSSAPIAuthentication = false;
      };
      
      # Host key configuration
      hostKeys = mkIf cfg.keys.hostKeys.generate (map (type: {
        path = "/etc/ssh/ssh_host_${type}_key";
        type = type;
      }) cfg.keys.hostKeys.types);
    };

    # Fail2Ban configuration for SSH protection
    services.fail2ban = mkIf cfg.security.fail2ban {
      enable = true;
      jails = {
        ssh = ''
          enabled = true
          port = ssh
          filter = sshd
          logpath = /var/log/auth.log
          maxretry = 3
          bantime = 3600
          findtime = 600
          action = iptables[name=ssh, port=ssh, protocol=tcp]
        '';
        
        ssh-ddos = ''
          enabled = true
          port = ssh
          filter = sshd-ddos
          logpath = /var/log/auth.log
          maxretry = 6
          bantime = 600
          findtime = 120
        '';
      };
    };

    # User SSH key configuration
    users.users.mahmoud = mkIf cfg.keys.enable {
      openssh.authorizedKeys.keys = cfg.keys.authorizedKeys;
    };

    # Firewall configuration
    networking.firewall = {
      allowedTCPPorts = [ cfg.server.port ] ++ cfg.server.alternativePorts;
      
      # Additional security rules
      extraCommands = mkIf cfg.security.enable ''
        # Rate limiting for SSH
        iptables -A INPUT -p tcp --dport ${toString cfg.server.port} -m conntrack --ctstate NEW -m recent --set
        iptables -A INPUT -p tcp --dport ${toString cfg.server.port} -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
      '';
    };

    # System packages for SSH management
    environment.systemPackages = with pkgs; [
      openssh
      sshfs
      autossh
      mosh  # Mobile shell for better mobile connectivity
      eternal-terminal  # Better connection persistence
    ] ++ optionals cfg.keys.enable [
      ssh-key-confirmer
      keychain
    ] ++ optionals cfg.monitoring.enable [
      tcpdump
      iproute2  # Provides ss command
      lsof
    ] ++ optionals cfg.tunneling.enable [
      sshuttle  # VPN over SSH
      proxychains
    ];

    # Mosh (mobile shell) for better mobile connectivity
    programs.mosh = mkIf cfg.mobileAccess.enable {
      enable = true;
      withUtempter = true;
    };

    # Network configuration for mosh
    networking.firewall.allowedUDPPortRanges = mkIf cfg.mobileAccess.enable [
      { from = 60000; to = 61000; }  # Mosh port range
    ];

    # SSH connection monitoring script
    systemd.services.ssh-monitor = mkIf cfg.monitoring.enable {
      description = "SSH Connection Monitor";
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = pkgs.writeScript "ssh-monitor" ''
          #!${pkgs.bash}/bin/bash
          
          # Log active SSH sessions
          echo "$(date): Active SSH sessions:" >> /var/log/ssh-monitor.log
          who | grep pts >> /var/log/ssh-monitor.log 2>/dev/null || true
          
          # Check for suspicious activity
          FAILED_LOGINS=$(journalctl -u ssh --since "1 hour ago" | grep "Failed password" | wc -l)
          if [ "$FAILED_LOGINS" -gt 10 ]; then
            echo "$(date): WARNING: $FAILED_LOGINS failed SSH login attempts in the last hour" >> /var/log/ssh-monitor.log
            ${optionalString cfg.monitoring.alerts "${pkgs.libnotify}/bin/notify-send 'SSH Alert' '$FAILED_LOGINS failed login attempts'"}
          fi
        '';
      };
    };

    # SSH monitor timer
    systemd.timers.ssh-monitor = mkIf cfg.monitoring.enable {
      description = "SSH Monitor Timer";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
        RandomizedDelaySec = "300";
      };
    };

    # SSH client configuration
    programs.ssh = {
      extraConfig = ''
        # Global SSH client optimizations
        ServerAliveInterval 60
        ServerAliveCountMax 3
        TCPKeepAlive yes
        Compression yes
        
        # Security settings
        HashKnownHosts yes
        ForwardAgent no
        ForwardX11 no
        ForwardX11Trusted no
        StrictHostKeyChecking ask
        VerifyHostKeyDNS yes
        
        # Mobile optimizations
        ${optionalString cfg.mobileAccess.enable ''
        IPQoS throughput
        RekeyLimit 1G 1h
        ''}
      '';
    };

    # Environment variables for SSH
    environment.sessionVariables = {
      SSH_AUTH_SOCK = mkDefault "/run/user/$(id -u)/ssh-agent.socket";
    };

    # Systemd user services for SSH agent
    systemd.user.services.ssh-agent = mkIf cfg.keys.enable {
      description = "SSH key agent";
      wantedBy = [ "default.target" ];
      
      serviceConfig = {
        Type = "simple";
        Environment = "SSH_AUTH_SOCK=/run/user/%i/ssh-agent.socket";
        ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a /run/user/%i/ssh-agent.socket";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # Log rotation for SSH logs
    services.logrotate.settings.ssh = mkIf cfg.monitoring.enable {
      files = [ "/var/log/ssh-monitor.log" ];
      frequency = "weekly";
      rotate = 4;
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
    };

    # Security hardening
    security.pam.services.sshd = mkIf cfg.security.enable {
      unixAuth = mkDefault true;
      limits = [
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = "1048576";
        }
      ];
    };

    # System activation script for SSH setup
    system.activationScripts.sshRemoteAccess = mkIf cfg.enable ''
      # Create SSH directories
      mkdir -p /var/log
      touch /var/log/ssh-monitor.log
      chmod 644 /var/log/ssh-monitor.log
      
      # Create user SSH directory
      mkdir -p /home/mahmoud/.ssh
      chmod 700 /home/mahmoud/.ssh
      chown mahmoud:users /home/mahmoud/.ssh
      
      # Generate SSH banner
      cat > /etc/ssh/banner << 'EOF'
      =====================================
      WARNING: Authorized Access Only
      =====================================
      This system is for authorized users only.
      All activity is monitored and logged.
      Unauthorized access is prohibited.
      =====================================
      EOF
      
      echo 'SSH remote access configured successfully'
    '';

    # SSH banner configuration merged with main openssh config above

    # Additional SSH security through systemd
    systemd.services.sshd.serviceConfig = mkIf cfg.security.enable {
      # Enhanced security
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      NoNewPrivileges = false;  # SSH needs privileges
      
      # Resource limits
      LimitNOFILE = 1048576;
      LimitNPROC = 32768;
    };
  };
}
