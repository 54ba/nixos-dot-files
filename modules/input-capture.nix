{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.inputCapture = {
      enable = mkEnableOption "input capture and logging";
      
      keyboard = {
        enable = mkEnableOption "keyboard input logging" // { default = true; };
        
        logLevel = mkOption {
          type = types.enum [ "minimal" "full" "secure" ];
          default = "secure";
          description = ''
            Logging level for keyboard events:
            - minimal: Only key press counts and timing
            - full: Complete key sequences (security risk!)
            - secure: Patterns and metadata without sensitive data
          '';
        };
        
        excludePasswords = mkOption {
          type = types.bool;
          default = true;
          description = "Exclude password field inputs from logging";
        };
        
        bufferSize = mkOption {
          type = types.int;
          default = 1000;
          description = "Number of events to buffer in memory";
        };
      };
      
      mouse = {
        enable = mkEnableOption "mouse input logging" // { default = true; };
        
        trackClicks = mkOption {
          type = types.bool;
          default = true;
          description = "Track mouse click events";
        };
        
        trackMovement = mkOption {
          type = types.bool;
          default = false;
          description = "Track detailed mouse movement (high data volume)";
        };
        
        trackScroll = mkOption {
          type = types.bool;
          default = true;
          description = "Track scroll events";
        };
        
        sampleRate = mkOption {
          type = types.int;
          default = 10;
          description = "Mouse movement sampling rate (Hz) when tracking movement";
        };
      };
      
      window = {
        enable = mkEnableOption "window focus and activity logging" // { default = true; };
        
        trackWindowSwitches = mkOption {
          type = types.bool;
          default = true;
          description = "Log window focus changes";
        };
        
        trackApplications = mkOption {
          type = types.bool;
          default = true;
          description = "Log application launches and closures";
        };
        
        trackTitles = mkOption {
          type = types.bool;
          default = false;
          description = "Log window titles (may contain sensitive information)";
        };
      };
      
      system = {
        enable = mkEnableOption "system event logging" // { default = true; };
        
        trackScreenshots = mkOption {
          type = types.bool;
          default = true;
          description = "Log when screenshots are taken";
        };
        
        trackClipboard = mkOption {
          type = types.bool;
          default = false;
          description = "Log clipboard changes (security risk!)";
        };
        
        trackUSB = mkOption {
          type = types.bool;
          default = true;
          description = "Log USB device connections/disconnections";
        };
      };
      
      storage = {
        path = mkOption {
          type = types.str;
          default = "/var/lib/input-capture";
          description = "Directory to store input logs";
        };
        
        format = mkOption {
          type = types.enum [ "json" "sqlite" "both" ];
          default = "both";
          description = "Log storage format";
        };
        
        compression = mkOption {
          type = types.bool;
          default = true;
          description = "Compress log files";
        };
        
        maxSize = mkOption {
          type = types.str;
          default = "1G";
          description = "Maximum size for input logs";
        };
        
        retentionDays = mkOption {
          type = types.int;
          default = 7;
          description = "Days to keep input logs";
        };
      };
      
      privacy = {
        anonymize = mkOption {
          type = types.bool;
          default = true;
          description = "Anonymize sensitive data in logs";
        };
        
        hashSensitive = mkOption {
          type = types.bool;
          default = true;
          description = "Hash potentially sensitive strings";
        };
        
        excludeApplications = mkOption {
          type = types.listOf types.str;
          default = [ "keepassxc" "bitwarden" "gnome-keyring" "kwallet" ];
          description = "Applications to exclude from input capture";
        };
      };
      
      realtime = {
        enable = mkEnableOption "real-time event streaming";
        
        socketPath = mkOption {
          type = types.str;
          default = "/tmp/input-capture.sock";
          description = "Unix socket path for real-time event streaming";
        };
        
        bufferEvents = mkOption {
          type = types.int;
          default = 100;
          description = "Number of events to buffer for real-time streaming";
        };
      };
    };
  };

  config = mkIf config.custom.inputCapture.enable {
    # Install input capture packages
    environment.systemPackages = with pkgs; [
      # Input event tools
      evtest
      # input-utils  # Package was dropped since it was unmaintained
      xdotool
      ydotool
      wtype
      
      # System monitoring
      acpi
      lsof
      psmisc
      procps
      
      # Database and processing
      sqlite
      jq
      
      # Wayland tools
      wlrctl
      wl-clipboard
      
      # X11 tools (for compatibility)
      xorg.xev
      xorg.xwininfo
      xorg.xprop
      
      # Python packages for input processing
      python3
      python3Packages.evdev
      python3Packages.pynput
      python3Packages.sqlite-utils
      python3Packages.watchdog
      python3Packages.psutil
    ];

    # Create input capture storage directory
    systemd.tmpfiles.rules = [
      "d ${config.custom.inputCapture.storage.path} 0700 root root -"
      "d ${config.custom.inputCapture.storage.path}/raw 0700 root root -"
      "d ${config.custom.inputCapture.storage.path}/processed 0700 root root -"
      "d ${config.custom.inputCapture.storage.path}/sessions 0700 root root -"
    ];

    # Input capture daemon
    systemd.services.input-capture = {
      description = "Input Capture Service";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      
      serviceConfig = {
        Type = "notify";
        ExecStart = pkgs.writeScript "input-capture-daemon" ''
          #!/bin/bash
          
          # Environment setup
          export CAPTURE_PATH="${config.custom.inputCapture.storage.path}"
          export CAPTURE_FORMAT="${config.custom.inputCapture.storage.format}"
          export LOG_LEVEL="${config.custom.inputCapture.keyboard.logLevel}"
          export PRIVACY_MODE="${if config.custom.inputCapture.privacy.anonymize then "1" else "0"}"
          export BUFFER_SIZE="${toString config.custom.inputCapture.keyboard.bufferSize}"
          
          # Keyboard settings
          export KEYBOARD_ENABLED="${if config.custom.inputCapture.keyboard.enable then "1" else "0"}"
          export EXCLUDE_PASSWORDS="${if config.custom.inputCapture.keyboard.excludePasswords then "1" else "0"}"
          
          # Mouse settings
          export MOUSE_ENABLED="${if config.custom.inputCapture.mouse.enable then "1" else "0"}"
          export TRACK_CLICKS="${if config.custom.inputCapture.mouse.trackClicks then "1" else "0"}"
          export TRACK_MOVEMENT="${if config.custom.inputCapture.mouse.trackMovement then "1" else "0"}"
          export TRACK_SCROLL="${if config.custom.inputCapture.mouse.trackScroll then "1" else "0"}"
          export MOUSE_SAMPLE_RATE="${toString config.custom.inputCapture.mouse.sampleRate}"
          
          # Window settings
          export WINDOW_ENABLED="${if config.custom.inputCapture.window.enable then "1" else "0"}"
          export TRACK_WINDOW_SWITCHES="${if config.custom.inputCapture.window.trackWindowSwitches then "1" else "0"}"
          export TRACK_APPLICATIONS="${if config.custom.inputCapture.window.trackApplications then "1" else "0"}"
          export TRACK_TITLES="${if config.custom.inputCapture.window.trackTitles then "1" else "0"}"
          
          # System settings
          export SYSTEM_ENABLED="${if config.custom.inputCapture.system.enable then "1" else "0"}"
          export TRACK_SCREENSHOTS="${if config.custom.inputCapture.system.trackScreenshots then "1" else "0"}"
          export TRACK_CLIPBOARD="${if config.custom.inputCapture.system.trackClipboard then "1" else "0"}"
          export TRACK_USB="${if config.custom.inputCapture.system.trackUSB then "1" else "0"}"
          
          # Excluded applications
          export EXCLUDED_APPS="${concatStringsSep "," config.custom.inputCapture.privacy.excludeApplications}"
          
          # Real-time settings
          export REALTIME_ENABLED="${if config.custom.inputCapture.realtime.enable then "1" else "0"}"
          export SOCKET_PATH="${config.custom.inputCapture.realtime.socketPath}"
          
          # Start the input capture daemon
          exec ${pkgs.python3}/bin/python3 ${./scripts/input-capture-daemon.py}
        '';
        
        Restart = "on-failure";
        RestartSec = "5s";
        User = "root";
        Group = "input";
        
        # Security settings
        NoNewPrivileges = false;
        ProtectSystem = "strict";
        ReadWritePaths = [ 
          config.custom.inputCapture.storage.path 
          "/dev/input"
          "/proc"
          "/sys"
          config.custom.inputCapture.realtime.socketPath
        ];
        ProtectHome = true;
        
        # Capabilities needed for input device access
        CapabilityBoundingSet = [ "CAP_SYS_ADMIN" "CAP_DAC_READ_SEARCH" ];
        AmbientCapabilities = [ "CAP_SYS_ADMIN" "CAP_DAC_READ_SEARCH" ];
      };
      
      environment = {
        DISPLAY = ":0";
        XDG_RUNTIME_DIR = "/run/user/1000";
        WAYLAND_DISPLAY = "wayland-0";
      };
    };

    # Window manager integration service
    systemd.services.window-tracker = mkIf config.custom.inputCapture.window.enable {
      description = "Window Activity Tracker";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" "input-capture.service" ];
      
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeScript "window-tracker" ''
          #!/bin/bash
          export CAPTURE_PATH="${config.custom.inputCapture.storage.path}"
          export TRACK_TITLES="${if config.custom.inputCapture.window.trackTitles then "1" else "0"}"
          
          # Detect desktop environment and use appropriate tools
          if [ -n "$WAYLAND_DISPLAY" ]; then
            exec ${pkgs.python3}/bin/python3 ${./scripts/wayland-window-tracker.py}
          else
            exec ${pkgs.python3}/bin/python3 ${./scripts/x11-window-tracker.py}
          fi
        '';
        
        Restart = "on-failure";
        RestartSec = "3s";
        User = "root";
      };
      
      environment = {
        DISPLAY = ":0";
        XDG_RUNTIME_DIR = "/run/user/1000";
        WAYLAND_DISPLAY = "wayland-0";
      };
    };

    # USB device monitor
    systemd.services.usb-monitor = mkIf config.custom.inputCapture.system.trackUSB {
      description = "USB Device Monitor";
      wantedBy = [ "multi-user.target" ];
      after = [ "input-capture.service" ];
      
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeScript "usb-monitor" ''
          #!/bin/bash
          export CAPTURE_PATH="${config.custom.inputCapture.storage.path}"
          
          # Monitor udev events for USB devices
          exec ${pkgs.udev}/bin/udevadm monitor --subsystem-match=usb --property | \
          ${pkgs.python3}/bin/python3 ${./scripts/usb-monitor.py}
        '';
        
        Restart = "on-failure";
        RestartSec = "5s";
        User = "root";
      };
    };

    # Log processing and cleanup service
    systemd.services.input-log-processor = {
      description = "Process and clean input capture logs";
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "input-log-processor" ''
          #!/bin/bash
          
          CAPTURE_PATH="${config.custom.inputCapture.storage.path}"
          RETENTION_DAYS="${toString config.custom.inputCapture.storage.retentionDays}"
          MAX_SIZE="${config.custom.inputCapture.storage.maxSize}"
          COMPRESSION="${if config.custom.inputCapture.storage.compression then "1" else "0"}"
          
          cd "$CAPTURE_PATH" || exit 1
          
          # Clean old files
          find . -type f -mtime +$RETENTION_DAYS -delete
          
          # Compress logs if enabled
          if [ "$COMPRESSION" = "1" ]; then
            find ./raw -name "*.json" -not -name "*.gz" -mtime +1 -exec gzip {} \;
          fi
          
          # Check disk usage and clean if over limit
          USAGE=$(du -sh . | cut -f1)
          echo "Current input capture storage usage: $USAGE"
          
          # Process raw logs into structured format
          ${pkgs.python3}/bin/python3 ${./scripts/log-processor.py}
        '';
        User = "root";
      };
    };

    # Timer for log processing
    systemd.timers.input-log-processor = {
      description = "Process input logs every hour";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
        RandomizedDelaySec = "10m";
      };
    };

    # Input device permissions
    services.udev.extraRules = ''
      # Allow access to input devices for capture
      SUBSYSTEM=="input", GROUP="input", MODE="0664"
      KERNEL=="event*", GROUP="input", MODE="0664"
      
      # Special handling for keyboard devices
      SUBSYSTEM=="input", ATTRS{name}=="*keyboard*", GROUP="input", MODE="0664"
      SUBSYSTEM=="input", ATTRS{name}=="*Keyboard*", GROUP="input", MODE="0664"
      
      # Mouse and touchpad devices
      SUBSYSTEM=="input", ATTRS{name}=="*mouse*", GROUP="input", MODE="0664"
      SUBSYSTEM=="input", ATTRS{name}=="*Mouse*", GROUP="input", MODE="0664"
      SUBSYSTEM=="input", ATTRS{name}=="*touchpad*", GROUP="input", MODE="0664"
    '';

    # Create input group
    users.groups.input = {};
    users.users.root.extraGroups = [ "input" ];

    # Kernel modules for input device access
    boot.kernelModules = [ "evdev" "uinput" ];

    # Security considerations
    security.sudo.extraRules = [{
      users = [ "root" ];
      commands = [{
        command = "${pkgs.systemd}/bin/systemctl restart input-capture.service";
        options = [ "NOPASSWD" ];
      }];
    }];

    # Environment variables
    environment.sessionVariables = {
      INPUT_CAPTURE_ENABLED = "1";
      INPUT_CAPTURE_PATH = config.custom.inputCapture.storage.path;
    };

    # Polkit rules for input capture management
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if ((action.id == "org.freedesktop.systemd1.manage-units" &&
               (action.lookup("unit") == "input-capture.service" ||
                action.lookup("unit") == "window-tracker.service" ||
                action.lookup("unit") == "usb-monitor.service")) &&
              subject.isInGroup("input")) {
              return polkit.Result.YES;
          }
      });
    '';
  };
}
