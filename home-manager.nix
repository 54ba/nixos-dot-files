# Enhanced Home Manager Configuration with nixai Integration
# This provides user-level AI assistance and development tools

{ config, pkgs, inputs, lib, ... }:

{

  dconf.settings = {
    "org/gnome/desktop/background" = {
      picture-uri = "file://${./bg.jpg}"; # Use ./ if image is relative to your config, or an absolute path
      # Or, if you want to fetch an image from the internet (e.g., for a "fetchurl" source):
      # picture-uri = "file://${pkgs.fetchurl {
      #   url = "https://example.com/your-wallpaper.png";
      #   sha256 = "your-sha256-hash"; # IMPORTANT: Get this with `nix-prefetch-url URL`
      # }}/your-wallpaper.png";
      picture-options = "zoom"; # Options: "none", "wallpaper", "centered", "scaled", "stretched", "zoom"
      primary-color = "#000000"; # Optional: background color for "none" or other options
      color-shading-type = "solid"; # Or "vertical", "horizontal"
    };
  };




  # imports = [
  #   inputs.nixai.homeManagerModules.default
  # ];

  # Basic user information
  home.username = "mahmoud";
  home.homeDirectory = "/home/mahmoud";
  home.stateVersion = "25.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # ===== NIXAI HOME MANAGER INTEGRATION (TEMPORARILY DISABLED) =====
  # services.nixai = {
  #   enable = true;
  #   
  #   mcp = {
  #     enable = true;
  #     aiProvider = "copilot";
  #     aiModel = "gpt-4";
  #     port = 8082; # Different port for user service
  #     socketPath = "$HOME/.local/share/nixai/mcp.sock";
  #     
  #     # User-specific documentation sources
  #     documentationSources = [
  #       "https://wiki.nixos.org/wiki/NixOS_Wiki"
  #       "https://nix.dev/"
  #       "https://nixos.org/manual/nixpkgs/stable/"
  #       "https://nix-community.github.io/home-manager/"
  #       "https://search.nixos.org/packages"
  #       "https://search.nixos.org/options"
  #       "https://github.com/nix-community/awesome-nix"
  #     ];
  #     
  #     environment = {
  #       # User environment variables
  #       HOME = config.home.homeDirectory;
  #       USER = config.home.username;
  #     };
  #     
  #     extraFlags = [ "--log-level=info" "--user-mode" ];
  #   };
  #   
  #   # Enable VS Code integration
  #   vscodeIntegration = {
  #     enable = true;
  #     contextAware = true;
  #     autoRefreshContext = true;
  #     contextTimeout = 5000;
  #   };
  #   
  #   # Enable Neovim integration
  #   neovimIntegration = {
  #     enable = true;
  #     useNixVim = true;
  #     autoStartMcp = true;
  #     keybindings = {
  #       askNixai = "<leader>na";
  #       askNixaiVisual = "<leader>na";
  #       startMcpServer = "<leader>ns";
  #     };
  #   };
  # };

  # Development packages
  home.packages = with pkgs; [
    # AI/ML Development
    python3
    python3Packages.pip
    python3Packages.virtualenv
    nodejs
    nodePackages.npm
    nodePackages.yarn
    
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
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "54ba";
    userEmail = "54bao.o@gmail.com"; # Update with your email
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";
      
      # Enhanced diff and merge tools
      diff.tool = "vimdiff";
      merge.tool = "vimdiff";
      
      # GPG signing (optional)
      # commit.gpgsign = true;
      # user.signingkey = "your-gpg-key";
    };
    
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      lg = "log --oneline --graph --decorate --all";
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
      hms = "home-manager switch";
      
      # Development shortcuts
      dev = "nix develop";
      run = "nix run";
      shell = "nix-shell";
    };
    initContent = lib.mkOrder 550 ''
      # Initialize starship prompt
      eval "$(starship init zsh)"
      
      # Initialize zoxide
      eval "$(zoxide init zsh)"
      
      # Initialize direnv
      eval "$(direnv hook zsh)"
      
      # nixai completion
      if command -v nixai > /dev/null 2>&1; then
        eval "$(nixai completion zsh)"
      fi
      
      # Custom functions
      nixai-context() {
        echo "🤖 Getting NixOS context for AI assistance..."
        nixai context detect --cache
      }
      
      nixai-optimize() {
        echo "⚡ Running AI-powered NixOS optimization..."
        nixai ask "Analyze my current NixOS configuration and suggest optimizations"
      }
      
      nixai-troubleshoot() {
        echo "🔧 Running AI-powered troubleshooting..."
        nixai diagnose --type system
      }
    '';
  };

  # Starship configuration
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      
      directory = {
        style = "blue";
        truncation_length = 4;
        truncation_symbol = "…/";
      };
      
      git_branch = {
        style = "bright-green";
      };
      
      nix_shell = {
        symbol = "❄️ ";
        style = "bright-blue";
      };
      
      # Custom nixai indicator
      custom.nixai = {
        command = "echo 🤖";
        when = "test -S ~/.local/share/nixai/mcp.sock";
        description = "nixai MCP server is running";
      };
    };
  };

  # VS Code configuration with AI integration (temporarily disabled)
  # programs.vscode = {
  #   enable = true;
  #   
  #   extensions = with pkgs.vscode-extensions; [
  #     # Nix support
  #     bbenoist.nix
  #     
  #     # General development
  #     ms-python.python
  #     
  #     # Productivity
  #     vscodevim.vim
  #     
  #     # Git
  #     eamodio.gitlens
  #   ];
  #   
  #   userSettings = {
  #     "editor.fontSize" = 14;
  #     "editor.fontFamily" = "'JetBrains Mono', 'Fira Code', monospace";
  #     "editor.fontLigatures" = true;
  #     "editor.minimap.enabled" = false;
  #     "editor.rulers" = [ 80 120 ];
  #     
  #     # AI settings
  #     "github.copilot.enable" = {
  #       "*" = true;
  #       "nix" = true;
  #     };
  #     
  #     # Nix settings
  #     "nix.enableLanguageServer" = true;
  #     "nix.serverPath" = "nil";
  #     
  #     # Terminal
  #     "terminal.integrated.shell.linux" = "${pkgs.zsh}/bin/zsh";
  #     "terminal.integrated.fontSize" = 14;
  #     
  #     # Theme
  #     "workbench.colorTheme" = "Tomorrow Night Blue";
  #     "workbench.iconTheme" = "material-icon-theme";
  #   };
  # };

  # Neovim configuration (basic)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    
    extraConfig = ''
      " Basic configuration
      set number relativenumber
      set expandtab tabstop=2 shiftwidth=2
      set hidden
      set ignorecase smartcase
      set termguicolors
      
      " Leader key
      let mapleader = " "
    '';
  };

  # Direnv for automatic development environments
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # File manager configuration
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain" = "nvim.desktop";
      "application/pdf" = "firefox.desktop";
    };
  };

  # XDG directories
  xdg.userDirs = {
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

  # System services
  systemd.user.startServices = "sd-switch";
  
  # Create nixai config directory
  xdg.configFile."nixai/.keep".text = "";
  
  # Development environment templates
  home.file.".local/share/nixai/templates/python.envrc".text = ''
    use flake github:the-nix-way/dev-templates#python
  '';
  
  home.file.".local/share/nixai/templates/rust.envrc".text = ''
    use flake github:the-nix-way/dev-templates#rust
  '';
  
  home.file.".local/share/nixai/templates/node.envrc".text = ''
    use flake github:the-nix-way/dev-templates#nodejs
  '';
}

