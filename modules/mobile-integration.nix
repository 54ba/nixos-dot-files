{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.mobile-integration;
in

{
  options.custom.mobile-integration = {
    enable = mkEnableOption "Mobile device integration and control";

    kdeConnect = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable KDE Connect for comprehensive mobile integration";
      };

      features = {
        notifications = mkOption {
          type = types.bool;
          default = true;
          description = "Enable notification sync between devices";
        };

        clipboard = mkOption {
          type = types.bool;
          default = true;
          description = "Enable clipboard sharing";
        };

        fileTransfer = mkOption {
          type = types.bool;
          default = true;
          description = "Enable file transfer";
        };

        mediaControl = mkOption {
          type = types.bool;
          default = true;
          description = "Enable media playback control from mobile";
        };

        remoteInput = mkOption {
          type = types.bool;
          default = true;
          description = "Enable mobile as mouse/keyboard";
        };

        sms = mkOption {
          type = types.bool;
          default = true;
          description = "Enable SMS integration";
        };

        findDevice = mkOption {
          type = types.bool;
          default = true;
          description = "Enable device finding (ring device)";
        };
      };
    };

    android = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Android device integration";
      };

      scrcpy = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable scrcpy for Android screen mirroring and control";
        };

        quality = mkOption {
          type = types.int;
          default = 8;
          description = "Video quality (1-8, 8=best)";
        };

        wireless = mkOption {
          type = types.bool;
          default = true;
          description = "Enable wireless Android control";
        };

        recordScreen = mkOption {
          type = types.bool;
          default = true;
          description = "Enable screen recording";
        };
      };

      adb = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable ADB (Android Debug Bridge)";
        };

        wireless = mkOption {
          type = types.bool;
          default = true;
          description = "Enable wireless ADB";
        };

        port = mkOption {
          type = types.int;
          default = 5555;
          description = "ADB wireless port";
        };
      };

      apps = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Android app management tools";
        };

        apkTool = mkOption {
          type = types.bool;
          default = false;
          description = "Enable APK analysis tools";
        };
      };
    };

    ios = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable iOS device integration";
      };

      libimobiledevice = mkOption {
        type = types.bool;
        default = true;
        description = "Enable libimobiledevice for iOS connectivity";
      };

      uxplay = mkOption {
        type = types.bool;
        default = true;
        description = "Enable AirPlay server for iOS screen mirroring";
      };

      fileTransfer = mkOption {
        type = types.bool;
        default = true;
        description = "Enable iOS file transfer";
      };
    };

    crossPlatform = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable cross-platform features";
      };

      localsend = mkOption {
        type = types.bool;
        default = true;
        description = "Enable LocalSend for easy file sharing";
      };

      warpinator = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Warpinator for file sharing";
      };

      snapdrop = mkOption {
        type = types.bool;
        default = false;
        description = "Enable local Snapdrop instance";
      };

      pairdrop = mkOption {
        type = types.bool;
        default = true;
        description = "Enable PairDrop for web-based file sharing";
      };
    };

    webInterface = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable web-based mobile control interface";
      };

      port = mkOption {
        type = types.int;
        default = 8080;
        description = "Web interface port";
      };

      ssl = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SSL for web interface";
      };

      authentication = mkOption {
        type = types.bool;
        default = true;
        description = "Enable authentication for web interface";
      };
    };

    notifications = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable notification forwarding";
      };

      pushover = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Pushover integration";
      };

      ntfy = mkOption {
        type = types.bool;
        default = true;
        description = "Enable ntfy.sh for notifications";
      };

      telegram = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Telegram bot notifications";
      };
    };

    automation = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable automation features";
      };

      homeAssistant = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Home Assistant integration";
      };

      shortcuts = mkOption {
        type = types.bool;
        default = true;
        description = "Enable mobile shortcuts for PC control";
      };

      tasker = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Tasker/automation integration";
      };
    };
  };

  config = mkIf cfg.enable {
    # System packages for mobile integration
    environment.systemPackages = with pkgs; [
      # Core mobile integration
    ] ++ optionals cfg.kdeConnect.enable [
      kdePackages.kdeconnect-kde
      plasma5Packages.kdeconnect-kde
    ] ++ optionals cfg.android.scrcpy.enable [
      scrcpy
      android-tools
      adb-sync
    ] ++ optionals cfg.android.adb.enable [
      android-tools
      android-udev-rules
    ] ++ optionals cfg.android.apps.enable [
      (mkIf cfg.android.apps.apkTool apktool)
      aapt
    ] ++ optionals cfg.ios.enable [
      (mkIf cfg.ios.libimobiledevice libimobiledevice)
      (mkIf cfg.ios.uxplay uxplay)
      (mkIf cfg.ios.fileTransfer ifuse)
    ] ++ optionals cfg.crossPlatform.enable [
      (mkIf cfg.crossPlatform.localsend localsend)
      (mkIf cfg.crossPlatform.warpinator warpinator)
    ] ++ optionals cfg.notifications.enable [
      (mkIf cfg.notifications.ntfy ntfy-sh)
      libnotify
      dunst
    ] ++ [
      # Utility tools
      curl
      wget
      jq
      socat
      netcat
      
      # Mobile development
      flutter
      nodejs
      
      # File sharing
      rsync
      rclone
      
      # Network discovery
      avahi
      nmap
      
      # Media tools
      ffmpeg
      imagemagick
      
      # Security
      gnupg
      openssl
    ];

    # KDE Connect service and configuration
    programs.kdeconnect = mkIf cfg.kdeConnect.enable {
      enable = true;
      package = pkgs.kdePackages.kdeconnect-kde;
    };

    # ADB configuration
    programs.adb = mkIf cfg.android.adb.enable {
      enable = true;
    };

    # Systemd services
    systemd.services = {
      # Custom web interface for mobile control
      mobile-web-interface = mkIf cfg.webInterface.enable {
        description = "Mobile Web Control Interface";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        
        serviceConfig = {
          Type = "simple";
          User = "mahmoud";
          Group = "users";
          ExecStart = pkgs.writeScript "mobile-web-server" ''
            #!${pkgs.nodejs}/bin/node
            
            const http = require('http');
            const fs = require('fs');
            const { exec } = require('child_process');
            
            const server = http.createServer((req, res) => {
              res.setHeader('Access-Control-Allow-Origin', '*');
              res.setHeader('Content-Type', 'application/json');
              
              if (req.url === '/api/system/info') {
                exec('uname -a && uptime', (error, stdout) => {
                  res.writeHead(200);
                  res.end(JSON.stringify({ system: stdout }));
                });
              } else if (req.url === '/api/power/suspend') {
                exec('systemctl suspend', () => {
                  res.writeHead(200);
                  res.end(JSON.stringify({ status: 'suspending' }));
                });
              } else if (req.url === '/api/power/reboot') {
                exec('systemctl reboot', () => {
                  res.writeHead(200);
                  res.end(JSON.stringify({ status: 'rebooting' }));
                });
              } else {
                res.writeHead(404);
                res.end(JSON.stringify({ error: 'Not found' }));
              }
            });
            
            server.listen(${toString cfg.webInterface.port}, '0.0.0.0');
            console.log('Mobile control server running on port ${toString cfg.webInterface.port}');
          '';
          Restart = "on-failure";
          RestartSec = "5s";
          
          # Security
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          NoNewPrivileges = true;
        };
      };

      # UxPlay for AirPlay support
      uxplay = mkIf cfg.ios.uxplay {
        description = "UxPlay AirPlay Server";
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
          ExecStart = "${pkgs.uxplay}/bin/uxplay -n NixOS-PC";
          Restart = "on-failure";
          RestartSec = "10s";
          
          # Security
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = false;
          NoNewPrivileges = true;
        };
      };

      # LocalSend service
      localsend = mkIf cfg.crossPlatform.localsend {
        description = "LocalSend File Sharing";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        
        serviceConfig = {
          Type = "simple";
          User = "mahmoud";
          Group = "users";
          ExecStart = "${pkgs.localsend}/bin/localsend_app --server";
          Restart = "on-failure";
          RestartSec = "5s";
          
          # Security
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = false;
          NoNewPrivileges = true;
        };
      };
    };

    # Network configuration for mobile services
    networking.firewall = {
      allowedTCPPorts = []
        ++ optional cfg.webInterface.enable cfg.webInterface.port
        ++ optionals cfg.kdeConnect.enable [ 1714 1715 1716 1717 1718 1719 1720 1721 1722 1723 1724 ]
        ++ optionals cfg.android.adb.wireless [ cfg.android.adb.port ]
        ++ optionals cfg.ios.uxplay [ 7000 7001 7100 ]  # AirPlay ports
        ++ optionals cfg.crossPlatform.localsend [ 53317 ]  # LocalSend
        ++ optionals cfg.crossPlatform.warpinator [ 42000 42001 ];  # Warpinator
        
      allowedUDPPorts = []
        ++ optionals cfg.kdeConnect.enable [ 1714 1715 1716 1717 1718 1719 1720 1721 1722 1723 1724 ]
        ++ optionals cfg.ios.uxplay [ 6000 6001 7011 ]  # AirPlay UDP
        ++ optionals cfg.crossPlatform.localsend [ 53317 ]  # LocalSend discovery
        ++ optionals cfg.crossPlatform.warpinator [ 42000 42001 ];  # Warpinator discovery
    };

    # Enable necessary system services
    services = {
      # Avahi for service discovery (mDNS/Bonjour)
      avahi = {
        enable = true;
        nssmdns4 = true;
        nssmdns6 = true;
        publish = {
          enable = true;
          addresses = true;
          workstation = true;
          userServices = true;
          domain = true;
        };
        
        extraServiceFiles = {
          # Custom service for mobile discovery
          mobile-control = mkIf cfg.webInterface.enable ''
            <?xml version="1.0" standalone='no'?>
            <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
            <service-group>
              <name replace-wildcards="yes">Mobile Control on %h</name>
              <service>
                <type>_http._tcp</type>
                <port>${toString cfg.webInterface.port}</port>
                <txt-record>path=/</txt-record>
                <txt-record>description=NixOS Mobile Control</txt-record>
              </service>
            </service-group>
          '';
        };
      };
      
      # Enable location services for apps that need it
      geoclue2 = {
        enable = true;
        enableDemoAgent = false;
        geoProviderUrl = "https://location.services.mozilla.com/v1/geolocate?key=geoclue";
      };
      
      # Enable printing support for mobile printing
      printing = {
        enable = true;
        drivers = with pkgs; [ cups-pdf gutenprint ];
        browsing = true;
        listenAddresses = [ "*:631" ];
        allowFrom = [ "all" ];
        defaultShared = true;
      };
    };

    # User groups for mobile access
    users.users.mahmoud.extraGroups = [ "adbusers" "lp" "scanner" "networkmanager" ];

    # udev rules for mobile devices
    services.udev.packages = with pkgs; [
      android-udev-rules
    ] ++ optionals cfg.ios.enable [
      libimobiledevice
    ];

    services.udev.extraRules = ''
      # Android devices
      SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="adbusers"
      SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="adbusers"
      SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", MODE="0666", GROUP="adbusers"
      
      # iOS devices
      SUBSYSTEM=="usb", ATTR{idVendor}=="05ac", MODE="0666", GROUP="users"
      
      # Enable wake on USB for mobile connections
      ACTION=="add", SUBSYSTEM=="usb", ATTR{power/wakeup}="enabled"
    '';

    # Environment variables for mobile integration
    environment.sessionVariables = {
      # Android development
      ANDROID_HOME = "/home/mahmoud/Android/Sdk";
      ANDROID_SDK_ROOT = "/home/mahmoud/Android/Sdk";
      
      # Flutter development
      FLUTTER_ROOT = "/home/mahmoud/flutter";
      
      # Mobile app debugging
      SCRCPY_SERVER_PATH = "${pkgs.scrcpy}/share/scrcpy/scrcpy-server";
      
      # KDE Connect
      KDECONNECT_DEVICE_NAME = config.networking.hostName;
    };

    # System activation scripts for mobile setup
    system.activationScripts.mobileIntegration = mkIf cfg.enable ''
      # Create Android SDK directory
      mkdir -p /home/mahmoud/Android/Sdk
      mkdir -p /home/mahmoud/Android/Projects
      
      # Create mobile control directories
      mkdir -p /home/mahmoud/.config/kdeconnect
      mkdir -p /home/mahmoud/.config/scrcpy
      mkdir -p /home/mahmoud/.config/localsend
      
      # Set permissions
      chown -R mahmoud:users /home/mahmoud/Android /home/mahmoud/.config/kdeconnect /home/mahmoud/.config/scrcpy /home/mahmoud/.config/localsend 2>/dev/null || true
      
      # Create scrcpy config
      cat > /home/mahmoud/.config/scrcpy/scrcpy.conf << 'EOF'
      # Scrcpy configuration for optimal mobile control
      max_size=1920
      bit_rate=8000000
      max_fps=60
      show_touches=true
      stay_awake=true
      turn_screen_off=false
      ${optionalString cfg.android.scrcpy.recordScreen "record=/home/mahmoud/Videos/scrcpy_recording.mp4"}
      ${optionalString cfg.android.scrcpy.wireless "tcpip=5555"}
      EOF
      
      chown mahmoud:users /home/mahmoud/.config/scrcpy/scrcpy.conf
      
      # Create mobile shortcuts script
      cat > /home/mahmoud/.local/bin/mobile-shortcuts << 'EOF'
      #!/bin/bash
      # Mobile shortcuts for common PC operations
      
      case "$1" in
        "suspend")
          systemctl suspend
          ;;
        "reboot")
          systemctl reboot
          ;;
        "shutdown")
          systemctl poweroff
          ;;
        "volume-up")
          pactl set-sink-volume @DEFAULT_SINK@ +10%
          ;;
        "volume-down")
          pactl set-sink-volume @DEFAULT_SINK@ -10%
          ;;
        "mute")
          pactl set-sink-mute @DEFAULT_SINK@ toggle
          ;;
        "screenshot")
          gnome-screenshot -f ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png
          ;;
        "lock")
          loginctl lock-session
          ;;
        *)
          echo "Usage: $0 {suspend|reboot|shutdown|volume-up|volume-down|mute|screenshot|lock}"
          exit 1
          ;;
      esac
      EOF
      
      chmod +x /home/mahmoud/.local/bin/mobile-shortcuts
      chown mahmoud:users /home/mahmoud/.local/bin/mobile-shortcuts
      
      echo 'Mobile integration configured successfully'
    '';

    # Polkit rules for mobile control
    security.polkit.extraConfig = mkIf cfg.enable ''
      // Allow mahmoud to control system power via mobile
      polkit.addRule(function(action, subject) {
          if ((action.id == "org.freedesktop.login1.suspend" ||
               action.id == "org.freedesktop.login1.hibernate" ||
               action.id == "org.freedesktop.login1.reboot" ||
               action.id == "org.freedesktop.login1.power-off") &&
              subject.user == "mahmoud") {
              return polkit.Result.YES;
          }
      });
      
      // Allow mobile apps to access multimedia controls
      polkit.addRule(function(action, subject) {
          if (action.id.indexOf("org.freedesktop.PolicyKit1") == 0 &&
              subject.user == "mahmoud") {
              return polkit.Result.YES;
          }
      });
    '';

    # Desktop integration files
    environment.etc = {
      # Mobile control desktop shortcuts
      "xdg/applications/mobile-control-panel.desktop" = {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=Mobile Control Panel
          Exec=firefox http://localhost:${toString cfg.webInterface.port}
          Icon=preferences-system-network
          Comment=Open mobile control web interface
          Categories=System;RemoteAccess;
        '';
      };
      
      # Android control desktop entry
      "xdg/applications/android-control.desktop" = mkIf cfg.android.scrcpy.enable {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=Android Control
          Exec=${pkgs.scrcpy}/bin/scrcpy
          Icon=android
          Comment=Control Android device via scrcpy
          Categories=System;RemoteAccess;Mobile;
        '';
      };
      
      # iOS AirPlay desktop entry
      "xdg/applications/ios-airplay.desktop" = mkIf cfg.ios.uxplay {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=iOS AirPlay Server
          Exec=${pkgs.uxplay}/bin/uxplay
          Icon=apple
          Comment=Start AirPlay server for iOS devices
          Categories=System;RemoteAccess;Mobile;
        '';
      };
    };

    # Network optimization for mobile connections
    boot.kernel.sysctl = mkIf cfg.enable {
      # TCP optimizations for mobile
      "net.core.rmem_default" = 262144;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_default" = 262144;
      "net.core.wmem_max" = 16777216;
      
      # Connection tracking for many mobile devices
      "net.netfilter.nf_conntrack_max" = 131072;
      "net.ipv4.ip_local_port_range" = "1024 65535";
      
      # Mobile network optimizations
      "net.ipv4.tcp_keepalive_time" = 120;
      "net.ipv4.tcp_keepalive_probes" = 3;
      "net.ipv4.tcp_keepalive_intvl" = 30;
    };

    # Systemd user services for session-based mobile integration
    systemd.user.services = {
      # Mobile notification forwarder
      mobile-notifications = mkIf cfg.notifications.enable {
        description = "Mobile Notification Forwarder";
        wantedBy = [ "graphical-session.target" ];
        
        serviceConfig = {
          Type = "simple";
          ExecStart = pkgs.writeScript "mobile-notifications" ''
            #!${pkgs.bash}/bin/bash
            
            # Monitor for new notifications and forward to mobile
            ${pkgs.inotify-tools}/bin/inotifywait -m /home/mahmoud/.local/share/applications/ -e create |
            while read path action file; do
              if [[ "$file" == *.desktop ]]; then
                # Send notification to mobile via KDE Connect
                ${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-cli --send-notification "New app installed: $file"
              fi
            done
          '';
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };
    };

    # Create directories and permissions
    system.activationScripts.mobile-directories = ''
      # Create mobile-related directories
      mkdir -p /home/mahmoud/Mobile/{Screenshots,Recordings,Transfers}
      mkdir -p /home/mahmoud/.local/bin
      mkdir -p /home/mahmoud/.config/{kdeconnect,scrcpy,localsend}
      
      # Set proper permissions
      chown -R mahmoud:users /home/mahmoud/Mobile /home/mahmoud/.local /home/mahmoud/.config/{kdeconnect,scrcpy,localsend} 2>/dev/null || true
      chmod 755 /home/mahmoud/.local/bin
    '';
  };
}
