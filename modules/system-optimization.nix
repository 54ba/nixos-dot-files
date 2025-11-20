{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.system-optimization = {
      enable = mkEnableOption "system optimization and performance settings" // { default = true; };
    };
  };

  config = mkIf config.custom.system-optimization.enable {
    # System-wide services for input device management
    systemd.services = {
      # Fix systemd services and virtual sessions
      "getty@tty1".enable = true;
      "autovt@tty1".enable = true;
      "getty@tty7".enable = false; # GDM conflicts
      
      # Restart input services after wake from sleep
      restart-input-devices = {
        description = "Restart input devices after sleep";
        after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeScript "restart-input-devices" ''
            #!${pkgs.bash}/bin/bash
            # Wait a moment for devices to settle
            sleep 2
            
            # Restart GNOME settings daemon to reload input settings
            systemctl --user restart gnome-settings-daemon || true
            
            # Reload input device configuration
            systemctl restart systemd-udevd || true
            
            # Trigger udev rules for input devices
            ${pkgs.systemd}/bin/udevadm trigger --subsystem-match=input || true
            ${pkgs.systemd}/bin/udevadm settle || true
            
            # Reset libinput calibration
            for device in /dev/input/event*; do
              if [[ -e "$device" ]]; then
                ${pkgs.systemd}/bin/udevadm trigger "$device" || true
              fi
            done
          '';
          RemainAfterExit = false;
        };
        wantedBy = [ "post-resume.target" ];
      };
      
      # Fix shutdown and reboot issues with /nix/store
      /*nix-store-umount-fix = {
        description = "Fix /nix/store umount on shutdown";
        wantedBy = [ "shutdown.target" ];
        before = [ "shutdown.target" "reboot.target" "halt.target" ];
        conflicts = [ "shutdown.target" "reboot.target" "halt.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "/bin/true";
          ExecStop = ''
            ${pkgs.util-linux}/bin/umount -l /nix/store || true
            ${pkgs.coreutils}/bin/sync
          '';
          TimeoutStopSec = "30s";
          KillMode = "none";
        };
      };*/
    };
    
    # Fix the UserTasksMax deprecation issue
    systemd.slices."user-.slice" = {
      sliceConfig = {
        TasksMax = "infinity";
      };
    };
    
    # Additional systemd settings
    systemd.extraConfig = ''
      DefaultTimeoutStopSec=30s
      DefaultTimeoutStartSec=30s
    '';
    
    # Container aliases (conditional based on container configuration)
    environment.shellAliases = mkIf (!config.custom.containers.enable || !config.custom.containers.podman.enable) {
      # Only provide fallback aliases if containers are disabled
      # This prevents conflicts when containers module is enabled
    };
  };
}
