{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.steamos-mobile-suite;
in

{
  imports = [
    ./steamos-gaming.nix
    ./ssh-remote-access.nix
    ./remote-control.nix
    ./mobile-integration.nix
  ];

  options.custom.steamos-mobile-suite = {
    enable = mkEnableOption "Complete SteamOS-like gaming system with mobile control";

    profile = mkOption {
      type = types.enum [ "gaming" "balanced" "productivity" "server" ];
      default = "balanced";
      description = ''
        System profile that determines default configurations:
        - gaming: Optimized for gaming performance
        - balanced: Good balance of gaming and productivity
        - productivity: Focus on remote work and productivity
        - server: Headless server setup with remote access
      '';
    };

    features = {
      steamGaming = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SteamOS-like gaming environment";
      };

      remoteAccess = mkOption {
        type = types.bool;
        default = true;
        description = "Enable remote access capabilities";
      };

      mobileControl = mkOption {
        type = types.bool;
        default = true;
        description = "Enable mobile device control and integration";
      };

      fileSharing = mkOption {
        type = types.bool;
        default = true;
        description = "Enable cross-device file sharing";
      };

      automation = mkOption {
        type = types.bool;
        default = true;
        description = "Enable automation and smart features";
      };
    };

    security = {
      level = mkOption {
        type = types.enum [ "minimal" "standard" "enhanced" "paranoid" ];
        default = "standard";
        description = "Security level for remote access";
      };

      requireKeys = mkOption {
        type = types.bool;
        default = true;
        description = "Require SSH keys for authentication";
      };

      allowMobileAuth = mkOption {
        type = types.bool;
        default = true;
        description = "Allow mobile device authentication";
      };

      encryptTraffic = mkOption {
        type = types.bool;
        default = true;
        description = "Encrypt all remote traffic";
      };
    };

    networking = {
      optimizeForGaming = mkOption {
        type = types.bool;
        default = true;
        description = "Apply gaming network optimizations";
      };

      optimizeForMobile = mkOption {
        type = types.bool;
        default = true;
        description = "Apply mobile-friendly network settings";
      };

      enableDiscovery = mkOption {
        type = types.bool;
        default = true;
        description = "Enable service discovery for mobile apps";
      };
    };

    performance = {
      prioritizeGaming = mkOption {
        type = types.bool;
        default = true;
        description = "Prioritize gaming performance";
      };

      lowLatency = mkOption {
        type = types.bool;
        default = true;
        description = "Enable low-latency optimizations";
      };

      hardwareAcceleration = mkOption {
        type = types.bool;
        default = true;
        description = "Enable hardware acceleration for video encoding";
      };
    };

    monitoring = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable system and connection monitoring";
      };

      mobileNotifications = mkOption {
        type = types.bool;
        default = true;
        description = "Send system alerts to mobile devices";
      };

      performanceMetrics = mkOption {
        type = types.bool;
        default = true;
        description = "Collect and display performance metrics";
      };
    };
  };

  config = mkIf cfg.enable {
    # Profile-based configurations
    custom.steamos-gaming = {
      enable = cfg.features.steamGaming;
      
      # Profile-specific gaming settings
      steam = {
        enable = cfg.features.steamGaming;
        remotePlay = cfg.features.remoteAccess;
        bigPicture = cfg.profile == "gaming";
        proton = {
          enable = true;
          ge = cfg.profile == "gaming" || cfg.profile == "balanced";
        };
      };
      
      performance = {
        enable = cfg.performance.prioritizeGaming;
        gamemode = cfg.performance.prioritizeGaming;
        mangohud = cfg.monitoring.performanceMetrics;
        lowLatency = cfg.performance.lowLatency;
      };
      
      networking = {
        gaming = cfg.networking.optimizeForGaming;
      };
    };

    # SSH remote access configuration
    custom.ssh-remote-access = {
      enable = cfg.features.remoteAccess;
      
      server = {
        enable = cfg.features.remoteAccess;
        passwordAuthentication = !cfg.security.requireKeys;
        permitRootLogin = if cfg.security.level == "paranoid" then "no" 
                         else if cfg.security.level == "enhanced" then "prohibit-password"
                         else "no";
        maxAuthTries = if cfg.security.level == "paranoid" then 2
                      else if cfg.security.level == "enhanced" then 3
                      else 5;
      };
      
      security = {
        enable = cfg.security.level != "minimal";
        fail2ban = cfg.security.level == "enhanced" || cfg.security.level == "paranoid";
      };
      
      mobileAccess = {
        enable = cfg.features.mobileControl;
        keepAlive = cfg.networking.optimizeForMobile;
        compression = cfg.networking.optimizeForMobile;
      };
      
      monitoring = {
        enable = cfg.monitoring.enable;
        alerts = cfg.monitoring.mobileNotifications;
      };
    };

    # Remote control configuration
    custom.remote-control = {
      enable = cfg.features.remoteAccess;
      
      rustdesk = {
        enable = cfg.features.remoteAccess;
        encryption = cfg.security.encryptTraffic;
        quality = if cfg.performance.prioritizeGaming then "high" else "balanced";
      };
      
      wayvnc = {
        enable = config.services.xserver.displayManager.gdm.wayland;
        quality = if cfg.performance.prioritizeGaming then "high" else "medium";
      };
      
      mobileApps = {
        enable = cfg.features.mobileControl;
        scrcpy = cfg.features.mobileControl;
        kdeConnect = cfg.features.mobileControl;
      };
      
      fileSharing = {
        enable = cfg.features.fileSharing;
        syncthing = cfg.features.fileSharing;
      };
      
      performance = {
        enable = cfg.performance.lowLatency;
        hardwareAcceleration = cfg.performance.hardwareAcceleration;
      };
      
      security = {
        enable = cfg.security.level != "minimal";
        encryption = cfg.security.encryptTraffic;
      };
    };

    # Mobile integration configuration
    custom.mobile-integration = {
      enable = cfg.features.mobileControl;
      
      kdeConnect = {
        enable = cfg.features.mobileControl;
        features = {
          notifications = cfg.monitoring.mobileNotifications;
          clipboard = true;
          fileTransfer = cfg.features.fileSharing;
          mediaControl = true;
          remoteInput = true;
        };
      };
      
      android = {
        enable = cfg.features.mobileControl;
        scrcpy = {
          enable = cfg.features.mobileControl;
          wireless = cfg.networking.optimizeForMobile;
        };
        adb = {
          enable = cfg.features.mobileControl;
          wireless = cfg.networking.optimizeForMobile;
        };
      };
      
      ios = {
        enable = cfg.features.mobileControl;
        uxplay = cfg.features.remoteAccess;
      };
      
      crossPlatform = {
        enable = cfg.features.fileSharing;
        localsend = cfg.features.fileSharing;
        warpinator = cfg.features.fileSharing;
      };
      
      webInterface = {
        enable = cfg.features.remoteAccess && cfg.features.mobileControl;
        authentication = cfg.security.level != "minimal";
      };
      
      notifications = {
        enable = cfg.monitoring.mobileNotifications;
      };
      
      automation = {
        enable = cfg.features.automation;
        shortcuts = cfg.features.automation;
      };
    };

    # Global system optimizations based on profile
    system.activationScripts.steamosMobileSuite = ''
      echo "Setting up SteamOS Mobile Suite..."
      echo "Profile: ${cfg.profile}"
      echo "Security Level: ${cfg.security.level}"
      
      # Create suite-specific directories
      mkdir -p /home/mahmoud/SteamOS-Mobile/{Gaming,Remote,Mobile,Logs}
      mkdir -p /var/log/steamos-mobile-suite
      
      # Set permissions
      chown -R mahmoud:users /home/mahmoud/SteamOS-Mobile 2>/dev/null || true
      
      # Create management scripts
      cat > /home/mahmoud/.local/bin/steamos-control << 'EOF'
      #!/bin/bash
      # SteamOS Mobile Suite Control Script
      
      SUITE_DIR="/home/mahmoud/SteamOS-Mobile"
      LOG_FILE="/var/log/steamos-mobile-suite/control.log"
      
      log_action() {
          echo "$(date): $1" >> "$LOG_FILE"
      }
      
      case "$1" in
          "start-gaming")
              log_action "Starting gaming mode"
              systemctl --user start gamemode 2>/dev/null || true
              ${pkgs.libnotify}/bin/notify-send "Gaming Mode" "Gaming optimizations enabled"
              ;;
          "start-remote")
              log_action "Starting remote access services"
              systemctl start wayvnc rustdesk-server 2>/dev/null || true
              ${pkgs.libnotify}/bin/notify-send "Remote Access" "Remote control services started"
              ;;
          "start-mobile")
              log_action "Starting mobile integration"
              systemctl --user start kdeconnectd 2>/dev/null || true
              systemctl start uxplay localsend 2>/dev/null || true
              ${pkgs.libnotify}/bin/notify-send "Mobile Control" "Mobile integration enabled"
              ;;
          "status")
              echo "=== SteamOS Mobile Suite Status ==="
              echo "Gaming Services:"
              systemctl is-active steam gamemode 2>/dev/null || echo "  Not running"
              echo "Remote Services:"
              systemctl is-active wayvnc rustdesk-server 2>/dev/null || echo "  Not running"
              echo "Mobile Services:"
              systemctl --user is-active kdeconnectd 2>/dev/null || echo "  Not running"
              systemctl is-active uxplay localsend 2>/dev/null || echo "  Not running"
              ;;
          "stop-all")
              log_action "Stopping all suite services"
              systemctl stop wayvnc rustdesk-server uxplay localsend 2>/dev/null || true
              systemctl --user stop kdeconnectd 2>/dev/null || true
              ${pkgs.libnotify}/bin/notify-send "Suite Control" "All services stopped"
              ;;
          *)
              echo "Usage: $0 {start-gaming|start-remote|start-mobile|status|stop-all}"
              echo ""
              echo "SteamOS Mobile Suite Control Commands:"
              echo "  start-gaming  - Enable gaming optimizations"
              echo "  start-remote  - Start remote access services"
              echo "  start-mobile  - Start mobile integration"
              echo "  status       - Show service status"
              echo "  stop-all     - Stop all suite services"
              exit 1
              ;;
      esac
      EOF
      
      chmod +x /home/mahmoud/.local/bin/steamos-control
      chown mahmoud:users /home/mahmoud/.local/bin/steamos-control
      
      # Create quick setup script
      cat > /home/mahmoud/.local/bin/quick-setup << 'EOF'
      #!/bin/bash
      # Quick setup for mobile devices
      
      echo "=== SteamOS Mobile Suite Quick Setup ==="
      echo ""
      echo "1. Gaming Mode:"
      echo "   - Steam Big Picture available"
      echo "   - Gaming optimizations enabled"
      echo "   - Controller support active"
      echo ""
      echo "2. Remote Access:"
      echo "   - SSH: ssh mahmoud@$(hostname -I | awk '{print $1}')"
      echo "   - VNC: vnc://$(hostname -I | awk '{print $1}'):5900"
      echo "   - Web: http://$(hostname -I | awk '{print $1}'):8080"
      echo ""
      echo "3. Mobile Integration:"
      echo "   - Install KDE Connect app on mobile"
      echo "   - Install scrcpy for Android control"
      echo "   - Use LocalSend for file transfers"
      echo ""
      echo "4. Quick Commands:"
      echo "   steamos-control start-gaming  # Enable gaming mode"
      echo "   steamos-control start-remote  # Start remote access"
      echo "   steamos-control start-mobile  # Start mobile integration"
      echo "   steamos-control status       # Check service status"
      echo ""
      EOF
      
      chmod +x /home/mahmoud/.local/bin/quick-setup
      chown mahmoud:users /home/mahmoud/.local/bin/quick-setup
      
      echo "SteamOS Mobile Suite configured successfully!"
      echo "Run: /home/mahmoud/.local/bin/quick-setup for setup instructions"
    '';

    # Profile-specific environment variables
    environment.sessionVariables = {
      # Suite identification
      STEAMOS_MOBILE_SUITE = "enabled";
      STEAMOS_PROFILE = cfg.profile;
      
      # Gaming environment
      STEAM_FRAME_FORCE_CLOSE = mkIf (cfg.profile == "gaming") "1";
      DXVK_ASYNC = mkIf (cfg.profile == "gaming") "1";
      
      # Remote access environment
      REMOTE_ACCESS_ENABLED = mkIf cfg.features.remoteAccess "1";
      MOBILE_CONTROL_ENABLED = mkIf cfg.features.mobileControl "1";
    };

    # Desktop entry for suite control
    environment.etc."xdg/applications/steamos-mobile-suite.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=SteamOS Mobile Suite
        Exec=gnome-terminal -- /home/mahmoud/.local/bin/steamos-control status
        Icon=preferences-system
        Comment=Manage SteamOS Mobile Suite services
        Categories=System;Game;RemoteAccess;
        Keywords=steam;gaming;remote;mobile;control;
        
        Actions=StartGaming;StartRemote;StartMobile;ShowStatus;
        
        [Desktop Action StartGaming]
        Name=Start Gaming Mode
        Exec=/home/mahmoud/.local/bin/steamos-control start-gaming
        
        [Desktop Action StartRemote]
        Name=Start Remote Access
        Exec=/home/mahmoud/.local/bin/steamos-control start-remote
        
        [Desktop Action StartMobile]
        Name=Start Mobile Control
        Exec=/home/mahmoud/.local/bin/steamos-control start-mobile
        
        [Desktop Action ShowStatus]
        Name=Show Status
        Exec=gnome-terminal -- /home/mahmoud/.local/bin/steamos-control status
      '';
    };

    # Systemd service for suite management
    systemd.services.steamos-mobile-suite = {
      description = "SteamOS Mobile Suite Manager";
      after = [ "network.target" "graphical-session.target" ];
      wantedBy = [ "multi-user.target" ];
      
      environment = {
        DISPLAY = ":0";
        WAYLAND_DISPLAY = "wayland-0";
        XDG_RUNTIME_DIR = "/run/user/1000";
      };
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        ExecStart = pkgs.writeScript "steamos-suite-start" ''
          #!${pkgs.bash}/bin/bash
          
          LOG_FILE="/var/log/steamos-mobile-suite/startup.log"
          mkdir -p "$(dirname "$LOG_FILE")"
          
          log() {
              echo "$(date): $1" >> "$LOG_FILE"
              echo "$1"
          }
          
          log "Starting SteamOS Mobile Suite (Profile: ${cfg.profile})"
          
          # Profile-specific startup
          case "${cfg.profile}" in
              "gaming")
                  log "Gaming profile: Starting gaming services"
                  systemctl start gamemode 2>/dev/null || true
                  ;;
              "server")
                  log "Server profile: Starting headless services"
                  systemctl start wayvnc 2>/dev/null || true
                  ;;
              "balanced"|"productivity")
                  log "Balanced profile: Starting all services"
                  systemctl start wayvnc 2>/dev/null || true
                  systemctl --user --machine=mahmoud@ start kdeconnectd 2>/dev/null || true
                  ;;
          esac
          
          # Check service status
          log "Service status check completed"
          
          # Send startup notification to mobile if available
          ${optionalString cfg.monitoring.mobileNotifications ''
          if systemctl --user --machine=mahmoud@ is-active kdeconnectd >/dev/null 2>&1; then
              ${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-cli --send-notification "SteamOS Suite started (${cfg.profile} profile)" 2>/dev/null || true
          fi
          ''}
          
          log "SteamOS Mobile Suite startup completed"
        '';
        
        ExecStop = pkgs.writeScript "steamos-suite-stop" ''
          #!${pkgs.bash}/bin/bash
          
          LOG_FILE="/var/log/steamos-mobile-suite/startup.log"
          
          log() {
              echo "$(date): $1" >> "$LOG_FILE"
          }
          
          log "Stopping SteamOS Mobile Suite services"
          
          # Stop services gracefully
          systemctl stop wayvnc rustdesk-server uxplay localsend 2>/dev/null || true
          systemctl --user --machine=mahmoud@ stop kdeconnectd 2>/dev/null || true
          
          log "SteamOS Mobile Suite stopped"
        '';
      };
    };

    # Suite monitoring and health check
    systemd.services.steamos-health-check = mkIf cfg.monitoring.enable {
      description = "SteamOS Mobile Suite Health Check";
      
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = pkgs.writeScript "steamos-health-check" ''
          #!${pkgs.bash}/bin/bash
          
          LOG_FILE="/var/log/steamos-mobile-suite/health.log"
          mkdir -p "$(dirname "$LOG_FILE")"
          
          log() {
              echo "$(date): $1" >> "$LOG_FILE"
          }
          
          # Check gaming services
          if ${pkgs.systemd}/bin/systemctl is-active steam >/dev/null 2>&1; then
              log "Gaming: Steam service active"
          else
              log "Gaming: Steam service inactive"
          fi
          
          # Check remote access
          if ${pkgs.systemd}/bin/systemctl is-active sshd >/dev/null 2>&1; then
              log "Remote: SSH service active"
          else
              log "WARNING: SSH service not running"
          fi
          
          # Check mobile connectivity
          MOBILE_DEVICES=$(${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-cli -l 2>/dev/null | grep -c "reachable" || echo "0")
          log "Mobile: $MOBILE_DEVICES devices connected"
          
          # Performance check
          CPU_LOAD=$(uptime | awk '{print $NF}')
          MEMORY_USAGE=$(free | awk '/^Mem:/{printf "%.1f", $3/$2 * 100.0}')
          log "Performance: CPU load $CPU_LOAD, Memory usage $MEMORY_USAGE%"
          
          # Network connectivity check
          if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
              log "Network: Internet connectivity OK"
          else
              log "WARNING: No internet connectivity"
          fi
          
          ${optionalString cfg.monitoring.mobileNotifications ''
          # Send summary to mobile if critical issues found
          if ! systemctl is-active sshd >/dev/null 2>&1; then
              ${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-cli --send-notification "System Alert: SSH service down" 2>/dev/null || true
          fi
          ''}
        '';
      };
    };

    # Health check timer
    systemd.timers.steamos-health-check = mkIf cfg.monitoring.enable {
      description = "SteamOS Mobile Suite Health Check Timer";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = "*:0/15";  # Every 15 minutes
        Persistent = true;
        RandomizedDelaySec = "60";
      };
    };

    # Log rotation for suite logs
    services.logrotate.settings.steamos-mobile-suite = mkIf cfg.monitoring.enable {
      files = [ "/var/log/steamos-mobile-suite/*.log" ];
      frequency = "weekly";
      rotate = 8;
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
      create = "644 root root";
    };

    # Additional system packages for the complete suite
    environment.systemPackages = with pkgs; [
      # Suite management tools
      htop
      iotop
      nethogs
      bandwhich
      
      # Remote connectivity
      mtr
      iperf3
      speedtest-cli
      
      # Mobile development
      flutter
      android-studio
      
      # Gaming utilities
      steam-tui
      legendary-gl  # Epic Games
      
      # File sharing
      syncthing
      
      # System information
      neofetch
      hardinfo
      
      # Network tools
      nmap
      wireshark
      tcpdump
    ];

    # Enable all necessary base services
    services = {
      # Network time synchronization (important for gaming and mobile)
      ntp.enable = true;
      
      # Hardware sensor monitoring
      lm_sensors.enable = true;
      
      # Automatic service discovery
      avahi.enable = cfg.networking.enableDiscovery;
      
      # Location services for mobile apps
      geoclue2.enable = cfg.features.mobileControl;
    };

    # Final system configuration message
    system.activationScripts.steamos-suite-complete = ''
      echo ""
      echo "========================================="
      echo "  SteamOS Mobile Suite Setup Complete!"
      echo "========================================="
      echo ""
      echo "Profile: ${cfg.profile}"
      echo "Security Level: ${cfg.security.level}"
      echo ""
      echo "Quick Start:"
      echo "  1. Run: quick-setup"
      echo "  2. Use: steamos-control status"
      echo "  3. Check desktop applications menu"
      echo ""
      echo "Mobile Apps to Install:"
      echo "  - KDE Connect (Android/iOS)"
      echo "  - scrcpy client (Android)"
      echo "  - LocalSend (cross-platform)"
      echo "  - RustDesk (cross-platform)"
      echo ""
      echo "========================================="
    '';
  };
}
