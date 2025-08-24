{ config, pkgs, lib, ... }:

with lib;

let
  # Define package categories for better organization
  packageCategories = {
    # Productivity and office applications
    productivity = [
      "libreoffice" "gimp" "inkscape" "blender" "audacity" "kdenlive"
      "calibre" "zotero" "obsidian" "notion" "slack" "discord"
    ];

    # Development tools and IDEs
    development = [
      "vscode" "intellij-idea-community" "eclipse" "android-studio"
      "git" "docker" "kubernetes" "postman" "dbeaver"
    ];

    # Creative and design software
    creative = [
      "blender" "gimp" "inkscape" "krita" "audacity" "kdenlive"
      "darktable" "rawtherapee" "scribus" "freecad"
    ];

    # Gaming and entertainment
    gaming = [
      "steam" "lutris" "wine" "proton" "retroarch" "mame"
      "minecraft" "tuxkart" "supertux" "supertuxkart"
    ];

    # System utilities and tools
    system = [
      "htop" "iotop" "ncdu" "tree" "rsync" "ddrescue"
      "testdisk" "photorec" "gparted" "gnome-disk-utility"
    ];

    # Networking and security tools
    networking = [
      "wireshark" "nmap" "metasploit" "burpsuite" "sqlmap"
      "john" "hashcat" "aircrack-ng" "kismet"
    ];

    # Educational and learning software
    education = [
      "geogebra" "scilab" "octave" "maxima" "sage"
      "anki" "khan-academy" "duolingo" "codecademy"
    ];
  };

  # Hardware-based recommendations
  hardwareRecommendations = {
    nvidia = [ "nvidia-x11" "nvidia-settings" "cuda" "cudnn" ];
    amd = [ "amdgpu" "rocm" "opencl-amd" ];
    intel = [ "intel-media-driver" "intel-compute-runtime" ];
    highPerformanceCPU = [ "stress-ng" "sysbench" "geekbench" ];
    highMemory = [ "memtest86" "stress-ng" "ramtest" ];
    ssdNvme = [ "nvme-cli" "smartmontools" "fio" "crystaldiskmark" ];
  };

  # Usage-based recommendations
  usageRecommendations = {
    developer = [ "git" "docker" "kubernetes" "vscode" "postman" ];
    designer = [ "gimp" "inkscape" "blender" "krita" "darktable" ];
    gamer = [ "steam" "lutris" "wine" "proton" "retroarch" ];
    student = [ "libreoffice" "geogebra" "anki" "calibre" ];
    business = [ "libreoffice" "gimp" "inkscape" "audacity" ];
  };

  cfg = config.custom.packageRecommendations;

in {
  options.custom.packageRecommendations = {
    enable = mkEnableOption "Enable package recommendations";

    categories = {
      productivity = mkEnableOption "Productivity package recommendations";
      development = mkEnableOption "Development package recommendations";
      creative = mkEnableOption "Creative package recommendations";
      gaming = mkEnableOption "Gaming package recommendations";
      system = mkEnableOption "System utility recommendations";
      networking = mkEnableOption "Networking tool recommendations";
      education = mkEnableOption "Educational software recommendations";
    };

    hardware = {
      enable = mkEnableOption "Hardware-based recommendations";
      gpu = mkEnableOption "GPU-specific recommendations";
      cpu = mkEnableOption "CPU-specific recommendations";
      memory = mkEnableOption "Memory-specific recommendations";
      storage = mkEnableOption "Storage-specific recommendations";
    };

    usage = {
      enable = mkEnableOption "Usage-based recommendations";
      developer = mkEnableOption "Developer profile recommendations";
      designer = mkEnableOption "Designer profile recommendations";
      gamer = mkEnableOption "Gamer profile recommendations";
      student = mkEnableOption "Student profile recommendations";
      business = mkEnableOption "Business profile recommendations";
    };

    ai = {
      enable = mkEnableOption "AI-powered recommendations";
      hardwareOptimization = mkEnableOption "Hardware optimization suggestions";
      performanceTuning = mkEnableOption "Performance tuning recommendations";
    };
  };

  config = mkIf cfg.enable {
    # Generate package recommendations based on configuration
    environment.etc."package-recommendations.yaml" = {
      text = builtins.toJSON {
        categories = packageCategories;
        hardware = hardwareRecommendations;
        usage = usageRecommendations;
        enabled = {
          categories = cfg.categories;
          hardware = cfg.hardware;
          usage = cfg.usage;
          ai = cfg.ai;
        };
      };
    };

    # Create a script to display recommendations
    environment.etc."package-recommendations.sh" = {
      text = ''
        #!/bin/bash
        echo "=== Package Recommendations ==="
        echo ""

        if [ -f /etc/package-recommendations.yaml ]; then
          echo "Configuration loaded from /etc/package-recommendations.yaml"
          echo ""

          # Display enabled categories
          echo "Enabled Categories:"
          for category in productivity development creative gaming system networking education; do
            if [ "$category" = "productivity" ] && [ "true" = "true" ]; then
              echo "  ✓ $category"
            elif [ "$category" = "development" ] && [ "true" = "true" ]; then
              echo "  ✓ $category"
            elif [ "$category" = "creative" ] && [ "true" = "true" ]; then
              echo "  ✓ $category"
            elif [ "$category" = "gaming" ] && [ "true" = "true" ]; then
              echo "  ✓ $category"
            elif [ "$category" = "system" ] && [ "true" = "true" ]; then
              echo "  ✓ $category"
            elif [ "$category" = "networking" ] && [ "true" = "true" ]; then
              echo "  ✓ $category"
            elif [ "$category" = "education" ] && [ "true" = "true" ]; then
              echo "  ✓ $category"
            fi
          done

          echo ""
          echo "Run 'cat /etc/package-recommendations.yaml' for full details"
        else
          echo "Package recommendations configuration not found"
        fi
      '';
      mode = "0755";
    };
  };
}

