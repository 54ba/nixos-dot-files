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

            # Gaming Performance
      DXVK_HUD = "1";
      DXVK_STATE_CACHE = "1";
      VKD3D_CONFIG = "dxr,dxr11";
    };

    # Basic system packages
    environment.systemPackages = import ../packages/system-base-packages.nix { inherit pkgs; };





    # Nix configuration for user access and binary caches
    nix = {
      # Package and build settings
      package = pkgs.nixVersions.stable;
      
      settings = {
        # Experimental features
        experimental-features = [ "nix-command" "flakes" ];
        
        # Binary cache and substitution settings
        substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org/"
          "https://devenv.cachix.org/"
          "https://nixpkgs-unfree.cachix.org/"
          "https://cuda-maintainers.cachix.org/"
          "https://hyprland.cachix.org/"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPiCgBV8vQQGjqozR5lnLBcBJKqKzR6bE="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3rkCI6Vd0HQRSIo3VbK+LSnRVQCQ="
        ];
        
        # User access control
        trusted-users = [ "root" "@wheel" "mahmoud" ];
        allowed-users = [ "@wheel" "mahmoud" ];
        
        # Build optimization
        builders-use-substitutes = true;   # Use substituters for building
        substitute = true;                 # Enable substitution from binary caches
        require-sigs = true;
        fallback = true;                   # Allow source builds when caches fail
        connect-timeout = 30;
        stalled-download-timeout = 300;
        max-jobs = 2;  # Allow local builds when substitutes fail
        cores = 2;
        keep-outputs = false;
        keep-derivations = false;
        auto-optimise-store = true;
        allow-import-from-derivation = true;
        sandbox = true;   # Re-enable sandboxing for security
        max-substitution-jobs = 16;
        warn-dirty = false;
      };

      # Additional Nix configuration
      extraOptions = ''
        experimental-features = nix-command flakes
        keep-outputs = false
        keep-derivations = false
        builders-use-substitutes = true
        substitute = true
        stalled-download-timeout = 300
        connect-timeout = 30
        max-substitution-jobs = 16
        warn-dirty = false
      '';

      # Garbage collection
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };
    
    # System state version
    system.stateVersion = "25.05";
  };
}
