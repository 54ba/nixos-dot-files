# Full Development Shell - All Languages
# Usage: nix-shell /etc/nixos/shells/full-dev-shell.nix

{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "full-dev-shell";
  
  buildInputs = with pkgs; [
    # Python Development
    python311
    python311Packages.pip
    python311Packages.poetry
    python311Packages.virtualenv
    
    # Node.js/TypeScript Development
    nodejs_20
    nodePackages.npm
    nodePackages.yarn
    nodePackages.pnpm
    nodePackages.typescript
    nodePackages.ts-node
    nodePackages.eslint
    nodePackages.prettier
    
    # Flutter/Dart Development
    flutter
    dart
    
    # PHP Development
    php82
    php82Packages.composer
    
    # Android Development
    android-tools
    
    # General Development Tools
    git
    vim
    neovim
    curl
    wget
    jq
    yq
    tree
    ripgrep
    fd
    bat
    eza
    fzf
    
    # Build Tools
    cmake
    ninja
    pkg-config
    gcc
    gnumake
    
    # Container Tools
    podman
    podman-compose
    
    # Database Tools
    postgresql_15
    mysql80
    redis
    sqlite
    
    # Web Servers
    nginx
    
    # Version Control
    git-lfs
    
    # IDE/Editor Support
    nil  # Nix LSP
    nixpkgs-fmt
    
    # Utilities
    unzip
    zip
    tar
    gzip
  ];
  
  shellHook = ''
    echo "🚀 Full Development Environment"
    echo "================================================"
    echo "🐍 Python: $(python --version)"
    echo "⚡ Node.js: $(node --version)"
    echo "🎯 Dart: $(dart --version 2>/dev/null | head -n1)"
    echo "🐘 PHP: $(php --version | head -n1)"
    echo "📱 Flutter: $(flutter --version | head -n1)"
    echo "================================================"
    echo ""
    echo "Available Development Shells:"
    echo "  nix-shell /etc/nixos/shells/python-shell.nix     # Python only"
    echo "  nix-shell /etc/nixos/shells/typescript-shell.nix # TypeScript/Node.js only"
    echo "  nix-shell /etc/nixos/shells/flutter-shell.nix    # Flutter only"
    echo "  nix-shell /etc/nixos/shells/php-shell.nix        # PHP only"
    echo ""
    echo "Quick Start Commands:"
    echo "  Python:     python -m venv venv && source venv/bin/activate"
    echo "  Node.js:    npm init -y"
    echo "  TypeScript: tsc --init"
    echo "  Flutter:    flutter create my_app"
    echo "  PHP:        composer init"
    echo ""
    echo "Environment ready for multi-language development!"
    
    # Set up environment variables for all languages
    export PYTHONPATH="$PWD:$PYTHONPATH"
    export NODE_ENV="development"
    export PATH="$PWD/node_modules/.bin:$PATH"
    export PATH="$PWD/vendor/bin:$PATH"
    export ANDROID_HOME="$HOME/Android/Sdk"
    export FLUTTER_ROOT="$(dirname $(which flutter) 2>/dev/null || echo '')"
  '';
}

