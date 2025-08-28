{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.pam = {
      enable = mkEnableOption "consolidated PAM configuration";

      fingerprint = {
        enable = mkEnableOption "fingerprint authentication support";
        services = mkOption {
          type = types.listOf types.str;
          default = [ "login" "sudo" "su" "polkit-1" ];
          description = "Services to enable fingerprint authentication for";
        };
      };

      totp = {
        enable = mkEnableOption "TOTP (Time-based One-Time Password) support";
        services = mkOption {
          type = types.listOf types.str;
          default = [ "login" "sudo" "su" ];
          description = "Services to enable TOTP authentication for";
        };
      };

      gnomeKeyring = {
        enable = mkEnableOption "GNOME Keyring integration";
        services = mkOption {
          type = types.listOf types.str;
          default = [ "login" "gdm" "gdm-password" "gdm-fingerprint" ];
          description = "Services to enable GNOME Keyring for";
        };
      };
    };
  };

  config = mkIf config.custom.pam.enable {
    # Consolidated PAM configuration
    security.pam = {
      # Login limits
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

      # Service-specific configurations
      services = {
        # Common session configuration
        common-session = {
          text = ''
            session optional pam_umask.so umask=0022
            session optional pam_env.so readenv=1 user_readenv=0
            session optional pam_env.so readenv=1 envfile=/etc/environment user_readenv=0
          '';
        };

                # Login service
        login = {
          enableGnomeKeyring = mkIf (config.custom.pam.gnomeKeyring.enable &&
                                    elem "login" config.custom.pam.gnomeKeyring.services) true;
          fprintAuth = mkIf (config.custom.pam.fingerprint.enable &&
                             elem "login" config.custom.pam.fingerprint.services) (lib.mkForce true);
        };

                # Sudo service
        sudo = {
          fprintAuth = mkIf (config.custom.pam.fingerprint.enable &&
                             elem "sudo" config.custom.pam.fingerprint.services) (lib.mkForce true);
        };

        # Su service
        su = {
          fprintAuth = mkIf (config.custom.pam.fingerprint.enable &&
                             elem "su" config.custom.pam.fingerprint.services) (lib.mkForce true);
        };

                # GDM services
        gdm = {
          enableGnomeKeyring = mkIf (config.custom.pam.gnomeKeyring.enable &&
                                     elem "gdm" config.custom.pam.gnomeKeyring.services) true;
        };

        gdm-password = {
          enableGnomeKeyring = mkIf (config.custom.pam.gnomeKeyring.enable &&
                                     elem "gdm-password" config.custom.pam.gnomeKeyring.services) true;
        };

        gdm-fingerprint = {
          enableGnomeKeyring = mkIf (config.custom.pam.gnomeKeyring.enable &&
                                     elem "gdm-fingerprint" config.custom.pam.gnomeKeyring.services) true;
          fprintAuth = mkIf (config.custom.pam.fingerprint.enable &&
                             elem "gdm-fingerprint" config.custom.pam.fingerprint.services) (lib.mkForce true);
        };

        # Polkit service
        polkit-1 = {
          fprintAuth = mkIf (config.custom.pam.fingerprint.enable &&
                             elem "polkit-1" config.custom.pam.fingerprint.services) (lib.mkForce true);
        };
      };
    };

    # Fingerprint service configuration
    services.fprintd = mkIf config.custom.pam.fingerprint.enable {
      enable = lib.mkForce true;
      tod.enable = lib.mkForce false; # Disable TOTP in fprintd to avoid conflicts
    };

    # TOTP configuration
    environment.systemPackages = with pkgs; mkIf config.custom.pam.totp.enable [
      totp-cli
    ];

    # Create TOTP directory
    system.activationScripts.totp = mkIf config.custom.pam.totp.enable ''
      mkdir -p /etc/totp
      chmod 700 /etc/totp
    '';
  };
}