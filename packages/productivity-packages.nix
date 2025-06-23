{ pkgs }:

with pkgs; [
  # Communication tools
  slack
  discord
  telegram-desktop
  signal-desktop
  thunderbird
  teams-for-linux
  zoom-us
  
  # Office suites and document editing
  libreoffice-fresh
  onlyoffice-bin
  
  # Note-taking and knowledge management
  # notion-app-enhanced  # If available
  obsidian
  logseq
  joplin-desktop
  zettlr
  
  # Password managers and security
  bitwarden
  keepassxc
  gnupg
  
  # PDF tools
  kdePackages.okular  # Qt 6 version
  evince
  pdftk
  poppler_utils
  
  # Mind mapping and diagramming
  drawio
  xmind
  freemind
  
  # Time tracking and productivity
  # toggl-track  # Check availability
  # rescuetime   # Check availability
  
  # Calendar and scheduling
  thunderbird  # Also includes calendar integration
  
  # File management
  kdePackages.dolphin  # Qt 6 version
  nemo
  pcmanfm
  
  # Cloud storage
  # dropbox  # Check availability
  nextcloud-client
  
  # System utilities
  gnome-tweaks  # Renamed
  dconf-editor
  
  # Text editors
  kdePackages.kate  # Qt 6 version
  gedit
  # typora  # Check availability
  
  # Clipboard managers
  copyq
  # clipit  # Check availability
  
  # Screenshot tools
  flameshot
  kdePackages.spectacle  # Qt 6 version
  gnome-screenshot
  
  # Archive managers
  kdePackages.ark  # Qt 6 version
  file-roller
  
  # System information
  # hardinfo  # Check availability
  # cpu-x     # Check availability
]

