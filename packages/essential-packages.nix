{ pkgs }:

with pkgs; [
  # Web browsers
  firefox
  chromium  # Better NixOS integration than google-chrome
  
  # GUI essentials from main config
  nautilus
  gnome-terminal
  flameshot
  pavucontrol
  networkmanagerapplet
  python3  # Use default Python 3.12 for better binary compatibility
  
  # Git and credentials
  git-lfs
  gitAndTools.gitFull
  git-credential-manager  # Modern git credentials manager
  seahorse  # GUI for managing credentials
  libsecret  # For storing credentials securely
  gnome-keyring  # GNOME keyring for credential storage
  
  # System tray and notifications
  libnotify
  gnome-tweaks
  gnome-shell-extensions
  gnomeExtensions.user-themes
  gnomeExtensions.dash-to-dock
  gnomeExtensions.arc-menu
  gnomeExtensions.blur-my-shell
  gnomeExtensions.compiz-windows-effect
  gnomeExtensions.desktop-icons-ng-ding
  gnomeExtensions.sound-output-device-chooser
  gnomeExtensions.caffeine
  gnomeExtensions.clipboard-indicator
  gnomeExtensions.workspace-indicator
  gnomeExtensions.removable-drive-menu
  gnomeExtensions.system-monitor
  gnomeExtensions.vitals
  gnomeExtensions.weather-oclock
  
  # Additional GNOME apps
  gnome-photos
  gnome-music
  gnome-maps
  gnome-calculator
  gnome-weather
  gnome-clocks
  gnome-calendar
  
  # Display and monitor management
  brightnessctl
  
  # Audio
  pulseaudio
  pamixer
  playerctl
  
  # Appearance and themes
  libsForQt5.qt5ct
  gnome-themes-extra
  papirus-icon-theme
  adwaita-icon-theme
  hicolor-icon-theme
  yaru-theme
  materia-theme
  nordic
  orchis-theme
  
  # Utilities
  polkit_gnome
  xdg-utils
  xdg-user-dirs
  xdg-desktop-portal
  xdg-desktop-portal-gnome
  desktop-file-utils
  xclip
  xorg.xdpyinfo
  xorg.xrandr
  xorg.xev
  
  # Additional utilities
  starship   # Prompt (system-wide installation)
  
  # Android development tools
  android-tools   # ADB, fastboot, and other Android utilities
  android-udev-rules  # Udev rules for Android devices
  
  # Terminal utilities
  wezterm  # Wez terminal
  
  # Development tools
  github-desktop
  code-cursor  # Code-cursor editor
  
  # Design and media tools
  figma-linux
  ffmpeg  # FFmpeg for media processing
  
  # System utilities
  gparted  # Partition editor
  
  # VPN and networking tools
  riseup-vpn
  shadowsocks-rust  # Shadowsocks client (rust implementation)

  # Package managers and development tools
  flatpak
  poetry  # Python dependency management
  pipx    # Install Python applications in isolated environments
  yarn    # JavaScript package manager
  
  # Network utilities (advanced)
  netcat
  socat
  openvpn
  wireguard-tools
  
  # System monitoring (advanced)
  iotop
  nethogs
  iftop
  strace
  
  # Archives and compression (additional formats)
  lz4
  zstd
]
