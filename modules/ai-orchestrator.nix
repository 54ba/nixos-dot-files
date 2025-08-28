{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.aiOrchestrator = {
      enable = mkEnableOption "AI orchestrator for intelligent recording control";
      
      nixai = {
        integration = mkOption {
          type = types.bool;
          default = true;
          description = "Enable nixai integration for AI analysis";
        };
        
        model = mkOption {
          type = types.enum [ "local" "cloud" "hybrid" ];
          default = "local";
          description = "AI model deployment strategy";
        };
        
        endpoint = mkOption {
          type = types.str;
          default = "http://localhost:11434";
          description = "AI service endpoint (Ollama by default)";
        };
        
        models = mkOption {
          type = types.listOf types.str;
          default = [ "llama3.1" "codellama" "vision" ];
          description = "AI models to use for different tasks";
        };
      };
      
      intelligence = {
        contextWindow = mkOption {
          type = types.int;
          default = 300;
          description = "Context window in seconds for decision making";
        };
        
        decisionFrequency = mkOption {
          type = types.int;
          default = 5;
          description = "AI decision making frequency in seconds";
        };
        
        confidence = {
          threshold = mkOption {
            type = types.float;
            default = 0.7;
            description = "Confidence threshold for AI decisions";
          };
          
          adaptiveThreshold = mkOption {
            type = types.bool;
            default = true;
            description = "Dynamically adjust confidence threshold";
          };
        };
        
        learning = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable continuous learning from user patterns";
          };
          
          feedbackIntegration = mkOption {
            type = types.bool;
            default = true;
            description = "Integrate user feedback for model improvement";
          };
        };
      };
      
      recording = {
        autoStart = mkOption {
          type = types.bool;
          default = true;
          description = "Automatically start recording based on AI analysis";
        };
        
        autoStop = mkOption {
          type = types.bool;
          default = true;
          description = "Automatically stop recording when appropriate";
        };
        
        smartSegmentation = mkOption {
          type = types.bool;
          default = true;
          description = "Intelligently segment recordings based on content";
        };
        
        triggers = mkOption {
          type = types.listOf types.str;
          default = [
            "presentation_mode"
            "coding_session"
            "meeting_detected"
            "tutorial_creation"
            "error_troubleshooting"
          ];
          description = "Scenarios that trigger automatic recording";
        };
        
        qualityAdaptation = mkOption {
          type = types.bool;
          default = true;
          description = "Adapt recording quality based on content type";
        };
      };
      
      analysis = {
        realtime = mkOption {
          type = types.bool;
          default = true;
          description = "Enable real-time content analysis";
        };
        
        screenAnalysis = mkOption {
          type = types.bool;
          default = true;
          description = "Analyze screen content for context understanding";
        };
        
        audioAnalysis = mkOption {
          type = types.bool;
          default = true;
          description = "Analyze audio for speech and context detection";
        };
        
        activityClassification = mkOption {
          type = types.bool;
          default = true;
          description = "Classify user activities in real-time";
        };
        
        sentimentAnalysis = mkOption {
          type = types.bool;
          default = false;
          description = "Analyze sentiment from audio and text";
        };
      };
      
      effects = {
        autoApply = mkOption {
          type = types.bool;
          default = true;
          description = "Automatically apply effects based on content";
        };
        
        types = mkOption {
          type = types.listOf types.str;
          default = [
            "zoom_enhancement"
            "highlight_cursor"
            "smooth_transitions"
            "auto_crop"
            "noise_reduction"
            "brightness_adjustment"
          ];
          description = "Types of effects to automatically apply";
        };
        
        intensity = mkOption {
          type = types.enum [ "subtle" "moderate" "prominent" ];
          default = "moderate";
          description = "Intensity level for automatic effects";
        };
      };
      
      streaming = {
        autoOptimize = mkOption {
          type = types.bool;
          default = true;
          description = "Automatically optimize stream settings";
        };
        
        sceneDetection = mkOption {
          type = types.bool;
          default = true;
          description = "Automatically switch scenes based on content";
        };
        
        audioDucking = mkOption {
          type = types.bool;
          default = true;
          description = "Automatically adjust audio levels";
        };
        
        chatIntegration = mkOption {
          type = types.bool;
          default = false;
          description = "Integrate with streaming platform chat";
        };
      };
      
      notifications = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable AI orchestrator notifications";
        };
        
        verbosity = mkOption {
          type = types.enum [ "minimal" "normal" "detailed" ];
          default = "normal";
          description = "Notification verbosity level";
        };
        
        channels = mkOption {
          type = types.listOf (types.enum [ "desktop" "system" "log" "api" ]);
          default = [ "desktop" "system" ];
          description = "Notification delivery channels";
        };
      };
      
      privacy = {
        dataProcessing = mkOption {
          type = types.enum [ "local_only" "anonymized" "full" ];
          default = "local_only";
          description = "Data processing privacy level";
        };
        
        excludeApps = mkOption {
          type = types.listOf types.str;
          default = [ "keepassxc" "bitwarden" "banking" "private" ];
          description = "Applications to exclude from AI analysis";
        };
        
        sensitiveContentDetection = mkOption {
          type = types.bool;
          default = true;
          description = "Detect and protect sensitive content";
        };
      };
    };
  };

  config = mkIf config.custom.aiOrchestrator.enable {
    # Install AI orchestrator packages
    environment.systemPackages = with pkgs; [
      # AI and ML packages
      python3
      python3Packages.torch
      python3Packages.transformers
      python3Packages.pillow
      python3Packages.opencv4
      python3Packages.soundfile
      python3Packages.librosa
      python3Packages.scikit-image
      
      # Computer vision
      # python3Packages.ultralytics  # YOLO - may not be available
      # python3Packages.mediapipe     # Not available in nixpkgs
      
      # Natural language processing
      # python3Packages.spacy         # May not be available
      # python3Packages.nltk          # May not be available
      
      # API clients
      python3Packages.openai
      # python3Packages.anthropic     # May not be available
      # python3Packages.ollama        # May not be available
      
      # Real-time processing
      # python3Packages.asyncio-mqtt  # Deprecated - replaced by aiomqtt
      python3Packages.websockets
      python3Packages.fastapi
      python3Packages.uvicorn
      
      # Desktop integration
      python3Packages.pydbus
      python3Packages.notify2
      python3Packages.pyqt6
      
      # Image and video processing
      imagemagick
      ffmpeg-full
      tesseract
      
      # Utilities
      jq
      curl
      wget
    ];

    # Create orchestrator storage directory
    systemd.tmpfiles.rules = [
      "d /var/lib/ai-orchestrator 0755 root root -"
      "d /var/lib/ai-orchestrator/models 0755 root root -"
      "d /var/lib/ai-orchestrator/cache 0755 root root -"
      "d /var/lib/ai-orchestrator/logs 0755 root root -"
      "d /var/lib/ai-orchestrator/analysis 0755 root root -"
      "d /var/lib/ai-orchestrator/feedback 0755 root root -"
    ];

    # Main AI orchestrator service
    systemd.services.ai-orchestrator = {
      description = "AI Recording Orchestrator";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ 
        "graphical-session.target" 
        "desktop-recorder.service" 
        "input-capture.service"
        "data-collector.service"
      ];
      
      serviceConfig = {
        Type = "notify";
        ExecStart = pkgs.writeScript "ai-orchestrator" ''
          #!/bin/bash
          
          # AI Configuration
          export NIXAI_ENABLED="${if config.custom.aiOrchestrator.nixai.integration then "1" else "0"}"
          export AI_MODEL="${config.custom.aiOrchestrator.nixai.model}"
          export AI_ENDPOINT="${config.custom.aiOrchestrator.nixai.endpoint}"
          export AI_MODELS="${concatStringsSep "," config.custom.aiOrchestrator.nixai.models}"
          
          # Intelligence settings
          export CONTEXT_WINDOW="${toString config.custom.aiOrchestrator.intelligence.contextWindow}"
          export DECISION_FREQUENCY="${toString config.custom.aiOrchestrator.intelligence.decisionFrequency}"
          export CONFIDENCE_THRESHOLD="${toString config.custom.aiOrchestrator.intelligence.confidence.threshold}"
          export ADAPTIVE_THRESHOLD="${if config.custom.aiOrchestrator.intelligence.confidence.adaptiveThreshold then "1" else "0"}"
          export LEARNING_ENABLED="${if config.custom.aiOrchestrator.intelligence.learning.enable then "1" else "0"}"
          
          # Recording control
          export AUTO_START_RECORDING="${if config.custom.aiOrchestrator.recording.autoStart then "1" else "0"}"
          export AUTO_STOP_RECORDING="${if config.custom.aiOrchestrator.recording.autoStop then "1" else "0"}"
          export SMART_SEGMENTATION="${if config.custom.aiOrchestrator.recording.smartSegmentation then "1" else "0"}"
          export RECORDING_TRIGGERS="${concatStringsSep "," config.custom.aiOrchestrator.recording.triggers}"
          export QUALITY_ADAPTATION="${if config.custom.aiOrchestrator.recording.qualityAdaptation then "1" else "0"}"
          
          # Analysis configuration
          export REALTIME_ANALYSIS="${if config.custom.aiOrchestrator.analysis.realtime then "1" else "0"}"
          export SCREEN_ANALYSIS="${if config.custom.aiOrchestrator.analysis.screenAnalysis then "1" else "0"}"
          export AUDIO_ANALYSIS="${if config.custom.aiOrchestrator.analysis.audioAnalysis then "1" else "0"}"
          export ACTIVITY_CLASSIFICATION="${if config.custom.aiOrchestrator.analysis.activityClassification then "1" else "0"}"
          
          # Effects and streaming
          export AUTO_APPLY_EFFECTS="${if config.custom.aiOrchestrator.effects.autoApply then "1" else "0"}"
          export EFFECT_TYPES="${concatStringsSep "," config.custom.aiOrchestrator.effects.types}"
          export EFFECT_INTENSITY="${config.custom.aiOrchestrator.effects.intensity}"
          export AUTO_OPTIMIZE_STREAM="${if config.custom.aiOrchestrator.streaming.autoOptimize then "1" else "0"}"
          
          # Privacy settings
          export PRIVACY_LEVEL="${config.custom.aiOrchestrator.privacy.dataProcessing}"
          export EXCLUDED_APPS="${concatStringsSep "," config.custom.aiOrchestrator.privacy.excludeApps}"
          export SENSITIVE_DETECTION="${if config.custom.aiOrchestrator.privacy.sensitiveContentDetection then "1" else "0"}"
          
          # Notification settings
          export NOTIFICATIONS_ENABLED="${if config.custom.aiOrchestrator.notifications.enable then "1" else "0"}"
          export NOTIFICATION_VERBOSITY="${config.custom.aiOrchestrator.notifications.verbosity}"
          export NOTIFICATION_CHANNELS="${concatStringsSep "," config.custom.aiOrchestrator.notifications.channels}"
          
          # Data integration paths
          export RECORDING_PATH="${if config.custom.desktopRecording.enable then config.custom.desktopRecording.storage.path else "/dev/null"}"
          export INPUT_CAPTURE_PATH="${if config.custom.inputCapture.enable then config.custom.inputCapture.storage.path else "/dev/null"}"
          export PIPELINE_PATH="${if config.custom.dataPipeline.enable then config.custom.dataPipeline.storage.path else "/dev/null"}"
          
          exec ${pkgs.python3}/bin/python3 /etc/nixos/modules/scripts/ai-orchestrator.py
        '';
        
        Restart = "on-failure";
        RestartSec = "15s";
        User = "root";
        Group = "orchestrator";
        
        # Resource limits
        MemoryMax = "4G";
        CPUQuota = "300%";
        
        # Security settings
        ProtectSystem = "strict";
        ReadWritePaths = [ 
          "/var/lib/ai-orchestrator"
          "/tmp"
        ] ++ optionals config.custom.desktopRecording.enable [ config.custom.desktopRecording.storage.path ]
          ++ optionals config.custom.inputCapture.enable [ config.custom.inputCapture.storage.path ]
          ++ optionals config.custom.dataPipeline.enable [ config.custom.dataPipeline.storage.path ];
        ProtectHome = true;
        NoNewPrivileges = true;
        
        # GPU access for AI processing
        SupplementaryGroups = [ "video" "render" ];
      };
      
      environment = {
        DISPLAY = ":0";
        XDG_RUNTIME_DIR = "/run/user/1000";
        WAYLAND_DISPLAY = "wayland-0";
        CUDA_VISIBLE_DEVICES = "0";
      };
    };

    # Screen analysis service
    systemd.services.screen-analyzer = mkIf config.custom.aiOrchestrator.analysis.screenAnalysis {
      description = "AI Screen Content Analyzer";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" "ai-orchestrator.service" ];
      
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeScript "screen-analyzer" ''
          #!/bin/bash
          
          export AI_ENDPOINT="${config.custom.aiOrchestrator.nixai.endpoint}"
          export ANALYSIS_FREQUENCY="2"  # Analyze screen every 2 seconds
          export PRIVACY_LEVEL="${config.custom.aiOrchestrator.privacy.dataProcessing}"
          export EXCLUDED_APPS="${concatStringsSep "," config.custom.aiOrchestrator.privacy.excludeApps}"
          
          exec ${pkgs.python3}/bin/python3 /etc/nixos/modules/scripts/screen-analyzer.py
        '';
        
        Restart = "on-failure";
        RestartSec = "10s";
        User = "root";
        Group = "orchestrator";
        
        MemoryMax = "2G";
        CPUQuota = "150%";
      };
      
      environment = {
        DISPLAY = ":0";
        WAYLAND_DISPLAY = "wayland-0";
      };
    };

    # Audio analysis service
    systemd.services.audio-analyzer = mkIf config.custom.aiOrchestrator.analysis.audioAnalysis {
      description = "AI Audio Content Analyzer";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" "ai-orchestrator.service" ];
      
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeScript "audio-analyzer" ''
          #!/bin/bash
          
          export AI_ENDPOINT="${config.custom.aiOrchestrator.nixai.endpoint}"
          export SENTIMENT_ANALYSIS="${if config.custom.aiOrchestrator.analysis.sentimentAnalysis then "1" else "0"}"
          export PRIVACY_LEVEL="${config.custom.aiOrchestrator.privacy.dataProcessing}"
          
          exec ${pkgs.python3}/bin/python3 /etc/nixos/modules/scripts/audio-analyzer.py
        '';
        
        Restart = "on-failure";
        RestartSec = "10s";
        User = "root";
        Group = "orchestrator";
        
        MemoryMax = "1G";
        CPUQuota = "100%";
      };
    };

    # Decision engine service
    systemd.services.decision-engine = {
      description = "AI Decision Engine for Recording Control";
      wantedBy = [ "multi-user.target" ];
      after = [ "ai-orchestrator.service" ];
      wants = [ "ai-orchestrator.service" ];
      
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeScript "decision-engine" ''
          #!/bin/bash
          
          export AI_ENDPOINT="${config.custom.aiOrchestrator.nixai.endpoint}"
          export DECISION_FREQUENCY="${toString config.custom.aiOrchestrator.intelligence.decisionFrequency}"
          export CONFIDENCE_THRESHOLD="${toString config.custom.aiOrchestrator.intelligence.confidence.threshold}"
          export RECORDING_TRIGGERS="${concatStringsSep "," config.custom.aiOrchestrator.recording.triggers}"
          
          exec ${pkgs.python3}/bin/python3 /etc/nixos/modules/scripts/decision-engine.py
        '';
        
        Restart = "on-failure";
        RestartSec = "5s";
        User = "root";
        Group = "orchestrator";
        
        MemoryMax = "512M";
        CPUQuota = "50%";
      };
    };

    # Model management service
    systemd.services.model-manager = mkIf config.custom.aiOrchestrator.nixai.integration {
      description = "AI Model Management Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "model-manager" ''
          #!/bin/bash
          
          export AI_ENDPOINT="${config.custom.aiOrchestrator.nixai.endpoint}"
          export AI_MODELS="${concatStringsSep "," config.custom.aiOrchestrator.nixai.models}"
          export MODEL_PATH="/var/lib/ai-orchestrator/models"
          
          # Download and manage AI models
          ${pkgs.python3}/bin/python3 /etc/nixos/modules/scripts/model-manager.py
        '';
        
        User = "root";
        Group = "orchestrator";
        MemoryMax = "8G";
        TimeoutStartSec = "3600";  # Allow 1 hour for model downloads
      };
    };

    # Feedback collection service
    systemd.services.feedback-collector = mkIf config.custom.aiOrchestrator.intelligence.learning.feedbackIntegration {
      description = "User Feedback Collection for AI Learning";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "ai-orchestrator.service" ];
      
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeScript "feedback-collector" ''
          #!/bin/bash
          
          export FEEDBACK_PATH="/var/lib/ai-orchestrator/feedback"
          export LEARNING_ENABLED="${if config.custom.aiOrchestrator.intelligence.learning.enable then "1" else "0"}"
          
          exec ${pkgs.python3}/bin/python3 /etc/nixos/modules/scripts/feedback-collector.py
        '';
        
        Restart = "on-failure";
        RestartSec = "30s";
        User = "root";
        Group = "orchestrator";
        
        MemoryMax = "256M";
      };
      
      environment = {
        DISPLAY = ":0";
        XDG_RUNTIME_DIR = "/run/user/1000";
      };
    };

    # Integration with Ollama service if local AI is used
    services.ollama = mkIf (config.custom.aiOrchestrator.nixai.integration && 
                           config.custom.aiOrchestrator.nixai.model == "local") {
      enable = true;
      acceleration = if config.custom.ai-services.nvidia.enable then "cuda" else "cpu";
      environmentVariables = {
        OLLAMA_MAX_LOADED_MODELS = "3";
        OLLAMA_NUM_PARALLEL = "4";
        OLLAMA_MAX_QUEUE = "10";
      };
      
      models = "/var/lib/ai-orchestrator/models";
    };

    # Create orchestrator user group
    users.groups.orchestrator = {};
    users.users.root.extraGroups = [ "orchestrator" "video" "audio" "render" ];

    # Desktop notifications integration
    services.dbus.packages = [ pkgs.libnotify ];

    # Environment variables
    environment.sessionVariables = {
      AI_ORCHESTRATOR_ENABLED = "1";
      AI_ORCHESTRATOR_ENDPOINT = config.custom.aiOrchestrator.nixai.endpoint;
      AI_ORCHESTRATOR_PATH = "/var/lib/ai-orchestrator";
    };

    # GPU access for AI processing
    hardware.graphics = mkIf (config.custom.ai-services.nvidia.enable) {
      enable = true;
      enable32Bit = true;
    };

    # Polkit rules for orchestrator management
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if ((action.id == "org.freedesktop.systemd1.manage-units" &&
               (action.lookup("unit").match(/ai-.*\.service/) ||
                action.lookup("unit").match(/.*-analyzer\.service/) ||
                action.lookup("unit").match(/decision-.*\.service/) ||
                action.lookup("unit").match(/model-.*\.service/))) &&
              subject.isInGroup("orchestrator")) {
              return polkit.Result.YES;
          }
      });
      
      polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.NetworkManager.control" &&
              subject.isInGroup("orchestrator")) {
              return polkit.Result.YES;
          }
      });
    '';

    # System optimization for AI workloads (avoid duplicate sysctl settings)
    boot.kernel.sysctl = {
      "kernel.sched_rt_runtime_us" = lib.mkDefault 950000;
      "kernel.sched_rt_period_us" = lib.mkDefault 1000000;
    };
  };
}
