{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.custom.windowsCompatibility;

  # Popular Windows-only applications that users commonly need
  popularWindowsApps = {
    # Office and Productivity
    office = {
      name = "Microsoft Office";
      description = "Office suite (Word, Excel, PowerPoint)";
      alternatives = [ "libreoffice" "onlyoffice" "wps-office" ];
      wineNotes = "Use Office 2016 or 2019 for best compatibility";
    };

    # Development Tools
    visualStudio = {
      name = "Visual Studio";
      description = "Microsoft IDE for .NET development";
      alternatives = [ "vscode" "rider" "monodevelop" ];
      wineNotes = "Use Visual Studio Community Edition";
    };

    # Design and Media
    photoshop = {
      name = "Adobe Photoshop";
      description = "Professional image editing";
      alternatives = [ "gimp" "krita" "affinity-photo" ];
      wineNotes = "CS6 or older versions work better";
    };

    illustrator = {
      name = "Adobe Illustrator";
      description = "Vector graphics editor";
      alternatives = [ "inkscape" "affinity-designer" ];
      wineNotes = "CS6 or older versions work better";
    };

    # Gaming
    games = {
      name = "Windows Games";
      description = "Games that don't have Linux versions";
      alternatives = [ "steam" "lutris" "heroic" ];
      wineNotes = "Use Lutris for easy game installation";
    };

    # Business Software
    quickbooks = {
      name = "QuickBooks";
      description = "Accounting software";
      alternatives = [ "gnucash" "ledger" "wave" ];
      wineNotes = "Use QuickBooks Online as alternative";
    };

    # CAD Software
    autocad = {
      name = "AutoCAD";
      description = "CAD software";
      alternatives = [ "freecad" "librecad" "openscad" ];
      wineNotes = "Use FreeCAD as primary alternative";
    };
  };

  # .NET Framework versions and compatibility
  dotnetVersions = {
    "4.8" = "Latest .NET Framework, best compatibility";
    "4.7.2" = "Good compatibility, stable";
    "4.6.2" = "Widely supported";
    "3.5" = "Legacy support";
  };

  # Wine prefixes for different application categories
  winePrefixes = {
    office = "~/.wine-office";
    development = "~/.wine-dev";
    gaming = "~/.wine-games";
    design = "~/.wine-design";
    business = "~/.wine-business";
  };

in {
  options.custom.windowsCompatibility = {
    enable = mkEnableOption "Windows application compatibility layer";

    # .NET Framework support
    dotnet = {
      enable = mkEnableOption ".NET Framework support";
      versions = mkOption {
        type = types.listOf types.str;
        default = [ "4.8" "3.5" ];
        description = "List of .NET Framework versions to install";
      };
      mono = mkEnableOption "Mono runtime support";
      core = mkEnableOption ".NET Core support";
    };

    # Application categories
    applications = {
      office = mkEnableOption "Office applications";
      development = mkEnableOption "Development tools";
      design = mkEnableOption "Design applications";
      gaming = mkEnableOption "Gaming applications";
      business = mkEnableOption "Business applications";
    };

    # Wine configuration
    wine = {
      prefixes = mkOption {
        type = types.attrsOf types.str;
        default = winePrefixes;
        description = "Wine prefix paths for different categories";
      };
      performance = {
        esync = mkEnableOption "Enable esync for better performance";
        fsync = mkEnableOption "Enable fsync for better performance";
        gamemode = mkEnableOption "Enable gamemode integration";
      };
    };

    # Alternative applications
    alternatives = {
      enable = mkEnableOption "Install Linux alternatives to Windows apps";
      office = mkEnableOption "Install LibreOffice/OnlyOffice";
      design = mkEnableOption "Install GIMP/Inkscape";
      development = mkEnableOption "Install VS Code/Rider";
    };
  };

  config = mkIf cfg.enable {
    # System packages for Windows compatibility
    environment.systemPackages = with pkgs; [
      # Core compatibility tools
      wine64
      wineWowPackages.stable
      winetricks

      # .NET Framework support
      mono
      dotnet-sdk
      dotnet-runtime

      # Application compatibility managers
      lutris
      bottles
      playonlinux
      q4wine

      # Alternative applications
      (mkIf cfg.alternatives.office libreoffice)
      (mkIf cfg.alternatives.design gimp)
      (mkIf cfg.alternatives.design inkscape)
      (mkIf cfg.alternatives.development vscode)

      # Additional tools
      cabextract
      p7zip
      unzip
      zip
      corefonts
    ];

    # Wine environment variables are handled by wine-support.nix module

    # Wine registry configuration
    environment.etc."wine/wine.conf" = {
      text = ''
        [wine]
        Windows = "10"
        ShowCrashDialog = false
        UseTakeFocus = false
        UseDGA = false
        UseXVidMode = false
        UseGLSL = enabled
        StrictDrawOrdering = true
        Multimon = false
        AlwaysOffscreen = false
        RenderTargetLockMode = auto
        VideoMemorySize = 2048
        OpenGL = true
        DirectDrawRenderer = opengl
        AudioDriver = pulse
        XInputDriver = enabled
        HID = enabled
        UseDGA = false
        UseXVidMode = false
        Managed = Y
        ShowCrashDialog = false
        UseTakeFocus = false
        UseDGA = false
        UseXVidMode = false
        UseGLSL = enabled
        StrictDrawOrdering = true
        Multimon = false
        AlwaysOffscreen = false
        RenderTargetLockMode = auto
        VideoMemorySize = 2048
        OpenGL = true
        DirectDrawRenderer = opengl
        AudioDriver = pulse
        XInputDriver = enabled
        HID = enabled
        UseDGA = false
        UseXVidMode = false
        Managed = Y
      '';
    };

    # Systemd user services are handled by wine-support.nix module
  };
}