{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.userSecurity = {
      enable = mkEnableOption "enhanced user security and permissions";
      
      mainUser = {
        name = mkOption {
          type = types.str;
          default = "mahmoud";
          description = "Main user name";
        };
        
        extraGroups = mkOption {
          type = types.listOf types.str;
          default = [ "wheel" "audio" "video" "input" "storage" "network" "docker" "libvirtd" ];
          description = "Additional groups for the main user";
        };
      };
      
      sudo = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable sudo access for wheel group";
        };
        
        noPassword = mkOption {
          type = types.bool;
          default = false;
          description = "Allow sudo without password for wheel group";
        };
      };
      
      polkit.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable polkit for GUI privilege escalation";
      };
      
      pam.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable PAM configuration enhancements";
      };
      
      gnomeKeyring.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GNOME Keyring for credential storage";
      };
    };
  };

  config = mkIf config.custom.userSecurity.enable {
    # Sudo configuration
    security.sudo = mkIf config.custom.userSecurity.sudo.enable {
      enable = true;
      wheelNeedsPassword = !config.custom.userSecurity.sudo.noPassword;
      extraRules = [{
        users = [ config.custom.userSecurity.mainUser.name ];
        commands = [{
          command = "ALL";
          options = if config.custom.userSecurity.sudo.noPassword then [ "NOPASSWD" ] else [ ];
        }];
      }];
    };
    
    # Polkit configuration
    security.polkit = mkIf config.custom.userSecurity.polkit.enable {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
      '';
    };
    
    # PAM configuration
    security.pam = mkIf config.custom.userSecurity.pam.enable {
      services = {
        login.enableGnomeKeyring = config.custom.userSecurity.gnomeKeyring.enable;
        passwd.enableGnomeKeyring = config.custom.userSecurity.gnomeKeyring.enable;
        gdm.enableGnomeKeyring = config.custom.userSecurity.gnomeKeyring.enable;
        gdm-fingerprint.enableGnomeKeyring = config.custom.userSecurity.gnomeKeyring.enable;
      };
    };
    
    # GNOME Keyring
    services.gnome.gnome-keyring.enable = mkIf config.custom.userSecurity.gnomeKeyring.enable true;
    programs.seahorse.enable = mkIf config.custom.userSecurity.gnomeKeyring.enable true;
    
    # User groups - ensure they exist
    users.groups = {
      wheel = {};
      audio = {};
      video = {};
      input = {};
      storage = {};
      network = {};
      render = {};
      gamemode = {};
      adbusers = {};
      plugdev = {};
      docker = {};
      podman = {};
      vboxusers = {};
      libvirtd = {};
      kvm = {};
    };
    
    # Security packages
    environment.systemPackages = with pkgs; [
      polkit
      polkit_gnome
    ] ++ optionals config.custom.userSecurity.gnomeKeyring.enable [
      gnome-keyring
      seahorse
      libsecret
    ];
    
    # Systemd user services
    systemd.user.services = mkIf config.custom.userSecurity.gnomeKeyring.enable {
      gnome-keyring = {
        description = "GNOME Keyring daemon";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --foreground --components=gpg,pkcs11,secrets,ssh";
          Restart = "on-failure";
        };
      };
    };
    
    # Environment variables for keyring
    environment.sessionVariables = mkIf config.custom.userSecurity.gnomeKeyring.enable {
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
      GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring";
    };
    
    # udev rules for device access
    services.udev.extraRules = ''
      # Allow users in plugdev group to access USB devices
      SUBSYSTEM=="usb", GROUP="plugdev", MODE="0664"
      
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
      
      # GPU access permissions
      SUBSYSTEM=="drm", GROUP="render", MODE="0664"
      KERNEL=="card[0-9]*", GROUP="render", MODE="0664"
    '';
  };
}
