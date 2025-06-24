{ pkgs }:

with pkgs; [
  # Essential system utilities
  wget
  curl
  git
  git-credential-manager
  vim
  neovim
  firefox
  chromium
  google-chrome  # System-wide Chrome
  tree
  htop
  btop
  neofetch
  zip
  unzip
  p7zip
  rsync
  
  # Terminal and shell utilities
  zsh
  oh-my-zsh
  starship
  fzf
  ripgrep
  fd
  bat
  eza  # Renamed from exa
  zoxide
  wezterm  # Wez terminal
  
  # Development tools
  github-desktop
  code-cursor  # Code-cursor editor
  
  # Design and media tools
  figma-linux
  ffmpeg  # FFmpeg for media processing
  
  # System utilities
  gparted  # Partition editor
  
  # Database and analytics
  neo4j
  
  # VPN and networking tools
  riseup-vpn
  shadowsocks-rust  # Shadowsocks client (rust implementation)

  # Package managers and development tools
  flatpak
  poetry  # Python dependency management
  pipx    # Install Python applications in isolated environments
  yarn    # JavaScript package manager

  # Virtualization
  virtualbox
  
  # Network utilities
  nmap
  netcat
  socat
  openssh
  openvpn
  wireguard-tools
  
  # System monitoring
  iotop
  nethogs
  iftop
  lsof
  strace
  
  # File system utilities
  ntfs3g
  exfat
  dosfstools
  
  # Archives and compression
  gnutar  # tar is now gnutar
  gzip
  bzip2
  xz
  lz4
  zstd
]
