{ pkgs }:

with pkgs; [
  # Essential CLI tools that everyone needs
  
  # Text editors (popular: vim, neovim, nano)
  vim
  neovim
  nano
  
  # Terminal emulators (popular: alacritty, kitty)
  alacritty
  kitty
  
  # Shell improvements (popular: zsh, fish)
  zsh
  fish
  bash-completion
  
  # File managers (popular: ranger, midnight commander)
  ranger
  mc      # Midnight Commander
  nnn
  
  # System monitoring (popular: htop, btop)
  htop
  btop
  
  # Network tools (essential: curl, wget, nmap)
  curl
  wget
  nmap
  
  # Multimedia tools (essential: vlc, mpv, ffmpeg)
  vlc
  mpv
  ffmpeg
  
  # Compression and archives
  zip
  unzip
  p7zip
  
  # Version control (essential: git, git-lfs)
  git
  git-lfs
  gitui
  lazygit
  
  # Search and find tools (popular: ripgrep, fd, fzf)
  ripgrep
  fd
  fzf
  
  # Disk usage and file analysis
  ncdu
  
  # Process management
  procps
  psmisc
  
  # Screenshot and screen recording
  scrot
  flameshot
  
  # Image viewers
  feh
  
  # PDF viewers
  zathura
  evince
  
  # Calculator
  bc
  
  # System information
  neofetch
  
  # Password generation
  pwgen
  
  # Clipboard utilities
  xclip
  xsel
  
  # JSON/YAML processing
  jq
  
  # HTTP clients
  httpie
  
  # Encryption
  age
  
  # Database clients
  sqlite
  
  # Cloud storage sync
  rclone
  
  # Backup tools
  rsync
  
  # Container tools
  docker
  podman
  
  # Package managers for other ecosystems
  # Use consistent Python 3.11 to avoid version conflicts
  python311Packages.pip
  cargo
  
  # Documentation viewers
  man-pages
  tldr
  
  # Notification daemon
  libnotify
  
  # Font tools
  fontconfig
  
  # Programming fonts (popular: fira-code, jetbrains-mono)
  fira-code
  jetbrains-mono
  
  # Gaming platforms (popular: steam, lutris)
  steam
  lutris
  
  # Communication (popular: discord, telegram)
  discord
  telegram-desktop
  
  # Development tools
  gnumake
  cmake
  clang
  
  # Virtualization
  qemu
  
  # Encryption/Security
  gnupg
  openssh
  
  # Messaging
  signal-desktop
  
  # VPN
  openvpn
  
  # Task management
  stow
]

