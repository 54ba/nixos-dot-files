{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.remote-control;
in

{
  options.custom.remote-control = {
    enable = mkEnableOption "Remote control and desktop sharing";

    rustdesk = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable RustDesk remote desktop";
      };

      server = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Run RustDesk as server (self-hosted)";
        };

        port = mkOption {
          type = types.int;
          default = 21115;
          description = "RustDesk server port";
        };
      };

      quality = mkOption {
        type = types.str;
        default = "balanced";
        description = "Video quality (low/balanced/high)";
      };

      encryption = mkOption {
        type = types.bool;
        default = true;
        description = "Enable end-to-end encryption";
      };
    };

    wayvnc = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Wayvnc for Wayland VNC support";
      };

      port = mkOption {
        type = types.int;
        default = 5900;
        description = "VNC server port";
      };

      password = mkOption {
        type = types.bool;
        default = true;
        description = "Enable password authentication";
      };

      quality = mkOption {
        type = types.str;
        default = "high";
        description = "Encoding quality (low/medium/high)";
      };
    };

    nomachine = {
      enable = mkOption {
        type = types.bool;
        default = false;  # Proprietary, disabled by default
        description = "Enable NoMachine remote desktop";
      };

      port = mkOption {
        type = types.int;
        default = 4000;
        description = "NoMachine server port";
      };
    };

    webRTC = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable WebRTC-based remote access";
      };

      meshcentral = mkOption {
        type = types.bool;
        default = true;
        description = "Enable MeshCentral web-based remote access";
      };

      port = mkOption {
        type = types.int;
        default = 443;
        description = "WebRTC service port";
      };
    };

    mobileApps = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable mobile app compatibility";
      };

      scrcpy = mkOption {
        type = types.bool;
        default = true;
        description = "Enable scrcpy for Android control";
      };

      kdeConnect = mkOption {
        type = types.bool;
        default = true;
        description = "Enable KDE Connect for mobile integration";
      };

      pushbullet = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Pushbullet integration";
      };
    };

    fileSharing = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable file sharing between devices";
      };

      syncthing = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Syncthing for file synchronization";
      };

      samba = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Samba for Windows compatibility";
      };

      ftp = mkOption {
        type = types.bool;
        default = false;
        description = "Enable FTP server";
      };
    };

    security = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable enhanced remote access security";
      };

      encryption = mkOption {
        type = types.bool;
        default = true;
        description = "Enforce encryption on all connections";
      };

      whitelist = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable IP whitelist";
        };

        ips = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Whitelisted IP addresses";
        };
      };

      authentication = {
        twoFactor = mkOption {
          type = types.bool;
          default = false;
          description = "Enable two-factor authentication";
        };

        timeout = mkOption {
          type = types.int;
          default = 3600;
          description = "Session timeout in seconds";
        };
      };
    };

    performance = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable performance optimizations";
      };

      compression = mkOption {
        type = types.bool;
        default = true;
        description = "Enable compression";
      };

      hardwareAcceleration = mkOption {
        type = types.bool;
        default = true;
        description = "Enable hardware acceleration for encoding";
      };

      adaptiveBitrate = mkOption {
        type = types.bool;
        default = true;
        description = "Enable adaptive bitrate based on connection";
      };
    };
  };

  config = mkIf cfg.enable {
    # RustDesk configuration
    environment.systemPackages = with pkgs; [
      # Remote desktop applications
    ] ++ optionals cfg.rustdesk.enable [
      rustdesk
    ] ++ optionals cfg.wayvnc.enable [
      wayvnc
      wlvncc  # Wayland VNC client
    ] ++ optionals cfg.mobileApps.enable [
      (mkIf cfg.mobileApps.scrcpy scrcpy)
      (mkIf cfg.mobileApps.kdeConnect kdePackages.kdeconnect-kde)
    ] ++ optionals cfg.fileSharing.enable [
      (mkIf cfg.fileSharing.syncthing syncthing)
    ] ++ optionals cfg.webRTC.enable [
      # WebRTC tools
      firefox  # For WebRTC support
      chromium
    ] ++ [
      # Remote control utilities
      tigervnc  # VNC server/client
      freerdp   # RDP client
      remmina   # Remote desktop client
      
      # Network tools
      netcat
      socat
      nmap
      
      # Mobile connectivity
      adb-sync
      android-tools
      
      # Screen sharing
      obs-studio
      ffmpeg
      
      # Security tools
      gnupg
      openssl
    ];

    # Wayvnc service for Wayland
    systemd.services.wayvnc = mkIf cfg.wayvnc.enable {
      description = "Wayland VNC server";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      
      environment = {
        WAYLAND_DISPLAY = "wayland-0";
        XDG_RUNTIME_DIR = "/run/user/1000";
      };
      
      serviceConfig = {
        Type = "simple";
        User = "mahmoud";
        Group = "users";
        ExecStart = "${pkgs.wayvnc}/bin/wayvnc -C /home/mahmoud/.config/wayvnc/config";
        Restart = "on-failure";
        RestartSec = "5s";
        
        # Security
        PrivateTmp = true;
        ProtectHome = false;  # Need access to user home
        ProtectSystem = "strict";
        NoNewPrivileges = true;
      };
    };

    # MeshCentral service disabled - missing meshcentral.js file
    # TODO: Install MeshCentral properly if needed
    # systemd.services.meshcentral = mkIf cfg.webRTC.meshcentral { ... };

    # Syncthing for file synchronization
    services.syncthing = mkIf cfg.fileSharing.syncthing {
      enable = true;
      user = "mahmoud";
      dataDir = "/home/mahmoud/Syncthing";
      configDir = "/home/mahmoud/.config/syncthing";
      
      settings = {
        gui = {
          user = "mahmoud";
          password = ""; # Use external authentication
          insecureAdminAccess = false;
        };
        
        options = {
          urAccepted = -1;  # Disable usage reporting
          crashReportingEnabled = false;
          relaysEnabled = true;
          globalAnnounceEnabled = true;
        };
      };
    };

    # KDE Connect for mobile integration
    programs.kdeconnect = mkIf cfg.mobileApps.kdeConnect {
      enable = true;
      package = mkDefault pkgs.kdePackages.kdeconnect-kde;
    };

    # ADB for Android connectivity
    programs.adb = mkIf cfg.mobileApps.scrcpy {
      enable = true;
    };

    # Network firewall configuration
    networking.firewall = {
      allowedTCPPorts = []
        ++ optional cfg.wayvnc.enable cfg.wayvnc.port
        ++ optional cfg.rustdesk.server.enable cfg.rustdesk.server.port
        ++ optional cfg.nomachine.enable cfg.nomachine.port
        ++ optional cfg.webRTC.enable cfg.webRTC.port
        ++ optionals cfg.fileSharing.syncthing [ 8384 22000 ]  # Syncthing ports
        ++ optionals cfg.mobileApps.kdeConnect [ 1714 1715 1716 1717 1718 1719 1720 1721 1722 1723 1724 ];  # KDE Connect
        
      allowedUDPPorts = []
        ++ optional cfg.rustdesk.enable 21116  # RustDesk UDP
        ++ optionals cfg.fileSharing.syncthing [ 21027 22000 ]  # Syncthing discovery
        ++ optionals cfg.mobileApps.kdeConnect [ 1714 1715 1716 1717 1718 1719 1720 1721 1722 1723 1724 ];  # KDE Connect
        
      # Port ranges for dynamic allocation
      allowedTCPPortRanges = mkIf cfg.performance.enable [
        { from = 21100; to = 21200; }  # RustDesk range
        { from = 5900; to = 5910; }   # VNC range
      ];
      
      allowedUDPPortRanges = mkIf cfg.performance.enable [
        { from = 21100; to = 21200; }  # RustDesk UDP range
      ];
    };

    # Create necessary system users
    users.users = mkMerge [
      (mkIf cfg.webRTC.meshcentral {
        meshcentral = {
          isSystemUser = true;
          group = "meshcentral";
          home = "/var/lib/meshcentral";
          createHome = true;
          description = "MeshCentral service user";
        };
      })
    ];

    users.groups = mkIf cfg.webRTC.meshcentral {
      meshcentral = {};
    };

    # System activation scripts
    system.activationScripts.remoteControl = mkIf cfg.enable ''
      # Create configuration directories
      mkdir -p /home/mahmoud/.config/wayvnc
      mkdir -p /home/mahmoud/.config/rustdesk
      mkdir -p /var/lib/meshcentral
      
      # Set proper permissions
      chown -R mahmoud:users /home/mahmoud/.config/wayvnc /home/mahmoud/.config/rustdesk 2>/dev/null || true
      ${optionalString cfg.webRTC.meshcentral "chown -R meshcentral:meshcentral /var/lib/meshcentral"}
      
      # Create Wayvnc config with proper syntax
      cat > /home/mahmoud/.config/wayvnc/config << 'EOF'
      address=0.0.0.0
      port=${toString cfg.wayvnc.port}
      enable_auth=true
      username=wayvnc
      EOF
      
      chown mahmoud:users /home/mahmoud/.config/wayvnc/config
      
      echo 'Remote control services configured successfully'
    '';

    # Desktop entries for remote control apps
    environment.etc = {
      # RustDesk desktop entry
      "xdg/applications/rustdesk-server.desktop" = mkIf cfg.rustdesk.enable {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=RustDesk Server
          Exec=${pkgs.rustdesk}/bin/rustdesk --server
          Icon=rustdesk
          Comment=Start RustDesk in server mode
          Categories=Network;RemoteAccess;
        '';
      };
      
      # Wayvnc desktop entry
      "xdg/applications/wayvnc.desktop" = mkIf cfg.wayvnc.enable {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=Wayvnc Server
          Exec=${pkgs.wayvnc}/bin/wayvnc
          Icon=network-server
          Comment=Start Wayland VNC server
          Categories=Network;RemoteAccess;
        '';
      };
    };

    # Polkit rules for remote access
    security.polkit.extraConfig = mkIf cfg.security.enable ''
      // Allow wheel group users to control remote access services
      polkit.addRule(function(action, subject) {
          if ((action.id.indexOf("org.freedesktop.systemd1.manage-units") == 0 ||
               action.id.indexOf("org.freedesktop.NetworkManager") == 0) &&
              subject.isInGroup("wheel")) {
              return polkit.Result.YES;
          }
      });
      
      // Allow remote desktop access for wheel group
      polkit.addRule(function(action, subject) {
          if (action.id == "org.gnome.desktop.remote-desktop.remote-desktop" &&
              subject.isInGroup("wheel")) {
              return polkit.Result.YES;
          }
      });
    '';

    # Systemd services configuration
    systemd.services = {
      # RustDesk server service
      rustdesk-server = mkIf cfg.rustdesk.server.enable {
        description = "RustDesk Remote Desktop Server";
        after = [ "network.target" "graphical-session.target" ];
        wantedBy = [ "multi-user.target" ];
        
        environment = {
          DISPLAY = ":0";
          WAYLAND_DISPLAY = "wayland-0";
          XDG_RUNTIME_DIR = "/run/user/1000";
        };
        
        serviceConfig = {
          Type = "simple";
          User = "mahmoud";
          Group = "users";
          ExecStart = "${pkgs.rustdesk}/bin/rustdesk --server --port ${toString cfg.rustdesk.server.port}";
          Restart = "on-failure";
          RestartSec = "10s";
          
          # Security
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = false;
          NoNewPrivileges = true;
          
          # Performance
          Nice = -10;
          IOSchedulingClass = 1;
          IOSchedulingPriority = 4;
        };
      };
    };

    # GNOME remote desktop (built-in)
    services.gnome.gnome-remote-desktop = mkIf (config.services.xserver.desktopManager.gnome.enable) {
      enable = true;
    };

    # VNC server configuration using TigerVNC
    systemd.services.vncserver = mkIf (!cfg.wayvnc.enable) {
      description = "TigerVNC Server";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      
      environment = {
        USER = "mahmoud";
        HOME = "/home/mahmoud";
      };
      
      serviceConfig = {
        Type = "simple";
        User = "mahmoud";
        Group = "users";
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'mkdir -p /home/mahmoud/.vnc'";
        ExecStart = "${pkgs.tigervnc}/bin/vncserver :1 -geometry 1920x1080 -depth 24 -localhost no";
        ExecStop = "${pkgs.tigervnc}/bin/vncserver -kill :1";
        Restart = "on-failure";
        RestartSec = "5s";
        
        # Security
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = false;
        ReadWritePaths = [ "/home/mahmoud" "/tmp" ];
      };
    };

    # Enable necessary system services
    services = {
      # Enable dbus for desktop integration
      dbus.enable = true;
      
      # Enable avahi for service discovery
      avahi = {
        enable = true;
        nssmdns4 = true;
        publish = {
          enable = true;
          addresses = true;
          workstation = true;
          userServices = true;
        };
      };
      
      # Enable location services for mobile apps
      geoclue2.enable = mkIf cfg.mobileApps.enable true;
      
      # Enable printing for remote access
      printing.enable = true;
      printing.drivers = [ pkgs.gutenprint ];
    };

    # Hardware configuration
    hardware = {
      # Enable hardware acceleration
      graphics = mkIf cfg.performance.hardwareAcceleration {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver
          vaapiIntel
          vaapiVdpau
          libvdpau-va-gl
        ];
      };
    };

    # Environment variables for remote control
    environment.sessionVariables = {
      # Display server detection
      WAYLAND_DISPLAY = "wayland-0";
      DISPLAY = ":0";
      
      # Performance optimizations
      LIBVA_DRIVER_NAME = mkIf cfg.performance.hardwareAcceleration "iHD";
      VDPAU_DRIVER = mkIf cfg.performance.hardwareAcceleration "va_gl";
      
      # Remote desktop optimizations
      RUSTDESK_QUALITY = cfg.rustdesk.quality;
    };

    # User groups for remote access handled by main configuration

    # Kernel modules for remote access
    boot.kernelModules = mkIf cfg.performance.enable [
      "v4l2loopback"  # Virtual camera support
    ];
    
    boot.extraModulePackages = mkIf cfg.performance.enable [
      pkgs.linuxPackages.v4l2loopback
    ];

    # Systemd timers for maintenance
    systemd.timers.remote-control-maintenance = mkIf cfg.enable {
      description = "Remote Control Maintenance";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1800";
      };
    };

    systemd.services.remote-control-maintenance = mkIf cfg.enable {
      description = "Remote Control Maintenance Service";
      
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = pkgs.writeScript "remote-control-maintenance" ''
          #!${pkgs.bash}/bin/bash
          
          # Clean up old VNC sessions
          ${pkgs.procps}/bin/pkill -u mahmoud Xvnc 2>/dev/null || true
          
          # Restart services if they're not responding
          ${pkgs.systemd}/bin/systemctl --user --machine=mahmoud@ is-active wayvnc >/dev/null || \
            ${pkgs.systemd}/bin/systemctl --user --machine=mahmoud@ restart wayvnc 2>/dev/null || true
          
          # Clean up temporary files
          find /tmp -name "rustdesk-*" -mtime +1 -delete 2>/dev/null || true
          find /tmp -name "vnc-*" -mtime +1 -delete 2>/dev/null || true
          
          echo "$(date): Remote control maintenance completed" >> /var/log/remote-control.log
        '';
      };
    };

    # Create log file
    system.activationScripts.remote-control-logs = ''
      touch /var/log/remote-control.log
      chmod 644 /var/log/remote-control.log
    '';

    # Log rotation
    services.logrotate.settings.remote-control = {
      files = [ "/var/log/remote-control.log" ];
      frequency = "weekly";
      rotate = 4;
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
    };
  };
}
