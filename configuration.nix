{ config, pkgs, lib, ... }:

{
  imports = [
    # === ESSENTIAL CORE MODULES ===
    ./hardware-configuration.nix
    ./cachix.nix                          # ENABLED - Cachix Python packages cache
    
    # Core system infrastructure
    ./modules/boot.nix
    ./modules/system-base.nix
    ./modules/hardware.nix
    ./modules/networking.nix
    
    # Enhanced application support
    ./modules/screen-sharing.nix
    ./modules/enhanced-packages.nix
    
    # Security framework (simplified)
    ./modules/security.nix
    ./modules/users.nix
    
    # Privacy and censorship circumvention
    ./modules/privacy-circumvention.nix      # ENABLED - Tor, obfs4, Snowflake, Riseup VPN
    
    # Desktop environment
    ./modules/display-manager.nix
    ./modules/wayland.nix
    ./modules/gnome-extensions.nix           # ENABLED - Testing for stage view allocation warnings
    ./modules/gtk-enhanced.nix
    ./modules/niri.nix                       # ENABLED - Niri window manager
    
    # Package management
    ./modules/core-packages.nix
    ./modules/profile-packages.nix
    ./modules/shell-environment.nix
    
    # Development tools
    ./modules/ai-services.nix
    ./modules/electron-apps.nix
    ./modules/void-editor.nix
    ./modules/dev-libs-test.nix
    
    # Intelligent Recording System - DISABLED DUE TO CONFLICTS
    # ./modules/desktop-recording.nix                 # DISABLED - Desktop recording capabilities (conflicts)
    # ./modules/input-capture.nix                     # DISABLED - Missing scripts
    # ./modules/data-pipeline.nix                     # DISABLED - Data processing pipeline (conflicts)
    # ./modules/ai-orchestrator.nix                   # DISABLED - AI orchestration (conflicts)
    # ./modules/intelligent-recording-system.nix      # DISABLED - Missing scripts
    
    # System utilities
    ./modules/virtualization.nix
    ./modules/containers.nix
    ./modules/custom-binding.nix
    ./modules/nixgl.nix
    
    # System health monitoring
    # ./modules/health-monitoring.nix             # DISABLED - System health monitoring (per user request)
    
    # Rescue system with generation management
    # ./modules/rescue-system.nix                 # DISABLED - Advanced rescue system (per user request)
    
    # SteamOS and Mobile PC Integration - DISABLED DUE TO CONFLICTS
    # ./modules/steamos-gaming.nix                 # DISABLED - SteamOS-like gaming environment (conflicts)
    # ./modules/steamos-mobile-suite.nix           # DISABLED - SteamOS mobile suite (conflicts)
    # ./modules/mobile-integration.nix             # DISABLED - Part of mobile suite (conflicts)
    # ./modules/remote-control.nix                 # DISABLED - Remote control capabilities (conflicts)
    # ./modules/ssh-remote-access.nix              # DISABLED - SSH remote access (conflicts)
    
    # === OPTIONAL MODULES (can be disabled for simplification) ===
    ./modules/boot-enhancements.nix              # ENABLED - Boot enhancements
    # ./modules/security-services.nix             # DISABLED - Security services (conflicts)
    # ./modules/user-security.nix                 # DISABLED - User security enhancements (conflicts)
    # ./modules/device-permissions.nix            # DISABLED - Device permission management (conflicts)
    ./modules/system-optimization.nix
    ./modules/system-services.nix
    ./modules/optional-packages.nix              # ENABLED - Optional package collections
    # ./modules/pentest.nix                       # DISABLED - Penetration testing tools (conflicts)
    ./modules/wine-support.nix                   # ENABLED - Wine compatibility layer for gaming
    ./modules/package-recommendations.nix        # ENABLED - Package recommendations
    # ./modules/windows-compatibility.nix         # DISABLED - Windows app compatibility (conflicts)
    ./modules/lenovo-s540-gtx-15iwl.nix         # ENABLED - Lenovo hardware optimizations
    ./modules/home-manager-integration.nix       # ENABLED - Home manager integration
    ./modules/nvidia-performance.nix             # ENABLED - NVIDIA gaming optimizations (compatible with ai-services)
    # ./modules/pam-consolidated.nix              # DISABLED - conflicts with main PAM config
    ./modules/nixai-integration.nix              # ENABLED - NixAI integration
    ./modules/migration-assistant.nix            # ENABLED - System migration tools
  ];

  # Allow unfree packages and insecure packages
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-27.3.11"
      "electron-33.4.11"
    ];
  };

  # nameservers handled by dnsmasq configuration above

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
  };

  # Nix configuration for user access
  nix = {
    # Allow users in wheel group to use Nix and fix home-manager permissions
    settings.trusted-users = [ "root" "@wheel" "mahmoud" ];
    settings.allowed-users = [ "@wheel" "mahmoud" ];

    # Enable flakes and new nix command
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

  # ===== MODULAR SYSTEM CONFIGURATION =====

  # Core system modules - MINIMAL WITH BASIC GUI
  custom.boot = {
    enable = true;
    grub = {
      theme = "none";                      # FIXED - Disable theme to prevent boot errors
      timeout = 10;                        # Allow time to select generations
      generations = 50;                    # Show all generations for recovery
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
    audio.enable = false;        # Disable - audio handled by system services
    input.enable = true;         # Enable input devices (keyboard/mouse)
    graphics.enable = true;      # Enable graphics for basic GUI
  };

  # Desktop environment configuration moved to gnome-consolidated.nix module

  custom.security = {
    enable = true;
    sudo.enable = true;
    pam.enable = true;           # Enable consolidated PAM configuration
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
  custom.screen-sharing.enable = true;              # Enable enhanced screen sharing support
  custom.enhanced-packages.enable = true;           # Enable enhanced application packages
  
  # Enable Electron apps with proper Wayland support and screen sharing
  custom.electron-apps = {
    enable = true;                                   # Enable Electron apps module
    enableDesktopFiles = true;                      # Create desktop files with proper flags
    packages = {
      discord.enable = true;                         # Discord with Wayland screen sharing
      chromium.enable = true;                        # Chromium with WebRTC PipeWire support
      vscode.enable = true;                          # VS Code with Wayland support
    };
  };
  
  # Enable system optimization
  custom.system-optimization.enable = true;         # Enable system performance optimizations
  
  # Enable enhanced system services
  custom.services.system = {
    enable = true;                                   # Enable enhanced system services
    ssh.enable = true;                               # Enable SSH server
    audio.enable = true;                             # Enable PipeWire audio
    bluetooth.enable = true;                         # Enable Bluetooth
    printing.enable = false;                         # Disable printing for now
    flatpak.enable = true;                           # Enable Flatpak
    gamemode.enable = true;                          # Enable GameMode
    android.enable = false;                          # Disable Android tools for now
    fuse.enable = true;                              # Enable FUSE support
  };
  
  # Enable PipeWire for screen sharing and audio
  services.pipewire = {
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
  
  # Disable PulseAudio since we're using PipeWire
  services.pulseaudio.enable = false;
  
  # Enable real-time scheduling for audio
  security.rtkit.enable = true;
  
  # Enhanced touchpad support with gestures - Override module settings
  services.libinput = {
    enable = lib.mkForce true;
    touchpad = {
      # Basic touchpad settings
      tapping = lib.mkForce true;                    # Enable tap-to-click
      tappingDragLock = lib.mkForce true;           # Enable drag lock after tapping
      naturalScrolling = lib.mkForce true;           # Natural (reverse) scrolling like macOS
      scrollMethod = lib.mkForce "twofinger";        # Two-finger scrolling
      disableWhileTyping = lib.mkForce true;        # Disable touchpad while typing
      
      # Advanced gesture settings
      clickMethod = lib.mkForce "clickfinger";       # Click method for multi-touch
      accelProfile = lib.mkForce "adaptive";         # Adaptive acceleration profile
      accelSpeed = lib.mkForce "0.3";               # Moderate acceleration speed (override module)
      
      # Gesture recognition settings
      horizontalScrolling = lib.mkForce true;       # Enable horizontal scrolling
      middleEmulation = lib.mkForce true;           # Enable middle mouse button emulation
      
      # Additional libinput options for gestures
      additionalOptions = lib.mkForce ''
        # Enhanced gesture support
        Option "Tapping" "on"
        Option "TappingDrag" "on"
        Option "TappingDragLock" "on"
        Option "NaturalScrolling" "true"
        Option "ScrollMethod" "twofinger"
        Option "HorizontalScrolling" "true"
        Option "ClickMethod" "clickfinger"
        
        # Multi-touch gesture support
        Option "PalmDetection" "on"
        Option "PalmMinWidth" "8"
        Option "PalmMinZ" "100"
        
        # Gesture thresholds
        Option "SwipeThreshold" "0.25"
        Option "PinchThreshold" "0.25"
        
        # Disable edge scrolling in favor of two-finger
        Option "EdgeScrolling" "off"
        Option "VertEdgeScroll" "off"
        Option "HorizEdgeScroll" "off"
      '';
    };
  };
  
  # Enable GNOME Remote Desktop for screen sharing
  services.gnome.gnome-remote-desktop.enable = true;
  
  # XDG Desktop Portal configuration for screen sharing AND file dialogs
  xdg.portal = {
    enable = lib.mkForce true;
    wlr.enable = lib.mkForce false;  # Disable wlr portal as we're using GNOME
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config = lib.mkForce {
      common = {
        default = [ "gnome" "gtk" ];
        "org.freedesktop.impl.portal.Screencast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gnome" "gtk" ];  # CRITICAL: File save/open dialogs
        "org.freedesktop.impl.portal.AppChooser" = [ "gnome" "gtk" ];   # CRITICAL: App chooser dialogs
      };
      gnome = {
        default = [ "gnome" "gtk" ];
        "org.freedesktop.impl.portal.Screencast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gnome" "gtk" ];  # CRITICAL: File save/open dialogs
        "org.freedesktop.impl.portal.AppChooser" = [ "gnome" "gtk" ];   # CRITICAL: App chooser dialogs
      };
      x11 = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.Screencast" = [ "gtk" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];           # CRITICAL: File save/open dialogs for X11 apps
        "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];            # CRITICAL: App chooser dialogs for X11 apps
      };
    };
  };
  
  # Enable enhanced security services
  custom.services.security = {
    enable = true;                                   # Enable security services
    firewall = {
      enable = true;                                 # Enable enhanced firewall
      allowedTCPPorts = [ 22 80 443 ];              # Allow SSH, HTTP, HTTPS
      allowedUDPPorts = [ 53 123 68 ];              # Allow DNS, NTP, DHCP
    };
    ssh = {
      enable = true;                                 # Enable SSH with security
      passwordAuthentication = false;               # Disable password auth
      permitRootLogin = "no";                       # Disable root login
    };
    fail2ban.enable = true;                          # Enable fail2ban
    hardening.enable = true;                         # Enable system hardening
  };
  
  # Health Monitoring - DISABLED (module commented out)
  # custom.healthMonitoring configuration removed to prevent option errors
  
  # Rescue System - DISABLED (module commented out)
  # custom.rescueSystem configuration removed to prevent option errors

  # ===== CUSTOM DATA DRIVE MOUNTS =====
  fileSystems."/mnt/data" = {
    device = "/dev/nvme0n1p1";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # Bind mounts for user data and Docker
  fileSystems."/home/mahmoud/.share" = {
    device = "/mnt/data/.share";
    options = [ "bind" ];
    depends = [ "/mnt/data" ];
  };

  fileSystems."/var/lib/docker" = {
    device = "/mnt/data/var/lib/docker";
    options = [ "bind" ];
    depends = [ "/mnt/data" ];
  };

  # ===== GNOME DESKTOP CONFIGURATION =====
  # GNOME configuration consolidated below to avoid conflicts

  # ===== APPLICATION MODULES =====

  # AI Services with CUDA acceleration - NVIDIA drivers handled by nvidia-performance module
  custom.ai-services = {
    enable = true;                        # Enable AI services
    ollama = {
      enable = true;                      # ENABLED - Testing PyTorch build
      acceleration = "cuda";               # Enable CUDA acceleration
    };
    nvidia = {
      enable = false;                     # DISABLED - Let nvidia-performance module handle NVIDIA drivers
      package = "stable";
      powerManagement = true;
    };
    packages.enable = true;               # ENABLED - Testing PyTorch build with binary caches
  };

  # Enable proprietary NVIDIA drivers for nvidia-smi
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;  # Disable fine-grained to avoid assertion error
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # Test Development Libraries Configuration
  custom.dev-libs-test = {
    enable = true;                        # Enable test development libraries module
  };

  # Development Libraries Configuration - TEMPORARILY DISABLED
  # custom.development-libraries = {
  #   enable = true;                        # Enable development libraries module
  #   core = true;                          # Enable core C/C++ libraries (glibc, libstdc++, etc.)
  #   graphics = true;                      # Enable graphics libraries (Mesa, Vulkan, etc.)
  #   multimedia = true;                    # Enable multimedia libraries (FFmpeg, GStreamer, etc.)
  #   networking = true;                    # Enable networking libraries (OpenSSL, curl, etc.)
  #   compression = true;                   # Enable compression libraries (zlib, bzip2, etc.)
  #   gui = true;                           # Enable GUI libraries (GTK, Qt, etc.)
  #   database = false;                     # Disable database libraries by default
  #   python = false;                       # Disable Python libraries by default
  #   nodejs = false;                       # Disable Node.js libraries by default
  #   java = false;                         # Disable Java libraries by default
  # };

  # Binary cache management with Cachix - ENABLED via root cachix.nix
  # Configuration handled by ./cachix.nix import above

  # === REMOVED MODULES FOR SIMPLIFICATION ===
  # NixAI Integration - Disabled (module not imported)
  # Migration Assistant - Disabled (module not imported) 
  # Home Manager Integration - Disabled (permission issues)

  # ===== CRITICAL FIXES FOR SYSTEMD ISSUES =====
  # Fix nsncd service failures by disabling it and using dnsmasq instead
  services.nscd.enable = false;               # Disable problematic nsncd
  system.nssModules = lib.mkForce [];         # Disable NSS modules when nscd is disabled
  
  # WORKING DNS CONFIGURATION: Use systemd-resolved which was functioning properly
  # Remove conflicting dnsmasq configuration that caused port 53 conflicts
  
  # Keep systemd-resolved enabled (from networking module) - it was working fine
  # services.resolved.enable = true; # This is handled by networking module
  
  # Remove problematic custom dnsmasq service that conflicts with NetworkManager
  # services.dnsmasq.enable = false; # Default is false
  
  # Let NetworkManager use its default DNS configuration (systemd-resolved)
  # networking.networkmanager.dns = "systemd-resolved"; # This is handled by networking module
  
  # NetworkManager configuration is now handled by modules/networking.nix
  
  # Enable SSD TRIM support for better performance and longevity
  services.fstrim.enable = true;
  
  # Enable GNOME keyring service properly
  services.gnome.gnome-keyring.enable = true;
  
  # Ensure AccountsService is enabled for GDM user authentication
  services.accounts-daemon.enable = true;
  
  # Fix D-Bus services for GNOME session
  services.dbus = {
    enable = true;
    packages = [ pkgs.gnome-session ];
  };

  # Ensure IBus is available (fixes 'ibus-daemon not found') - using new syntax
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
  };
  
  # Disable problematic recovery service to avoid conflicts
  # systemd.user.services.gnome-session-failed-services-recovery disabled
  
  # RESTORED WORKING KERNEL PARAMETERS FROM GENERATION 16
  # Simplified, clean configuration that matches the working generation
  boot.kernelParams = lib.mkForce [
    # Base hardware parameters (from hardware-configuration.nix)
    "usbcore.autosuspend=-1"
    "usbcore.use_both_schemes=1" 
    "pcie_aspm=off"
    "intel_pstate=active"
    
    # Intel graphics optimizations (working settings)
    "i915.enable_psr=0"
    "i915.enable_fbc=1"
    
    # WORKING BOOT CONFIGURATION (matches generation 16)
    "quiet"                                       # Quiet boot (working configuration)
    "splash"                                      # Boot splash
    "rd.udev.log_level=3"                         # Normal udev logging
    "vt.global_cursor_default=0"                  # Hide cursor
    
    # WORKING ACPI CONFIGURATION (from generation 16)
    "acpi_osi=Linux"                              # Use Linux ACPI (working setting)
    "acpi_backlight=vendor"                       # Vendor backlight control
    
    # NVIDIA GRAPHICS CONFIGURATION - DISABLED temporarily to fix login loop
    # "nvidia_drm.modeset=1"                        # Enable NVIDIA DRM modesetting (disabled)
    # "nouveau.modeset=0"                           # Disable nouveau to use NVIDIA (disabled)
    
    # Security framework
    "lsm=landlock,yama,bpf,apparmor"
    "audit=1"
    "apparmor=1"
    
    # Filesystem
    "root=fstab"
    
    # Boot logging (minimal for stability)
    "loglevel=0"                                  # Minimal logging (working setting)
  ];
  
  # Disable ThinkFan service as it's failing on this hardware
  services.thinkfan.enable = false;
  
  # SIMPLIFIED LOGGING CONFIGURATION (matches working generation 16)
  # Reduce logging to prevent boot issues
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
  
  # Boot generations limit is now handled by custom.boot.grub.generations in modules/boot.nix
  # Health monitoring is now handled by modules/health-monitoring.nix
  
  # ===== DESKTOP ENVIRONMENT CONFIGURATION =====
  # Enable desktop environment and GNOME
  custom.desktop = {
    enable = true;                    # Enable desktop environment
    wayland.enable = true;            # Enable Wayland (works in generation 45)
    gnome = {
      enable = true;                  # Enable GNOME desktop environment
      extensions.enable = true;       # ENABLED - Testing for stage view allocation warnings
      excludeApps.enable = true;      # Exclude unwanted apps
      theme.enable = true;            # Enable custom theming
    };
  };
  
  # Niri Window Manager Configuration
  custom.niri = {
    enable = true;                    # Enable Niri scrollable-tiling compositor
    enableGdm = true;                 # Enable GDM session integration
    defaultTerminal = "gnome-terminal";
    startupPrograms = [
      "waybar"                        # Status bar
      "dunst"                         # Notification daemon
    ];
  };

  # PAM configuration handled by existing modules

    # ===== GNOME CONFIGURATION =====
  # GNOME configuration handled by display-manager.nix module

  # Virtualization services
  custom.virtualization = {
    enable = true;               # Enable virtualization
    virtualbox.enable = false;   # Disable VirtualBox to prevent module loading errors
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

  # Privacy and Censorship Circumvention
  custom.privacy-circumvention = {
    enable = true;                # Enable censorship circumvention tools
    
    # Tor with pluggable transports
    tor = {
      enable = true;             # Enable Tor with SOCKS proxy
      obfs4 = {
        enable = true;           # Enable obfs4 bridges for traffic obfuscation
        bridges = [              # Add obfs4 bridges (you can add more here)
          # Example bridges - replace with actual working bridges
          # "obfs4 192.95.36.142:443 CDF2E852BF539B82BD549EB5A0C1F7C5CA26881BA57A99E8F6A3A59C2B21B30E cert=SWnSJ4z5Fq1LQOCDQCu3AcVUiHPFnUTqBL6mPZnDU55JYkc+Tnn7a9g+CW8FVnE2z5BF6g iat-mode=0"
          # "obfs4 85.31.186.98:443 011F2599C0E9B27EE74B353155E244813763C3E5 cert=ayq0XzCwhpdysn5o0EyDUbmSOx3X/oTEbzDMvjNqKoZd/z7y7L9DaXEEEhWOjfWPmDvRyQ iat-mode=0"
        ];
      };
      snowflake = {
        enable = true;           # Enable Snowflake pluggable transport
        # Default settings for Snowflake - will use built-in configuration
      };
    };
    
    # Riseup VPN with Tor transport support
    riseupVpn = {
      enable = true;             # Enable Riseup VPN client
      useTorTransport = false;   # Set to true to use Tor as transport by default
      kerSupport = true;         # Enable KER (obfs with KCP) support
    };
    
    # Privacy browsers
    browser = {
      torBrowser = true;         # Enable Tor Browser
      hardened = true;           # Enable hardened browser configuration
    };
  };

  # === ACTIVE MODULE CONFIGURATIONS ===
  # Only configurations for imported modules
  

  # nixGL Graphics Compatibility
  custom.nixgl = {
    enable = true;
    defaultWrapper = "intel";
    enableVulkan = true;
    applications = {
      enable = true;
      wrappers = [ "firefox" "chrome" "code" "blender" "steam" ];
    };
    help = true;
  };

  # Shell Environment Configuration
  custom.shellEnvironment = {
    enable = true;
    features = {
      starship = true; direnv = true; fzf = true; bat = true;
      exa = true; fd = true; ripgrep = true; jq = true;
      htop = true; tmux = true; zoxide = true;
    };
    aliases = {
      enable = false;  # DISABLED - Keep original commands available
      ls = "exa --icons --group-directories-first";
      ll = "exa --icons --group-directories-first -la";
      cat = "bat"; grep = "rg"; find = "fd";
    };
  };

  # GTK and Desktop Enhancements
  custom.gtk = {
    enable = true;
    version = "both";
    theming = {
      enable = true;
      theme = "Adwaita";
      iconTheme = "Adwaita";
      cursorTheme = "Adwaita";
      cursorSize = 24;
      fontName = "Cantarell 11";
    };
    wayland = {
      enable = true;
      fractionalScaling = true;
      touchScrolling = true;
    };
    performance = {
      enable = true;
      animations = true;
      rendering = "auto";
    };
    applications.fileChooser.enable = true;
  };

  # Core package configuration is handled in the Optional Package Collections section below

  # Void Editor Configuration
  custom.void-editor = {
    enable = true;
    createDesktopEntry = true;
  };


  #   # Ensure WAYLAND_DISPLAY is set globally for all applications
  environment.sessionVariables = {
    WAYLAND_DISPLAY = "wayland-0";
  };

  # NVIDIA Performance Optimizations - DISABLED temporarily to fix login/logout loop
  custom.nvidiaPerformance = {
    enable = false;                              # Disable NVIDIA performance optimizations temporarily
    gaming = {
      enable = true;                             # Enable gaming optimizations
      dlss = true;                               # Enable DLSS support
      rayTracing = true;                         # Enable ray tracing
      performanceMode = "performance";           # Use performance mode
    };
    monitoring = {
      enable = false;                            # Monitoring packages work, but disabled by default for safety
      autoStart = false;                         # Auto-start disabled for safety
      tools = {
        nvitop = true;                           # Enable nvitop GPU monitoring tool when monitoring is enabled
        nvtop = true;                            # Enable nvtop GPU monitoring tool when monitoring is enabled 
        gpustat = true;                          # Enable gpustat GPU monitoring tool when monitoring is enabled
      };
    };
  };

  # ===== NEWLY ENABLED MODULE CONFIGURATIONS =====
  # (NVIDIA Performance configuration moved above to avoid duplicates)
  
  # Wine Support for Windows Applications - ENABLED with minimal configuration
  custom.wine = {
    enable = true;                        # Enable Wine support
    packages = {
      wine64 = true;                      # Enable Wine 64-bit
      winetricks = true;                  # Enable Winetricks
      lutris = true;                      # Enable Lutris
      dxvk = true;                        # Enable DXVK for DirectX
      vkd3d = true;                       # Enable VKD3D for DirectX 12
      mono = true;                        # Enable .NET support
      gecko = true;                       # Enable web browser support
    };
    performance = {
      enable = true;                      # Enable performance optimizations
      esync = true;                       # Enable Esync
      fsync = true;                       # Enable Fsync
      gamemode = true;                    # Enable GameMode
      mangohud = true;                    # Enable MangoHud
    };
    compatibility = {
      enable = true;                      # Enable compatibility features
      dpiScaling = true;                  # Enable DPI scaling
      audio = true;                       # Enable enhanced audio
      networking = true;                  # Enable networking support
    };
  };
  
  # Windows Compatibility Layer - DISABLED (module commented out)
  # custom.windowsCompatibility configuration removed to prevent option errors
  
  # Migration Assistant
  custom.migrationAssistant = {
    enable = true;                         # Enable migration assistant
    features = {
      backup = true;                       # Enable backup functionality
      restore = true;                      # Enable restore functionality
      validation = true;                   # Enable configuration validation
      rollback = true;                     # Enable rollback functionality
    };
    tools = {
      enable = true;                       # Enable migration tools
      scripts = true;                      # Enable migration scripts
      gui = false;                         # Disable GUI for now (command-line only)
    };
  };
  
  # Lenovo S540 GTX 15IWL Hardware Optimizations
  custom.lenovoS540Gtx15iwl = {
    enable = true;                         # Enable Lenovo-specific optimizations
    performance = {
      enable = true;                       # Enable performance optimizations
      cpuGovernor = "performance";         # Use performance CPU governor
      thermalManagement = false;           # Disable ThinkFan (conflicts with current setup)
      powerManagement = true;              # Enable power management optimizations
    };
  };
  
  # Boot Enhancements - RESTORED FOR GNOME/TTY FIX
  custom.boot.enhancements.enable = true;        # Enable boot enhancements
  custom.boot.plymouth = {
    enable = true;                                # Enable Plymouth boot splash
    theme = "breeze";                            # Use breeze theme
  };
  custom.boot.quietBoot.enable = true;           # Enable quiet boot mode
  
  # DIRECT PLYMOUTH CONFIGURATION TO OVERRIDE MODULE ISSUES
  boot.plymouth = {
    enable = lib.mkForce true;                    # Force enable Plymouth
    theme = "breeze";                             # Use breeze theme
  };
  
  # RESTORE MISSING KERNEL PARAMETERS (critical for TTY/display)
  # These parameters are added to the existing boot.kernelParams below
  
  # User Security Enhancements - DISABLED (module commented out)
  # custom.userSecurity configuration removed to prevent option errors
  
  # Device Permission Management - DISABLED (module commented out)
  # custom.device-permissions configuration removed to prevent option errors
  
  # Optional Package Collections
  custom.packages = {
    essential.enable = true;               # Enable essential packages
    media.enable = true;                   # Enable media and graphics packages
    development.enable = true;             # Enable development packages
    productivity.enable = true;            # Enable productivity packages
    popular.enable = true;                 # Enable popular packages collection
    entertainment.enable = true;           # ENABLED - Entertainment software packages
    gaming.enable = true;                  # Enable gaming packages for SteamOS
    pentest.enable = true;                 # ENABLED - Testing penetration testing tools
  };
  
  # Profile-based packages migrated to system config
  custom.profile-packages.enable = true;    # ENABLED - Packages from nix profiles
  
  # Penetration Testing Tools (handled by custom.packages.pentest.enable above)
  
  # Package Recommendations
  custom.packageRecommendations = {
    enable = true;                         # Enable package recommendations
    categories = {
      productivity = true;                 # Enable productivity package recommendations
      development = true;                  # Enable development package recommendations
      creative = true;                     # Enable creative package recommendations
      gaming = false;                      # Disable gaming recommendations for now
      system = true;                       # Enable system utility recommendations
      networking = false;                  # Disable networking tools for security
      education = true;                    # Enable educational software recommendations
    };
    hardware = {
      enable = true;                       # Enable hardware-based recommendations
      gpu = true;                          # Enable GPU-specific recommendations
      cpu = true;                          # Enable CPU-specific recommendations
      memory = true;                       # Enable memory-specific recommendations
      storage = true;                      # Enable storage-specific recommendations
    };
    usage = {
      enable = true;                       # Enable usage-based recommendations
      developer = true;                    # Enable developer profile recommendations
      designer = true;                     # Enable designer profile recommendations
      gamer = false;                       # Disable gamer profile for now
      student = true;                      # Enable student profile recommendations
      business = false;                    # Disable business profile for now
    };
    ai = {
      enable = false;                      # Disable AI-powered recommendations for now
      hardwareOptimization = false;       # Disable hardware optimization suggestions
      performanceTuning = false;           # Disable performance tuning recommendations
    };
  };
  
  # Home Manager Integration
  custom.home-manager = {
    enable = true;                         # Enable Home Manager integration
    user = "mahmoud";                       # Username for home-manager configuration
    configPath = "./home-manager-base.nix"; # Path to home-manager configuration file
    useGlobalPkgs = true;                  # Use global package set for home-manager
    useUserPackages = true;                # Install packages to user profile
    backupFileExtension = "backup";        # Extension for backup files
    development = {
      enable = true;                       # Enable development tools in home-manager
      languages = [ "python" "nodejs" "dart" "php" ]; # Development languages to enable
    };
    shell = {
      enable = true;                       # Configure shell with home-manager
      defaultShell = "zsh";                # Default shell to configure
      starship = true;                     # Enable starship prompt
      direnv = true;                       # Enable direnv integration
    };
    desktop = {
      enable = true;                       # Configure desktop environment settings
      theme = "Adwaita-dark";              # GTK theme name
      iconTheme = "Papirus-Dark";          # Icon theme name
    };
  };
  
  # NixAI Integration
  custom.nixaiIntegration = {
    enable = true;                         # Enable NixAI for recording system
    features = {
      cli = true;                          # Enable nixai CLI tools
      gui = false;                         # Disable nixai GUI applications for now
      development = true;                  # Enable nixai development tools
      ai = true;                           # Enable nixai AI capabilities
    };
    packages = {
      enable = true;                       # Enable nixai packages
      core = true;                         # Enable core nixai packages
      extras = true;                       # Enable extra nixai packages
    };
  };

  # ===== INTELLIGENT RECORDING SYSTEM COMPONENTS =====
  # Recording system modules are currently disabled due to missing script dependencies
  # The intelligent recording system will be configured later when scripts are available
  
  # ===== STEAMOS AND MOBILE PC INTEGRATION =====
  # SteamOS Mobile Suite - DISABLED (module commented out)
  # custom.steamos-mobile-suite configuration removed to prevent option errors
  
  # SteamOS Gaming Environment - DISABLED (module commented out)
  # custom.steamos-gaming configuration removed to prevent option errors

  # ===== COMPREHENSIVE SYSTEM CONFIGURATION =====

  # System-wide security and permissions
  security = {
    # Allow users in wheel group to run sudo without password
    sudo.wheelNeedsPassword = lib.mkForce false;

    # Enable comprehensive security features
    apparmor.enable = true;
    # Disable auditd due to configuration errors
    # auditd.enable = true;
    polkit.enable = true;

    # PAM configuration
    pam.services = {
      login.enableGnomeKeyring = true;
      gdm.enableGnomeKeyring = true;
      gdm-password.enableGnomeKeyring = true;
      gdm-fingerprint.enableGnomeKeyring = true;
    };
  };

  # User management and permissions
  users.users.mahmoud = {
    isNormalUser = true;
    description = "mahmoud";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" "libvirtd" "kvm" "input" "systemd-journal" ];
    shell = lib.mkForce pkgs.zsh;
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here if needed
    ];
  };

  # System-wide environment variables
  environment = {
    systemPackages = with pkgs; [
      # Essential tools
      vim
      wget
      curl
      git
      htop
      tree
      ripgrep
      fd
      bat
      eza
      fzf
      tmux
      starship
      direnv

      # Development tools
      python3
      nodejs
      rustc
      cargo
      go
      gcc
      cmake
      ninja
      
      # Firefox with enhanced Wayland screen sharing support
      (pkgs.firefox.override {
        # Enable WebRTC and PipeWire screen sharing
        cfg.enablePipeWire = true;
      })
      
      # Firefox wrapper with WebRTC PipeWire support
      (pkgs.writeShellScriptBin "firefox-screenshare" ''
        # Firefox with enhanced screen sharing support
        export MOZ_ENABLE_WAYLAND=1
        export MOZ_USE_XINPUT2=1
        export MOZ_WEBRENDER=1
        export MOZ_ACCELERATED=1
        
        # WebRTC PipeWire environment
        export PIPEWIRE_RUNTIME_DIR="/run/user/$(id -u)"
        
        # Set Firefox preferences for screen sharing
        FIREFOX_PREFS_DIR="$HOME/.mozilla/firefox"
        if [ -d "$FIREFOX_PREFS_DIR" ]; then
            # Find default profile
            PROFILE=$(find "$FIREFOX_PREFS_DIR" -name "*.default*" -type d | head -n1)
            if [ -n "$PROFILE" ] && [ -d "$PROFILE" ]; then
                # Create or update user.js with screen sharing preferences
                cat >> "$PROFILE/user.js" << 'EOF'
// Enable WebRTC screen sharing with PipeWire on Wayland
user_pref("media.webrtc.pipewire", true);
user_pref("media.webrtc.capture.allow-capturer", true);
user_pref("media.navigator.mediadatadecoder_vpx_enabled", true);
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("widget.dmabuf.force-enabled", true);
user_pref("media.webrtc.hw.h264.enabled", true);
user_pref("media.webrtc.hw.vp8.enabled", true);
user_pref("media.webrtc.hw.vp9.enabled", true);
EOF
            fi
        fi
        
        exec ${pkgs.firefox}/bin/firefox "$@"
      '')
      
      # Chrome with comprehensive screen sharing support
      (pkgs.google-chrome.override {
        commandLineArgs = [
          # Wayland and screen sharing
          "--ozone-platform-hint=auto"
          "--enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder,VaapiIgnoreDriverChecks,WebRTCPipeWireCapturer,WebRTCScreenCaptureV2"
          "--disable-features=UseChromeOSDirectVideoDecoder"
          "--enable-wayland-ime"
          "--disable-gpu-sandbox"
          
          # Additional WebRTC and screen sharing optimizations
          "--enable-webrtc-pipewire-capturer"
          "--rtc-use-pipewire"
          "--enable-gpu-rasterization"
          "--enable-zero-copy"
          "--ignore-gpu-blocklist"
          
          # Force PipeWire for screen capture
          "--webrtc-max-cpu-consumption-percentage=100"
          "--force-dark-mode"
        ];
      })
      
      # Chromium with enhanced screen sharing support  
      (pkgs.chromium.override {
        commandLineArgs = [
          # Wayland and screen sharing  
          "--ozone-platform-hint=auto"
          "--enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder,WebRTCPipeWireCapturer,WebRTCScreenCaptureV2"
          "--enable-wayland-ime"
          "--disable-gpu-sandbox"
          
          # WebRTC PipeWire support
          "--enable-webrtc-pipewire-capturer"
          "--rtc-use-pipewire"
          "--enable-gpu-rasterization"
          "--enable-zero-copy"
        ];
      })
      
      # Zoom with screen sharing support (if using system package)
      (pkgs.writeShellScriptBin "zoom-screenshare" ''
        # Set up screen sharing environment for Zoom
        export XDG_SESSION_TYPE="wayland"
        export XDG_CURRENT_DESKTOP="gnome"
        export WAYLAND_DISPLAY="wayland-0"
        export QT_QPA_PLATFORM="wayland;xcb"
        export GDK_BACKEND="wayland,x11"
        
        # WebRTC and PipeWire support
        export PIPEWIRE_RUNTIME_DIR="/run/user/$(id -u)"
        export PIPEWIRE_MEDIA_SESSION_CONFIG_DIR="/etc/pipewire/media-session.d"
        
        exec ${pkgs.zoom-us}/bin/zoom "$@"
      '')
      
      # Discord with enhanced Wayland support
      (pkgs.writeShellScriptBin "discord-wayland" ''
        # Discord with Wayland screen sharing support
        export XDG_SESSION_TYPE="wayland"
        export XDG_CURRENT_DESKTOP="gnome"
        export WAYLAND_DISPLAY="wayland-0"
        
        # Enable Ozone/Wayland for Electron
        export ELECTRON_OZONE_PLATFORM_HINT="auto"
        export NIXOS_OZONE_WL="1"
        
        # WebRTC flags for screen sharing
        FLAGS="--enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer,VaapiVideoDecoder"
        FLAGS="$FLAGS --ozone-platform=wayland --enable-wayland-ime"
        FLAGS="$FLAGS --enable-webrtc-pipewire-capturer --rtc-use-pipewire"
        
        exec ${pkgs.discord}/bin/discord $FLAGS "$@"
      '')
      
      # Slack with Wayland screen sharing
      (pkgs.writeShellScriptBin "slack-wayland" ''
        # Slack with enhanced Wayland screen sharing
        export XDG_SESSION_TYPE="wayland"
        export XDG_CURRENT_DESKTOP="gnome"
        export WAYLAND_DISPLAY="wayland-0"
        
        # Electron Wayland support
        export ELECTRON_OZONE_PLATFORM_HINT="auto"
        export NIXOS_OZONE_WL="1"
        
        # WebRTC screen sharing flags
        FLAGS="--enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer"
        FLAGS="$FLAGS --ozone-platform=wayland --enable-wayland-ime"
        FLAGS="$FLAGS --enable-webrtc-pipewire-capturer --rtc-use-pipewire"
        FLAGS="$FLAGS --disable-gpu-sandbox"
        
        exec ${pkgs.slack}/bin/slack $FLAGS "$@"
      '')

      # System tools
      pciutils
      usbutils
      lshw
      hwloc
      iotop
      smartmontools
      
      # Cypress testing framework with all dependencies
      cypress                # Cypress end-to-end testing framework
      glib                   # GLib library for Cypress

      # XDG Desktop utilities and integration tools
      xdg-utils                # XDG desktop integration utilities (xdg-open, xdg-mime, etc.)
      xdg-user-dirs           # XDG user directory management
      xdg-user-dirs-gtk       # GTK frontend for XDG user dirs
      desktop-file-utils      # Desktop entry validation and processing
      shared-mime-info        # MIME type database
      hicolor-icon-theme      # Base icon theme
      
      # Enhanced XDG and desktop integration - CRITICAL FOR SCREEN SHARING
      xdg-desktop-portal      # Desktop portal framework for sandboxed apps
      xdg-desktop-portal-gnome # GNOME implementation of desktop portals
      xdg-desktop-portal-gtk  # GTK implementation of desktop portals
      xdg-desktop-portal-wlr  # wlroots implementation for additional support
      xdg-ninja              # Check for XDG Base Directory compliance
      handlr                  # Better xdg-utils alternative for file associations
      mimeo                   # File association and MIME type manager
      
      # CRITICAL SCREEN SHARING PACKAGES
      gst_all_1.gstreamer   # GStreamer 1.x multimedia framework
      gst_all_1.gst-plugins-base    # Base GStreamer plugins
      gst_all_1.gst-plugins-good    # Good quality GStreamer plugins
      gst_all_1.gst-plugins-bad     # Additional GStreamer plugins
      gst_all_1.gst-plugins-ugly    # Additional GStreamer plugins
      pipewire              # Audio/video server (includes GStreamer plugin)
      wireplumber           # PipeWire session manager
      
      # TOUCHPAD GESTURE SUPPORT PACKAGES
      libinput              # Modern input handling library
      libinput-gestures     # Gesture recognition for touchpad
      touchegg              # Multi-touch gesture recognizer
      fusuma               # Multi-touch gesture recognizer for Linux
      evtest               # Input event testing tool
      xdotool              # X11 automation tool for gesture actions
      ydotool              # Wayland automation tool for gesture actions
      
      # File association and MIME tools
      file                    # File type detection utility (includes libmagic)
      perlPackages.FileMimeInfo # Perl MIME info utilities
      
      # Desktop environment integration
      glib                    # GLib library with desktop integration tools
      gsettings-desktop-schemas # Desktop schemas for GSettings
      dbus                    # D-Bus system for desktop communication
      at-spi2-core           # Accessibility toolkit
      
      # Icon and theme management
      adwaita-icon-theme      # GNOME Adwaita icon theme
      gnome-icon-theme       # Classic GNOME icon theme
      papirus-icon-theme     # Papirus icon theme
      numix-icon-theme       # Numix icon theme
      
      # Font management and XDG fonts
      fontconfig              # Font configuration and management (includes fc-list)
      
      # Application launchers and desktop tools
      rofi                    # Application launcher and window switcher
      ulauncher              # Application launcher for Linux
      
      # Clipboard and desktop utilities
      xclip                   # Command line clipboard interface
      xsel                    # Command line clipboard selection tool
      
      # Notification system (XDG notifications)
      libnotify               # Desktop notification library
      dunst                   # Lightweight notification daemon
      
      # Dialog and menu tools for GUI wrappers
      dialog                  # Terminal dialog boxes
      newt                    # Provides whiptail command for dialog menus
      zenity                  # GTK dialog boxes
      
      # MAC Address Spoofing and Network Tools
      macchanger              # Change MAC addresses of network interfaces
      ethtool                 # Display and change ethernet device settings
      iw                      # Wireless configuration utility
      wirelesstools          # Wireless network configuration tools
      aircrack-ng             # Wireless network security tools (includes aireplay-ng)
      wireshark              # Network protocol analyzer
      nmap                    # Network discovery and security auditing
      nettools               # Network configuration tools (ifconfig, route, etc.)
      
      # Hostname compatibility for applications like AnyDesk
      hostname-debian
      lsb-release
      
      # AnyDesk wrapper script for proper functionality
      (pkgs.writeShellScriptBin "anydesk-working" ''
        # Set up proper environment for AnyDesk
        export PATH="${pkgs.hostname-debian}/bin:$PATH"
        
        # GTK/Wayland compatibility settings
        export GDK_BACKEND=x11
        export QT_QPA_PLATFORM=xcb
        export XDG_SESSION_TYPE=x11
        
        # Suppress GTK warnings
        export G_MESSAGES_DEBUG=""
        export GTK_DEBUG=""
        
        # Ensure X11 display is available for AnyDesk
        if [ -z "$DISPLAY" ]; then
          export DISPLAY=:0
        fi
        
        # Enable screen sharing capabilities
        export WAYLAND_DISPLAY=""
        
        # Run AnyDesk with error suppression
        exec ${pkgs.anydesk}/bin/anydesk "$@" 2>/dev/null
      '')
      
      # RustDesk wrapper with Wayland support
      (pkgs.writeShellScriptBin "rustdesk-wayland" ''
        # RustDesk with Wayland optimizations
        export WAYLAND_DISPLAY="wayland-0"
        export XDG_SESSION_TYPE="wayland"
        export GDK_BACKEND="wayland,x11"
        export QT_QPA_PLATFORM="wayland;xcb"
        
        # Enable screen sharing
        export ELECTRON_OZONE_PLATFORM_HINT="auto"
        export NIXOS_OZONE_WL="1"
        
        exec ${pkgs.rustdesk}/bin/rustdesk "$@"
      '')
      
      # Desktop entry for AnyDesk
      (pkgs.makeDesktopItem {
        name = "anydesk-working";
        desktopName = "AnyDesk (Working)";
        comment = "Fast and secure remote desktop application";
        exec = "anydesk-working";
        icon = "anydesk";
        categories = [ "Network" "RemoteAccess" ];
      })
      
      # Desktop entry for RustDesk with Wayland support
      (pkgs.makeDesktopItem {
        name = "rustdesk-wayland";
        desktopName = "RustDesk (Wayland)";
        comment = "Remote desktop application with Wayland screen sharing";
        exec = "rustdesk-wayland";
        icon = "rustdesk";
        categories = [ "Network" "RemoteAccess" ];
      })
      
      # Home Manager for manual user management
      home-manager
      
      # MAC Address Management Script
      (pkgs.writeShellScriptBin "mac-manager" ''
        exec ${pkgs.bash}/bin/bash /etc/nixos/scripts/mac-manager.sh "$@"
      '')
      
      # XDG Utilities Management Script
      (pkgs.writeShellScriptBin "xdg-manager" ''
        exec ${pkgs.bash}/bin/bash /etc/nixos/scripts/xdg-manager.sh "$@"
      '')
      
      # GUI MAC Address Manager with interactive menu
      (pkgs.writeShellScriptBin "mac-manager-gui" ''
        # Interactive MAC Address Manager GUI
        DIALOG_HEIGHT=20
        DIALOG_WIDTH=70
        
        # Check if dialog/whiptail is available
        if command -v whiptail &>/dev/null; then
            DIALOG=whiptail
        elif command -v dialog &>/dev/null; then
            DIALOG=dialog
        else
            # Fallback to zenity for GUI environments
            if command -v zenity &>/dev/null; then
                # Use zenity GUI version
                exec zenity --question --text="MAC Address Manager\n\nChoose an action:" --ok-label="Open Terminal Manager" --cancel-label="Cancel"
                if [ $? -eq 0 ]; then
                    exec gnome-terminal -- sudo mac-manager
                fi
                exit 0
            else
                # Final fallback to gnome-terminal with menu
                exec gnome-terminal --title="MAC Address Manager" -- bash -c '
                    echo "MAC Address Manager"
                    echo "=================="
                    echo
                    sudo /etc/nixos/scripts/mac-manager.sh list
                    echo
                    echo "Available Commands:"
                    echo "  list                    - Show this interface list"
                    echo "  randomize-wifi         - Randomize all WiFi MACs"
                    echo "  restore wifi           - Restore WiFi MACs"
                    echo "  restore all            - Restore all MACs"
                    echo "  nm-configure           - Configure NetworkManager"
                    echo "  help                   - Show detailed help"
                    echo
                    echo -n "Enter command (or press Enter to exit): "
                    read cmd
                    if [ -n "$cmd" ]; then
                        sudo /etc/nixos/scripts/mac-manager.sh $cmd
                        echo
                        echo "Press Enter to continue..."
                        read
                    fi
                '
                exit 0
            fi
        fi
        
        while true; do
            # Main menu
            CHOICE=$($DIALOG --title "MAC Address Manager" --menu "Choose an action:" $DIALOG_HEIGHT $DIALOG_WIDTH 10 \
                "1" "List all network interfaces" \
                "2" "Randomize WiFi MAC addresses" \
                "3" "Restore WiFi MAC addresses" \
                "4" "Restore all MAC addresses" \
                "5" "Configure NetworkManager" \
                "6" "Show NetworkManager status" \
                "7" "Generate random MAC address" \
                "8" "Manual MAC change" \
                "9" "Help" \
                "0" "Exit" \
                3>&1 1>&2 2>&3)
            
            if [ $? -ne 0 ]; then
                break
            fi
            
            case $CHOICE in
                1)
                    gnome-terminal --title="Interface List" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh list; echo; echo 'Press Enter to continue...'; read"
                    ;;
                2)
                    if $DIALOG --title "Confirm" --yesno "Randomize MAC addresses for all WiFi interfaces?\n\nThis will temporarily change your network identity." 10 50; then
                        gnome-terminal --title="Randomizing WiFi MACs" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh randomize-wifi; echo; echo 'Press Enter to continue...'; read"
                    fi
                    ;;
                3)
                    if $DIALOG --title "Confirm" --yesno "Restore original MAC addresses for WiFi interfaces?" 8 50; then
                        gnome-terminal --title="Restoring WiFi MACs" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh restore wifi; echo; echo 'Press Enter to continue...'; read"
                    fi
                    ;;
                4)
                    if $DIALOG --title "Confirm" --yesno "Restore original MAC addresses for ALL interfaces?" 8 50; then
                        gnome-terminal --title="Restoring All MACs" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh restore all; echo; echo 'Press Enter to continue...'; read"
                    fi
                    ;;
                5)
                    if $DIALOG --title "Confirm" --yesno "Configure NetworkManager for enhanced MAC randomization?\n\nThis will modify NetworkManager settings." 10 60; then
                        gnome-terminal --title="Configuring NetworkManager" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh nm-configure; echo; echo 'Press Enter to continue...'; read"
                    fi
                    ;;
                6)
                    gnome-terminal --title="NetworkManager Status" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh nm-status; echo; echo 'Press Enter to continue...'; read"
                    ;;
                7)
                    MAC=$(sudo /etc/nixos/scripts/mac-manager.sh generate | grep "Generated MAC:" | cut -d: -f2- | xargs)
                    $DIALOG --title "Generated MAC Address" --msgbox "Generated MAC: $MAC\n\nThis address can be used for manual MAC changes." 8 50
                    ;;
                8)
                    INTERFACE=$($DIALOG --title "Manual MAC Change" --inputbox "Enter interface name (e.g., wlan0):" 8 40 3>&1 1>&2 2>&3)
                    if [ $? -eq 0 ] && [ -n "$INTERFACE" ]; then
                        MAC_ADDR=$($DIALOG --title "Manual MAC Change" --inputbox "Enter new MAC address\n(format: XX:XX:XX:XX:XX:XX)\nor enter 'random' for random MAC:" 10 50 3>&1 1>&2 2>&3)
                        if [ $? -eq 0 ] && [ -n "$MAC_ADDR" ]; then
                            gnome-terminal --title="Changing MAC Address" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh change $INTERFACE $MAC_ADDR; echo; echo 'Press Enter to continue...'; read"
                        fi
                    fi
                    ;;
                9)
                    gnome-terminal --title="MAC Manager Help" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh help; echo; echo 'Press Enter to continue...'; read"
                    ;;
                0)
                    break
                    ;;
            esac
        done
      '')
      
      # Desktop entry for MAC Manager
      (pkgs.makeDesktopItem {
        name = "mac-manager";
        desktopName = "MAC Address Manager";
        comment = "Manage and randomize network interface MAC addresses";
        exec = "mac-manager-gui";
        icon = "network-wired";
        categories = [ "Network" "System" ];
        terminal = false;
      })
      
      # Desktop entry for XDG Manager
      (pkgs.makeDesktopItem {
        name = "xdg-manager";
        desktopName = "XDG Utilities Manager";
        comment = "Manage XDG Base Directory Specification and file associations";
        exec = "gnome-terminal -- xdg-manager tools";
        icon = "folder";
        categories = [ "System" "Utility" ];
        terminal = true;
      })
      
      # Enhanced Screen Sharing Application Launchers
      (pkgs.makeDesktopItem {
        name = "firefox-screenshare";
        desktopName = "Firefox (Screen Share)";
        comment = "Firefox with enhanced WebRTC PipeWire screen sharing support";
        exec = "firefox-screenshare";
        icon = "firefox";
        categories = [ "Network" "WebBrowser" ];
      })
      
      (pkgs.makeDesktopItem {
        name = "discord-wayland";
        desktopName = "Discord (Wayland)";
        comment = "Discord with Wayland screen sharing support";
        exec = "discord-wayland";
        icon = "discord";
        categories = [ "Network" "InstantMessaging" ];
      })
      
      (pkgs.makeDesktopItem {
        name = "slack-wayland";
        desktopName = "Slack (Wayland)";
        comment = "Slack with Wayland screen sharing support";
        exec = "slack-wayland";
        icon = "slack";
        categories = [ "Network" "InstantMessaging" "Office" ];
      })
      
      (pkgs.makeDesktopItem {
        name = "zoom-screenshare";
        desktopName = "Zoom (Screen Share)";
        comment = "Zoom with enhanced screen sharing support";
        exec = "zoom-screenshare";
        icon = "zoom";
        categories = [ "Network" "AudioVideo" "VideoConference" ];
      })
    ];

    # Global environment variables
    variables = {
      EDITOR = "vim";
      VISUAL = "vim";
      PAGER = "less";
      LESS = "-R";
      MANPAGER = "less -R";
      TERM = "xterm-256color";
      COLORTERM = "truecolor";
      LC_ALL = "en_US.UTF-8";
      LANG = "en_US.UTF-8";
      
      # Firefox Wayland screen sharing support
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      MOZ_WEBRENDER = "1";
      MOZ_ACCELERATED = "1";
      
      # XDG Base Directory Specification
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_STATE_HOME = "$HOME/.local/state";
      XDG_RUNTIME_DIR = "/run/user/$(id -u)";
      
      # XDG User Directories (will be overridden by xdg-user-dirs if configured)
      XDG_DESKTOP_DIR = "$HOME/Desktop";
      XDG_DOWNLOAD_DIR = "$HOME/Downloads";
      XDG_TEMPLATES_DIR = "$HOME/Templates";
      XDG_PUBLICSHARE_DIR = "$HOME/Public";
      XDG_DOCUMENTS_DIR = "$HOME/Documents";
      XDG_MUSIC_DIR = "$HOME/Music";
      XDG_PICTURES_DIR = "$HOME/Pictures";
      XDG_VIDEOS_DIR = "$HOME/Videos";
      
      # XDG Desktop Integration
      XDG_CURRENT_DESKTOP = "GNOME";
      XDG_SESSION_DESKTOP = "gnome";
      XDG_MENU_PREFIX = "gnome-";
      
      # Desktop file and MIME handling (XDG_DATA_DIRS is managed by system)
      XDG_CONFIG_DIRS = "/etc/xdg";
      
      # Desktop portal settings
      XDG_DESKTOP_PORTAL_DIR = "/run/current-system/sw/share/xdg-desktop-portal/portals";
      
      # Application defaults for better XDG compliance
      BROWSER = "firefox";
      FILE_MANAGER = "nautilus";
      TERMINAL = "gnome-terminal";
      
      # Ensure applications use XDG directories
      HISTFILE = "$XDG_STATE_HOME/bash/history";
      INPUTRC = "$XDG_CONFIG_HOME/readline/inputrc";
      WGETRC = "$XDG_CONFIG_HOME/wget/wgetrc";
    };
  };


}

