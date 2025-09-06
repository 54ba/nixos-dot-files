{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.system-base = {
      enable = mkEnableOption "base system services and configuration" // { default = true; };
      hostname = mkOption {
        type = types.str;
        default = "mahmoud-laptop";
        description = "System hostname";
      };
      timezone = mkOption {
        type = types.str;
        default = "Africa/Cairo";
        description = "System timezone";
      };
      locale = mkOption {
        type = types.str;
        default = "en_US.UTF-8";
        description = "System locale";
      };
    };
  };

  config = mkIf config.custom.system-base.enable {
    # System identity
    networking.hostName = config.custom.system-base.hostname;
    time.timeZone = config.custom.system-base.timezone;
    i18n.defaultLocale = config.custom.system-base.locale;

    # Basic services
    services = {
      openssh.enable = true;
      udisks2.enable = true;
      acpid.enable = true;
      dbus.enable = true;
      flatpak.enable = true;
    };



    # Network manager
    networking.networkmanager.enable = true;
    systemd.services.NetworkManager-wait-online.enable = false;

    # Android development services
    programs.adb.enable = true;

    # Enable nix-ld for compatibility
    programs.nix-ld.enable = true;



    # Font configuration
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      jetbrains-mono
      font-awesome
    ];

    # Chromium configuration
    programs.chromium = {
      enable = true;
      extensions = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "hkgfoiooedgoejojocmhlaklaeopbecg" # Picture-in-Picture Extension
      ];
    };

    # Git configuration
    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      config = {
        init.defaultBranch = "main";
        credential.helper = "${pkgs.libsecret}/lib/libsecret/git-credential-libsecret";
      };
    };

    # Wireshark and GameMode
    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };

    programs.gamemode = {
      enable = true;
      settings = {
        general = {
          renice = 10;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
          amd_performance_level = "high";
        };
      };
    };

    # Environment variables
    environment.variables = {
      EDITOR = "vim";
      BROWSER = "firefox";

      # Gaming Performance (can be overridden by Wine module)
      DXVK_HUD = mkDefault "1";
      DXVK_STATE_CACHE = "1";
      VKD3D_CONFIG = "dxr,dxr11";
    };

    # Basic system packages
    environment.systemPackages = import ../packages/system-base-packages.nix { inherit pkgs; };





    # System state version
    system.stateVersion = "25.05";
  };
}
