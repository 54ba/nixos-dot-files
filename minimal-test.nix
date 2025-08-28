{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Essential hardware configuration
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelParams = [ "acpi_osi=Linux" "acpi_backlight=vendor" "usbcore.autosuspend=-1" ];

  # Basic bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Filesystems
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/19324f88-fbf3-41a8-8758-1c35604d7137";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/EF5B-1A82";
    fsType = "vfat";
  };

  # Minimum required configuration
  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "x86_64-linux";
}
