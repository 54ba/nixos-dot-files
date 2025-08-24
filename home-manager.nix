{ config, pkgs, inputs, lib, ... }:
{
  home.username = "mahmoud";
  home.homeDirectory = "/home/mahmoud";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;


  # Development packages
  home.packages = with pkgs; [
    # Home Manager CLI
    home-manager

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

    # GNOME Extensions (User-level installation)
    gnomeExtensions.dash-to-dock
    gnomeExtensions.blur-my-shell
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.desktop-icons-ng-ding
    gnomeExtensions.system-monitor
    gnomeExtensions.system-monitor-next
    gnomeExtensions.multicore-system-monitor
    gnomeExtensions.status-icons
    gnomeExtensions.auto-move-windows
    gnomeExtensions.all-windows
    gnomeExtensions.all-windows-saverestore-window-positions
    gnomeExtensions.arc-menu
    gnomeExtensions.activity-app-launcher
    gnomeExtensions.alphabetical-app-grid
    gnomeExtensions.sound-output-device-chooser
    gnomeExtensions.removable-drive-menu
    gnomeExtensions.do-not-disturb-while-screen-sharing-or-recording
    gnomeExtensions.screenshot-window-sizer
    gnomeExtensions.light-style
    gnomeExtensions.compiz-windows-effect
    gnomeExtensions.runcat
    gnomeExtensions.slinger
    gnomeExtensions.shyriiwook
    gnomeExtensions.reading-strip
    gnomeExtensions.extension-list
    gnomeExtensions.user-stylesheet-font
    gnomeExtensions.lockscreen-extension
    gnomeExtensions.primary-input-on-lockscreen

    # Professional Themes and Icons
    # Modern GTK Themes
    whitesur-gtk-theme
    nordic
    gruvbox-gtk-theme
    catppuccin-gtk
    dracula-theme

    # Professional Icon Themes
    papirus-icon-theme
    papirus-folders
    tela-icon-theme
    numix-icon-theme-circle
    breeze-icons

    # Cursor Themes
    bibata-cursors
    phinger-cursors
    capitaine-cursors

    # Fonts
    inter
    jetbrains-mono
    fira-code
    source-code-pro
    noto-fonts
    noto-fonts-emoji

    # Additional GNOME Tools
    gnome-tweaks
    gnome-shell-extensions
    dconf-editor
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

      # Theme switching functions
      theme-whitesur() {
        gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-dark"
        gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
        gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice"
        gsettings set org.gnome.desktop.interface font-name "Inter 10"
        gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono 10"
        echo "Switched to WhiteSur Dark theme"
      }

      theme-nordic() {
        gsettings set org.gnome.desktop.interface gtk-theme "Nordic"
        gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
        gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice"
        gsettings set org.gnome.desktop.interface font-name "Inter 10"
        gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono 10"
        echo "Switched to Nordic theme"
      }

      theme-gruvbox() {
        gsettings set org.gnome.desktop.interface gtk-theme "Gruvbox-Dark-B"
        gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
        gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice"
        gsettings set org.gnome.desktop.interface font-name "Inter 10"
        gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono 10"
        echo "Switched to Gruvbox Dark theme"
      }

      theme-catppuccin() {
        gsettings set org.gnome.desktop.interface gtk-theme "Catppuccin-Mocha-Standard-Mauve-Dark"
        gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
        gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice"
        gsettings set org.gnome.desktop.interface font-name "Inter 10"
        gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono 10"
        echo "Switched to Catppuccin Mocha theme"
      }

      theme-dracula() {
        gsettings set org.gnome.desktop.interface gtk-theme "Dracula"
        gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
        gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Ice"
        gsettings set org.gnome.desktop.interface font-name "Inter 10"
        gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono 10"
        echo "Switched to Dracula theme"
      }

      # List available themes
      list-themes() {
        echo "Available themes:"
        echo "  theme-whitesur   - WhiteSur Dark theme"
        echo "  theme-nordic     - Nordic theme"
        echo "  theme-gruvbox    - Gruvbox Dark theme"
        echo "  theme-catppuccin - Catppuccin Mocha theme"
        echo "  theme-dracula    - Dracula theme"
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

  # Enhanced Fonts configuration
  fonts.fontconfig.enable = true;

  # Font packages and configuration
  fonts.fonts = with pkgs; [
    # Modern Sans-serif fonts
    inter
    source-sans-pro
    source-serif-pro
    source-code-pro

    # Programming fonts
    jetbrains-mono
    fira-code
    hack
    ubuntu-font-family

    # Icon fonts
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk
    noto-fonts-extra

    # Additional fonts
    liberation-fonts
    dejavu-fonts
    freefont_ttf
  ];

  # Fontconfig configuration
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "JetBrains Mono" "Fira Code" "Hack" "DejaVu Sans Mono" ];
      sansSerif = [ "Inter" "Source Sans Pro" "DejaVu Sans" ];
      serif = [ "Source Serif Pro" "DejaVu Serif" ];
      emoji = [ "Noto Color Emoji" ];
    };

    # Font substitution
    substitutions = {
      monospace = [ "JetBrains Mono" "Fira Code" "Hack" ];
      sansSerif = [ "Inter" "Source Sans Pro" ];
      serif = [ "Source Serif Pro" ];
    };

    # Local font configuration
    localConf = ''
      <!-- Enable subpixel rendering -->
      <match target="font">
        <edit name="rgba" mode="assign">
          <const>rgb</const>
        </edit>
      </match>

      <!-- Enable LCD filtering -->
      <match target="font">
        <edit name="lcdfilter" mode="assign">
          <const>default</const>
        </edit>
      </match>

      <!-- Enable hinting -->
      <match target="font">
        <edit name="hinting" mode="assign">
          <bool>true</bool>
        </edit>
      </match>

      <!-- Enable antialiasing -->
      <match target="font">
        <edit name="antialias" mode="assign">
          <bool>true</bool>
        </edit>
      </match>
    '';
  };

  # Services
  services = {
    # Enable GPG agent
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 1800;
      enableSshSupport = true;
    };
  };

    # Enhanced GNOME dconf settings for session restoration and extensions
  dconf.settings = {
    # Session management
    "org/gnome/desktop/session" = {
      idle-delay = 300;  # 5 minutes before idle
    };

    # Enable session saving and restoration
    "org/gnome/SessionManager" = {
      auto-save-session = true;
    };

    # Additional window manager settings for better session handling
    "org/gnome/desktop/wm/preferences" = {
      focus-mode = "sloppy";
      auto-raise = false;
      raise-on-click = true;
    };

    # Mutter settings for window management
    "org/gnome/mutter" = {
      attach-modal-dialogs = true;
      dynamic-workspaces = true;
      workspaces-only-on-primary = false;
      focus-change-on-pointer-rest = true;
    };

    # GNOME Shell Extensions Configuration
    "org/gnome/shell" = {
      enabled-extensions = [
        "dash-to-dock@micxgx.gmail.com"
        "blur-my-shell@aunetx"
        "caffeine@patapon.info"
        "clipboard-indicator@tudmotu.com"
        "desktop-icons-ng-ding@rastersoft.com"
        "system-monitor@gnome-shell-extensions.gcampax.github.io"
        "auto-move-windows@gnome-shell-extensions.gcampax.github.io"
        "arc-menu@arcmenu.com"
        "sound-output-device-chooser@kgshank.net"
        "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.io"
        "light-style@gnome-shell-extensions.gcampax.github.io"
        "compiz-windows-effect@hermes83.github.io"
        "runcat@kolesnikov.se"
        "slinger@gfxmonk.net"
        "shyriiwook@madhead.me"
        "reading-strip@madhead.me"
        "extension-list@tu.berry"
        "user-stylesheet-font@tomaszgasior.pl"
        "lockscreen-extension@pratap.fastmail.fm"
        "primary-input-on-lockscreen@tudmotu.com"
      ];
      disable-user-extensions = false;
      development-tools = true;
    };

    # Dash to Dock Configuration
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "BOTTOM";
      dock-fixed = false;
      transparency-mode = "DYNAMIC";
      running-indicator-style = "DOTS";
      show-favorites = true;
      show-running = true;
      show-windows-preview = true;
      click-action = "cycle-windows";
      scroll-action = "cycle-windows";
      theme = "default";
      dash-max-icon-size = 32;
      background-opacity = 0.8;
      extend-height = false;
      background-color = "rgb(0, 0, 0)";
    };

    # Blur My Shell Configuration
    "org/gnome/shell/extensions/blur-my-shell" = {
      blur-dash = true;
      blur-panel = true;
      blur-overview = true;
      blur-intensity = 10;
      brightness = 0;
      sigma = 10;
      style-panel = 0;
      style-overview = 0;
    };

    # Caffeine Configuration
    "org/gnome/shell/extensions/caffeine" = {
      enable-fullscreen = true;
      restore-state = true;
      duration = 300;
      show-indicator = true;
    };

    # Clipboard Indicator Configuration
    "org/gnome/shell/extensions/clipboard-indicator" = {
      toggle-menu = ["<Super>V"];
      clear-history = ["<Super><Shift>V"];
      show-indicator = true;
      history-size = 20;
      enable-keybindings = true;
    };

    # Desktop Icons NG Configuration
    "org/gnome/shell/extensions/desktop-icons-ng" = {
      show-desktop-icons = true;
      show-trash = true;
      show-home = true;
      show-volumes = true;
      icon-size = 48;
      use-custom-font = true;
      custom-font = "Inter 10";
      desktop-layout = "columns";
      keep-arranged = true;
    };

    # System Monitor Configuration
    "org/gnome/shell/extensions/system-monitor" = {
      background = "rgba(0, 0, 0, 0.8)";
      cpu-graph-width = 0;
      memory-graph-width = 0;
      swap-graph-width = 0;
      network-graph-width = 0;
      disk-graph-width = 0;
      gpu-graph-width = 0;
      temperature-graph-width = 0;
      battery-graph-width = 0;
      show-icon = true;
      show-text = true;
      compact-display = true;
    };

    # Arc Menu Configuration
    "org/gnome/shell/extensions/arc-menu" = {
      menu-button-icon = "Distro_Icon";
      menu-layout = "Gnome";
      menu-position = "Bottom";
      menu-size = 0.85;
      menu-font-size = 12;
      menu-border-width = 1;
      menu-border-color = "rgb(255, 255, 255)";
      menu-background-color = "rgba(0, 0, 0, 0.9)";
      menu-arrow-color = "rgb(255, 255, 255)";
      menu-arrow-rtl = "Arc_Left_Arrow";
      menu-categories-rtl = "Arc_Left_Arrow";
      menu-applications-list-icon = "SIDE_VIEW";
      menu-category-icon-size = 16;
      menu-application-icon-size = 24;
      menu-favorites-icon-size = 16;
      menu-button-appearance = "Text";
      menu-button-text = "Applications";
      menu-button-font-size = 14;
      menu-button-font-weight = "Bold";
      menu-button-text-color = "rgb(255, 255, 255)";
      menu-button-hover-background-color = "rgba(255, 255, 255, 0.1)";
      menu-button-hover-text-color = "rgb(255, 255, 255)";
    };

    # Light Style Configuration
    "org/gnome/shell/extensions/light-style" = {
      panel-opacity = 0.8;
      panel-blur = true;
      panel-blur-strength = 0.5;
      panel-border = true;
      panel-border-color = "rgb(255, 255, 255)";
      panel-border-width = 1;
      panel-border-opacity = 0.3;
      panel-shadow = true;
      panel-shadow-color = "rgb(0, 0, 0)";
      panel-shadow-opacity = 0.5;
      panel-shadow-blur = 10;
      panel-shadow-offset = 2;
    };
  };

  # Enhanced GTK theme configuration
  gtk = {
    enable = true;

    # Modern GTK Theme
    theme = {
      name = "WhiteSur-dark";
      package = pkgs.whitesur-gtk-theme;
    };

    # Professional Icon Theme
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    # Cursor Theme
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    # Font Configuration
    font = {
      name = "Inter 10";
      package = pkgs.inter;
    };

    # GTK Settings
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
      gtk-menu-images = true;
      gtk-button-images = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Enhanced Qt theme configuration
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "gtk2";
  };

}

