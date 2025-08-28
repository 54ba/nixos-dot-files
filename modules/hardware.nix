{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.hardware = {
      enable = mkEnableOption "hardware configuration" // { default = true; };
      bluetooth.enable = mkEnableOption "Bluetooth support" // { default = true; };
      audio.enable = mkEnableOption "audio with pipewire" // { default = true; };
      input.enable = mkEnableOption "input device configuration" // { default = true; };
      graphics.enable = mkEnableOption "graphics acceleration" // { default = true; };
      fingerprint.enable = mkEnableOption "fingerprint reader support" // { default = true; };
    };
  };

  config = mkIf config.custom.hardware.enable {
    # Audio configuration with pipewire
    security.rtkit.enable = mkIf config.custom.hardware.audio.enable true;
    services.pipewire = mkIf config.custom.hardware.audio.enable {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # Bluetooth configuration
    hardware.bluetooth.enable = config.custom.hardware.bluetooth.enable;
    services.blueman.enable = config.custom.hardware.bluetooth.enable;

    # Fingerprint reader configuration
    services.fprintd = mkIf config.custom.hardware.fingerprint.enable {
      enable = false;
      tod.enable = false;
    };

    # Graphics configuration
    hardware.graphics = mkIf config.custom.hardware.graphics.enable {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
      ];
    };

    # Graphics configuration handled by Lenovo module

    # Input device configuration with Lenovo-specific fixes
    services.libinput = mkIf config.custom.hardware.input.enable {
      enable = true;
      touchpad = {
        # Basic touchpad settings
        tapping = true;
        naturalScrolling = true;
        scrollMethod = "twofinger";
        disableWhileTyping = true;
        clickMethod = "clickfinger";
        accelProfile = "adaptive";
        accelSpeed = "0.5";

        # Lenovo-specific touchpad fixes
        leftHanded = false;
        middleEmulation = true;
        horizontalScrolling = true;

        # Gesture support - tapButtonMap not available in current libinput

        # Sensitivity and acceleration
        calibrationMatrix = "1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0";
      };

      mouse = {
        accelProfile = "adaptive";
        accelSpeed = "0.0";
        leftHanded = false;
        middleEmulation = true;
      };
    };

    # Session management
    services.logind = {
      lidSwitch = "suspend";
      extraConfig = ''
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
    };

    # PAM configuration handled by consolidated module
  };
}
