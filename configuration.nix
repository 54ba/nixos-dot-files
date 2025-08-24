{ config, pkgs, lib, ... }:

{
  imports = [
    # Hardware and essential configuration
    ./hardware-configuration.nix

    # Core system modules (new modular structure)
    ./modules/boot.nix
    ./modules/boot-enhancements.nix
    ./modules/system-base.nix
    ./modules/hardware.nix
    ./modules/display-manager.nix
    ./modules/wayland.nix
    ./modules/security.nix
    ./modules/security-services.nix
    ./modules/user-security.nix
    ./modules/users.nix
    ./modules/device-permissions.nix
    ./modules/system-optimization.nix
    ./modules/system-services.nix
    ./modules/networking.nix

    # Package modules
    ./modules/core-packages.nix
    ./modules/optional-packages.nix
    ./modules/pentest.nix

    # Desktop and application modules
    ./modules/virtualization.nix
    ./modules/containers.nix

    # Application and service modules
    ./modules/ai-services.nix
    ./modules/nixgl.nix
    ./modules/electron-apps.nix
    ./modules/flake-config.nix
    ./modules/custom-binding.nix

    # Enhanced modular configuration
    ./modules/gnome-extensions.nix
    ./modules/package-recommendations.nix
  ];

  # Allow unfree packages and insecure packages
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-27.3.11"
      "electron-33.4.11"
    ];
  };

  # Binary cache and build optimization settings
  nix.settings = {
    # Use substituters when packages aren't available locally
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
    builders-use-substitutes = true;   # Use substituters for building
    substitute = true;                 # Enable substitution from binary caches
    require-sigs = true;
    fallback = false;                  # Don't build from source if substituters fail
    connect-timeout = 30;
    stalled-download-timeout = 300;
    max-jobs = 4;
    cores = 2;
    keep-outputs = false;
    keep-derivations = false;
    auto-optimise-store = true;
    trusted-users = [ "root" "@wheel" ];
    allow-import-from-derivation = true;
    sandbox = false;  # Disable sandboxing for installation - will re-enable after reboot
  };

  # Enable flakes and new nix command
  nix.extraOptions = ''
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
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # ===== MODULAR SYSTEM CONFIGURATION =====

  # Core system modules - MINIMAL WITH BASIC GUI
  custom.boot = {
    enable = true;
    grub = {
      theme = "dark";
      timeout = 5;
      generations = 5;
    };
  };

  custom.system-base = {
    enable = true;
    hostname = "mahmoud-laptop";
    timezone = "Africa/Cairo";
    locale = "en_US.UTF-8";
  };

  # Flatpak setting will be controlled by custom.services.system.flatpak.enable

  # Basic hardware like live USB - minimal GUI support
  custom.hardware = {
    enable = true;
    bluetooth.enable = true;     # Enable Bluetooth support
    audio.enable = true;         # Enable audio like live USB
    input.enable = true;         # Enable input devices (keyboard/mouse)
    graphics.enable = true;      # Enable graphics for basic GUI
  };

  # ENABLE FULL GNOME DESKTOP ENVIRONMENT
  custom.desktop = {
    enable = true;               # Enable full desktop environment
    wayland.enable = true;       # Enable Wayland support
  };

  custom.security = {
    enable = true;
    sudo.enable = true;
    pam.enable = true;
    apparmor.enable = true;      # Enable AppArmor security
  };

  custom.users = {
    enable = true;
    mainUser = {
      name = "mahmoud";
      home = "/home/mahmoud";
      description = "mahmoud";
      shell = pkgs.bash;         # Use bash for minimal setup
    };
  };

  custom.networking = {
    enable = true;               # ENABLED per user request
    hostName = "mahmoud-laptop";
    timeZone = "Africa/Cairo";
    locale = "en_US.UTF-8";
    networkManager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ 53 ];
      extraRules.enable = false;  # Disable extra firewall rules
    };
  };

  # Enable additional modules
  custom.wayland.enable = true;                     # Enable Wayland optimizations
  custom.device-permissions.enable = true;         # Keep device permissions
  custom.system-optimization.enable = true;        # Enable optimizations

  # System services with specific overrides
  custom.services.system = {
    enable = true;                                   # Enable system services
    bluetooth.enable = true;                        # Enable Bluetooth service
    flatpak.enable = true;                          # Enable Flatpak support
  };

  custom.services.security.enable = true;          # Enable security services (correct path)
  custom.userSecurity.enable = true;              # Enable user security
  custom.boot.enhancements.enable = true;          # Enable boot enhancements

  # ===== CUSTOM SSD2 BIND MOUNTS =====
  custom.binding = {
    enable = false;                                  # Disabled - using hardware-configuration.nix instead
    ssd2Path = "/mnt/ssd2";                          # Path to SSD2 mount
    tmp = {
      enable = true;                                 # Bind /tmp to SSD2
      path = "tmp";                                  # Use /mnt/ssd2/tmp
      options = [ "bind" "noatime" ];                # Performance options
    };
    var = {
      enable = true;                                 # Bind /var to SSD2
      path = "var";                                  # Use /mnt/ssd2/var
      options = [ "bind" ];                          # Standard bind options
    };
    createDirectories = true;                        # Auto-create directories
  };

  # ===== GNOME DESKTOP CONFIGURATION =====
  # GNOME desktop environment will be configured through the modules
  # Display manager and desktop environment are handled by the GNOME modules

  # ===== APPLICATION MODULES =====

  # AI Services (disabled by default)
  custom.ai-services = {
    enable = false;  # Enable for AI development
    ollama = {
      enable = true;
      acceleration = "cuda";
    };
    nvidia = {
      enable = true;
      package = "stable";
      powerManagement = false;
    };
    packages.enable = true;
  };

  # These configurations are moved below to avoid duplicates

  # # Home Manager Integration
  # custom.home-manager = {
  #   enable = true;  # Enable for home-manager integration
  #   user = "mahmoud";
  #   configPath = "./home-manager.nix";
  #   useGlobalPkgs = true;
  #   useUserPackages = true;
  #   backupFileExtension = "backup";
  #   development = {
  #     enable = true;
  #     languages = [ "python" "nodejs" "dart" "php" ];
  #   };
  #   shell = {
  #     enable = true;
  #     defaultShell = "zsh";
  #     starship = true;
  #     direnv = true;
  #   };
  #   desktop = {
  #     enable = true;
  #     theme = "Adwaita-dark";
  #     iconTheme = "Papirus-Dark";
  #   };
  # };

  # # Flake Configuration
  # custom.flake = {
  #   enable = true;  # Enable for flake-based configuration management
  # #   inputs = {
  #     nixpkgs = "github:nixos/nixpkgs/nixos-25.05";
  #     nixpkgsUnstable = "github:nixos/nixpkgs/nixos-unstable";
  #     homeManager = "github:nix-community/home-manager/release-25.05";
  #   };
  #   system = "x86_64-linux";
  #   hostname = "mahmoud-laptop";
  #   homeManager = {
  #     enable = true;
  #     useGlobalPkgs = true;
  #     useUserPackages = true;
  #     backupFileExtension = "backup";
  #   };
  #   overlays = {
  #     enable = true;
  #     unstable = true;
  #   };
  # };

  # # ===== DESKTOP AND APPLICATION MODULES =====

  # # GNOME Desktop (enabled for full desktop experience)
  # custom.desktop.gnome = {
  #   enable = true;               # Enable GNOME desktop
  #   extensions.enable = true;    # Enable GNOME extensions
  #   excludeApps.enable = true;   # Exclude unwanted apps
#     theme.enable = true;         # Enable custom theme
  # };

  # Virtualization services
  custom.virtualization = {
    enable = true;               # Enable virtualization
    virtualbox.enable = true;    # Enable VirtualBox
    kvm.enable = true;           # Enable KVM virtualization
    libvirt.enable = true;       # Enable libvirt
  };

  # Container services
  custom.containers = {
    enable = true;               # Enable containers
    podman.enable = false;       # Disable Podman to avoid conflicts
    docker.enable = true;        # Enable Docker support
    dockerCompat = false;        # Disable Docker compatibility (not needed when using Docker directly)
  };

  # Electron Apps with proper Wayland support (RECOMMENDED APPROACH)
  custom.electron-apps = {
    enable = true;                # Enable proper electron app integration
    enableDesktopFiles = true;    # Create desktop files with Wayland flags
    packages = {
      discord.enable = true;      # Install Discord with Wayland support
      chromium.enable = true;     # Use Chromium instead of Google Chrome
      vscode.enable = true;       # Install VS Code with Wayland support
    };
  };

  # nixGL Graphics Compatibility (enable for graphics apps)
  custom.nixgl = {
    enable = true;               # Enable for graphics apps
    defaultWrapper = "intel";
    enableVulkan = true;
    applications = {
      enable = true;
      wrappers = [ "firefox" "chrome" "code" "blender" "steam" ];
    };
    help = true;
  };

  # ===== PACKAGE COLLECTIONS =====

  # Core package configuration
  custom.packages = {
    # ENABLED PACKAGES:
    minimal.enable = true;          # Essential system packages
    core.enable = true;             # Core system packages
    productivity.enable = true;     # Enable productivity packages for full desktop
    development.enable = true;      # Enable development packages
    media.enable = true;            # Enable media packages for full desktop
    entertainment.enable = true;    # Enable entertainment packages
    popular.enable = true;          # Enable popular packages

    # OPTIONAL PACKAGES:
    gaming.enable = false;          # Gaming packages - can enable if needed
    # nixai.enable = false;         # nixai packages - EXCLUDED (option may not exist)
  };

  # Security packages (pentest excluded per user request)
  custom.security = {
    # pentest.enable = false;       # pentest packages - EXCLUDED
  };

  # Enhanced GNOME Extensions Management
  custom.gnome.extensions = {
    enable = true;
    categories = {
      productivity = true; system = true; windows = true; launchers = true;
      media = true; utilities = true; development = true; security = true;
    };
    migration = { windows = true; macos = true; android = true; };
    premium = { enable = true; gnomeLook = true; pling = true; };
    settings.enable = true; performance.enable = true;
  };

  # Package Recommendations
  custom.packageRecommendations = {
    enable = true;
    categories = {
      productivity = true; development = true; creative = true; gaming = true;
      system = true; networking = true; education = true;
    };
    hardware = { enable = true; gpu = true; cpu = true; memory = true; storage = true; };
    usage = { enable = true; developer = true; designer = true; gamer = true; student = true; business = true; };
    ai = { enable = true; hardwareOptimization = true; performanceTuning = true; };
  };

  # # Ensure WAYLAND_DISPLAY is set globally for all applications
  environment.sessionVariables = {
    WAYLAND_DISPLAY = "wayland-0";
  };


}

