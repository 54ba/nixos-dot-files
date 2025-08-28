{ config, pkgs, lib, ... }:

{
  imports = [
    # Hardware specific modules
    ./hardware-configuration.nix
    ./modules/boot.nix
    ./modules/boot-enhancements.nix
    ./modules/system-base.nix
    ./modules/hardware.nix
    ./modules/display-manager.nix
    ./modules/wayland.nix
    ./modules/security.nix
    ./modules/security-services.nix
    ./modules/user-security.nix
    ./modules/users.nix
    ./modules/device-permissions.nix
    ./modules/system-optimization.nix
    ./modules/system-services.nix
    ./modules/networking.nix
    ./modules/core-packages.nix
    ./modules/optional-packages.nix
    ./modules/pentest.nix
    ./modules/virtualization.nix
    ./modules/containers.nix
    ./modules/ai-services.nix
    ./modules/nixgl.nix
    ./modules/electron-apps.nix
    ./modules/custom-binding.nix
    ./modules/wine-support.nix
    ./modules/package-recommendations.nix
    ./modules/windows-compatibility.nix
    ./modules/lenovo-s540-gtx-15iwl.nix
    ./modules/gnome-extensions.nix
    ./modules/gtk-enhanced.nix
    ./modules/home-manager-integration.nix
    ./modules/nvidia-performance.nix
    ./modules/pam-consolidated.nix
    ./modules/shell-environment.nix
    ./modules/void-editor.nix
    ./modules/nixai-integration.nix
    ./modules/migration-assistant.nix
  ];

  # Fix polkit rules
  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';
  };

  # System stability improvements
  security.pam.services = {
    gdm.enableGnomeKeyring = true;
    gdm-password.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
  };

  # Enable custom modules
  custom = {
    boot.enable = true;
    nvidiaPerformance.enable = true;
    lenovoS540Gtx15iwl.enable = true;
  };
}
