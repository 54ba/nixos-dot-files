{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.custom.automation-workflow;
in
{
  options.custom.automation-workflow = {
    enable = mkEnableOption "automation and workflow orchestration tools";
    
    # Core workflow engines
    engines = {
      n8n = {
        enable = mkEnableOption "n8n workflow automation platform";
        port = mkOption {
          type = types.int;
          default = 5678;
          description = "Port for n8n web interface";
        };
        dataDir = mkOption {
          type = types.str;
          default = "/var/lib/n8n";
          description = "Data directory for n8n";
        };
        encryptionKey = mkOption {
          type = types.str;
          default = "changeme_encryption_key";
          description = "Encryption key for n8n data";
        };
      };
      
      nodeRed = {
        enable = mkEnableOption "Node-RED visual programming environment";
        port = mkOption {
          type = types.int;
          default = 1880;
          description = "Port for Node-RED web interface";
        };
        userDir = mkOption {
          type = types.str;
          default = "/var/lib/node-red";
          description = "User directory for Node-RED";
        };
      };
      
      airflow = {
        enable = mkEnableOption "Apache Airflow workflow orchestration";
        port = mkOption {
          type = types.int;
          default = 8080;
          description = "Port for Airflow web interface";
        };
        homeDir = mkOption {
          type = types.str;
          default = "/var/lib/airflow";
          description = "Home directory for Airflow";
        };
      };
      
      temporal = {
        enable = mkEnableOption "Temporal workflow orchestration";
        frontendPort = mkOption {
          type = types.int;
          default = 8088;
          description = "Port for Temporal web interface";
        };
        serverPort = mkOption {
          type = types.int;
          default = 7233;
          description = "Port for Temporal server";
        };
        dataDir = mkOption {
          type = types.str;
          default = "/var/lib/temporal";
          description = "Data directory for Temporal";
        };
      };
      
      kestra = {
        enable = mkEnableOption "Kestra workflow orchestration platform";
        port = mkOption {
          type = types.int;
          default = 8080;
          description = "Port for Kestra web interface";
        };
        dataDir = mkOption {
          type = types.str;
          default = "/var/lib/kestra";
          description = "Data directory for Kestra";
        };
        javaOpts = mkOption {
          type = types.str;
          default = "-Xmx2G";
          description = "JVM options for Kestra";
        };
      };
    };
    
    # API automation tools
    api = {
      enable = mkEnableOption "API automation and testing tools";
      tools = {
        postman = mkEnableOption "Postman API testing";
        insomnia = mkEnableOption "Insomnia API testing";
        httpie = mkEnableOption "HTTPie command-line HTTP client";
        curl = mkEnableOption "curl command-line tool";
        jq = mkEnableOption "jq JSON processor";
        yq = mkEnableOption "yq YAML processor";
      };
    };
    
    # CLI automation tools
    cli = {
      enable = mkEnableOption "command-line automation tools";
      tools = {
        github-cli = mkEnableOption "GitHub CLI";
        gitlab-cli = mkEnableOption "GitLab CLI";
        slack-cli = mkEnableOption "Slack CLI tools";
        telegram-cli = mkEnableOption "Telegram CLI tools";
        discord-cli = mkEnableOption "Discord CLI tools";
        aws-cli = mkEnableOption "AWS CLI";
        azure-cli = mkEnableOption "Azure CLI";
        gcloud-cli = mkEnableOption "Google Cloud CLI";
      };
    };
    
    # Scripting and task automation
    scripting = {
      enable = mkEnableOption "scripting and task automation tools";
      languages = {
        python = mkEnableOption "Python automation tools";
        nodejs = mkEnableOption "Node.js automation tools";
        bash = mkEnableOption "Bash automation tools";
        powershell = mkEnableOption "PowerShell Core";
      };
      schedulers = {
        cron = mkEnableOption "traditional cron scheduling";
        systemd-timers = mkEnableOption "systemd timer scheduling";
        at = mkEnableOption "at command for one-time scheduling";
      };
    };
    
    # Integration and messaging
    integration = {
      enable = mkEnableOption "integration and messaging tools";
      messaging = {
        rabbitmq = mkEnableOption "RabbitMQ message broker";
        redis = mkEnableOption "Redis in-memory data store";
        kafka = mkEnableOption "Apache Kafka streaming";
        mqtt = mkEnableOption "MQTT message broker";
      };
      databases = {
        postgresql = mkEnableOption "PostgreSQL database";
        mongodb = mkEnableOption "MongoDB database";
        sqlite = mkEnableOption "SQLite database";
        influxdb = mkEnableOption "InfluxDB time-series database";
      };
    };
    
    # Monitoring and observability
    monitoring = {
      enable = mkEnableOption "workflow monitoring and observability";
      tools = {
        prometheus = mkEnableOption "Prometheus metrics collection";
        grafana = mkEnableOption "Grafana visualization";
        jaeger = mkEnableOption "Jaeger distributed tracing";
        elk = mkEnableOption "ELK stack (Elasticsearch, Logstash, Kibana)";
      };
    };
    
    # Security and authentication
    security = {
      enable = mkEnableOption "automation security features";
      authentication = {
        oauth2 = mkEnableOption "OAuth2 authentication";
        jwt = mkEnableOption "JWT token handling";
        apiKeys = mkEnableOption "API key management";
        certificates = mkEnableOption "certificate management";
      };
      secrets = {
        vault = mkEnableOption "HashiCorp Vault secret management";
        sops = mkEnableOption "SOPS encrypted secrets";
        pass = mkEnableOption "pass password manager";
      };
    };
    
    # Development and testing
    development = {
      enable = mkEnableOption "automation development tools";
      testing = {
        newman = mkEnableOption "Newman API testing";
        jest = mkEnableOption "Jest testing framework";
        pytest = mkEnableOption "pytest Python testing";
        playwright = mkEnableOption "Playwright browser automation";
        selenium = mkEnableOption "Selenium web automation";
      };
      debugging = {
        ngrok = mkEnableOption "ngrok tunneling";
        mitmproxy = mkEnableOption "mitmproxy HTTP proxy";
        burp = mkEnableOption "Burp Suite community edition";
      };
    };
  };
  
  config = mkIf cfg.enable {
    # Core automation packages
    environment.systemPackages = with pkgs; [
      # Always include essential automation tools
      jq yq curl wget httpie
      git gh glab
      python3 nodejs npm yarn
      
      # Conditional packages based on configuration
    ] ++ optionals cfg.api.enable [
      # API tools
    ] ++ optionals cfg.api.tools.postman [
      postman
    ] ++ optionals cfg.api.tools.insomnia [
      insomnia
    ] ++ optionals cfg.cli.enable [
      # CLI automation tools
    ] ++ optionals cfg.cli.tools.github-cli [
      gh
    ] ++ optionals cfg.cli.tools.gitlab-cli [
      glab
    ] ++ optionals cfg.cli.tools.aws-cli [
      awscli2
    ] ++ optionals cfg.cli.tools.azure-cli [
      azure-cli
    ] ++ optionals cfg.cli.tools.gcloud-cli [
      google-cloud-sdk
    ] ++ optionals cfg.scripting.enable [
      # Scripting tools
    ] ++ optionals cfg.scripting.languages.python [
      python3 python3Packages.pip python3Packages.requests
      python3Packages.pyyaml python3Packages.click
      python3Packages.schedule python3Packages.celery
    ] ++ optionals cfg.scripting.languages.nodejs [
      nodejs npm yarn nodePackages.pm2
    ] ++ optionals cfg.scripting.languages.powershell [
      powershell
    ] ++ optionals cfg.development.enable [
      # Development tools
    ] ++ optionals cfg.development.testing.newman [
      newman
    ] ++ optionals cfg.development.testing.playwright [
      playwright-driver.browsers
    ] ++ optionals cfg.development.debugging.ngrok [
      ngrok
    ] ++ optionals cfg.engines.temporal.enable [
      # Temporal workflow orchestration
      temporal temporal-cli temporalite
    ] ++ optionals cfg.engines.kestra.enable [
      # Kestra workflow orchestration (Python package)
      python3Packages.kestra
    ];
    
    # Automation service configurations
    systemd.services = mkMerge [
      # n8n service configuration (only if package is available)
      (mkIf (cfg.engines.n8n.enable && (pkgs ? n8n)) {
        n8n = {
          description = "n8n workflow automation";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          
          environment = {
            N8N_PORT = toString cfg.engines.n8n.port;
            N8N_USER_FOLDER = cfg.engines.n8n.dataDir;
            N8N_ENCRYPTION_KEY = cfg.engines.n8n.encryptionKey;
            N8N_HOST = "0.0.0.0";
            WEBHOOK_URL = "http://localhost:${toString cfg.engines.n8n.port}/";
            GENERIC_TIMEZONE = config.time.timeZone or "UTC";
          };
          
          serviceConfig = {
            Type = "simple";
            User = "n8n";
            Group = "n8n";
            ExecStart = "${pkgs.n8n}/bin/n8n start";
            Restart = "always";
            RestartSec = 5;
            WorkingDirectory = cfg.engines.n8n.dataDir;
            StateDirectory = "n8n";
            StateDirectoryMode = "0700";
          };
        };
      })
      
      # Node-RED service configuration
      (mkIf cfg.engines.nodeRed.enable {
        node-red = {
          description = "Node-RED visual programming";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          
          environment = {
            NODE_RED_HOME = cfg.engines.nodeRed.userDir;
            NODE_RED_PORT = toString cfg.engines.nodeRed.port;
          };
          
          serviceConfig = {
            Type = "simple";
            User = "node-red";
            Group = "node-red";
            ExecStart = "${pkgs.nodePackages.node-red}/bin/node-red --port ${toString cfg.engines.nodeRed.port} --userDir ${cfg.engines.nodeRed.userDir}";
            Restart = "always";
            RestartSec = 5;
            WorkingDirectory = cfg.engines.nodeRed.userDir;
            StateDirectory = "node-red";
            StateDirectoryMode = "0700";
          };
        };
      })
      
      # Temporal service configuration using temporalite for simplicity
      (mkIf cfg.engines.temporal.enable {
        temporal = {
          description = "Temporal workflow orchestration (temporalite)";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          
          environment = {
            TEMPORAL_CLI_ADDRESS = "localhost:${toString cfg.engines.temporal.serverPort}";
            TEMPORAL_WEB_PORT = toString cfg.engines.temporal.frontendPort;
          };
          
          serviceConfig = {
            Type = "simple";
            User = "temporal";
            Group = "temporal";
            ExecStart = "${pkgs.temporalite}/bin/temporalite start --namespace default --headless --ip 0.0.0.0 --port ${toString cfg.engines.temporal.serverPort} --web-port ${toString cfg.engines.temporal.frontendPort}";
            Restart = "always";
            RestartSec = 10;
            WorkingDirectory = cfg.engines.temporal.dataDir;
            StateDirectory = "temporal";
            StateDirectoryMode = "0700";
          };
        };
      })
      
      # Kestra service configuration using Python package
      (mkIf cfg.engines.kestra.enable {
        kestra = {
          description = "Kestra workflow orchestration";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          
          environment = {
            KESTRA_CONFIGURATION = "${cfg.engines.kestra.dataDir}/application.yml";
            JAVA_OPTS = cfg.engines.kestra.javaOpts;
          };
          
          serviceConfig = {
            Type = "simple";
            User = "kestra";
            Group = "kestra";
            ExecStart = "${pkgs.python3}/bin/python3 -m kestra.server --config=${cfg.engines.kestra.dataDir}/application.yml";
            ExecStartPre = pkgs.writeShellScript "kestra-setup" ''
              mkdir -p ${cfg.engines.kestra.dataDir}
              if [ ! -f "${cfg.engines.kestra.dataDir}/application.yml" ]; then
                cat > "${cfg.engines.kestra.dataDir}/application.yml" << EOF
kestra:
  server:
    port: ${toString cfg.engines.kestra.port}
  datasources:
    default:
      url: jdbc:h2:file:${cfg.engines.kestra.dataDir}/kestra
      driverClassName: org.h2.Driver
      username: kestra
      password: kestra
EOF
              fi
            '';
            Restart = "always";
            RestartSec = 10;
            WorkingDirectory = cfg.engines.kestra.dataDir;
            StateDirectory = "kestra";
            StateDirectoryMode = "0700";
          };
        };
      })
    ];
    
    # Create system users for automation services
    users.users = mkMerge [
      (mkIf cfg.engines.n8n.enable {
        n8n = {
          isSystemUser = true;
          group = "n8n";
          home = cfg.engines.n8n.dataDir;
          createHome = true;
          description = "n8n automation user";
        };
      })
      
      (mkIf cfg.engines.nodeRed.enable {
        node-red = {
          isSystemUser = true;
          group = "node-red";
          home = cfg.engines.nodeRed.userDir;
          createHome = true;
          description = "Node-RED automation user";
        };
      })
      
      (mkIf cfg.engines.temporal.enable {
        temporal = {
          isSystemUser = true;
          group = "temporal";
          home = cfg.engines.temporal.dataDir;
          createHome = true;
          description = "Temporal workflow user";
        };
      })
      
      (mkIf cfg.engines.kestra.enable {
        kestra = {
          isSystemUser = true;
          group = "kestra";
          home = cfg.engines.kestra.dataDir;
          createHome = true;
          description = "Kestra workflow user";
        };
      })
    ];
    
    users.groups = mkMerge [
      (mkIf cfg.engines.n8n.enable {
        n8n = {};
      })
      
      (mkIf cfg.engines.nodeRed.enable {
        node-red = {};
      })
      
      (mkIf cfg.engines.temporal.enable {
        temporal = {};
      })
      
      (mkIf cfg.engines.kestra.enable {
        kestra = {};
      })
    ];
    
    # Firewall configuration for automation services
    networking.firewall.allowedTCPPorts = mkMerge [
      (mkIf cfg.engines.n8n.enable [ cfg.engines.n8n.port ])
      (mkIf cfg.engines.nodeRed.enable [ cfg.engines.nodeRed.port ])
      (mkIf cfg.engines.airflow.enable [ cfg.engines.airflow.port ])
      (mkIf cfg.engines.temporal.enable [ cfg.engines.temporal.frontendPort cfg.engines.temporal.serverPort ])
      (mkIf cfg.engines.kestra.enable [ cfg.engines.kestra.port ])
    ];
    
    # Enable cron service if requested
    services.cron.enable = mkIf (cfg.scripting.enable && cfg.scripting.schedulers.cron) true;
    
    # Enable PostgreSQL if requested for workflow storage
    services.postgresql = mkIf (cfg.integration.enable && cfg.integration.databases.postgresql) {
      enable = true;
      ensureDatabases = [ "n8n" "airflow" "temporal" ];
      ensureUsers = [
        {
          name = "n8n";
          ensurePermissions = {
            "DATABASE n8n" = "ALL PRIVILEGES";
          };
        }
        {
          name = "airflow";
          ensurePermissions = {
            "DATABASE airflow" = "ALL PRIVILEGES";
          };
        }
        {
          name = "temporal";
          ensurePermissions = {
            "DATABASE temporal" = "ALL PRIVILEGES";
          };
        }
      ];
    };
    
    # Enable Redis if requested for caching and queues
    services.redis = mkIf (cfg.integration.enable && cfg.integration.messaging.redis) {
      servers.main = {
        enable = true;
        port = 6379;
        bind = "127.0.0.1";
      };
    };
    
    # Enable RabbitMQ if requested for message queuing
    services.rabbitmq = mkIf (cfg.integration.enable && cfg.integration.messaging.rabbitmq) {
      enable = true;
      listenAddress = "127.0.0.1";
    };
    
    # Create automation directories
    systemd.tmpfiles.rules = [
      "d /var/lib/automation 0755 root root -"
      "d /var/lib/automation/scripts 0755 root root -"
      "d /var/lib/automation/workflows 0755 root root -"
      "d /var/lib/automation/logs 0755 root root -"
      "d /var/lib/automation/temp 0755 root root -"
    ];
    
    # Add automation user to required groups
    users.users.mahmoud.extraGroups = mkIf config.users.users.mahmoud.isNormalUser [
      "automation"
    ] ++ optionals cfg.engines.n8n.enable [ "n8n" ]
      ++ optionals cfg.engines.nodeRed.enable [ "node-red" ];
    
    # Create automation group
    users.groups.automation = {};
  };
}
