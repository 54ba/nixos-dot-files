{ config, pkgs, lib, ... }:

with lib;

{
  options.custom.enhanced-packages = {
    enable = mkEnableOption "enhanced application packages with screen sharing support";
    
    browsers = {
      firefox = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Firefox with enhanced screen sharing support";
      };
      chrome = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Chrome with enhanced screen sharing support";
      };
      chromium = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Chromium with enhanced screen sharing support";
      };
    };
    
    communication = {
      discord = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Discord with Wayland screen sharing support";
      };
      slack = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Slack with Wayland screen sharing support";
      };
      zoom = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Zoom with enhanced screen sharing support";
      };
    };
    
    utilities = {
      macManager = mkOption {
        type = types.bool;
        default = true;
        description = "Enable MAC Address Manager GUI";
      };
      xdgManager = mkOption {
        type = types.bool;
        default = true;
        description = "Enable XDG Utilities Manager";
      };
    };
    
    desktopEntries = mkOption {
      type = types.bool;
      default = true;
      description = "Create desktop entries for enhanced applications";
    };
  };

  config = mkIf config.custom.enhanced-packages.enable {
    
    environment.systemPackages = with pkgs; [
      # Enhanced Browsers
      (mkIf config.custom.enhanced-packages.browsers.firefox
        (pkgs.firefox.override {
          # Enable WebRTC and PipeWire screen sharing
          cfg.enablePipeWire = true;
        })
      )
      
      (mkIf config.custom.enhanced-packages.browsers.firefox
        (pkgs.writeShellScriptBin "firefox-screenshare" ''
          # Firefox with enhanced screen sharing support
          export MOZ_ENABLE_WAYLAND=1
          export MOZ_USE_XINPUT2=1
          export MOZ_WEBRENDER=1
          export MOZ_ACCELERATED=1
          
          # WebRTC PipeWire environment
          export PIPEWIRE_RUNTIME_DIR="/run/user/$(id -u)"
          
          # Set Firefox preferences for screen sharing
          FIREFOX_PREFS_DIR="$HOME/.mozilla/firefox"
          if [ -d "$FIREFOX_PREFS_DIR" ]; then
              # Find default profile
              PROFILE=$(find "$FIREFOX_PREFS_DIR" -name "*.default*" -type d | head -n1)
              if [ -n "$PROFILE" ] && [ -d "$PROFILE" ]; then
                  # Create or update user.js with screen sharing preferences
                  cat >> "$PROFILE/user.js" << 'EOF'
// Enable WebRTC screen sharing with PipeWire on Wayland
user_pref("media.webrtc.pipewire", true);
user_pref("media.webrtc.capture.allow-capturer", true);
user_pref("media.navigator.mediadatadecoder_vpx_enabled", true);
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("widget.dmabuf.force-enabled", true);
user_pref("media.webrtc.hw.h264.enabled", true);
user_pref("media.webrtc.hw.vp8.enabled", true);
user_pref("media.webrtc.hw.vp9.enabled", true);
EOF
              fi
          fi
          
          exec ${pkgs.firefox}/bin/firefox "$@"
        '')
      )
      
      (mkIf config.custom.enhanced-packages.browsers.chrome
        (pkgs.google-chrome.override {
          commandLineArgs = [
            # Wayland and screen sharing
            "--ozone-platform-hint=auto"
            "--enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder,VaapiIgnoreDriverChecks,WebRTCPipeWireCapturer,WebRTCScreenCaptureV2"
            "--disable-features=UseChromeOSDirectVideoDecoder"
            "--enable-wayland-ime"
            "--disable-gpu-sandbox"
            
            # Additional WebRTC and screen sharing optimizations
            "--enable-webrtc-pipewire-capturer"
            "--rtc-use-pipewire"
            "--enable-gpu-rasterization"
            "--enable-zero-copy"
            "--ignore-gpu-blocklist"
            
            # Force PipeWire for screen capture
            "--webrtc-max-cpu-consumption-percentage=100"
            "--force-dark-mode"
          ];
        })
      )
      
      (mkIf config.custom.enhanced-packages.browsers.chromium
        (pkgs.chromium.override {
          commandLineArgs = [
            # Wayland and screen sharing  
            "--ozone-platform-hint=auto"
            "--enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder,WebRTCPipeWireCapturer,WebRTCScreenCaptureV2"
            "--enable-wayland-ime"
            "--disable-gpu-sandbox"
            
            # WebRTC PipeWire support
            "--enable-webrtc-pipewire-capturer"
            "--rtc-use-pipewire"
            "--enable-gpu-rasterization"
            "--enable-zero-copy"
          ];
        })
      )
      
      # Communication Apps with Screen Sharing
      (mkIf config.custom.enhanced-packages.communication.discord
        (pkgs.writeShellScriptBin "discord-wayland" ''
          # Discord with Wayland screen sharing support
          export XDG_SESSION_TYPE="wayland"
          export XDG_CURRENT_DESKTOP="gnome"
          export WAYLAND_DISPLAY="wayland-0"
          
          # Enable Ozone/Wayland for Electron
          export ELECTRON_OZONE_PLATFORM_HINT="auto"
          export NIXOS_OZONE_WL="1"
          
          # WebRTC flags for screen sharing
          FLAGS="--enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer,VaapiVideoDecoder"
          FLAGS="$FLAGS --ozone-platform=wayland --enable-wayland-ime"
          FLAGS="$FLAGS --enable-webrtc-pipewire-capturer --rtc-use-pipewire"
          
          exec ${pkgs.discord}/bin/discord $FLAGS "$@"
        '')
      )
      
      (mkIf config.custom.enhanced-packages.communication.slack
        (pkgs.writeShellScriptBin "slack-wayland" ''
          # Slack with enhanced Wayland screen sharing
          export XDG_SESSION_TYPE="wayland"
          export XDG_CURRENT_DESKTOP="gnome"
          export WAYLAND_DISPLAY="wayland-0"
          
          # Electron Wayland support
          export ELECTRON_OZONE_PLATFORM_HINT="auto"
          export NIXOS_OZONE_WL="1"
          
          # WebRTC screen sharing flags
          FLAGS="--enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer"
          FLAGS="$FLAGS --ozone-platform=wayland --enable-wayland-ime"
          FLAGS="$FLAGS --enable-webrtc-pipewire-capturer --rtc-use-pipewire"
          FLAGS="$FLAGS --disable-gpu-sandbox"
          
          exec ${pkgs.slack}/bin/slack $FLAGS "$@"
        '')
      )
      
      (mkIf config.custom.enhanced-packages.communication.zoom
        (pkgs.writeShellScriptBin "zoom-screenshare" ''
          # Set up screen sharing environment for Zoom
          export XDG_SESSION_TYPE="wayland"
          export XDG_CURRENT_DESKTOP="gnome"
          export WAYLAND_DISPLAY="wayland-0"
          export QT_QPA_PLATFORM="wayland;xcb"
          export GDK_BACKEND="wayland,x11"
          
          # WebRTC and PipeWire support
          export PIPEWIRE_RUNTIME_DIR="/run/user/$(id -u)"
          export PIPEWIRE_MEDIA_SESSION_CONFIG_DIR="/etc/pipewire/media-session.d"
          
          exec ${pkgs.zoom-us}/bin/zoom "$@"
        '')
      )
      
      # Utility Applications
      (mkIf config.custom.enhanced-packages.utilities.macManager
        (pkgs.writeShellScriptBin "mac-manager" ''
          exec ${pkgs.bash}/bin/bash /etc/nixos/scripts/mac-manager.sh "$@"
        '')
      )
      
      (mkIf config.custom.enhanced-packages.utilities.macManager
        (pkgs.writeShellScriptBin "mac-manager-gui" ''
          # Interactive MAC Address Manager GUI
          DIALOG_HEIGHT=20
          DIALOG_WIDTH=70
          
          # Check if dialog/whiptail is available
          if command -v whiptail &>/dev/null; then
              DIALOG=whiptail
          elif command -v dialog &>/dev/null; then
              DIALOG=dialog
          else
              # Fallback to zenity for GUI environments
              if command -v zenity &>/dev/null; then
                  # Use zenity GUI version
                  exec zenity --question --text="MAC Address Manager\\n\\nChoose an action:" --ok-label="Open Terminal Manager" --cancel-label="Cancel"
                  if [ $? -eq 0 ]; then
                      exec gnome-terminal -- sudo mac-manager
                  fi
                  exit 0
              else
                  # Final fallback to gnome-terminal with menu
                  exec gnome-terminal --title="MAC Address Manager" -- bash -c '
                      echo "MAC Address Manager"
                      echo "=================="
                      echo
                      sudo /etc/nixos/scripts/mac-manager.sh list
                      echo
                      echo "Available Commands:"
                      echo "  list                    - Show this interface list"
                      echo "  randomize-wifi         - Randomize all WiFi MACs"
                      echo "  restore wifi           - Restore WiFi MACs"
                      echo "  restore all            - Restore all MACs"
                      echo "  nm-configure           - Configure NetworkManager"
                      echo "  help                   - Show detailed help"
                      echo
                      echo -n "Enter command (or press Enter to exit): "
                      read cmd
                      if [ -n "$cmd" ]; then
                          sudo /etc/nixos/scripts/mac-manager.sh $cmd
                          echo
                          echo "Press Enter to continue..."
                          read
                      fi
                  '
                  exit 0
              fi
          fi
          
          while true; do
              # Main menu
              CHOICE=$($DIALOG --title "MAC Address Manager" --menu "Choose an action:" $DIALOG_HEIGHT $DIALOG_WIDTH 10 \\
                  "1" "List all network interfaces" \\
                  "2" "Randomize WiFi MAC addresses" \\
                  "3" "Restore WiFi MAC addresses" \\
                  "4" "Restore all MAC addresses" \\
                  "5" "Configure NetworkManager" \\
                  "6" "Show NetworkManager status" \\
                  "7" "Generate random MAC address" \\
                  "8" "Manual MAC change" \\
                  "9" "Help" \\
                  "0" "Exit" \\
                  3>&1 1>&2 2>&3)
              
              if [ $? -ne 0 ]; then
                  break
              fi
              
              case $CHOICE in
                  1)
                      gnome-terminal --title="Interface List" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh list; echo; echo 'Press Enter to continue...'; read"
                      ;;
                  2)
                      if $DIALOG --title "Confirm" --yesno "Randomize MAC addresses for all WiFi interfaces?\\n\\nThis will temporarily change your network identity." 10 50; then
                          gnome-terminal --title="Randomizing WiFi MACs" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh randomize-wifi; echo; echo 'Press Enter to continue...'; read"
                      fi
                      ;;
                  3)
                      if $DIALOG --title "Confirm" --yesno "Restore original MAC addresses for WiFi interfaces?" 8 50; then
                          gnome-terminal --title="Restoring WiFi MACs" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh restore wifi; echo; echo 'Press Enter to continue...'; read"
                      fi
                      ;;
                  4)
                      if $DIALOG --title "Confirm" --yesno "Restore original MAC addresses for ALL interfaces?" 8 50; then
                          gnome-terminal --title="Restoring All MACs" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh restore all; echo; echo 'Press Enter to continue...'; read"
                      fi
                      ;;
                  5)
                      if $DIALOG --title "Confirm" --yesno "Configure NetworkManager for enhanced MAC randomization?\\n\\nThis will modify NetworkManager settings." 10 60; then
                          gnome-terminal --title="Configuring NetworkManager" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh nm-configure; echo; echo 'Press Enter to continue...'; read"
                      fi
                      ;;
                  6)
                      gnome-terminal --title="NetworkManager Status" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh nm-status; echo; echo 'Press Enter to continue...'; read"
                      ;;
                  7)
                      MAC=$(sudo /etc/nixos/scripts/mac-manager.sh generate | grep "Generated MAC:" | cut -d: -f2- | xargs)
                      $DIALOG --title "Generated MAC Address" --msgbox "Generated MAC: $MAC\\n\\nThis address can be used for manual MAC changes." 8 50
                      ;;
                  8)
                      INTERFACE=$($DIALOG --title "Manual MAC Change" --inputbox "Enter interface name (e.g., wlan0):" 8 40 3>&1 1>&2 2>&3)
                      if [ $? -eq 0 ] && [ -n "$INTERFACE" ]; then
                          MAC_ADDR=$($DIALOG --title "Manual MAC Change" --inputbox "Enter new MAC address\\n(format: XX:XX:XX:XX:XX:XX)\\nor enter 'random' for random MAC:" 10 50 3>&1 1>&2 2>&3)
                          if [ $? -eq 0 ] && [ -n "$MAC_ADDR" ]; then
                              gnome-terminal --title="Changing MAC Address" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh change $INTERFACE $MAC_ADDR; echo; echo 'Press Enter to continue...'; read"
                          fi
                      fi
                      ;;
                  9)
                      gnome-terminal --title="MAC Manager Help" -- bash -c "sudo /etc/nixos/scripts/mac-manager.sh help; echo; echo 'Press Enter to continue...'; read"
                      ;;
                  0)
                      break
                      ;;
              esac
          done
        '')
      )
      
      (mkIf config.custom.enhanced-packages.utilities.xdgManager
        (pkgs.writeShellScriptBin "xdg-manager" ''
          exec ${pkgs.bash}/bin/bash /etc/nixos/scripts/xdg-manager.sh "$@"
        '')
      )
      
      # Dialog and menu tools for GUI wrappers
      dialog                  # Terminal dialog boxes
      newt                    # Provides whiptail command for dialog menus
      zenity                  # GTK dialog boxes
      
    ] ++ (optionals config.custom.enhanced-packages.desktopEntries [
      # Desktop entries for enhanced applications
      (pkgs.makeDesktopItem {
        name = "firefox-screenshare";
        desktopName = "Firefox (Screen Share)";
        comment = "Firefox with enhanced WebRTC PipeWire screen sharing support";
        exec = "firefox-screenshare";
        icon = "firefox";
        categories = [ "Network" "WebBrowser" ];
      })
      
      (pkgs.makeDesktopItem {
        name = "discord-wayland";
        desktopName = "Discord (Wayland)";
        comment = "Discord with Wayland screen sharing support";
        exec = "discord-wayland";
        icon = "discord";
        categories = [ "Network" "InstantMessaging" ];
      })
      
      (pkgs.makeDesktopItem {
        name = "slack-wayland";
        desktopName = "Slack (Wayland)";
        comment = "Slack with Wayland screen sharing support";
        exec = "slack-wayland";
        icon = "slack";
        categories = [ "Network" "InstantMessaging" "Office" ];
      })
      
      (pkgs.makeDesktopItem {
        name = "zoom-screenshare";
        desktopName = "Zoom (Screen Share)";
        comment = "Zoom with enhanced screen sharing support";
        exec = "zoom-screenshare";
        icon = "zoom";
        categories = [ "Network" "AudioVideo" "VideoConference" ];
      })
      
      (pkgs.makeDesktopItem {
        name = "mac-manager";
        desktopName = "MAC Address Manager";
        comment = "Manage and randomize network interface MAC addresses";
        exec = "mac-manager-gui";
        icon = "network-wired";
        categories = [ "Network" "System" ];
        terminal = false;
      })
      
      (pkgs.makeDesktopItem {
        name = "xdg-manager";
        desktopName = "XDG Utilities Manager";
        comment = "Manage XDG Base Directory Specification and file associations";
        exec = "gnome-terminal -- xdg-manager tools";
        icon = "folder";
        categories = [ "System" "Utility" ];
        terminal = true;
      })
    ]);
  };
}
