{ config, pkgs, lib, ... }:

with lib;

let
  void-editor = pkgs.callPackage ./packages/void-editor.nix {};
in

{
  options = {
    custom.void-editor = {
      enable = mkEnableOption "Void editor (Cursor alternative) with Wayland support";
      
      createDesktopEntry = mkOption {
        type = types.bool;
        default = true;
        description = "Create desktop entry with Wayland support";
      };
    };
  };

  config = mkIf config.custom.void-editor.enable {
    # Install void-editor package
    environment.systemPackages = [ void-editor ];
    
    # The desktop entry is now created by the package itself
    # with proper working flags, so we don't override it here
    
    # Shell alias for terminal users with working flags
    environment.shellAliases = {
      void = "${void-editor}/bin/void";  # Use the wrapper directly
    };
    
    # System-wide environment variables for optimal Wayland support
    environment.sessionVariables = {
      # Ensure WAYLAND_DISPLAY is set globally for all Wayland apps
      WAYLAND_DISPLAY = mkDefault "wayland-0";
    };
  };
}
