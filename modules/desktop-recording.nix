{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.desktopRecording = {
      enable = mkEnableOption "desktop recording capabilities";
      
      recorder = {
        backend = mkOption {
          type = types.enum [ "obs" "ffmpeg" "both" ];
          default = "both";
          description = "Recording backend to use";
        };
        
        quality = mkOption {
          type = types.enum [ "low" "medium" "high" "ultra" ];
          default = "high";
          description = "Recording quality preset";
        };
        
        fps = mkOption {
          type = types.int;
          default = 60;
          description = "Recording frame rate";
        };
        
        format = mkOption {
          type = types.enum [ "mp4" "mkv" "webm" "mov" ];
          default = "mp4";
          description = "Output video format";
        };
        
        codec = mkOption {
          type = types.enum [ "h264" "h265" "av1" "vp9" ];
          default = "h264";
          description = "Video codec to use";
        };
        
        hwAcceleration = mkOption {
          type = types.bool;
          default = true;
          description = "Enable hardware acceleration for encoding";
        };
      };
      
      audio = {
        enable = mkEnableOption "audio recording" // { default = true; };
        
        sources = mkOption {
          type = types.listOf (types.enum [ "desktop" "microphone" "both" ]);
          default = [ "both" ];
          description = "Audio sources to capture";
        };
        
        quality = mkOption {
          type = types.enum [ "low" "medium" "high" ];
          default = "high";
          description = "Audio quality setting";
        };
      };
      
      storage = {
        path = mkOption {
          type = types.str;
          default = "/var/lib/desktop-recordings";
          description = "Directory to store recordings";
        };
        
        maxSize = mkOption {
          type = types.str;
          default = "50G";
          description = "Maximum storage size for recordings";
        };
        
        autoCleanup = mkOption {
          type = types.bool;
          default = true;
          description = "Automatically clean up old recordings";
        };
        
        retentionDays = mkOption {
          type = types.int;
          default = 30;
          description = "Days to keep recordings before cleanup";
        };
      };
      
      streaming = {
        enable = mkEnableOption "streaming capabilities";
        
        platforms = mkOption {
          type = types.listOf types.str;
          default = [ "twitch" "youtube" "custom" ];
          description = "Streaming platforms to support";
        };
        
        bitrate = mkOption {
          type = types.int;
          default = 6000;
          description = "Streaming bitrate in kbps";
        };
      };
    };
  };

  config = mkIf config.custom.desktopRecording.enable {
    # Install recording packages
    environment.systemPackages = with pkgs; [
      # Core recording tools
      obs-studio
      obs-studio-plugins.wlrobs
      obs-studio-plugins.obs-backgroundremoval
      obs-studio-plugins.obs-pipewire-audio-capture
      ffmpeg-full
      
      # Screen capture utilities
      slurp  # Screen area selection
      grim   # Screenshot utility
      wf-recorder  # Wayland screen recorder
      
      # Audio tools
      pavucontrol
      pulseaudio
      pipewire
      wireplumber
      
      # Video processing
      kdePackages.kdenlive  # Use Qt6 version instead of removed alias
      # davinci-resolve  # May not be available
      
      # Streaming tools
      streamlink
      yt-dlp
      
      # Additional utilities
      imagemagick
      tesseract  # OCR for screenshot analysis
    ] ++ (optionals (config.custom.desktopRecording.recorder.backend == "obs" || 
                    config.custom.desktopRecording.recorder.backend == "both") [
      # OBS plugins and extensions
      obs-studio-plugins.obs-vkcapture
      obs-studio-plugins.obs-gstreamer
    ]);

    # Audio system configuration
    services.pipewire = mkIf config.custom.desktopRecording.audio.enable {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
      
      wireplumber.enable = true;
      
      # Low latency audio configuration
      extraConfig.pipewire."99-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 32;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 32;
        };
      };
    };

    # Create recording storage directory
    systemd.tmpfiles.rules = [
      "d ${config.custom.desktopRecording.storage.path} 0755 root root -"
      "d ${config.custom.desktopRecording.storage.path}/sessions 0755 root root -"
      "d ${config.custom.desktopRecording.storage.path}/clips 0755 root root -"
      "d ${config.custom.desktopRecording.storage.path}/streams 0755 root root -"
    ];

    # Recording service
    systemd.services.desktop-recorder = {
      description = "Desktop Recording Service";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      
      serviceConfig = {
        Type = "dbus";
        BusName = "org.nixos.DesktopRecorder";
        ExecStart = pkgs.writeScript "desktop-recorder-daemon" ''
          #!/bin/bash
          export RECORDING_PATH="${config.custom.desktopRecording.storage.path}"
          export RECORDING_QUALITY="${config.custom.desktopRecording.recorder.quality}"
          export RECORDING_FPS="${toString config.custom.desktopRecording.recorder.fps}"
          export RECORDING_FORMAT="${config.custom.desktopRecording.recorder.format}"
          export RECORDING_CODEC="${config.custom.desktopRecording.recorder.codec}"
          
          # Start the recording daemon
          ${pkgs.python3}/bin/python3 ${./scripts/recording-daemon.py}
        '';
        Restart = "on-failure";
        RestartSec = "5s";
        User = "root";
        Group = "video";
      };
      
      environment = {
        DISPLAY = ":0";
        XDG_RUNTIME_DIR = "/run/user/1000";
        WAYLAND_DISPLAY = "wayland-0";
      };
    };

    # Cleanup service for old recordings
    systemd.services.recording-cleanup = mkIf config.custom.desktopRecording.storage.autoCleanup {
      description = "Clean up old desktop recordings";
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "recording-cleanup" ''
          #!/bin/bash
          find "${config.custom.desktopRecording.storage.path}" -type f -name "*.${config.custom.desktopRecording.recorder.format}" -mtime +${toString config.custom.desktopRecording.storage.retentionDays} -delete
          find "${config.custom.desktopRecording.storage.path}" -type f -name "*.log" -mtime +${toString config.custom.desktopRecording.storage.retentionDays} -delete
        '';
        User = "root";
      };
    };

    # Timer for cleanup service
    systemd.timers.recording-cleanup = mkIf config.custom.desktopRecording.storage.autoCleanup {
      description = "Run recording cleanup daily";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };

    # OBS Studio configuration
    environment.etc."obs-studio/global.ini" = mkIf (config.custom.desktopRecording.recorder.backend == "obs" || 
                                                   config.custom.desktopRecording.recorder.backend == "both") {
      text = let
        qualitySettings = {
          low = { width = 1280; height = 720; bitrate = 2500; };
          medium = { width = 1920; height = 1080; bitrate = 5000; };
          high = { width = 1920; height = 1080; bitrate = 8000; };
          ultra = { width = 2560; height = 1440; bitrate = 12000; };
        };
        settings = qualitySettings.${config.custom.desktopRecording.recorder.quality};
      in ''
        [General]
        FirstRun=false
        
        [Video]
        OutputCX=${toString settings.width}
        OutputCY=${toString settings.height}
        BaseCX=${toString settings.width}
        BaseCY=${toString settings.height}
        FPSCommon=60
        
        [Output]
        RecFilePath=${config.custom.desktopRecording.storage.path}/sessions
        RecFormat=${config.custom.desktopRecording.recorder.format}
        RecEncoder=${if config.custom.desktopRecording.recorder.hwAcceleration then "nvenc_h264" else "x264"}
        
        [AdvOut]
        RecRB=true
        RecRBSize=1024
      '';
    };

    # Environment variables for recording
    environment.sessionVariables = {
      OBS_USE_EGL = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      DESKTOP_RECORDING_ENABLED = "1";
    };

    # Enable necessary kernel modules for capture
    boot.kernelModules = [ "v4l2loopback" "snd-aloop" ];
    boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

    # V4L2 loopback configuration for virtual cameras
    boot.extraModprobeConfig = ''
      options v4l2loopback devices=4 video_nr=10,11,12,13 card_label="Virtual Camera 1","Virtual Camera 2","Virtual Camera 3","Virtual Camera 4" exclusive_caps=1
    '';

    # User groups for recording access
    users.groups.recording = {};
    users.users.root.extraGroups = [ "video" "audio" "recording" ];
    
    # Polkit rules for recording access
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if ((action.id == "org.freedesktop.systemd1.manage-units" &&
               action.lookup("unit") == "desktop-recorder.service") &&
              subject.isInGroup("recording")) {
              return polkit.Result.YES;
          }
      });
    '';
  };
}
