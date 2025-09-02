{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.hostname-compat = {
      enable = mkEnableOption "Enhanced hostname/domainname compatibility for applications";
      
      replaceSystemTools = mkOption {
        type = types.bool;
        default = true;
        description = "Replace system hostname/domainname with Debian-compatible versions";
      };
    };
  };

  config = mkIf config.custom.hostname-compat.enable {
    # Use debian hostname package which supports more flags including -A
    environment.systemPackages = [ pkgs.hostname-debian ];
    
    # Create compatibility symlinks if requested
    environment.etc = mkIf config.custom.hostname-compat.replaceSystemTools {
      "hostname-compat-wrapper".source = pkgs.writeShellScript "hostname-wrapper" ''
        #!/bin/bash
        # Compatibility wrapper for hostname/domainname commands
        # Redirects to Debian-compatible versions that support extended flags
        
        TOOL_NAME="$(basename "$0")"
        DEBIAN_HOSTNAME="${pkgs.hostname-debian}/bin/hostname"
        DEBIAN_DOMAINNAME="${pkgs.hostname-debian}/bin/domainname"
        
        case "$TOOL_NAME" in
          hostname)
            exec "$DEBIAN_HOSTNAME" "$@"
            ;;
          domainname|nisdomainname|ypdomainname|dnsdomainname)
            exec "$DEBIAN_DOMAINNAME" "$@"
            ;;
          *)
            echo "Unknown tool: $TOOL_NAME" >&2
            exit 1
            ;;
        esac
      '';
    };
    
    # Add to PATH with higher priority than system tools
    environment.sessionVariables.PATH = mkBefore [ "${pkgs.hostname-debian}/bin" ];
  };
}
