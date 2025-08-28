{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.intelligentRecordingSystem = {
      enable = mkEnableOption "intelligent recording system with AI orchestration";
      
      profile = mkOption {
        type = types.enum [ "minimal" "standard" "professional" "streaming" "development" ];
        default = "standard";
        description = ''
          Recording system profile:
          - minimal: Basic recording with light AI features
          - standard: Balanced features for general use
          - professional: Full features for content creation
          - streaming: Optimized for live streaming
          - development: Focused on coding and development workflows
        '';
      };
      
      components = {
        desktopRecording = mkOption {
          type = types.bool;
          default = true;
          description = "Enable desktop recording capabilities";
        };
        
        inputCapture = mkOption {
          type = types.bool;
          default = true;
          description = "Enable input capture and logging";
        };
        
        dataPipeline = mkOption {
          type = types.bool;
          default = true;
          description = "Enable data processing pipeline";
        };
        
        aiOrchestrator = mkOption {
          type = types.bool;
          default = true;
          description = "Enable AI orchestration and intelligence";
        };
      };
      
      features = {
        autoRecording = mkOption {
          type = types.bool;
          default = true;
          description = "Enable automatic recording based on AI analysis";
        };
        
        smartEffects = mkOption {
          type = types.bool;
          default = true;
          description = "Enable intelligent effects and enhancements";
        };
        
        realTimeAnalysis = mkOption {
          type = types.bool;
          default = true;
          description = "Enable real-time content analysis";
        };
        
        streamingIntegration = mkOption {
          type = types.bool;
          default = false;
          description = "Enable streaming platform integration";
        };
        
        cloudSync = mkOption {
          type = types.bool;
          default = false;
          description = "Enable cloud synchronization of recordings";
        };
        
        privacyMode = mkOption {
          type = types.bool;
          default = true;
          description = "Enable enhanced privacy protection";
        };
      };
      
      storage = {
        centralPath = mkOption {
          type = types.str;
          default = "/var/lib/intelligent-recording";
          description = "Central storage path for all recording data";
        };
        
        totalQuota = mkOption {
          type = types.str;
          default = "100G";
          description = "Total storage quota for the recording system";
        };
        
        distribution = {
          recordings = mkOption {
            type = types.int;
            default = 60;
            description = "Percentage of storage for video recordings";
          };
          
          logs = mkOption {
            type = types.int;
            default = 20;
            description = "Percentage of storage for input logs";
          };
          
          analysis = mkOption {
            type = types.int;
            default = 15;
            description = "Percentage of storage for analysis data";
          };
          
          cache = mkOption {
            type = types.int;
            default = 5;
            description = "Percentage of storage for cache and temporary files";
          };
        };
        
        backup = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable automatic backup of important recordings";
          };
          
          location = mkOption {
            type = types.str;
            default = "/backup/recordings";
            description = "Backup storage location";
          };
          
          schedule = mkOption {
            type = types.str;
            default = "daily";
            description = "Backup schedule (daily, weekly, monthly)";
          };
        };
      };
      
      performance = {
        priority = mkOption {
          type = types.enum [ "low" "normal" "high" "realtime" ];
          default = "normal";
          description = "System priority for recording processes";
        };
        
        cpuCores = mkOption {
          type = types.int;
          default = 0;  # 0 means auto-detect
          description = "Number of CPU cores to allocate (0 for auto-detect)";
        };
        
        memoryLimit = mkOption {
          type = types.str;
          default = "8G";
          description = "Total memory limit for recording system";
        };
        
        gpuAcceleration = mkOption {
          type = types.bool;
          default = true;
          description = "Enable GPU acceleration when available";
        };
      };
      
      integration = {
        nixai = mkOption {
          type = types.bool;
          default = true;
          description = "Enable nixai integration for AI capabilities";
        };
        
        development = {
          vscode = mkOption {
            type = types.bool;
            default = false;
            description = "Enable VS Code integration";
          };
          
          github = mkOption {
            type = types.bool;
            default = false;
            description = "Enable GitHub integration for code recording";
          };
          
          documentation = mkOption {
            type = types.bool;
            default = false;
            description = "Enable automatic documentation generation";
          };
        };
        
        streaming = {
          obs = mkOption {
            type = types.bool;
            default = true;
            description = "Enable OBS Studio integration";
          };
          
          platforms = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Streaming platforms to integrate with";
          };
        };
      };
      
      security = {
        encryption = mkOption {
          type = types.bool;
          default = true;
          description = "Encrypt sensitive recordings and data";
        };
        
        accessControl = mkOption {
          type = types.bool;
          default = true;
          description = "Enable role-based access control";
        };
        
        auditLogging = mkOption {
          type = types.bool;
          default = true;
          description = "Enable audit logging for security events";
        };
        
        sandboxing = mkOption {
          type = types.bool;
          default = true;
          description = "Enable process sandboxing for security";
        };
      };
      
      ui = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable graphical user interface";
        };
        
        type = mkOption {
          type = types.enum [ "gtk" "qt" "web" ];
          default = "gtk";
          description = "UI framework to use";
        };
        
        systray = mkOption {
          type = types.bool;
          default = true;
          description = "Enable system tray integration";
        };
        
        notifications = mkOption {
          type = types.bool;
          default = true;
          description = "Enable desktop notifications";
        };
      };
    };
  };

  config = mkIf config.custom.intelligentRecordingSystem.enable {
    # Profile-based configurations
    custom.desktopRecording = mkIf config.custom.intelligentRecordingSystem.components.desktopRecording {
      enable = true;
      
      recorder = {
        backend = if config.custom.intelligentRecordingSystem.profile == "professional" then "both"
                 else if config.custom.intelligentRecordingSystem.profile == "streaming" then "obs"
                 else "ffmpeg";
        
        quality = if config.custom.intelligentRecordingSystem.profile == "minimal" then "medium"
                 else if config.custom.intelligentRecordingSystem.profile == "professional" then "ultra"
                 else "high";
        
        fps = if config.custom.intelligentRecordingSystem.profile == "streaming" then 60
              else if config.custom.intelligentRecordingSystem.profile == "minimal" then 30
              else 60;
        
        hwAcceleration = config.custom.intelligentRecordingSystem.performance.gpuAcceleration;
      };
      
      storage = {
        path = "${config.custom.intelligentRecordingSystem.storage.centralPath}/recordings";
        maxSize = "${toString (config.custom.intelligentRecordingSystem.storage.distribution.recordings * 
                  (if config.custom.intelligentRecordingSystem.storage.totalQuota == "100G" then 100 else 50) / 100)}G";
      };
      
      streaming.enable = config.custom.intelligentRecordingSystem.features.streamingIntegration;
    };

    custom.inputCapture = mkIf config.custom.intelligentRecordingSystem.components.inputCapture {
      enable = true;
      
      keyboard = {
        enable = true;
        logLevel = if config.custom.intelligentRecordingSystem.features.privacyMode then "secure"
                   else if config.custom.intelligentRecordingSystem.profile == "development" then "full"
                   else "minimal";
        excludePasswords = config.custom.intelligentRecordingSystem.features.privacyMode;
      };
      
      mouse = {
        enable = true;
        trackMovement = config.custom.intelligentRecordingSystem.profile == "professional" || 
                       config.custom.intelligentRecordingSystem.profile == "development";
      };
      
      storage = {
        path = "${config.custom.intelligentRecordingSystem.storage.centralPath}/input-logs";
        maxSize = "${toString (config.custom.intelligentRecordingSystem.storage.distribution.logs * 
                  (if config.custom.intelligentRecordingSystem.storage.totalQuota == "100G" then 100 else 50) / 100)}G";
      };
      
      privacy = {
        anonymize = config.custom.intelligentRecordingSystem.features.privacyMode;
        excludeApplications = if config.custom.intelligentRecordingSystem.features.privacyMode then
          [ "keepassxc" "bitwarden" "gnome-keyring" "kwallet" "banking" "private" ]
          else [ "keepassxc" "bitwarden" ];
      };
    };

    custom.dataPipeline = mkIf config.custom.intelligentRecordingSystem.components.dataPipeline {
      enable = true;
      
      processing = {
        realtime = config.custom.intelligentRecordingSystem.features.realTimeAnalysis;
        workers = if config.custom.intelligentRecordingSystem.performance.cpuCores == 0 then 4
                  else config.custom.intelligentRecordingSystem.performance.cpuCores;
        memoryLimit = "2G";
      };
      
      storage = {
        path = "${config.custom.intelligentRecordingSystem.storage.centralPath}/pipeline";
        maxSize = "${toString (config.custom.intelligentRecordingSystem.storage.distribution.analysis * 
                  (if config.custom.intelligentRecordingSystem.storage.totalQuota == "100G" then 100 else 50) / 100)}G";
      };
      
      analysis = {
        enable = config.custom.intelligentRecordingSystem.features.realTimeAnalysis;
        ml.enable = config.custom.intelligentRecordingSystem.profile != "minimal";
      };
      
      api.enable = config.custom.intelligentRecordingSystem.components.aiOrchestrator;
    };

    custom.aiOrchestrator = mkIf config.custom.intelligentRecordingSystem.components.aiOrchestrator {
      enable = true;
      
      nixai.integration = config.custom.intelligentRecordingSystem.integration.nixai;
      
      recording = {
        autoStart = config.custom.intelligentRecordingSystem.features.autoRecording;
        autoStop = config.custom.intelligentRecordingSystem.features.autoRecording;
        smartSegmentation = config.custom.intelligentRecordingSystem.features.smartEffects;
        
        triggers = if config.custom.intelligentRecordingSystem.profile == "development" then
          [ "coding_session" "error_troubleshooting" "tutorial_creation" ]
          else if config.custom.intelligentRecordingSystem.profile == "streaming" then
          [ "presentation_mode" "meeting_detected" "streaming_session" ]
          else [ "presentation_mode" "meeting_detected" "tutorial_creation" ];
      };
      
      analysis = {
        realtime = config.custom.intelligentRecordingSystem.features.realTimeAnalysis;
        screenAnalysis = config.custom.intelligentRecordingSystem.features.smartEffects;
        audioAnalysis = config.custom.intelligentRecordingSystem.features.smartEffects;
      };
      
      effects.autoApply = config.custom.intelligentRecordingSystem.features.smartEffects;
      
      streaming = {
        autoOptimize = config.custom.intelligentRecordingSystem.features.streamingIntegration;
        sceneDetection = config.custom.intelligentRecordingSystem.features.streamingIntegration;
      };
      
      privacy = {
        dataProcessing = if config.custom.intelligentRecordingSystem.features.privacyMode then "local_only"
                        else "anonymized";
        sensitiveContentDetection = config.custom.intelligentRecordingSystem.features.privacyMode;
      };
    };

    # Create central storage structure
    systemd.tmpfiles.rules = [
      "d ${config.custom.intelligentRecordingSystem.storage.centralPath} 0755 root root -"
      "d ${config.custom.intelligentRecordingSystem.storage.centralPath}/recordings 0755 root root -"
      "d ${config.custom.intelligentRecordingSystem.storage.centralPath}/input-logs 0755 root root -"
      "d ${config.custom.intelligentRecordingSystem.storage.centralPath}/pipeline 0755 root root -"
      "d ${config.custom.intelligentRecordingSystem.storage.centralPath}/cache 0755 root root -"
      "d ${config.custom.intelligentRecordingSystem.storage.centralPath}/exports 0755 root root -"
      "d ${config.custom.intelligentRecordingSystem.storage.centralPath}/backups 0755 root root -"
    ];

    # Central management service
    systemd.services.recording-system-manager = {
      description = "Intelligent Recording System Manager";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      
      serviceConfig = {
        Type = "notify";
        ExecStart = pkgs.writeScript "recording-system-manager" ''
          #!/bin/bash
          
          # System configuration
          export SYSTEM_PROFILE="${config.custom.intelligentRecordingSystem.profile}"
          export CENTRAL_PATH="${config.custom.intelligentRecordingSystem.storage.centralPath}"
          export TOTAL_QUOTA="${config.custom.intelligentRecordingSystem.storage.totalQuota}"
          export MEMORY_LIMIT="${config.custom.intelligentRecordingSystem.performance.memoryLimit}"
          export PRIORITY="${config.custom.intelligentRecordingSystem.performance.priority}"
          
          # Feature flags
          export AUTO_RECORDING="${if config.custom.intelligentRecordingSystem.features.autoRecording then "1" else "0"}"
          export SMART_EFFECTS="${if config.custom.intelligentRecordingSystem.features.smartEffects then "1" else "0"}"
          export REALTIME_ANALYSIS="${if config.custom.intelligentRecordingSystem.features.realTimeAnalysis then "1" else "0"}"
          export STREAMING_INTEGRATION="${if config.custom.intelligentRecordingSystem.features.streamingIntegration then "1" else "0"}"
          export PRIVACY_MODE="${if config.custom.intelligentRecordingSystem.features.privacyMode then "1" else "0"}"
          
          # Component status
          export DESKTOP_RECORDING="${if config.custom.intelligentRecordingSystem.components.desktopRecording then "1" else "0"}"
          export INPUT_CAPTURE="${if config.custom.intelligentRecordingSystem.components.inputCapture then "1" else "0"}"
          export DATA_PIPELINE="${if config.custom.intelligentRecordingSystem.components.dataPipeline then "1" else "0"}"
          export AI_ORCHESTRATOR="${if config.custom.intelligentRecordingSystem.components.aiOrchestrator then "1" else "0"}"
          
          # Security settings
          export ENCRYPTION="${if config.custom.intelligentRecordingSystem.security.encryption then "1" else "0"}"
          export ACCESS_CONTROL="${if config.custom.intelligentRecordingSystem.security.accessControl then "1" else "0"}"
          export AUDIT_LOGGING="${if config.custom.intelligentRecordingSystem.security.auditLogging then "1" else "0"}"
          
          # UI settings
          export UI_ENABLED="${if config.custom.intelligentRecordingSystem.ui.enable then "1" else "0"}"
          export UI_TYPE="${config.custom.intelligentRecordingSystem.ui.type}"
          export SYSTRAY="${if config.custom.intelligentRecordingSystem.ui.systray then "1" else "0"}"
          
          exec ${pkgs.python3}/bin/python3 ${./scripts/recording-system-manager.py}
        '';
        
        Restart = "on-failure";
        RestartSec = "10s";
        User = "root";
        Group = "recording-system";
        
        # Resource management
        MemoryMax = config.custom.intelligentRecordingSystem.performance.memoryLimit;
        CPUQuota = if config.custom.intelligentRecordingSystem.performance.priority == "realtime" then "800%"
                   else if config.custom.intelligentRecordingSystem.performance.priority == "high" then "400%"
                   else "200%";
        
        # Security
        ProtectSystem = if config.custom.intelligentRecordingSystem.security.sandboxing then "strict" else "yes";
        ReadWritePaths = [ config.custom.intelligentRecordingSystem.storage.centralPath ];
        ProtectHome = config.custom.intelligentRecordingSystem.security.sandboxing;
        NoNewPrivileges = config.custom.intelligentRecordingSystem.security.sandboxing;
      };
      
      environment = {
        DISPLAY = ":0";
        XDG_RUNTIME_DIR = "/run/user/1000";
        WAYLAND_DISPLAY = "wayland-0";
      };
    };

    # Storage quota management
    systemd.services.storage-quota-manager = {
      description = "Recording System Storage Quota Manager";
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "storage-quota-manager" ''
          #!/bin/bash
          
          CENTRAL_PATH="${config.custom.intelligentRecordingSystem.storage.centralPath}"
          TOTAL_QUOTA="${config.custom.intelligentRecordingSystem.storage.totalQuota}"
          
          # Convert quota to bytes for calculations
          QUOTA_BYTES=$(echo "$TOTAL_QUOTA" | sed 's/G//' | awk '{print $1 * 1024 * 1024 * 1024}')
          
          # Check current usage
          CURRENT_USAGE=$(du -sb "$CENTRAL_PATH" | cut -f1)
          
          if [ "$CURRENT_USAGE" -gt "$QUOTA_BYTES" ]; then
            echo "Storage quota exceeded: $(($CURRENT_USAGE / 1024 / 1024 / 1024))G / $TOTAL_QUOTA"
            
            # Cleanup old files starting with least important
            find "$CENTRAL_PATH/cache" -type f -mtime +1 -delete
            find "$CENTRAL_PATH/input-logs" -type f -mtime +7 -delete
            find "$CENTRAL_PATH/recordings" -type f -mtime +30 -delete
          fi
          
          echo "Current storage usage: $(($CURRENT_USAGE / 1024 / 1024 / 1024))G / $TOTAL_QUOTA"
        '';
        User = "root";
        Group = "recording-system";
      };
    };

    # Timer for storage management
    systemd.timers.storage-quota-manager = {
      description = "Check storage quota hourly";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };

    # Backup service
    systemd.services.recording-backup = mkIf config.custom.intelligentRecordingSystem.storage.backup.enable {
      description = "Recording System Backup Service";
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "recording-backup" ''
          #!/bin/bash
          
          CENTRAL_PATH="${config.custom.intelligentRecordingSystem.storage.centralPath}"
          BACKUP_PATH="${config.custom.intelligentRecordingSystem.storage.backup.location}"
          
          mkdir -p "$BACKUP_PATH"
          
          # Create timestamped backup
          TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
          BACKUP_DIR="$BACKUP_PATH/backup_$TIMESTAMP"
          
          # Backup important recordings (marked by AI or user)
          rsync -av --include="**/important/**" --include="**/starred/**" --exclude="*" \
            "$CENTRAL_PATH/recordings/" "$BACKUP_DIR/recordings/"
          
          # Backup analysis data
          rsync -av --include="**/models/**" --include="**/analysis/**" --exclude="*" \
            "$CENTRAL_PATH/pipeline/" "$BACKUP_DIR/pipeline/"
          
          # Cleanup old backups (keep last 10)
          cd "$BACKUP_PATH"
          ls -dt backup_* | tail -n +11 | xargs rm -rf
          
          echo "Backup completed: $BACKUP_DIR"
        '';
        User = "root";
        Group = "recording-system";
      };
    };

    # Timer for backups
    systemd.timers.recording-backup = mkIf config.custom.intelligentRecordingSystem.storage.backup.enable {
      description = "Run recording system backup";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = config.custom.intelligentRecordingSystem.storage.backup.schedule;
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };

    # Install UI packages based on configuration
    environment.systemPackages = with pkgs; [
      # Core system packages
      python3
      python3Packages.pydbus
      python3Packages.pygobject3
      python3Packages.psutil
      
      # Notification support
      libnotify
      
      # System monitoring
      htop
      iotop
      nethogs
      
      # Media utilities
      mediainfo
      exiftool
      
      # Backup utilities
      rsync
      rclone
    ] ++ optionals (config.custom.intelligentRecordingSystem.ui.enable && 
                   config.custom.intelligentRecordingSystem.ui.type == "gtk") [
      gtk4
      python3Packages.pygobject3
      glib
    ] ++ optionals (config.custom.intelligentRecordingSystem.ui.enable && 
                   config.custom.intelligentRecordingSystem.ui.type == "qt") [
      qt6.qtbase
      python3Packages.pyqt6
    ] ++ optionals config.custom.intelligentRecordingSystem.integration.development.vscode [
      vscode-extensions.ms-python.python
    ];

    # Create system user group
    users.groups.recording-system = {};
    users.users.root.extraGroups = [ "recording-system" ];

    # Environment variables
    environment.sessionVariables = {
      INTELLIGENT_RECORDING_ENABLED = "1";
      INTELLIGENT_RECORDING_PATH = config.custom.intelligentRecordingSystem.storage.centralPath;
      INTELLIGENT_RECORDING_PROFILE = config.custom.intelligentRecordingSystem.profile;
    };

    # Performance optimizations
    boot.kernel.sysctl = mkIf (config.custom.intelligentRecordingSystem.performance.priority == "realtime") {
      "kernel.sched_rt_runtime_us" = 950000;
      "kernel.sched_rt_period_us" = 1000000;
      "vm.swappiness" = 1;
    };

    # Security configurations
    security.pam.loginLimits = mkIf (config.custom.intelligentRecordingSystem.performance.priority == "realtime") [
      {
        domain = "@recording-system";
        type = "soft";
        item = "rtprio";
        value = "99";
      }
      {
        domain = "@recording-system";
        type = "hard";
        item = "rtprio";
        value = "99";
      }
    ];

    # Polkit rules for system management
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if ((action.id == "org.freedesktop.systemd1.manage-units" &&
               action.lookup("unit").match(/recording-.*\.service/)) &&
              subject.isInGroup("recording-system")) {
              return polkit.Result.YES;
          }
      });
    '';
  };
}
