{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.users = {
      enable = mkEnableOption "user configuration" // { default = true; };
      mainUser = {
        name = mkOption {
          type = types.str;
          default = "mahmoud";
          description = "Main user name";
        };
        home = mkOption {
          type = types.str;
          default = "/home/mahmoud";
          description = "Main user home directory";
        };
        description = mkOption {
          type = types.str;
          default = "mahmoud";
          description = "Main user description";
        };
        shell = mkOption {
          type = types.package;
          default = pkgs.zsh;
          description = "Main user shell";
        };
      };
    };
  };

  config = mkIf config.custom.users.enable {
    # Enable ZSH
    programs.zsh.enable = true;
    
    # Enhanced user configuration with comprehensive groups
    users.users.${config.custom.users.mainUser.name} = {
      isNormalUser = true;
      home = config.custom.users.mainUser.home;
      description = config.custom.users.mainUser.description;
      extraGroups = [ 
        "wheel"           # sudo access
        "networkmanager"  # network management
        "podman"         # container management
        "audio"          # audio devices
        "video"          # video devices
        "input"          # input devices
        "storage"        # storage devices
        "disk"           # disk access for partitioning
        "optical"        # CD/DVD access
        "scanner"        # scanner access
        "lp"             # printer access
        "dialout"        # serial port access
        "uucp"           # serial communications
        "tty"            # TTY access
        "floppy"         # floppy disk (legacy)
        "cdrom"          # CD-ROM access
        "tape"           # tape devices
        "kvm"            # KVM virtualization
        "libvirtd"       # libvirt virtualization
        "docker"         # Docker (if used)
        "flatpak"        # Flatpak system access
        "vboxusers"      # VirtualBox access
        "wireshark"      # network analysis
        "render"         # GPU rendering
        "gamemode"       # gaming performance
        "adbusers"       # Android debugging bridge
        "plugdev"        # USB device access for Android
      ];
      group = "users";
      shell = config.custom.users.mainUser.shell;
    };
    
    # Additional groups for system functionality
    users.groups = {
      vboxusers = {};
      wireshark = {};
      gamemode = {};
      flatpak = {};
      adbusers = {};   # Android debugging
      plugdev = {};    # USB device access
      netdev = {};     # Network device management
      storage = {};    # Storage device access group
    };
    
    # Enhanced systemd user services
    systemd.user.services = {
      fix-user-permissions = {
        description = "Fix user directory permissions";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            ${pkgs.coreutils}/bin/chmod 755 ${config.custom.users.mainUser.home}
            ${pkgs.coreutils}/bin/chmod 700 ${config.custom.users.mainUser.home}/.ssh
            ${pkgs.coreutils}/bin/find ${config.custom.users.mainUser.home} -type d -exec chmod 755 {} +
            ${pkgs.coreutils}/bin/find ${config.custom.users.mainUser.home} -type f -exec chmod 644 {} +
          '';
          RemainAfterExit = true;
        };
        wantedBy = [ "default.target" ];
      };
    };
    
    # System-wide tmpfiles rules for user directories
    systemd.tmpfiles.rules = [
      "d ${config.custom.users.mainUser.home} 0755 ${config.custom.users.mainUser.name} users -"
      "d ${config.custom.users.mainUser.home}/.config 0755 ${config.custom.users.mainUser.name} users -"
      "d ${config.custom.users.mainUser.home}/.local 0755 ${config.custom.users.mainUser.name} users -"
      "d ${config.custom.users.mainUser.home}/.local/share 0755 ${config.custom.users.mainUser.name} users -"
      "d ${config.custom.users.mainUser.home}/.cache 0755 ${config.custom.users.mainUser.name} users -"
      "d ${config.custom.users.mainUser.home}/Downloads 0755 ${config.custom.users.mainUser.name} users -"
      "d ${config.custom.users.mainUser.home}/Documents 0755 ${config.custom.users.mainUser.name} users -"
      "d ${config.custom.users.mainUser.home}/Pictures 0755 ${config.custom.users.mainUser.name} users -"
      "d ${config.custom.users.mainUser.home}/Videos 0755 ${config.custom.users.mainUser.name} users -"
      "d ${config.custom.users.mainUser.home}/Music 0755 ${config.custom.users.mainUser.name} users -"
      "d ${config.custom.users.mainUser.home}/Desktop 0755 ${config.custom.users.mainUser.name} users -"
      "d ${config.custom.users.mainUser.home}/.ssh 0700 ${config.custom.users.mainUser.name} users -"
      "d ${config.custom.users.mainUser.home}/.local/share/flatpak 0755 ${config.custom.users.mainUser.name} users -"
      "d '${config.custom.users.mainUser.home}/VirtualBox VMs' 0755 ${config.custom.users.mainUser.name} users -"
      "d ${config.custom.users.mainUser.home}/Development 0755 ${config.custom.users.mainUser.name} users -"
      "d ${config.custom.users.mainUser.home}/Projects 0755 ${config.custom.users.mainUser.name} users -"
      "d /run/user 0755 root root -"
      "d /var/lib/systemd 0755 root root -"
    ];
  };
}
