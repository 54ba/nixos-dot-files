{ config, pkgs, inputs, lib, ... }:
{
  home.username = "mahmoud";
  home.homeDirectory = "/home/mahmoud";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;


  # Development packages
  home.packages = with pkgs; [
    # AI/ML Development
    python311  # Use consistent Python 3.11 instead of python3
    python311Packages.pip
    python311Packages.virtualenv
    poetry
    python311Packages.setuptools
    python311Packages.wheel
    
    # Node.js/TypeScript Development
    nodejs  # Default version to avoid conflicts
    nodePackages.npm
    nodePackages.yarn
    nodePackages.pnpm
    nodePackages.typescript
    nodePackages.ts-node
    nodePackages.eslint
    nodePackages.prettier
    
    # Flutter/Dart Development
    flutter
    # dart - included with flutter, removing to avoid collision
    
    # PHP Development
    php82
    # php82Packages.composer - removed to avoid collision with Flutter
    
    # Development Tools
    jq
    yq
    curl
    wget
    tree
    ripgrep
    fd
    bat
    eza
    fzf
    
    # Container Tools
    docker-compose
    podman-compose
    
    # Nix Tools
    nil # Nix LSP
    nixpkgs-fmt
    alejandra
    nix-tree
    nix-du
    
    # Terminal Tools
    starship
    zoxide
    direnv
    nix-direnv
    
    # Editor Tools
    tree-sitter
    
    # Communication
    slack
    zoom-us
    discord
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = lib.mkDefault "54ba";
    userEmail = lib.mkDefault "54bao.o@gmail.com"; # Update with your email
    
    extraConfig = {
      init.defaultBranch = lib.mkDefault "main";
      pull.rebase = lib.mkDefault true;
      push.autoSetupRemote = lib.mkDefault true;
      core.editor = lib.mkDefault "nvim";
      
      # Enhanced diff and merge tools
      diff.tool = lib.mkDefault "vimdiff";
      merge.tool = lib.mkDefault "vimdiff";
      
      # GPG signing (optional)
      # commit.gpgsign = true;
      # user.signingkey = "your-gpg-key";
    };
    
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      
      # AI-assisted git commands using nixai
      ai-commit = "!f() { nixai ask \"Generate a commit message for these changes: $(git diff --cached)\"; }; f";
      ai-review = "!f() { nixai ask \"Review this code change: $(git diff)\"; }; f";
    };
  };

  # Shell configuration with AI enhancement
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      ll = "eza -la";
      ls = "eza";
      cat = "bat";
      find = "fd";
      grep = "rg";
      
    # nixai shortcuts
    nai = "nixai ask";
    nix-help = "nixai ask";
    nix-build-help = "nixai build --help";
    nix-debug = "nixai diagnose";
    
    # Enhanced flake aliases with nixai integration
    rebuild-flake = "sudo nixos-rebuild switch --flake .#mahmoud-laptop";
    test-flake = "sudo nixos-rebuild test --flake .#mahmoud-laptop";
    boot-flake = "sudo nixos-rebuild boot --flake .#mahmoud-laptop";
      
      # NixOS shortcuts
      nrs = "sudo nixos-rebuild switch";
      nrt = "sudo nixos-rebuild test";
      nrb = "sudo nixos-rebuild boot";
      nrc = "sudo nixos-rebuild switch --flake .";
      nrct = "sudo nixos-rebuild test --flake .";
      nrg = "sudo nix-collect-garbage -d";
      
      # Package management
      nps = "nix search nixpkgs";
      npi = "nix profile install";
      npr = "nix profile remove";
      npl = "nix profile list";
      
      # Development shortcuts
      ns = "nix-shell";
      nsp = "nix-shell -p";
      
      # Development environment shortcuts
      dev-python = "nix-shell /etc/nixos/shells/python-shell.nix";
      dev-ts = "nix-shell /etc/nixos/shells/typescript-shell.nix";
      dev-flutter = "nix-shell /etc/nixos/shells/flutter-shell.nix";
      dev-php = "nix-shell /etc/nixos/shells/php-shell.nix";
      dev-full = "nix-shell /etc/nixos/shells/full-dev-shell.nix";
      
      # Directory shortcuts
      cd-nix = "cd /etc/nixos";
      cd-home = "cd ~/.config/home-manager";
    };
    
    initContent = ''
      # Enable starship prompt
      eval "$(starship init zsh)"
      
      # Enable zoxide
      eval "$(zoxide init zsh)"
      
      # Enable direnv
      eval "$(direnv hook zsh)"
      
      # Custom functions
      nixai-help() {
        echo "NixAI Commands:"
        echo "  nai [question]      - Ask nixai a question"
        echo "  nix-help [topic]    - Get help on Nix topics"
        echo "  nix-debug          - Diagnose system issues"
        echo "  rebuild-flake      - Rebuild system with flake"
        echo "  test-flake         - Test system build with flake"
      }
      
      # Function to easily edit NixOS config
      edit-nix() {
        sudo $EDITOR /etc/nixos/configuration.nix
      }
      
      # Function to edit home-manager config
      edit-home() {
        $EDITOR ~/.config/home-manager/home.nix
      }
      
      # Function to search and install packages
      nix-install() {
        if [ -z "$1" ]; then
          echo "Usage: nix-install <package-name>"
          return 1
        fi
        nix search nixpkgs $1
        read "?Install $1? (y/N): " confirm
        if [[ $confirm == [yY] ]]; then
          nix profile install nixpkgs#$1
        fi
      }
    '';
  };

  # Starship prompt configuration
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };
      
      git_branch = {
        format = "[$symbol$branch]($style) ";
      };
      
      nix_shell = {
        format = "[⎈ $state( \\($name\\))]($style) ";
        heuristic = true;
      };
      
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };
      
      cmd_duration = {
        min_time = 500;
        format = "⏱️  [$duration]($style) ";
      };
    };
  };

  # Direnv configuration for automatic shell environments
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Bat (better cat) configuration
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      pager = "less -FR";
    };
  };

  # FZF configuration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f";
    defaultOptions = [ "--height 40%" "--border" ];
  };

  # Zoxide (better cd) configuration
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Development environment configuration with Wayland optimizations
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "gnome-terminal";
    
    # Wayland environment variables
    WAYLAND_DISPLAY = "wayland-0";
    XDG_SESSION_TYPE = "wayland";
    XDG_RUNTIME_DIR = "/run/user/1000";
    
    # Force Wayland for applications
    NIXOS_OZONE_WL = "1";  # Chromium/Electron apps
    MOZ_ENABLE_WAYLAND = "1";  # Firefox
    QT_QPA_PLATFORM = "wayland;xcb";  # Qt applications
    GDK_BACKEND = "wayland,x11";  # GTK applications
    SDL_VIDEODRIVER = "wayland,x11";  # SDL applications
    CLUTTER_BACKEND = "wayland";  # Clutter applications
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    
    # Java applications Wayland support
    _JAVA_AWT_WM_NONREPARENTING = "1";
    
    # Development environment variables
    NIXPKGS_ALLOW_UNFREE = "1";
    
    # Python environment
    PYTHONPATH = "$HOME/.local/lib/python3.11/site-packages:$PYTHONPATH";
    
    # Terminal and shell optimizations
    TERM = "xterm-256color";
  };

  # XDG configuration
  xdg = {
    enable = true;
    
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      videos = "$HOME/Videos";
      templates = "$HOME/Templates";
      publicShare = "$HOME/Public";
    };
    
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        "application/pdf" = "evince.desktop";
        "image/jpeg" = "eog.desktop";
        "image/png" = "eog.desktop";
        "text/plain" = "nvim.desktop";
        "inode/directory" = "nautilus.desktop";
      };
    };
  };

  # Fonts configuration
  fonts.fontconfig.enable = true;

  # Services
  services = {
    # Enable GPG agent
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 1800;
      enableSshSupport = true;
    };
  };

  # GTK theme configuration
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # Qt theme configuration
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

}

