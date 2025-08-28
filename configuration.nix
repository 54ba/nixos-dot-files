{ config, pkgs, lib, ... }:

{
  imports = [
    # === ESSENTIAL CORE MODULES ===
    ./hardware-configuration.nix
    
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
    ./modules/gnome-extensions.nix
    ./modules/gtk-enhanced.nix
    
    # Package management
    ./modules/core-packages.nix
    ./modules/shell-environment.nix
    
    # Development tools
    ./modules/ai-services.nix
    ./modules/electron-apps.nix
    ./modules/void-editor.nix
    
    # Intelligent Recording System
    # ./modules/desktop-recording.nix              # TEMPORARILY DISABLED - Missing script issue
    # ./modules/input-capture.nix                  # TEMPORARILY DISABLED - Depends on desktop-recording
    # ./modules/data-pipeline.nix                  # TEMPORARILY DISABLED - Depends on desktop-recording  
    # ./modules/ai-orchestrator.nix                # TEMPORARILY DISABLED - Depends on desktop-recording
    # ./modules/intelligent-recording-system.nix   # TEMPORARILY DISABLED - Depends on desktop-recording
    
    # System utilities
    ./modules/virtualization.nix
    ./modules/containers.nix
    ./modules/custom-binding.nix
    ./modules/nixgl.nix
    
    # System health monitoring
    # ./modules/health-monitoring.nix              # DISABLED - Module not available in flake path
    
    # Rescue system with generation management
    # ./modules/rescue-system.nix                  # DISABLED - Module causes build issues
    
    # SteamOS and Mobile PC Integration - TEMPORARILY DISABLED FOR TESTING
    # ./modules/steamos-gaming.nix                 # DISABLED - Path issues with flakes
    # ./modules/steamos-mobile-suite.nix           # DISABLED - Path issues with flakes
    # ./modules/mobile-integration.nix             # DISABLED - Path issues with flakes
    # ./modules/remote-control.nix                 # DISABLED - Path issues with flakes
    # ./modules/ssh-remote-access.nix              # DISABLED - Path issues with flakes
    
    # === OPTIONAL MODULES (can be disabled for simplification) ===
    ./modules/boot-enhancements.nix              # ENABLED - Boot enhancements
    ./modules/security-services.nix
    ./modules/user-security.nix                  # ENABLED - User security enhancements
    ./modules/device-permissions.nix             # ENABLED - Device permission management
    ./modules/system-optimization.nix
    ./modules/system-services.nix
    ./modules/optional-packages.nix              # ENABLED - Optional package collections
    ./modules/pentest.nix                        # ENABLED - Penetration testing tools
    ./modules/wine-support.nix                   # ENABLED - Wine compatibility layer
    ./modules/package-recommendations.nix        # ENABLED - Package recommendations
    ./modules/windows-compatibility.nix          # ENABLED - Windows app compatibility
    ./modules/lenovo-s540-gtx-15iwl.nix         # ENABLED - Lenovo hardware optimizations
    ./modules/home-manager-integration.nix       # ENABLED - Home manager integration
    ./modules/nvidia-performance.nix             # ENABLED - NVIDIA gaming optimizations
    # ./modules/pam-consolidated.nix  # REMOVED - conflicts with main PAM config
    ./modules/nixai-integration.nix              # ENABLED - NixAI integration
    ./modules/migration-assistant.nix            # ENABLED - System migration tools
    
    # ===== AUTOMATION & WORKFLOW ORCHESTRATION =====
    ./modules/automation-workflow.nix             # ENABLED - Automation and workflow orchestration
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
      theme = "dark";
    #  timeout = 5;
      generations = 40;
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
    #audio.enable = true;         # Enable audio like live USB
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
  
  # Enable comprehensive health monitoring (DISABLED - Module not imported)
  # custom.healthMonitoring = {
  #   enable = true;                         # Enable system health monitoring
  #   monitoring = {
  #     interval = "hourly";                 # Run health checks hourly
  #     checkDisk = true;                    # Monitor disk health and usage
  #     checkMemory = true;                  # Monitor memory usage
  #     checkServices = true;                # Monitor service status
  #     checkNetwork = true;                 # Monitor network connectivity
  #   };
  #   logging.enable = true;                 # Enable health monitoring logs
  # };
  
  # Enable advanced rescue system with generation management (DISABLED - Module not imported)
  # custom.rescueSystem = {
  #   enable = true;                         # Enable comprehensive rescue system
  #   grub = {
  #     enableAdvancedMenu = true;           # Advanced GRUB menu with rescue options
  #     timeout = 30;                        # 30 second timeout for rescue menu
  #     enableGenerationSorting = true;      # Sort boot generations by date
  #     rescueEntries = true;                # Add dedicated rescue mode entries
  #   };
  #   generations = {
  #     maxCount = 100;                      # Keep up to 100 generations for recovery
  #     sortBy = "date";                     # Sort by date (newest first)
  #     groupBy = "week";                    # Group generations by week
  #     autoCleanup = true;                  # Auto-cleanup old generations
  #   };
  #   rescueTools = {
  #     enable = true;                       # Enable comprehensive rescue tools
  #     networkTools = true;                 # Network diagnostic and recovery tools
  #     diskTools = true;                    # Disk recovery and filesystem tools
  #     systemTools = true;                  # System diagnostic and repair tools
  #     developmentTools = false;            # Disable dev tools for security
  #   };
  #   emergencyAccess = {
  #     enableRootShell = true;              # Emergency root shell access
  #     enableNetworkAccess = true;          # Network access in rescue mode
  #     enableSSH = false;                   # Disable SSH for security (enable manually if needed)
  #     allowPasswordAuth = true;            # Allow password authentication in rescue mode
  #   };
  #   autoRescue = {
  #     enable = false;                      # Disable auto-rescue for now
  #     bootFailureThreshold = 3;            # Trigger after 3 boot failures
  #     autoRepair = false;                  # Disable automatic repairs
  #   };
  # };

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

  # AI Services (disabled by default)
  custom.ai-services = {
    enable = true;  # Enable for AI development
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

  # === REMOVED MODULES FOR SIMPLIFICATION ===
  # NixAI Integration - Now enabled via nixaiIntegration below
  # Migration Assistant - Now enabled via migrationAssistant below
  # Home Manager Integration - Now enabled via home-manager below

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
  
  # Fix GPU and hardware issues
  boot.kernelParams = [ 
    "nvidia.drm.modeset=0" 
    "nouveau.modeset=1"
    "acpi_osi=!"
    "acpi_osi=\"Windows 2020\""
    "acpi_backlight=vendor"
    "thinkpad_acpi.fan_control=0"  # Disable thinkpad_acpi fan control
  ];
  
  # Disable ThinkFan service as it's failing on this hardware (not a ThinkPad)
  services.thinkfan.enable = lib.mkForce false;
  
  # Boot generations limit is now handled by custom.boot.grub.generations in modules/boot.nix
  # Health monitoring is now handled by modules/health-monitoring.nix
  
  # ===== DESKTOP ENVIRONMENT CONFIGURATION =====
  # Enable desktop environment and GNOME
  custom.desktop = {
    enable = true;                    # Enable desktop environment
    wayland.enable = true;            # Enable Wayland support
    gnome = {
      enable = true;                  # Enable GNOME desktop environment
      extensions.enable = true;       # Enable GNOME extensions
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
      theme = "Adwaita-dark";
      iconTheme = "Papirus-Dark";
      cursorTheme = "Bibata-Modern-Ice";
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

  # NVIDIA Performance Optimizations
  #custom.nvidiaPerformance = {
  #  enable = true;               # Enable NVIDIA performance optimizations
  #  gaming = {
  #    enable = true;             # Enable gaming optimizations
  #    dlss = true;               # Enable DLSS support
  #    rayTracing = true;         # Enable ray tracing support
  #    performanceMode = "performance"; # Performance mode preference
  #  };
   # overclocking = {
   #   enable = false;            # Disable overclocking for stability
   #   powerLimit = 100;          # Power limit percentage
   #   memoryOverclock = 0;       # Memory overclock in MHz
   #   coreOverclock = 0;         # Core overclock in MHz
   # };
   # monitoring = {
   #  enable = true;             # Enable GPU monitoring tools
   #   nvtop = true;              # Enable nvtop for GPU monitoring
   # greenWithEnvy = true;      # Enable GreenWithEnvy for advanced GPU control
   # };
   # optimization = {
   #   enable = true;             # Enable performance optimizations
   #   powerMizer = "prefer_maximum_performance"; # PowerMizer mode for performance
   #   textureQuality = "performance"; # Texture quality preference
   #   shaderCache = true;        # Enable shader cache for better performance
   # };
  #};

  # ===== NEWLY ENABLED MODULE CONFIGURATIONS =====
  
  # NVIDIA Performance Optimizations
  custom.nvidiaPerformance = {
    enable = true;                         # Enable NVIDIA performance optimizations
    gaming = {
      enable = true;                       # Enable gaming optimizations
      dlss = true;                         # Enable DLSS support
      rayTracing = true;                   # Enable ray tracing support
      performanceMode = "performance";     # Performance mode preference
    };
    monitoring = {
      enable = true;                       # Enable GPU monitoring tools
    };
  };
  
  # Wine Support for Windows Applications
  custom.wine = {
    enable = true;                         # Enable Wine support
    packages = {
      wine64 = true;                       # Install Wine 64-bit
      wine32 = true;                       # Install Wine 32-bit for compatibility
      winetricks = true;                   # Install Winetricks for easy configuration
      playonlinux = true;                  # Install PlayOnLinux for game management
      lutris = true;                       # Install Lutris for comprehensive game management
      dxvk = true;                         # Install DXVK for DirectX 11/10 support
      vkd3d = true;                        # Install VKD3D for DirectX 12 support
      mono = true;                         # Install Wine Mono for .NET applications
      gecko = true;                        # Install Wine Gecko for web browser support
    };
    performance = {
      enable = true;                       # Enable Wine performance optimizations
      esync = true;                        # Enable Esync for better performance
      fsync = true;                        # Enable Fsync for better performance (kernel 5.16+)
      gamemode = true;                     # Enable Feral GameMode for performance
      mangohud = true;                     # Enable MangoHud for performance monitoring
    };
    compatibility = {
      enable = true;                       # Enable Wine compatibility features
      virtualDesktop = false;              # Disable virtual desktop mode for better integration
      dpiScaling = true;                   # Enable DPI scaling support
      audio = true;                        # Enable enhanced audio support
      networking = true;                   # Enable enhanced networking support
    };
  };
  
  # Windows Compatibility Layer
  custom.windowsCompatibility = {
    enable = true;                         # Enable Windows compatibility layer
    dotnet = {
      enable = true;                       # Enable .NET Framework support
      versions = [ "4.8" "4.7.2" "3.5" ];  # Install multiple .NET versions
      mono = true;                         # Enable Mono runtime support
      core = true;                         # Enable .NET Core support
    };
    applications = {
      office = true;                       # Enable Office applications
      development = true;                  # Enable Development tools
      design = true;                       # Enable Design applications
      gaming = true;                       # Enable Gaming applications
      business = false;                    # Disable Business applications for now
    };
    wine = {
      performance = {
        esync = true;                      # Enable esync for better performance
        fsync = true;                      # Enable fsync for better performance
        gamemode = true;                   # Enable gamemode integration
      };
    };
    alternatives = {
      enable = true;                       # Install Linux alternatives to Windows apps
      office = true;                       # Install LibreOffice/OnlyOffice
      design = true;                       # Install GIMP/Inkscape
      development = true;                  # Install VS Code/Rider
    };
  };
  
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
  
  # Boot Enhancements
  custom.boot.enhancements.enable = true;        # Enable boot enhancements
  custom.boot.plymouth = {
    enable = true;                                # Enable Plymouth boot splash
    theme = "breeze";                            # Use breeze theme
  };
  custom.boot.quietBoot.enable = true;           # Enable quiet boot mode
  
  # User Security Enhancements
  custom.userSecurity = {
    enable = true;                         # Enable user security enhancements
    mainUser = {
      name = "mahmoud";                      # Main user name
      extraGroups = [ "wheel" "audio" "video" "input" "storage" "network" "docker" "libvirtd" "kvm" ];
    };
    sudo = {
      enable = true;                       # Enable sudo access
      noPassword = true;                   # Allow sudo without password for convenience
    };
    polkit.enable = true;                  # Enable polkit for GUI privilege escalation
    pam.enable = true;                     # Enable PAM configuration enhancements
    gnomeKeyring.enable = true;            # Enable GNOME Keyring for credential storage
  };
  
  # Device Permission Management
  custom.device-permissions.enable = true;      # Enable device permission management
  
  # Optional Package Collections
  custom.packages = {
    essential.enable = true;               # Enable essential packages
    media.enable = true;                   # Enable media and graphics packages
    development.enable = true;             # Enable development packages
    productivity.enable = true;            # Enable productivity packages
    popular.enable = true;                 # Enable popular packages collection
    entertainment.enable = false;          # Disable entertainment packages for now
    gaming.enable = false;                 # Disable gaming packages for now
    pentest.enable = false;                # Disable pentest packages by default (security)
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
  
  # ===== INTELLIGENT RECORDING SYSTEM =====
  # NOTE: Intelligent recording system configuration is temporarily disabled
  # Re-enable when desktop-recording modules are restored
  # custom.intelligentRecordingSystem = {
  #   enable = true;                         # Enable intelligent recording system
  #   profile = "development";               # Use development profile for coding workflows
  #   
  #   # Component configuration
  #   components = {
  #     desktopRecording = true;             # Enable desktop recording
  #     inputCapture = true;                 # Enable input capture and logging
  #     dataPipeline = true;                 # Enable data processing pipeline
  #     aiOrchestrator = true;               # Enable AI orchestration
  #   };
  #   
  #   # Feature configuration
  #   features = {
  #     autoRecording = true;                # Enable automatic recording based on AI analysis
  #     smartEffects = true;                 # Enable intelligent effects and enhancements
  #     realTimeAnalysis = true;             # Enable real-time content analysis
  #     streamingIntegration = false;        # Disable streaming for now
  #     cloudSync = false;                   # Keep everything local for privacy
  #     privacyMode = true;                  # Enable enhanced privacy protection
  #   };
  #   
  #   # Storage configuration
  #   storage = {
  #     centralPath = "/var/lib/intelligent-recording";
  #     totalQuota = "50G";                  # Allocate 50GB for recording system
  #     distribution = {
  #       recordings = 60;                   # 60% for video recordings (30GB)
  #       logs = 20;                         # 20% for input logs (10GB)
  #       analysis = 15;                     # 15% for analysis data (7.5GB)
  #       cache = 5;                         # 5% for cache and temporary files (2.5GB)
  #     };
  #     backup = {
  #       enable = false;                    # Disable automatic backups for now
  #       location = "/backup/recordings";
  #       schedule = "weekly";
  #     };
  #   };
  #   
  #   # Performance configuration
  #   performance = {
  #     priority = "normal";                 # Normal system priority
  #     cpuCores = 4;                        # Use 4 CPU cores
  #     memoryLimit = "4G";                  # Limit to 4GB memory usage
  #     gpuAcceleration = true;              # Enable GPU acceleration
  #   };
  #   
  #   # Integration settings
  #   integration = {
  #     nixai = true;                        # Enable nixai integration
  #     development = {
  #       vscode = true;                     # Enable VS Code integration
  #       github = false;                    # Disable GitHub integration for now
  #       documentation = true;              # Enable automatic documentation generation
  #     };
  #     streaming = {
  #       obs = true;                        # Enable OBS Studio integration
  #       platforms = [];                    # No streaming platforms for now
  #     };
  #   };
  #   
  #   # Security configuration
  #   security = {
  #     encryption = true;                   # Encrypt sensitive recordings
  #     accessControl = true;                # Enable role-based access control
  #     auditLogging = true;                 # Enable audit logging
  #     sandboxing = true;                   # Enable process sandboxing
  #   };
  #   
  #   # UI configuration
  #   ui = {
  #     enable = true;                       # Enable graphical user interface
  #     type = "gtk";                        # Use GTK UI framework
  #     systray = true;                      # Enable system tray integration
  #     notifications = true;                # Enable desktop notifications
  #   };
  # };
  
  # ===== AUTOMATION & WORKFLOW ORCHESTRATION =====
  # Enable comprehensive automation platform with n8n, Temporal, and Kestra
  custom.automation-workflow = {
    enable = true;                         # Enable automation workflow system
    
    # Core workflow engines
    engines = {
      n8n = {
        enable = false;                      # Disable n8n for initial setup (enable manually if needed)
        port = 5678;
        dataDir = "/var/lib/n8n";
        encryptionKey = "changeme_automation_key_2024";
      };
      
      nodeRed = {
        enable = false;                      # Disable Node-RED for initial setup
        port = 1880;
        userDir = "/var/lib/node-red";
      };
      
      temporal = {
        enable = false;                      # Disable Temporal for initial setup (enable manually if needed)
        frontendPort = 8088;
        serverPort = 7233;
        dataDir = "/var/lib/temporal";
      };
      
      kestra = {
        enable = false;                      # Disable Kestra for initial setup (enable manually if needed) 
        port = 8081;                        # Use different port to avoid conflicts with Airflow
        dataDir = "/var/lib/kestra";
        javaOpts = "-Xmx1G";                 # Reduce memory usage for initial setup
      };
    };
    
    # API automation tools
    api = {
      enable = true;                       # Enable API automation tools
      tools = {
        postman = false;                     # Disable GUI tools for server setup
        insomnia = false;
        httpie = true;                       # Enable CLI HTTP client
        curl = true;
        jq = true;
        yq = true;
      };
    };
    
    # CLI automation tools
    cli = {
      enable = true;                       # Enable CLI automation
      tools = {
        github-cli = true;
        gitlab-cli = true;
        slack-cli = false;
        telegram-cli = false;
        discord-cli = false;
        aws-cli = true;
        azure-cli = true;
        gcloud-cli = true;
      };
    };
    
    # Scripting and task automation
    scripting = {
      enable = true;                       # Enable scripting tools
      languages = {
        python = true;
        nodejs = true;
        bash = true;
        powershell = false;                  # Disable PowerShell for Linux setup
      };
      schedulers = {
        cron = true;
        systemd-timers = true;
        at = true;
      };
    };
    
    # Integration and messaging (basic setup)
    integration = {
      enable = true;
      messaging = {
        rabbitmq = false;                    # Disable for initial setup
        redis = false;                       # Disable for initial setup
        kafka = false;
        mqtt = false;
      };
      databases = {
        postgresql = false;                  # Use existing PostgreSQL setup
        mongodb = false;
        sqlite = true;                       # Enable SQLite for lightweight storage
        influxdb = false;
      };
    };
    
    # Development and testing
    development = {
      enable = true;
      testing = {
        newman = true;                       # API testing
        jest = false;
        pytest = true;
        playwright = false;
        selenium = false;
      };
      debugging = {
        ngrok = false;
        mitmproxy = true;
        burp = false;
      };
    };
  };
  
  # ===== STEAMOS AND MOBILE PC INTEGRATION =====
  # NOTE: SteamOS and mobile PC modules are currently disabled due to flake path issues
  # They can be re-enabled once the path resolution is fixed

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
    # Create user without password - password will be set on first login
    initialPassword = "changeme";
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

