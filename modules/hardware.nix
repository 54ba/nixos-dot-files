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

    # Enhanced touchpad support with gestures - Override module settings
    services.libinput = mkIf config.custom.hardware.input.enable {
      enable = mkForce true;
      touchpad = {
        # Basic touchpad settings
        tapping = mkForce true;                    # Enable tap-to-click
        tappingDragLock = mkForce true;           # Enable drag lock after tapping
        naturalScrolling = mkForce true;           # Natural (reverse) scrolling like macOS
        scrollMethod = mkForce "twofinger";        # Two-finger scrolling
        disableWhileTyping = mkForce true;        # Disable touchpad while typing
        
        # Advanced gesture settings
        clickMethod = mkForce "clickfinger";       # Click method for multi-touch
        accelProfile = mkForce "adaptive";         # Adaptive acceleration profile
        accelSpeed = mkForce "0.3";               # Moderate acceleration speed (override module)
        
        # Gesture recognition settings
        horizontalScrolling = mkForce true;       # Enable horizontal scrolling
        middleEmulation = mkForce true;           # Enable middle mouse button emulation
        
        # Lenovo-specific touchpad fixes
        leftHanded = false;
        
        # Sensitivity and acceleration
        calibrationMatrix = "1.0 0.0 0.0 0.0 1.0 0.0 0.0 0.0 1.0";
        
        # Additional libinput options for gestures
        additionalOptions = mkForce ''
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

      mouse = {
        accelProfile = "adaptive";
        accelSpeed = "0.0";
        leftHanded = false;
        middleEmulation = true;
      };
    };
    
    # TOUCHPAD GESTURE SUPPORT PACKAGES
    environment.systemPackages = mkIf config.custom.hardware.input.enable (with pkgs; [
      libinput              # Modern input handling library
      libinput-gestures     # Gesture recognition for touchpad
      touchegg              # Multi-touch gesture recognizer
      fusuma               # Multi-touch gesture recognizer for Linux
      evtest               # Input event testing tool
      xdotool              # X11 automation tool for gesture actions
      ydotool              # Wayland automation tool for gesture actions
    ]);

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
