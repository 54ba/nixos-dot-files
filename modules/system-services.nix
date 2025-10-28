{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.services.system = {
      enable = mkEnableOption "enhanced system services configuration";
      
      ssh.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable OpenSSH server";
      };
      
      audio.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Pipewire audio system";
      };
      
      bluetooth.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Bluetooth support";
      };
      
      printing.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable printing support";
      };
      
      flatpak.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Flatpak package manager";
      };
      
      gamemode.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GameMode for gaming performance";
      };
      
      android.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Android development tools";
      };
      
      fuse.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable FUSE filesystem support for AppImages";
      };
    };
  };

  config = mkIf config.custom.services.system.enable {
    # Essential system services
    services.openssh.enable = mkIf config.custom.services.system.ssh.enable true;
    services.udisks2.enable = true;  # Disk management
    services.acpid.enable = true;    # Power management
    systemd.services.NetworkManager-wait-online.enable = false;  # Faster boot
    
    # SSD TRIM support for better performance and longevity
    services.fstrim.enable = true;
    
    # Fix nsncd service failures
    services.nscd.enable = false;
    system.nssModules = mkForce [];
    
    # Journald configuration
    services.journald.extraConfig = ''
      # Persistent storage for logs
      Storage=persistent
      # Compress logs to save space
      Compress=yes
      # Keep logs for 7 days
      MaxRetentionSec=604800
      # Limit journal size to 1GB
      SystemMaxUse=1G
      # Keep at least 100MB free
      SystemKeepFree=100M
    '';
    
    # Audio system with PipeWire - Enhanced configuration for screen sharing
    security.rtkit.enable = mkIf config.custom.services.system.audio.enable true;
    
    # Disable PulseAudio since we're using PipeWire
    services.pulseaudio.enable = false;
    
    services.pipewire = mkIf config.custom.services.system.audio.enable {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      
      # Enable WirePlumber session manager
      wireplumber.enable = true;
      
      # PipeWire configuration for screen sharing
      extraConfig.pipewire = {
        "context.properties" = {
          "link.max-buffers" = 16;
          "log.level" = 2;
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 8192;
          "core.daemon" = true;
          "core.name" = "pipewire-0";
        };
        "context.modules" = [
          {
            name = "libpipewire-module-rtkit";
            args = {
              "nice.level" = -15;
              "rt.prio" = 88;
              "rt.time.soft" = 200000;
              "rt.time.hard" = 200000;
            };
            flags = [ "ifexists" "nofail" ];
          }
          { name = "libpipewire-module-protocol-native"; }
          { name = "libpipewire-module-profiler"; }
          { name = "libpipewire-module-metadata"; }
          { name = "libpipewire-module-spa-device-factory"; }
          { name = "libpipewire-module-spa-node-factory"; }
          { name = "libpipewire-module-client-node"; }
          { name = "libpipewire-module-client-device"; }
          {
            name = "libpipewire-module-portal";
            flags = [ "ifexists" "nofail" ];
          }
          {
            name = "libpipewire-module-access";
            args = {};
          }
          { name = "libpipewire-module-adapter"; }
          { name = "libpipewire-module-link-factory"; }
          { name = "libpipewire-module-session-manager"; }
        ];
      };
    };
    
    # Bluetooth support (only enable if not explicitly configured in hardware module)
    hardware.bluetooth.enable = mkIf config.custom.services.system.bluetooth.enable (mkDefault true);
    services.blueman.enable = mkIf config.custom.services.system.bluetooth.enable (mkDefault true);
    
    # Printing support
    services.printing = mkIf config.custom.services.system.printing.enable {
      enable = true;
      drivers = with pkgs; [
        gutenprint
        hplip
        canon-cups-ufr2
      ];
    };
    services.avahi = mkIf config.custom.services.system.printing.enable {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    
    # Flatpak support
    services.flatpak.enable = mkIf config.custom.services.system.flatpak.enable true;
    
    # GameMode for better gaming performance
    programs.gamemode = mkIf config.custom.services.system.gamemode.enable {
      enable = true;
      enableRenice = true;
      settings = {
        general = {
          renice = 10;
          ioprio = 0;
          inhibit_screensaver = 1;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
          amd_performance_level = "high";
        };
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
    };
    
    # Android development services
    programs.adb.enable = mkIf config.custom.services.system.android.enable true;
    
    # FUSE filesystem support for AppImages
    programs.fuse.userAllowOther = mkIf config.custom.services.system.fuse.enable true;
    
    # Additional system packages for services
    environment.systemPackages = with pkgs; 
      # Basic system utilities
      [
        # System monitoring and information
        htop
        btop
        neofetch
        lsof
        
        # Network utilities
        wget
        curl
        
        # Archive tools
        zip
        unzip
        p7zip
        
        # File system utilities
        ntfs3g
        exfat
        dosfstools
      ] ++
      
      # Audio packages
      (optionals config.custom.services.system.audio.enable [
        pavucontrol    # Audio control GUI
        pulseaudio     # Compatibility layer
        pamixer        # Command-line audio mixer
        playerctl      # Media player control
      ]) ++
      
      # Bluetooth packages
      (optionals config.custom.services.system.bluetooth.enable [
        bluez          # Bluetooth stack
        bluez-tools    # Bluetooth utilities
      ]) ++
      
      # Printing packages
      (optionals config.custom.services.system.printing.enable [
        cups           # Printing system
        system-config-printer  # Printer configuration GUI
      ]) ++
      
      # Android development packages
      (optionals config.custom.services.system.android.enable [
        android-tools       # ADB, fastboot, etc.
      ]) ++
      
      # FUSE packages
      (optionals config.custom.services.system.fuse.enable [
        fuse           # FUSE filesystem
        fuse3          # FUSE3 filesystem
      ]);
    
    # User groups for system services
    users.groups = {
      gamemode = mkIf config.custom.services.system.gamemode.enable {};
      adbusers = mkIf config.custom.services.system.android.enable {};
      plugdev = mkIf config.custom.services.system.android.enable {};
      lp = mkIf config.custom.services.system.printing.enable {};
      fuse = mkIf config.custom.services.system.fuse.enable {};
    };
    
    # Systemd tmpfiles rules for service integration
    systemd.tmpfiles.rules = [
      # Flatpak user directories
      "d /home/mahmoud/.local/share/flatpak 0755 mahmoud users -"
    ] ++ (optionals config.custom.services.system.android.enable [
      # Android development directories
      "d /home/mahmoud/.android 0755 mahmoud users -"
      "d /home/mahmoud/Android 0755 mahmoud users -"
    ]);
    
    # Enhanced udev rules for hardware access
    services.udev.extraRules = ''
      # Allow users in audio group to access audio devices
      SUBSYSTEM=="sound", GROUP="audio", MODE="0664"
      SUBSYSTEM=="snd", GROUP="audio", MODE="0664"
      
      # Allow users in video group to access video devices
      SUBSYSTEM=="video4linux", GROUP="video", MODE="0664"
      SUBSYSTEM=="graphics", GROUP="video", MODE="0664"
      
      # Allow users in input group to access input devices
      SUBSYSTEM=="input", GROUP="input", MODE="0664"
      
      # Allow users in storage group to access removable storage
      SUBSYSTEM=="block", ATTRS{removable}=="1", GROUP="storage", MODE="0664"
      
      # GPU access permissions for render group
      SUBSYSTEM=="drm", GROUP="render", MODE="0664"
      KERNEL=="card[0-9]*", GROUP="render", MODE="0664"
      
      # FUSE device permissions
      KERNEL=="fuse", GROUP="fuse", MODE="0664"
    '';
  };
}
