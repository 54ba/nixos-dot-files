# Example configuration for SteamOS Mobile Suite
# Add this to your configuration.nix imports or use as reference

{ config, lib, pkgs, ... }:

{
  imports = [
    # Import the main suite module
    ./modules/steamos-mobile-suite.nix
  ];

  # Enable the complete SteamOS Mobile Suite
  custom.steamos-mobile-suite = {
    enable = true;
    profile = "balanced";  # or "gaming", "productivity", "server"
    
    features = {
      steamGaming = true;      # Enable SteamOS-like gaming
      remoteAccess = true;     # Enable remote desktop/SSH
      mobileControl = true;    # Enable mobile device control
      fileSharing = true;      # Enable cross-device file sharing
      automation = true;       # Enable automation features
    };
    
    security = {
      level = "standard";      # minimal/standard/enhanced/paranoid
      requireKeys = true;      # Require SSH keys
      allowMobileAuth = true;  # Allow mobile authentication
      encryptTraffic = true;   # Encrypt remote traffic
    };
    
    performance = {
      prioritizeGaming = true;     # Prioritize gaming performance
      lowLatency = true;           # Enable low-latency optimizations
      hardwareAcceleration = true; # Enable hardware acceleration
    };
    
    monitoring = {
      enable = true;                # Enable monitoring
      mobileNotifications = true;   # Send alerts to mobile
      performanceMetrics = true;    # Show performance overlays
    };
  };

  # Alternative: Enable individual modules with custom settings
  # This gives you more granular control over each component
  
  # custom.steamos-gaming = {
  #   enable = true;
  #   steam = {
  #     enable = true;
  #     remotePlay = true;
  #     bigPicture = true;
  #     proton = {
  #       enable = true;
  #       ge = true;
  #     };
  #   };
  #   performance = {
  #     enable = true;
  #     gamemode = true;
  #     mangohud = true;
  #     lowLatency = true;
  #   };
  # };

  # custom.ssh-remote-access = {
  #   enable = true;
  #   server = {
  #     enable = true;
  #     passwordAuthentication = false;
  #     alternativePorts = [ 2222 ];
  #   };
  #   security = {
  #     enable = true;
  #     fail2ban = true;
  #   };
  #   mobileAccess = {
  #     enable = true;
  #     compression = true;
  #   };
  # };

  # custom.remote-control = {
  #   enable = true;
  #   rustdesk = {
  #     enable = true;
  #     encryption = true;
  #     quality = "high";
  #   };
  #   wayvnc = {
  #     enable = true;
  #     quality = "high";
  #   };
  #   mobileApps = {
  #     enable = true;
  #     scrcpy = true;
  #     kdeConnect = true;
  #   };
  # };

  # custom.mobile-integration = {
  #   enable = true;
  #   android = {
  #     enable = true;
  #     scrcpy = {
  #       enable = true;
  #       wireless = true;
  #       recordScreen = true;
  #     };
  #   };
  #   ios = {
  #     enable = true;
  #     uxplay = true;
  #   };
  #   webInterface = {
  #     enable = true;
  #     port = 8080;
  #     authentication = true;
  #   };
  # };
}
