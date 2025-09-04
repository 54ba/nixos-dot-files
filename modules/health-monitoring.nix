{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.healthMonitoring = {
      enable = mkEnableOption "system health monitoring";
      
      monitoring = {
        interval = mkOption {
          type = types.str;
          default = "hourly";
          description = "How often to run health checks (systemd timer format)";
        };
        
        checkDisk = mkOption {
          type = types.bool;
          default = true;
          description = "Monitor disk usage and health";
        };
        
        checkMemory = mkOption {
          type = types.bool;
          default = true;
          description = "Monitor memory usage";
        };
        
        checkServices = mkOption {
          type = types.bool;
          default = true;
          description = "Monitor critical system services";
        };
        
        checkNetwork = mkOption {
          type = types.bool;
          default = true;
          description = "Monitor network connectivity";
        };
        
        alertThresholds = {
          diskUsage = mkOption {
            type = types.int;
            default = 85;
            description = "Disk usage percentage to trigger alerts";
          };
          
          memoryUsage = mkOption {
            type = types.int;
            default = 90;
            description = "Memory usage percentage to trigger alerts";
          };
        };
      };
      
      logging = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable health monitoring logs";
        };
        
        logPath = mkOption {
          type = types.str;
          default = "/var/log/health-monitor.log";
          description = "Path for health monitoring logs";
        };
      };
    };
  };

  config = mkIf config.custom.healthMonitoring.enable {
    # Create the health monitoring script
    environment.etc."nixos/scripts/health-monitor.sh" = {
      text = ''
        #!${pkgs.bash}/bin/bash
        
        # System Health Monitor Script
        LOG_FILE="${config.custom.healthMonitoring.logging.logPath}"
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Function to log messages
        log_message() {
            echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
        }
        
        # Function to check disk usage
        check_disk() {
            ${optionalString config.custom.healthMonitoring.monitoring.checkDisk ''
            log_message "=== Disk Usage Check ==="
            df -h | grep -E '^/dev/' | while read line; do
                usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
                mount=$(echo "$line" | awk '{print $6}')
                if [ "$usage" -gt ${toString config.custom.healthMonitoring.monitoring.alertThresholds.diskUsage} ]; then
                    log_message "WARNING: Disk usage on $mount is $usage%"
                fi
            done
            ''}
        }
        
        # Function to check memory usage
        check_memory() {
            ${optionalString config.custom.healthMonitoring.monitoring.checkMemory ''
            log_message "=== Memory Usage Check ==="
            mem_usage=$(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}')
            if [ "$mem_usage" -gt ${toString config.custom.healthMonitoring.monitoring.alertThresholds.memoryUsage} ]; then
                log_message "WARNING: Memory usage is $mem_usage%"
            else
                log_message "Memory usage: $mem_usage%"
            fi
            ''}
        }
        
        # Function to check critical services
        check_services() {
            ${optionalString config.custom.healthMonitoring.monitoring.checkServices ''
            log_message "=== Critical Services Check ==="
            critical_services=(
                "systemd-resolved"
                "NetworkManager"
                "gdm"
                "dbus"
                "nix-daemon"
            )
            
            for service in "''${critical_services[@]}"; do
                if systemctl is-active --quiet "$service"; then
                    log_message "✓ $service is running"
                else
                    log_message "✗ WARNING: $service is not running"
                fi
            done
            ''}
        }
        
        # Function to check network connectivity
        check_network() {
            ${optionalString config.custom.healthMonitoring.monitoring.checkNetwork ''
            log_message "=== Network Connectivity Check ==="
            if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
                log_message "✓ Network connectivity is OK"
            else
                log_message "✗ WARNING: Network connectivity issue"
            fi
            ''}
        }
        
        # Function to check failed systemd units
        check_failed_units() {
            log_message "=== Failed Units Check ==="
            failed_units=$(systemctl --failed --no-legend | wc -l)
            if [ "$failed_units" -gt 0 ]; then
                log_message "WARNING: $failed_units failed systemd units found"
                systemctl --failed --no-legend | while read unit; do
                    log_message "Failed unit: $unit"
                done
            else
                log_message "✓ No failed systemd units"
            fi
        }
        
        # Function to check system load
        check_load() {
            log_message "=== System Load Check ==="
            load=$(uptime | awk -F'load average:' '{ print $2 }' | awk '{ print $1 }' | sed 's/,//')
            cpu_count=$(nproc)
            log_message "System load: $load (CPUs: $cpu_count)"
        }
        
        # Main execution
        log_message "Starting health monitoring check"
        check_disk
        check_memory
        check_services
        check_network
        check_failed_units
        check_load
        log_message "Health monitoring check completed"
        log_message "=================================="
      '';
      mode = "0755";
    };
    
    # Create log directory
    systemd.tmpfiles.rules = mkIf config.custom.healthMonitoring.logging.enable [
      "d /var/log 0755 root root -"
      "f ${config.custom.healthMonitoring.logging.logPath} 0644 root root -"
    ];
    
    # Health monitoring service
    systemd.services.health-monitor = {
      description = "System Health Monitor";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/etc/nixos/scripts/health-monitor.sh";
        User = "root";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
    
    # Health monitoring timer
    systemd.timers.health-monitor = {
      description = "Run system health monitoring";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = config.custom.healthMonitoring.monitoring.interval;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
    
    # Add monitoring tools to system packages
    environment.systemPackages = with pkgs; [
      htop
      iotop
      nethogs
      lsof
      smartmontools
      sysstat
      lm_sensors
      gawk  # Fix for awk command errors in monitoring script
      procps  # Provides uptime command
      coreutils  # Basic utilities
      iproute2  # Network utilities
    ];
    
    # Enable smartd for disk monitoring
    services.smartd = mkIf config.custom.healthMonitoring.monitoring.checkDisk {
      enable = true;
      autodetect = true;
    };
  };
}
