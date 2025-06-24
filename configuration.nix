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
  
  # Use default Python 3.12 for better binary cache compatibility
  # nixpkgs.config.packageOverrides = pkgs: {
  #   python3 = pkgs.python311;
  #   python3Packages = pkgs.python311Packages;
  # };
  
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

  # Boot loader configuration with beautiful theme
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;  # Detect other operating systems
    configurationLimit = 10;  # Keep last 10 generations
    default = "saved";  # Remember last choice
    
    # Custom GRUB configuration for better appearance and functionality
    extraConfig = ''
      # Set custom colors for menu - beautiful dark theme
      set color_normal=light-cyan/black
      set color_highlight=white/blue
      
      # Set timeout with menu visible
      set timeout_style=menu
      
      # Better font rendering
      set gfxmode=auto
      set gfxpayload=keep
      
      # Enable graphics terminal
      terminal_output gfxterm
      
      # Show menu entries clearly
      set menu_color_normal=light-cyan/black
      set menu_color_highlight=white/blue
      
      # Custom boot message
      echo "Loading NixOS - Mahmoud's Laptop..."
      echo "Use arrow keys to select boot option"
    '';
    
    # Set resolution for better display
    gfxmodeEfi = "1920x1080,1366x768,1024x768,auto";
    gfxmodeBios = "1920x1080,1366x768,1024x768,auto";
    
    # Use original splash image for now
    splashImage = ./backgrounds/bg.jpg;
    
    # Font configuration for better text rendering
    font = "${pkgs.grub2}/share/grub/unicode.pf2";
  };
  
  # Set timeout separately as recommended
  boot.loader.timeout = 10;
  
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Boot splash and kernel parameters for eye candy
  boot.initrd.systemd.enable = true;
  boot.plymouth = {
    enable = true;
    theme = "breeze";  # Beautiful boot splash
  };
  
  # Fix systemd services and virtual sessions
  systemd.services."getty@tty1".enable = true;
  systemd.services."autovt@tty1".enable = true;
  
  # Disable getty@tty7 since GDM display manager conflicts with it
  # GDM is using tty2, so tty7 getty is not needed
  systemd.services."getty@tty7".enable = false;
  
  # Enable proper session management
  services.logind.lidSwitch = "suspend";
  services.logind.extraConfig = ''
    HandlePowerKey=poweroff
    HandleSuspendKey=suspend
    HandleHibernateKey=hibernate
    HandleLidSwitch=suspend
    IdleAction=ignore
    KillUserProcesses=no
    KillOnlyUsers=
    KillExcludeUsers=root
    InhibitDelayMaxSec=5
  '';
  
  # Kernel parameters for better boot experience
  boot.kernelParams = [
    "quiet"          # Less verbose boot
    "splash"         # Show splash screen
    "rd.udev.log_level=3"  # Reduce udev log noise
    "vt.global_cursor_default=0"  # Hide cursor during boot
  ];
  
  # Console settings - fix console setup issues
  boot.consoleLogLevel = 0;
  boot.kernelPackages = pkgs.linuxPackages;  # Use stable kernel for better compatibility
  
  # Fix console font issues - use properly configured console font
  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-v16n.psf.gz";
    keyMap = "us";
    useXkbConfig = false;  # Use console keyMap
  };
  
  # Enable ZSH
  programs.zsh.enable = true;

  # Enhanced user configuration with comprehensive groups
  users.users.mahmoud = {
    isNormalUser = true;
    home = "/home/mahmoud";
    description = "mahmoud";
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
    ];
    group = "users";
    shell = pkgs.zsh;
  };
  
  # Additional groups for system functionality - ensure storage group exists
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
    # Ensure proper permissions for user directories
    fix-user-permissions = {
      description = "Fix user directory permissions";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.coreutils}/bin/chmod 755 /home/mahmoud
          ${pkgs.coreutils}/bin/chmod 700 /home/mahmoud/.ssh
          ${pkgs.coreutils}/bin/find /home/mahmoud -type d -exec chmod 755 {} +
          ${pkgs.coreutils}/bin/find /home/mahmoud -type f -exec chmod 644 {} +
        '';
        RemainAfterExit = true;
      };
      wantedBy = [ "default.target" ];
    };
  };

  # Desktop environment packages
  environment.systemPackages = with pkgs; [
    # Console font packages - fix virtual console setup
    terminus_font
    kbd
    
    # GUI essentials
    firefox
    nautilus
    gnome-terminal
    flameshot
    pavucontrol
    networkmanagerapplet
    python3  # Use default Python 3.12 for better binary compatibility
    
    # Git and credentials
    git
    git-lfs
    gitAndTools.gitFull
    git-credential-manager  # Modern git credentials manager
    seahorse  # GUI for managing credentials
    libsecret  # For storing credentials securely
    gnome-keyring  # GNOME keyring for credential storage
    
    # System tray and notifications
    libnotify
    gnome-tweaks
    gnome-shell-extensions
    gnomeExtensions.user-themes
    gnomeExtensions.dash-to-dock
    gnomeExtensions.arc-menu
    gnomeExtensions.blur-my-shell
    gnomeExtensions.compiz-windows-effect
    gnomeExtensions.desktop-icons-ng-ding
    gnomeExtensions.sound-output-device-chooser
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.workspace-indicator
    gnomeExtensions.removable-drive-menu
    gnomeExtensions.system-monitor
    gnomeExtensions.vitals
    gnomeExtensions.weather-oclock
    
    # Additional GNOME eye candy
    gnome-photos
    gnome-music
    gnome-maps
    gnome-calculator
    gnome-weather
    gnome-clocks
    gnome-calendar
    
    # Display and monitor management
    brightnessctl
    
    # Audio
    pulseaudio
    pamixer
    playerctl
    
    # Appearance and themes
    libsForQt5.qt5ct
    gnome-themes-extra
    papirus-icon-theme
    adwaita-icon-theme
    hicolor-icon-theme
    yaru-theme
    materia-theme
    nordic
    orchis-theme
    
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
    
    # Security and firewall tools
    fail2ban     # Intrusion prevention
    clamav       # Antivirus scanner
    nmap         # Network discovery and security auditing
    iptables     # Advanced firewall rules
    lsof         # List open files
    psmisc       # Process utilities (pstree, killall, etc.)
    nettools     # Network utilities (netstat, etc.)
    
    # Container tools for Podman
    podman-compose  # Docker-compose equivalent for Podman
    podman-tui     # Terminal UI for Podman
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
    gnome-online-accounts.enable = true;
  };
  
  # Configure credential management services
  services.dbus.enable = true;
  
  
  # Enable Flatpak
  services.flatpak.enable = true;
  
  # Comprehensive Google Chrome fixes
  programs.chromium = {
    enable = true;
    extensions = [
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
      "hkgfoiooedgoejojocmhlaklaeopbecg" # Picture-in-Picture Extension
    ];
  };
  
  # Chrome-specific fixes and environment variables
  environment.sessionVariables = {
    CHROME_WRAPPER = "${pkgs.google-chrome}/bin/google-chrome-stable";
    CHROME_DESKTOP = "google-chrome";
    # Fix Chrome sandbox issues
    CHROME_FLAGS = "--no-sandbox --disable-gpu-sandbox --disable-software-rasterizer";
    # Enable hardware acceleration
    NIXOS_OZONE_WL = "1";
  };
  
  # Security and sandbox fixes for Chrome
  security.chromiumSuidSandbox.enable = true;
  
  # Enable kernel namespaces for proper sandboxing
  security.allowUserNamespaces = true;
  
  # Enhanced security settings
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    # Allow wheel group to run certain commands without password
    extraRules = [{
      users = [ "mahmoud" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/mount";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/umount";
          options = [ "NOPASSWD" ];
        }
      ];
    }];
  };
  
  # Enhanced file permissions and access controls
  security.pam.loginLimits = [
    {
      domain = "@users";
      item = "nofile";
      type = "soft";
      value = "65536";
    }
    {
      domain = "@users";
      item = "nofile";
      type = "hard";
      value = "65536";
    }
    {
      domain = "@wheel";
      item = "nice";
      type = "soft";
      value = "-10";
    }
  ];
  
  # Enhanced AppArmor security (optional, comment out if issues)
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true;
  };
  
  # File system permissions and mount options
  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "defaults" "noatime" "nodiratime" "nosuid" "nodev" "noexec" "size=2G" ];
  };
  
  # VirtualBox configuration and permissions (temporarily disabled due to kernel compatibility)
  # virtualisation.virtualbox.host = {
  #   enable = true;
  #   enableExtensionPack = false;  # Disabled to use binary cache
  #   addNetworkInterface = true;
  # };
  
  # Wireshark permissions (allows non-root packet capture)
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };
  
  # GameMode for better gaming performance
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
  
  # Enhanced file system and device permissions - fixed udev rules
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
    
    # Camera and webcam permissions
    SUBSYSTEM=="video4linux", KERNEL=="video[0-9]*", GROUP="video", MODE="0664"
  '';
  
  # Enhanced PAM configuration for better session management
  security.pam.services = {
    # Login session enhancements
    login.enableGnomeKeyring = true;
    gdm.enableGnomeKeyring = true;
    gdm-password.enableGnomeKeyring = true;
    
    # Set proper umask for all sessions
    common-session = {
      text = ''
        session optional pam_umask.so umask=0022
      '';
    };
  };
  
  # Additional system-wide file and directory permissions - fixed tmpfiles syntax
  systemd.tmpfiles.rules = [
    # Ensure proper permissions for common directories
    "d /home/mahmoud 0755 mahmoud users -"
    "d /home/mahmoud/.config 0755 mahmoud users -"
    "d /home/mahmoud/.local 0755 mahmoud users -"
    "d /home/mahmoud/.local/share 0755 mahmoud users -"
    "d /home/mahmoud/.cache 0755 mahmoud users -"
    "d /home/mahmoud/Downloads 0755 mahmoud users -"
    "d /home/mahmoud/Documents 0755 mahmoud users -"
    "d /home/mahmoud/Pictures 0755 mahmoud users -"
    "d /home/mahmoud/Videos 0755 mahmoud users -"
    "d /home/mahmoud/Music 0755 mahmoud users -"
    "d /home/mahmoud/Desktop 0755 mahmoud users -"
    
    # Secure SSH directory
    "d /home/mahmoud/.ssh 0700 mahmoud users -"
    
    # Flatpak user directories
    "d /home/mahmoud/.local/share/flatpak 0755 mahmoud users -"
    
    # VirtualBox directories
    "d /home/mahmoud/VirtualBox\\ VMs 0755 mahmoud users -"
    
    # Development directories with proper permissions
    "d /home/mahmoud/Development 0755 mahmoud users -"
    "d /home/mahmoud/Projects 0755 mahmoud users -"
    
    # Fix systemd-tmpfiles permissions issues
    "d /run/user 0755 root root -"
    "d /var/lib/systemd 0755 root root -"
  ];
  
  # Install custom desktop entries (commented out temporarily)
  # environment.etc = {
  #   "xdg/applications/riseup-vpn.desktop".source = ./desktop-entries/riseup-vpn.desktop;
  #   "xdg/applications/github-desktop.desktop".source = ./desktop-entries/github-desktop.desktop;
  #   "xdg/applications/wezterm.desktop".source = ./desktop-entries/wezterm.desktop;
  #   "xdg/applications/gparted.desktop".source = ./desktop-entries/gparted.desktop;
  #   "xdg/applications/cursor.desktop".source = ./desktop-entries/cursor.desktop;
  #   "xdg/applications/figma-linux.desktop".source = ./desktop-entries/figma-linux.desktop;
  #   # Background images will be added when bg.jpg is placed in backgrounds folder
  # };
  
  # Enable GNOME extensions support and additional tweaks
  services.udev.packages = with pkgs; [ gnome-settings-daemon ];
  
  # GNOME appearance and behavior tweaks
  environment.gnome.excludePackages = with pkgs; [
    # Remove unwanted GNOME apps to keep system clean
    gnome-tour
    epiphany  # GNOME web browser
    geary     # Email client
    totem     # Video player (we have better alternatives)
  ];
  
  # Enable additional GNOME services for better integration
  services.gnome.evolution-data-server.enable = true;
  
  # GNOME Shell configuration
  services.xserver.desktopManager.gnome = {
    extraGSettingsOverrides = ''
      [org.gnome.desktop.interface]
      gtk-theme='Adwaita-dark'
      icon-theme='Papirus-Dark'
      cursor-theme='Adwaita'
      enable-animations=true
      enable-hot-corners=true
      
      [org.gnome.desktop.wm.preferences]
      theme='Adwaita-dark'
      button-layout='appmenu:minimize,maximize,close'
      
      [org.gnome.shell]
      enabled-extensions=['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com', 'blur-my-shell@aunetx', 'caffeine@patapon.info']
      
      [org.gnome.shell.extensions.dash-to-dock]
      dock-position='BOTTOM'
      transparency-mode='DYNAMIC'
      running-indicator-style='DOTS'
      
      [org.gnome.mutter]
      experimental-features=['scale-monitor-framebuffer']
    '';
  };
  
  # Configure git globally
  programs.git = {
    enable = true;
    package = pkgs.gitFull;  # Include Git with GUI tools
    config = {
      init.defaultBranch = "main";
      credential.helper = "${pkgs.libsecret}/lib/libsecret/git-credential-libsecret";
    };
  };
  
  # GNOME Keyring is already configured in PAM services above
  
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
  services.acpid.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;
  
  # Localization
  time.timeZone = "Africa/Cairo";
  i18n.defaultLocale = "en_US.UTF-8";
  
  
  # Allow unfree packages and specific insecure packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "electron-27.3.11"  # Required for some applications
    "electron-33.4.11"  # Required for some applications
  ];

  # Binary cache and build optimization settings
  nix.settings = {
    # Enable binary caches to avoid building
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org/"
      "https://devenv.cachix.org/"
      "https://nixpkgs-unfree.cachix.org/"
      "https://cuda-maintainers.cachix.org/"  # For gaming/NVIDIA packages
      "https://hyprland.cachix.org/"          # For modern desktop packages
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPiCgBV8vQQGjqozR5lnLBcBJKqKzR6bE="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3rkCI6Vd0HQRSIo3VbK+LSnRVQCQ="
    ];
    # Prefer binary substitutes over building - aggressive settings
    builders-use-substitutes = true;
    # Always try substituters first
    substitute = true;
    # Require signatures for better security
    require-sigs = true;
    # Fallback to building only if no substitute is available
    fallback = true;
    # Extended timeout for downloads
    connect-timeout = 30;
    stalled-download-timeout = 300;
    # Limit parallel jobs to reduce memory pressure
    max-jobs = 4;  # Reduced from "auto" to prevent overwhelming system
    # Limit cores per build job
    cores = 2;     # Reduced from 0 (unlimited) to prevent memory issues
    # Keep build logs only for failed builds
    keep-outputs = false;
    keep-derivations = false;
    # Optimize store and use hard links to save space
    auto-optimise-store = true;
    # Trust binary caches more aggressively
    trusted-users = [ "root" "@wheel" ];
    # Allow import-from-derivation for better compatibility
    allow-import-from-derivation = true;
  };

  # Enable flakes and new nix command with aggressive binary cache preferences
  nix.extraOptions = ''
    experimental-features = nix-command flakes
    keep-outputs = false
    keep-derivations = false
    # Prefer substitutes over building aggressively
    builders-use-substitutes = true
    substitute = true
    # Extended timeouts for binary cache
    stalled-download-timeout = 300
    connect-timeout = 30
    # Try harder to avoid building
    max-substitution-jobs = 16
    # Warn instead of failing on missing substitutes
    warn-dirty = false
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
  # Enhanced firewall configuration with iptables
  networking.firewall = {
    enable = true;
    # Allow essential services
    allowedTCPPorts = [ 22 80 443 ];
    allowedUDPPorts = [ 53 123 68 ];
    # Allow local network communication
    trustedInterfaces = [ "lo" ];
    # Log dropped packets
    logRefusedConnections = true;
    logRefusedPackets = true;
    # Additional firewall rules
    extraCommands = ''
      # Allow local network communication
      iptables -A INPUT -s 192.168.0.0/16 -j ACCEPT
      iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT
      iptables -A INPUT -s 172.16.0.0/12 -j ACCEPT
      
      # Allow mDNS for service discovery
      iptables -A INPUT -p udp --dport 5353 -j ACCEPT
      
      # Allow KDE Connect if needed (comment out if not used)
      # iptables -A INPUT -p tcp --dport 1714:1764 -j ACCEPT
      # iptables -A INPUT -p udp --dport 1714:1764 -j ACCEPT
      
      # Rate limiting for SSH to prevent brute force
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 --rttl --name SSH -j DROP
    '';
    extraStopCommands = ''
      iptables -D INPUT -s 192.168.0.0/16 -j ACCEPT 2>/dev/null || true
      iptables -D INPUT -s 10.0.0.0/8 -j ACCEPT 2>/dev/null || true
      iptables -D INPUT -s 172.16.0.0/12 -j ACCEPT 2>/dev/null || true
    '';
  };
  
  # Fail2ban configuration for intrusion prevention
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      formula = "ban.Time * (1<<(ban.Count if ban.Count<20 else 20)) * findtime";
      maxtime = "24h";
    };
    # Default jails
    jails = {
      apache-nohome-iptables.settings = {
        # Disable if you don't use Apache
        enabled = false;
      };
      ssh-iptables = {
        settings = {
          enabled = true;
          port = "ssh";
          filter = "sshd";
          logpath = "/var/log/auth.log";
          maxretry = 3;
          bantime = 3600;
        };
      };
      # Add more jails as needed
    };
  };
  
  # ClamAV antivirus configuration
  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
    updater.frequency = 2;  # Update twice daily
  };
  
  # Enable periodic security scans
  systemd.services.security-scan = {
    description = "Periodic security scan with ClamAV";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeScript "security-scan" ''
        #!/bin/bash
        echo "Running security scan at $(date)" | systemd-cat -t security-scan
        
        # Quick ClamAV scan of home directory
        ${pkgs.clamav}/bin/clamscan --recursive --infected --bell /home/mahmoud | systemd-cat -t clamav-scan
        
        # Check for open ports
        ${pkgs.nettools}/bin/netstat -tuln | systemd-cat -t port-scan
        
        # Check for suspicious processes
        ${pkgs.psmisc}/bin/pstree | systemd-cat -t process-scan
        
        echo "Security scan completed at $(date)" | systemd-cat -t security-scan
      '';
      User = "root";
    };
  };
  
  # Schedule security scans
  systemd.timers.security-scan = {
    description = "Run security scan daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
  
  # Enable container support - prefer Podman over Docker for better binary cache usage
  virtualisation.docker.enable = false;  # Disabled to avoid compilation
  virtualisation.podman = {
    enable = true;
    # Docker compatibility layer
    dockerCompat = true;
    dockerSocket.enable = true;
    # Required for containers under podman
    defaultNetwork.settings.dns_enabled = true;
    # Auto-update containers
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
  
  # Add alias for docker -> podman compatibility
  environment.shellAliases = {
    docker = "podman";
    docker-compose = "podman-compose";
  };
  
  # Fix the UserTasksMax deprecation issue by configuring systemd slices
  systemd.slices."user-.slice" = {
    sliceConfig = {
      TasksMax = "infinity";
    };
  };
  
  # Fix shutdown and reboot issues with /nix/store
  systemd.services.nix-store-umount-fix = {
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
  };
  
  # Additional systemd settings to prevent /nix/store umount issues
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=30s
    DefaultTimeoutStartSec=30s
  '';
  
  # D-Bus is already enabled above
}
