{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.dataPipeline = {
      enable = mkEnableOption "data processing pipeline for captured data";
      
      collection = {
        sources = mkOption {
          type = types.listOf (types.enum [ "recordings" "input" "system" "external" ]);
          default = [ "recordings" "input" "system" ];
          description = "Data sources to collect from";
        };
        
        interval = mkOption {
          type = types.int;
          default = 30;
          description = "Data collection interval in seconds";
        };
        
        batchSize = mkOption {
          type = types.int;
          default = 1000;
          description = "Number of events to process in each batch";
        };
        
        compression = mkOption {
          type = types.bool;
          default = true;
          description = "Compress collected data";
        };
      };
      
      processing = {
        realtime = mkOption {
          type = types.bool;
          default = true;
          description = "Enable real-time data processing";
        };
        
        workers = mkOption {
          type = types.int;
          default = 4;
          description = "Number of processing worker threads";
        };
        
        memoryLimit = mkOption {
          type = types.str;
          default = "2G";
          description = "Memory limit for processing workers";
        };
        
        algorithms = mkOption {
          type = types.listOf types.str;
          default = [ "pattern_detection" "anomaly_detection" "activity_classification" ];
          description = "Data processing algorithms to apply";
        };
      };
      
      storage = {
        backend = mkOption {
          type = types.enum [ "sqlite" "postgresql" "timescaledb" "influxdb" ];
          default = "sqlite";
          description = "Database backend for processed data";
        };
        
        path = mkOption {
          type = types.str;
          default = "/var/lib/data-pipeline";
          description = "Base directory for pipeline data";
        };
        
        maxSize = mkOption {
          type = types.str;
          default = "10G";
          description = "Maximum storage size for pipeline data";
        };
        
        retentionPolicy = {
          raw = mkOption {
            type = types.int;
            default = 1;
            description = "Days to keep raw data";
          };
          
          processed = mkOption {
            type = types.int;
            default = 30;
            description = "Days to keep processed data";
          };
          
          aggregated = mkOption {
            type = types.int;
            default = 365;
            description = "Days to keep aggregated data";
          };
        };
        
        partitioning = mkOption {
          type = types.enum [ "daily" "weekly" "monthly" ];
          default = "daily";
          description = "Data partitioning strategy";
        };
      };
      
      analysis = {
        enable = mkEnableOption "advanced data analysis" // { default = true; };
        
        metrics = mkOption {
          type = types.listOf types.str;
          default = [
            "productivity_score"
            "activity_patterns"
            "focus_sessions"
            "application_usage"
            "interaction_frequency"
          ];
          description = "Metrics to calculate and track";
        };
        
        ml = {
          enable = mkEnableOption "machine learning analysis";
          
          models = mkOption {
            type = types.listOf types.str;
            default = [ "activity_classifier" "pattern_detector" "anomaly_detector" ];
            description = "ML models to train and use";
          };
          
          training = {
            auto = mkOption {
              type = types.bool;
              default = true;
              description = "Automatically retrain models";
            };
            
            interval = mkOption {
              type = types.str;
              default = "weekly";
              description = "Model retraining interval";
            };
          };
        };
      };
      
      api = {
        enable = mkEnableOption "data pipeline API server";
        
        port = mkOption {
          type = types.int;
          default = 8080;
          description = "API server port";
        };
        
        auth = mkOption {
          type = types.bool;
          default = true;
          description = "Enable API authentication";
        };
        
        endpoints = mkOption {
          type = types.listOf types.str;
          default = [ "data" "metrics" "analysis" "models" ];
          description = "API endpoints to expose";
        };
      };
      
      streaming = {
        enable = mkEnableOption "real-time data streaming";
        
        protocol = mkOption {
          type = types.enum [ "websocket" "sse" "mqtt" ];
          default = "websocket";
          description = "Streaming protocol to use";
        };
        
        bufferSize = mkOption {
          type = types.int;
          default = 10000;
          description = "Stream buffer size";
        };
      };
      
      monitoring = {
        enable = mkEnableOption "pipeline monitoring and alerting" // { default = true; };
        
        metrics = mkOption {
          type = types.bool;
          default = true;
          description = "Collect pipeline performance metrics";
        };
        
        alerts = mkOption {
          type = types.listOf types.str;
          default = [ "high_memory_usage" "processing_delays" "storage_full" ];
          description = "Alert conditions to monitor";
        };
        
        healthcheck = {
          interval = mkOption {
            type = types.int;
            default = 60;
            description = "Health check interval in seconds";
          };
        };
      };
    };
  };

  config = mkIf config.custom.dataPipeline.enable {
    # Install data pipeline packages
    environment.systemPackages = with pkgs; [
      # Database systems
      sqlite
      postgresql
      
      # Data processing tools
      # apache-kafka  # Package may not be available as 'apache-kafka'
      redis
      
      # Python data science stack
      python3
      python3Packages.pandas
      python3Packages.numpy
      python3Packages.scipy
      python3Packages.scikit-learn
      python3Packages.matplotlib
      python3Packages.seaborn
      python3Packages.plotly
      
      # Database connectors
      python3Packages.psycopg2
      python3Packages.sqlalchemy
      python3Packages.redis
      
      # Machine learning
      python3Packages.tensorflow
      python3Packages.torch
      python3Packages.transformers
      
      # Data formats
      python3Packages.h5py
      python3Packages.pyarrow
      python3Packages.openpyxl
      
      # Monitoring
      python3Packages.prometheus-client
      python3Packages.psutil
      
      # API framework
      python3Packages.fastapi
      python3Packages.uvicorn
      python3Packages.websockets
      
      # Utilities
      jq
      yq-go
      curl
      wget
    ] ++ optionals (config.custom.dataPipeline.storage.backend == "postgresql") [
      postgresql
    ] ++ optionals (config.custom.dataPipeline.storage.backend == "influxdb") [
      influxdb2
    ];

    # Create pipeline directories
    systemd.tmpfiles.rules = [
      "d ${config.custom.dataPipeline.storage.path} 0755 root root -"
      "d ${config.custom.dataPipeline.storage.path}/raw 0755 root root -"
      "d ${config.custom.dataPipeline.storage.path}/processed 0755 root root -"
      "d ${config.custom.dataPipeline.storage.path}/models 0755 root root -"
      "d ${config.custom.dataPipeline.storage.path}/cache 0755 root root -"
      "d ${config.custom.dataPipeline.storage.path}/exports 0755 root root -"
    ];

    # Database setup based on backend
    services.postgresql = mkIf (config.custom.dataPipeline.storage.backend == "postgresql") {
      enable = true;
      package = pkgs.postgresql;
      
      settings = {
        max_connections = 100;
        shared_buffers = "256MB";
        effective_cache_size = "1GB";
        maintenance_work_mem = "64MB";
        checkpoint_completion_target = 0.9;
        wal_buffers = "16MB";
        default_statistics_target = 100;
        random_page_cost = 1.1;
        effective_io_concurrency = 200;
      };
      
      initialScript = pkgs.writeText "pipeline-init.sql" ''
        CREATE DATABASE pipeline_data;
        CREATE USER pipeline WITH PASSWORD 'pipeline123';
        GRANT ALL PRIVILEGES ON DATABASE pipeline_data TO pipeline;
      '';
    };

    # Redis for caching and real-time data
    services.redis.servers.pipeline = mkIf config.custom.dataPipeline.processing.realtime {
      enable = true;
      port = 6379;
      bind = "127.0.0.1";
      
      settings = {
        maxmemory = "512mb";
        maxmemory-policy = "allkeys-lru";
        save = lib.mkForce "900 1 300 10 60 10000";
      };
    };

    # Main data collection service
    systemd.services.data-collector = {
      description = "Data Pipeline Collection Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      
      serviceConfig = {
        Type = "notify";
        ExecStart = pkgs.writeScript "data-collector" ''
          #!/bin/bash
          
          # Environment configuration
          export PIPELINE_PATH="${config.custom.dataPipeline.storage.path}"
          export COLLECTION_INTERVAL="${toString config.custom.dataPipeline.collection.interval}"
          export BATCH_SIZE="${toString config.custom.dataPipeline.collection.batchSize}"
          export COMPRESSION="${if config.custom.dataPipeline.collection.compression then "1" else "0"}"
          export SOURCES="${concatStringsSep "," config.custom.dataPipeline.collection.sources}"
          
          # Database configuration
          export DB_BACKEND="${config.custom.dataPipeline.storage.backend}"
          
          # Processing configuration
          export REALTIME="${if config.custom.dataPipeline.processing.realtime then "1" else "0"}"
          export WORKERS="${toString config.custom.dataPipeline.processing.workers}"
          export MEMORY_LIMIT="${config.custom.dataPipeline.processing.memoryLimit}"
          
          # Input capture integration
          export INPUT_CAPTURE_PATH="${if config.custom.inputCapture.enable then config.custom.inputCapture.storage.path else "/dev/null"}"
          
          # Recording integration
          export RECORDING_PATH="${if config.custom.desktopRecording.enable then config.custom.desktopRecording.storage.path else "/dev/null"}"
          
          exec ${pkgs.python3}/bin/python3 ${./scripts/data-collector.py}
        '';
        
        Restart = "on-failure";
        RestartSec = "10s";
        User = "root";
        Group = "pipeline";
        
        # Resource limits
        MemoryMax = config.custom.dataPipeline.processing.memoryLimit;
        CPUQuota = "200%";
        
        # Security
        ProtectSystem = "strict";
        ReadWritePaths = [ 
          config.custom.dataPipeline.storage.path
          "/tmp"
        ] ++ optionals config.custom.inputCapture.enable [ config.custom.inputCapture.storage.path ]
          ++ optionals config.custom.desktopRecording.enable [ config.custom.desktopRecording.storage.path ];
        ProtectHome = true;
        NoNewPrivileges = true;
      };
    };

    # Data processing service
    systemd.services.data-processor = {
      description = "Data Pipeline Processing Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "data-collector.service" ];
      wants = [ "data-collector.service" ];
      
      serviceConfig = {
        Type = "notify";
        ExecStart = pkgs.writeScript "data-processor" ''
          #!/bin/bash
          
          export PIPELINE_PATH="${config.custom.dataPipeline.storage.path}"
          export DB_BACKEND="${config.custom.dataPipeline.storage.backend}"
          export WORKERS="${toString config.custom.dataPipeline.processing.workers}"
          export ALGORITHMS="${concatStringsSep "," config.custom.dataPipeline.processing.algorithms}"
          export PARTITIONING="${config.custom.dataPipeline.storage.partitioning}"
          
          # ML configuration
          export ML_ENABLED="${if config.custom.dataPipeline.analysis.ml.enable then "1" else "0"}"
          export ML_MODELS="${concatStringsSep "," config.custom.dataPipeline.analysis.ml.models}"
          export AUTO_TRAINING="${if config.custom.dataPipeline.analysis.ml.training.auto then "1" else "0"}"
          
          exec ${pkgs.python3}/bin/python3 ${./scripts/data-processor.py}
        '';
        
        Restart = "on-failure";
        RestartSec = "15s";
        User = "root";
        Group = "pipeline";
        
        # Resource limits
        MemoryMax = config.custom.dataPipeline.processing.memoryLimit;
        CPUQuota = "400%";
        
        # Security
        ProtectSystem = "strict";
        ReadWritePaths = [ config.custom.dataPipeline.storage.path ];
        ProtectHome = true;
        NoNewPrivileges = true;
      };
    };

    # Analysis engine service
    systemd.services.analysis-engine = mkIf config.custom.dataPipeline.analysis.enable {
      description = "Data Analysis Engine";
      wantedBy = [ "multi-user.target" ];
      after = [ "data-processor.service" ];
      wants = [ "data-processor.service" ];
      
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeScript "analysis-engine" ''
          #!/bin/bash
          
          export PIPELINE_PATH="${config.custom.dataPipeline.storage.path}"
          export METRICS="${concatStringsSep "," config.custom.dataPipeline.analysis.metrics}"
          export DB_BACKEND="${config.custom.dataPipeline.storage.backend}"
          
          exec ${pkgs.python3}/bin/python3 ${./scripts/analysis-engine.py}
        '';
        
        Restart = "on-failure";
        RestartSec = "20s";
        User = "root";
        Group = "pipeline";
        
        MemoryMax = "1G";
        CPUQuota = "150%";
      };
    };

    # API server service
    systemd.services.pipeline-api = mkIf config.custom.dataPipeline.api.enable {
      description = "Data Pipeline API Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "data-processor.service" ];
      
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeScript "pipeline-api" ''
          #!/bin/bash
          
          export PIPELINE_PATH="${config.custom.dataPipeline.storage.path}"
          export API_PORT="${toString config.custom.dataPipeline.api.port}"
          export AUTH_ENABLED="${if config.custom.dataPipeline.api.auth then "1" else "0"}"
          export ENDPOINTS="${concatStringsSep "," config.custom.dataPipeline.api.endpoints}"
          export DB_BACKEND="${config.custom.dataPipeline.storage.backend}"
          
          # Streaming configuration
          export STREAMING_ENABLED="${if config.custom.dataPipeline.streaming.enable then "1" else "0"}"
          export STREAMING_PROTOCOL="${config.custom.dataPipeline.streaming.protocol}"
          export BUFFER_SIZE="${toString config.custom.dataPipeline.streaming.bufferSize}"
          
          exec ${pkgs.python3}/bin/python3 ${./scripts/pipeline-api.py}
        '';
        
        Restart = "on-failure";
        RestartSec = "10s";
        User = "root";
        Group = "pipeline";
        
        MemoryMax = "512M";
      };
    };

    # Data retention and cleanup service
    systemd.services.data-retention = {
      description = "Data Pipeline Retention Manager";
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "data-retention" ''
          #!/bin/bash
          
          PIPELINE_PATH="${config.custom.dataPipeline.storage.path}"
          RAW_RETENTION="${toString config.custom.dataPipeline.storage.retentionPolicy.raw}"
          PROCESSED_RETENTION="${toString config.custom.dataPipeline.storage.retentionPolicy.processed}"
          AGGREGATED_RETENTION="${toString config.custom.dataPipeline.storage.retentionPolicy.aggregated}"
          
          cd "$PIPELINE_PATH" || exit 1
          
          # Clean raw data
          find ./raw -type f -mtime +$RAW_RETENTION -delete
          
          # Clean processed data
          find ./processed -type f -mtime +$PROCESSED_RETENTION -delete
          
          # Archive old aggregated data
          find . -name "*aggregated*" -type f -mtime +$AGGREGATED_RETENTION -delete
          
          # Database cleanup
          ${pkgs.python3}/bin/python3 ${./scripts/cleanup-database.py}
          
          echo "Data retention cleanup completed"
        '';
        User = "root";
        Group = "pipeline";
      };
    };

    # Timer for retention cleanup
    systemd.timers.data-retention = {
      description = "Run data retention cleanup daily";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "2h";
      };
    };

    # ML model training service
    systemd.services.ml-training = mkIf config.custom.dataPipeline.analysis.ml.enable {
      description = "Machine Learning Model Training";
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeScript "ml-training" ''
          #!/bin/bash
          
          export PIPELINE_PATH="${config.custom.dataPipeline.storage.path}"
          export ML_MODELS="${concatStringsSep "," config.custom.dataPipeline.analysis.ml.models}"
          export DB_BACKEND="${config.custom.dataPipeline.storage.backend}"
          
          ${pkgs.python3}/bin/python3 ${./scripts/ml-trainer.py}
        '';
        
        User = "root";
        Group = "pipeline";
        MemoryMax = "4G";
        CPUQuota = "800%";
      };
    };

    # Timer for ML training
    systemd.timers.ml-training = mkIf (config.custom.dataPipeline.analysis.ml.enable && 
                                        config.custom.dataPipeline.analysis.ml.training.auto) {
      description = "Run ML training periodically";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = config.custom.dataPipeline.analysis.ml.training.interval;
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };

    # Monitoring service
    systemd.services.pipeline-monitor = mkIf config.custom.dataPipeline.monitoring.enable {
      description = "Data Pipeline Monitor";
      wantedBy = [ "multi-user.target" ];
      after = [ "data-collector.service" ];
      
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeScript "pipeline-monitor" ''
          #!/bin/bash
          
          export PIPELINE_PATH="${config.custom.dataPipeline.storage.path}"
          export CHECK_INTERVAL="${toString config.custom.dataPipeline.monitoring.healthcheck.interval}"
          export ALERTS="${concatStringsSep "," config.custom.dataPipeline.monitoring.alerts}"
          export METRICS_ENABLED="${if config.custom.dataPipeline.monitoring.metrics then "1" else "0"}"
          
          exec ${pkgs.python3}/bin/python3 ${./scripts/pipeline-monitor.py}
        '';
        
        Restart = "on-failure";
        RestartSec = "30s";
        User = "root";
        Group = "pipeline";
        
        MemoryMax = "256M";
      };
    };

    # Create pipeline user group
    users.groups.pipeline = {};
    users.users.root.extraGroups = [ "pipeline" ];

    # Environment variables
    environment.sessionVariables = {
      DATA_PIPELINE_ENABLED = "1";
      DATA_PIPELINE_PATH = config.custom.dataPipeline.storage.path;
      DATA_PIPELINE_API_PORT = toString config.custom.dataPipeline.api.port;
    };

    # Networking configuration for API
    networking.firewall = mkIf config.custom.dataPipeline.api.enable {
      allowedTCPPorts = [ config.custom.dataPipeline.api.port ];
    };

    # Polkit rules for pipeline management
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if ((action.id == "org.freedesktop.systemd1.manage-units" &&
               (action.lookup("unit").match(/data-.*\.service/) ||
                action.lookup("unit").match(/pipeline-.*\.service/) ||
                action.lookup("unit").match(/analysis-.*\.service/) ||
                action.lookup("unit") == "ml-training.service")) &&
              subject.isInGroup("pipeline")) {
              return polkit.Result.YES;
          }
      });
    '';
  };
}
