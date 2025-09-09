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
    
    # Security framework (simplified)
    ./modules/security.nix
    ./modules/users.nix
    
    # Desktop environment
    ./modules/display-manager.nix
    ./modules/wayland.nix
    ./modules/gnome-extensions.nix           # ENABLED - Testing for stage view allocation warnings
    ./modules/gtk-enhanced.nix
    
    # Package management
    ./modules/core-packages.nix
    ./modules/shell-environment.nix
    
    # Development tools
    ./modules/ai-services.nix
    ./modules/electron-apps.nix
    ./modules/void-editor.nix
    
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

 networking.nameservers = ["8.8.8.8" "8.8.4.4"];

# Disable networking.wireless in favor of NetworkManager
 # networking.wireless = {
 #  enable = true;
 #  networks = {
 #    "Yogurt" = {
 #       hidden = true;
 #       psk = "Kitty1520";
 #      };
 #    };
 #  };

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

  # ===== CUSTOM SSD2 BIND MOUNTS =====
  custom.binding = {
    enable = true;                                   # Enable custom binding for SSD2
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

  # Binary cache management with Cachix - ENABLED via root cachix.nix
  # Configuration handled by ./cachix.nix import above

  # === REMOVED MODULES FOR SIMPLIFICATION ===
  # NixAI Integration - Disabled (module not imported)
  # Migration Assistant - Disabled (module not imported) 
  # Home Manager Integration - Disabled (permission issues)

  # ===== CRITICAL FIXES FOR SYSTEMD ISSUES =====
  # Fix nsncd service failures by using systemd-resolved instead
  services.nscd.enable = false;               # Disable problematic nsncd
  system.nssModules = lib.mkForce [];         # Disable NSS modules when nscd is disabled
  services.resolved.enable = true;            # Enable modern DNS resolver
  services.resolved.dnssec = "false";         # Avoid DNSSEC issues on some networks
  
  # Ensure NetworkManager uses systemd-resolved
  networking.networkmanager.dns = "systemd-resolved";
  
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

  # === ACTIVE MODULE CONFIGURATIONS ===
  # Only configurations for imported modules
  
  # Electron Apps with proper Wayland support
  custom.electron-apps = {
    enable = true;
    enableDesktopFiles = true;
    packages = {
      discord.enable = true;
      chromium.enable = true; 
      vscode.enable = true;
    };
  };

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
      htop = true; tmux = true;
    };
    aliases = {
      enable = true;
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

      # System tools
      pciutils
      usbutils
      lshw
      hwloc
      iotop
      smartmontools
      
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
        
        # Ensure X11 display is available
        if [ -z "$DISPLAY" ]; then
          export DISPLAY=:0
        fi
        
        # Run AnyDesk with error suppression
        exec ${pkgs.anydesk}/bin/anydesk "$@" 2>/dev/null
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
      
      # Home Manager for manual user management
      home-manager
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
    };
  };


}

