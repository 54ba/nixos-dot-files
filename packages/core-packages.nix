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

