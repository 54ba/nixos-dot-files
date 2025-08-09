{ config, pkgs, lib, ... }:

with lib;

let
  void-editor = pkgs.callPackage ../packages/void-editor.nix {};
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
    
    # Create desktop entry with proper Wayland support
    environment.etc = mkIf config.custom.void-editor.createDesktopEntry {
      "applications/void-editor.desktop" = {
        text = ''
          [Desktop Entry]
          Name=Void
          Comment=Open source Cursor alternative - AI-powered code editor
          GenericName=Code Editor
          Exec=${void-editor}/bin/void --ozone-platform-hint=auto --enable-features=UseOzonePlatform,WaylandWindowDecorations %F
          Icon=void-editor
          Type=Application
          Categories=Development;TextEditor;IDE;
          MimeType=text/plain;text/x-markdown;application/json;text/x-python;text/x-javascript;text/x-typescript;
          StartupNotify=true
          StartupWMClass=void
          Keywords=editor;code;development;programming;
          Actions=new-window;
          
          [Desktop Action new-window]
          Name=New Window
          Exec=${void-editor}/bin/void --ozone-platform-hint=auto --enable-features=UseOzonePlatform,WaylandWindowDecorations --new-window
        '';
        mode = "0644";
      };
    };
    
    # Shell alias for terminal users
    environment.shellAliases = {
      void = "${void-editor}/bin/void --ozone-platform-hint=auto --enable-features=UseOzonePlatform,WaylandWindowDecorations";
    };
    
    # System-wide environment variables for optimal Wayland support
    environment.sessionVariables = {
      VOID_OZONE_PLATFORM_HINT = "auto";
    };
  };
}
