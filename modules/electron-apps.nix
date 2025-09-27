{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.electron-apps = {
      enable = mkEnableOption "Electron applications with proper Wayland support";
      
      enableDesktopFiles = mkOption {
        type = types.bool;
        default = true;
        description = "Create custom desktop files with Wayland flags";
      };
      
      packages = {
        discord.enable = mkOption {
          type = types.bool;
          default = true;
          description = "Install Discord with Wayland support";
        };
        
        chromium.enable = mkOption {
          type = types.bool;
          default = true;
          description = "Install Chromium with Wayland support";
        };
        
        vscode.enable = mkOption {
          type = types.bool;
          default = true;
          description = "Install VS Code with Wayland support";
        };
      };
    };
  };

  config = mkIf config.custom.electron-apps.enable {
    # Install packages based on options
    environment.systemPackages = with pkgs; 
      (optionals config.custom.electron-apps.packages.discord.enable [ discord ]) ++
      (optionals config.custom.electron-apps.packages.chromium.enable [ chromium ]) ++
      (optionals config.custom.electron-apps.packages.vscode.enable [ vscode ]);
    
    # System-wide environment for Electron apps
    environment.sessionVariables = {
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      NIXOS_OZONE_WL = "1";  # Enable Ozone Wayland for all Chromium-based apps
    };
    
    # Desktop files with proper Wayland flags
    environment.etc = mkIf config.custom.electron-apps.enableDesktopFiles (mkMerge [
      (mkIf config.custom.electron-apps.packages.discord.enable {
        "applications/discord-wayland.desktop" = {
          text = ''
            [Desktop Entry]
            Name=Discord
            Comment=All-in-one cross-platform voice and text chat
            GenericName=Internet Messenger  
            Exec=discord --enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer --ozone-platform=wayland --enable-wayland-ime %U
            Icon=discord
            Type=Application
            Categories=Network;InstantMessaging;
            MimeType=x-scheme-handler/discord;
            StartupWMClass=discord
            StartupNotify=true
          '';
          mode = "0644";
        };
      })
      
      (mkIf config.custom.electron-apps.packages.chromium.enable {
        "applications/chromium-wayland.desktop" = {
          text = ''
            [Desktop Entry]
            Version=1.0
            Name=Chromium Web Browser (Wayland)
            GenericName=Web Browser
            Comment=Access the Internet
            Exec=chromium --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland %U
            StartupNotify=true
            Terminal=false
            Icon=chromium
            Type=Application
            Categories=Network;WebBrowser;
            MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
            Actions=new-window;new-private-window;
            
            [Desktop Action new-window]
            Name=New Window
            Exec=chromium --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland --new-window
            
            [Desktop Action new-private-window]
            Name=New Incognito Window
            Exec=chromium --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland --incognito
          '';
          mode = "0644";
        };
      })
      
      (mkIf config.custom.electron-apps.packages.vscode.enable {
        "applications/code-wayland.desktop" = {
          text = ''
            [Desktop Entry]
            Name=Visual Studio Code (Wayland)
            Comment=Code Editing. Redefined.
            GenericName=Text Editor
            Exec=code --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --password-store=gnome %F
            Icon=vscode
            Type=Application
            StartupNotify=false
            StartupWMClass=Code
            Categories=Utility;TextEditor;Development;IDE;
            MimeType=text/plain;inode/directory;
            Actions=new-empty-window;
            Keywords=vscode;
            
            [Desktop Action new-empty-window]
            Name=New Empty Window
            Exec=code --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --password-store=gnome --new-window %F
            Icon=vscode
          '';
          mode = "0644";
        };
      })
    ]);
    
    # Shell aliases for terminal users (both work consistently)
    environment.shellAliases = {
      discord = mkIf config.custom.electron-apps.packages.discord.enable
        "discord --enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer --ozone-platform=wayland --enable-wayland-ime";
      chromium = mkIf config.custom.electron-apps.packages.chromium.enable  
        "chromium --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland";
      chrome = mkIf config.custom.electron-apps.packages.chromium.enable
        "chromium --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland";  # Redirect chrome to chromium
      code = mkIf config.custom.electron-apps.packages.vscode.enable
        "code --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --password-store=gnome";
    };
  };
}
