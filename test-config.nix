# Minimal test configuration to isolate issues
{ config, pkgs, lib, nixgl, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/core-packages.nix
  ];

  # Enable experimental features
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "openssl-1.1.1w"
      "electron-25.9.0"
    ];
  };

  # Boot loader configuration
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
    };
  };

  # Networking configuration
  networking = {
    hostName = "mahmoud-laptop";
    networkmanager.enable = true;
  };

  # Time zone and locale settings
  time.timeZone = "Africa/Cairo";
  i18n.defaultLocale = "en_US.UTF-8";

  # X11 and desktop environment
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    xkb.layout = "us";
  };
  
  # Display manager and desktop environment
  services.displayManager = {
    gdm.enable = true;
    defaultSession = "gnome";
  };
  services.desktopManager.gnome.enable = true;

  # Hardware configuration
  services.pulseaudio.enable = false;
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      open = false;
    };
    steam-hardware.enable = true;
  };
  
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User configuration
  users.users.mahmoud = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  # Basic packages
  environment.systemPackages = with pkgs; [
    git
    vim
    firefox
    zsh
  ];

  programs.zsh.enable = true;
  
  system.stateVersion = "23.11";
}

