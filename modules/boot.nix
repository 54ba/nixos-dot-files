{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.boot = {
      enable = mkEnableOption "custom boot configuration" // { default = true; };
      grub = {
        theme = mkOption {
          type = types.str;
          default = "dark";
          description = "GRUB theme (dark/light)";
        };
        timeout = mkOption {
          type = types.int;
          default = 10;
          description = "GRUB timeout in seconds";
        };
        generations = mkOption {
          type = types.int;
          default = 10;
          description = "Number of generations to keep";
        };
      };
    };
  };

  config = mkIf config.custom.boot.enable {
    # Boot loader configuration with beautiful theme
    boot.loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;  # Detect other operating systems
      configurationLimit = config.custom.boot.grub.generations;
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
      
      # Font configuration for better text rendering
      font = "${pkgs.grub2}/share/grub/unicode.pf2";
    };
    
    # Set timeout separately as recommended
    boot.loader.timeout = config.custom.boot.grub.timeout;
    boot.loader.efi.canTouchEfiVariables = true;
    
    # Basic boot configuration  
    boot.initrd.systemd.enable = true;
    
    # Kernel parameters for better boot experience
    boot.kernelParams = [
      "quiet"          # Less verbose boot
      "splash"         # Show splash screen
      "rd.udev.log_level=3"  # Reduce udev log noise
      "vt.global_cursor_default=0"  # Hide cursor during boot
    ];
    
    # Console settings
    boot.consoleLogLevel = 0;
    # boot.kernelPackages = pkgs.linuxPackages;  # Use default kernel - commented out to avoid build issues
    
    # Console font configuration
    console = {
      font = "${pkgs.terminus_font}/share/consolefonts/ter-v16n.psf.gz";
      keyMap = "us";
      useXkbConfig = false;  # Use console keyMap
    };
    
    # System packages needed for boot
    environment.systemPackages = import ../packages/boot-packages.nix { inherit pkgs; };
  };
}
