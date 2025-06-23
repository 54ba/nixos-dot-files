{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./nixGL.nix
    ./modules/core-packages.nix
    ./modules/optional-packages.nix
    ./modules/pentest-packages.nix
    ./ai-services.nix
  ];
  
  # Force all Python packages to use Python 3.11 to avoid version conflicts
  nixpkgs.config.packageOverrides = pkgs: {
    python3 = pkgs.python311;
    python3Packages = pkgs.python311Packages;
  };
  
  custom.packages.development.enable = true;
  custom.packages.media.enable = true;
  custom.packages.productivity.enable = true;
  custom.packages.gaming.enable = true;
  custom.packages.entertainment.enable = true;
  custom.packages.popular.enable = true;

  # Enable X11 windowing system
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };
    
  # Configure GDM display manager and GNOME desktop
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  
  # Enable touchpad support (for laptops)
  services.libinput = {
    enable = true;
    touchpad.tapping = true;
    touchpad.naturalScrolling = true;
  };

  # Boot loader configuration
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    devices = [ "nodev" ];
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable ZSH
  programs.zsh.enable = true;

  # User configuration
  users.users.mahmoud = {
    isNormalUser = true;
    home = "/home/mahmoud";
    description = "mahmoud";
    extraGroups = [ "wheel" "networkmanager" "docker" "audio" "video" "input" ];
    group = "users";
    shell = pkgs.zsh;
  };

  # Desktop environment packages
  environment.systemPackages = with pkgs; [
    # GUI essentials
    firefox
    nautilus
    gnome-terminal
    flameshot
    pavucontrol
    networkmanagerapplet
    python311  # Use consistent Python 3.11 instead of python3
    
    # Git and credentials
    git
    git-lfs
    gitAndTools.gitFull
    seahorse  # GUI for managing credentials
    
    # System tray and notifications
    libnotify
    gnome-tweaks
    
    # Display and monitor management
    brightnessctl
    
    # Audio
    pulseaudio
    pamixer
    playerctl
    
    # Appearance
    libsForQt5.qt5ct
    gnome-themes-extra
    papirus-icon-theme
    
    # Utilities
    polkit_gnome
    xdg-utils
    xdg-user-dirs
    xdg-desktop-portal
    xdg-desktop-portal-gnome
    desktop-file-utils
    xclip
    xorg.xdpyinfo
    xorg.xrandr
    xorg.xev
    
    # Additional utilities
    gnome-keyring
    libsecret  # For storing credentials
    starship   # Prompt (system-wide installation)
    home-manager  # For managing user configuration
  ];

  # Enable sound with pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  
  # Enable network manager for GUI network management
  networking.networkmanager.enable = true;

  # Enable dconf for some GNOME tools that might be used
  programs.dconf.enable = true;

  # Enable polkit for privilege escalation
  security.polkit.enable = true;

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

  # System state version
  system.stateVersion = "25.05";

  # Enable GNOME services
  services.gnome = {
    core-utilities.enable = true;
    gnome-keyring.enable = true;
  };
  
  # Enable GNOME extensions support
  services.udev.packages = with pkgs; [ gnome-settings-daemon ];
  
  # Configure git globally
  programs.git = {
    enable = true;
    package = pkgs.gitFull;  # Include Git with GUI tools
    config = {
      init.defaultBranch = "main";
      credential.helper = "${pkgs.libsecret}/lib/libsecret/git-credential-libsecret";
    };
  };
  
  # Enable GNOME Keyring
  security.pam.services.gdm.enableGnomeKeyring = true;
  
  # Configure XDG file associations
  xdg = {
    portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
      config = {
        common = {
          default = [ "gnome" ];
        };
      };
    };
    mime = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/chrome" = "firefox.desktop";
        "text/html" = "firefox.desktop";
        "application/x-extension-htm" = "firefox.desktop";
        "application/x-extension-html" = "firefox.desktop";
        "application/x-extension-shtml" = "firefox.desktop";
        "application/xhtml+xml" = "firefox.desktop";
        "application/x-extension-xhtml" = "firefox.desktop";
        "application/x-extension-xht" = "firefox.desktop";
        "inode/directory" = "org.gnome.Nautilus.desktop";
      };
    };
  };

  # Services
  services.openssh.enable = true;
  services.udisks2.enable = true;
  services.dbus.enable = true;
  services.acpid.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;
  
  # Localization
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Binary cache and build optimization settings
  nix.settings = {
    # Enable binary caches to avoid building
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org/"
      "https://devenv.cachix.org/"
      "https://nixpkgs-unfree.cachix.org/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
    ];
    # Prefer binary substitutes over building
    builders-use-substitutes = true;
    # Always try substituters first
    substitute = true;
    # Fallback to building only if no substitute is available
    fallback = true;
    # Keep trying substituters for a while
    connect-timeout = 10;
    # Maximum number of parallel downloads
    max-jobs = "auto";
    # Enable parallel building when needed
    cores = 0;
    # Keep build logs only for failed builds
    keep-outputs = false;
    keep-derivations = false;
    # Optimize store
    auto-optimise-store = true;
  };

  # Enable flakes and new nix command
  nix.extraOptions = ''
    experimental-features = nix-command flakes
    keep-outputs = false
    keep-derivations = false
    # Prefer substitutes over building
    builders-use-substitutes = true
    substitute = true
    # Timeout for substitute attempts
    stalled-download-timeout = 300
  '';

  # Garbage collection to keep system clean
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  
  # Environment variables
  environment.variables = {
    EDITOR = "vim";
    BROWSER = "firefox";
  };
  
  # Hardware acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  
  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  
  # Networking
  networking.hostName = "mahmoud-laptop";
  networking.firewall.enable = false;  # Disabled for development
  
  # Enable container support
  virtualisation.docker.enable = true;
  virtualisation.podman.enable = true;
}

