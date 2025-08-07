{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.device-permissions = {
      enable = mkEnableOption "device permissions and udev rules" // { default = true; };
    };
  };

  config = mkIf config.custom.device-permissions.enable {
    # Enhanced file system and device permissions
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
      
      # Android device permissions
      SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", GROUP="adbusers", MODE="0664"
      SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", GROUP="adbusers", MODE="0664"
      SUBSYSTEM=="usb", ATTR{idVendor}=="0bb4", GROUP="adbusers", MODE="0664"
      SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", GROUP="adbusers", MODE="0664"
      SUBSYSTEM=="usb", ATTR{idVendor}=="1004", GROUP="adbusers", MODE="0664"
      SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", GROUP="adbusers", MODE="0664"
      SUBSYSTEM=="usb", ATTR{idVendor}=="2717", GROUP="adbusers", MODE="0664"
    '';
  };
}
