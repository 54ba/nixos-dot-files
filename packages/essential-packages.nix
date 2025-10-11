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

  # Flutter development dependencies
  sysprof  # System profiler
  libsysprof-capture  # Static library for Sysprof capture data generation (provides sysprof-capture-4.pc)
  libsecret.dev  # Development files for libsecret (provides libsecret-1.pc)
  glib.dev  # Development files for GLib (includes sysprof-capture-4.pc)

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
  
  # Wayland Window Managers
  niri  # Modern tiling Wayland compositor

  # Android development tools
  android-tools   # ADB, fastboot, and other Android utilities
  android-udev-rules  # Udev rules for Android devices

  # Terminal utilities
  wezterm  # Wez terminal

  # Development tools
  github-desktop
  cursor-latest  # Latest Cursor AI editor from cursor.com (v1.7)

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

  # Wine and Windows Compatibility
  wine64
  wineWowPackages.stable
  winetricks
  playonlinux
  lutris
  dxvk
  vkd3d
  gamemode
  mangohud

  # NVIDIA Gaming and Performance
  nvidia-vaapi-driver
  nvidia-docker
  nvidia-container-toolkit

    # NVIDIA Performance Monitoring
  nvtopPackages.nvidia

  # Gaming Performance Tools
  gamemode
  mangohud
  goverlay
  libstrangle
  vkbasalt

  # Touchpad and Gesture Support
  libinput
  xorg.xf86inputlibinput
  xorg.xinput
  xorg.xev
  xorg.xrandr
  xorg.xset
  xorg.xsetroot

  # Gesture Recognition
  touchegg
  libgestures
  libinput-gestures

  # Touchpad Utilities
  xorg.xf86inputsynaptics

  # Fingerprint Reader Support
  fprintd
  libfprint
  libfprint-tod
  fprintd-tod
  open-fprintd

  # .NET Framework and Windows Compatibility
  mono
  dotnet-sdk
  dotnet-runtime
  q4wine
  bottles

  # Wine dependencies
  cabextract
  p7zip
  unzip
  zip
  corefonts
  liberation_ttf
  dejavu_fonts
]
