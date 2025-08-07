{ pkgs }:

with pkgs; [
  # Essential system utilities
  wget
  curl
  git
  vim
  neovim
  tree
  htop
  btop
  neofetch
  zip
  unzip
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
  
  # Network utilities (basic)
  openssh
  
  # System monitoring (basic)
  lsof
  
  # File system utilities
  ntfs3g
  exfat
  dosfstools
  
  # Archives and compression
  gnutar  # tar is now gnutar
  gzip
  bzip2
  xz
  p7zip
]
