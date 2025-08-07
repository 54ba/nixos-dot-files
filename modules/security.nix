{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.security = {
      enable = mkEnableOption "enhanced security settings" // { default = true; };
      sudo.enable = mkEnableOption "sudo configuration" // { default = true; };
      pam.enable = mkEnableOption "PAM configuration" // { default = true; };
      apparmor.enable = mkEnableOption "AppArmor configuration" // { default = true; };
    };
  };

  config = mkIf config.custom.security.enable {
    # Sudo configuration
    security.sudo = mkIf config.custom.security.sudo.enable {
      enable = true;
      wheelNeedsPassword = true;
      extraRules = [{
        users = [ "mahmoud" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/systemctl";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/mount";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/umount";
            options = [ "NOPASSWD" ];
          }
        ];
      }];
    };
    
    # PAM configuration
    security.pam = mkIf config.custom.security.pam.enable {
      loginLimits = [
        {
          domain = "@users";
          item = "nofile";
          type = "soft";
          value = "65536";
        }
        {
          domain = "@users";
          item = "nofile";
          type = "hard";
          value = "65536";
        }
        {
          domain = "@wheel";
          item = "nice";
          type = "soft";
          value = "-10";
        }
      ];
      services = {
        login.enableGnomeKeyring = true;
        gdm.enableGnomeKeyring = true;
        gdm-password.enableGnomeKeyring = true;
        common-session = {
          text = ''
            session optional pam_umask.so umask=0022
          '';
        };
      };
    };
    
    # AppArmor configuration
    security.apparmor = mkIf config.custom.security.apparmor.enable {
      enable = true;
      killUnconfinedConfinables = true;
    };
    
    # Other security settings
    security.polkit.enable = true;
    security.chromiumSuidSandbox.enable = true;
    security.allowUserNamespaces = true;
  };
}
