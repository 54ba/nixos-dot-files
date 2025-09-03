{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.home-manager = {
      enable = mkEnableOption "home-manager integration";

      user = mkOption {
        type = types.str;
        default = "mahmoud";
        description = "Username for home-manager configuration";
      };

      configPath = mkOption {
        type = types.str;
        default = "./home-manager-base.nix";
        description = "Path to home-manager configuration file";
      };

      useGlobalPkgs = mkOption {
        type = types.bool;
        default = true;
        description = "Use global package set for home-manager";
      };

      useUserPackages = mkOption {
        type = types.bool;
        default = true;
        description = "Install packages to user profile";
      };

      backupFileExtension = mkOption {
        type = types.str;
        default = "backup";
        description = "Extension for backup files";
      };

      development = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable development tools in home-manager";
        };

        languages = mkOption {
          type = types.listOf (types.enum [ "python" "nodejs" "rust" "go" "java" "php" "dart" ]);
          default = [ "python" "nodejs" "dart" "php" ];
          description = "Development languages to enable";
        };
      };

      shell = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Configure shell with home-manager";
        };

        defaultShell = mkOption {
          type = types.enum [ "zsh" "bash" "fish" ];
          default = "zsh";
          description = "Default shell to configure";
        };

        starship = mkOption {
          type = types.bool;
          default = true;
          description = "Enable starship prompt";
        };

        direnv = mkOption {
          type = types.bool;
          default = true;
          description = "Enable direnv integration";
        };
      };

      desktop = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Configure desktop environment settings";
        };

        theme = mkOption {
          type = types.str;
          default = "Adwaita-dark";
          description = "GTK theme name";
        };

        iconTheme = mkOption {
          type = types.str;
          default = "Papirus-Dark";
          description = "Icon theme name";
        };
      };
    };
  };

  config = mkIf config.custom.home-manager.enable {
    # Basic home-manager configuration that would be used in flake.nix
    # This provides the structure and options for home-manager integration

    # Create a separate home-manager configuration file with modular structure
    environment.etc."nixos/home-manager-base.nix".text = ''
      { config, pkgs, lib, ... }:

      {
        home.username = "${config.custom.home-manager.user}";
        home.homeDirectory = "/home/${config.custom.home-manager.user}";
        home.stateVersion = "25.05";
        programs.home-manager.enable = true;

        # Import modular home configurations based on enabled options
        imports = [
          ${optionalString config.custom.home-manager.development.enable "./home/development.nix"}
          ${optionalString config.custom.home-manager.shell.enable "./home/shell.nix"}
          ${optionalString config.custom.home-manager.desktop.enable "./home/desktop.nix"}
        ];
      }
    '';

    # Create development configuration
    environment.etc."nixos/home/development.nix" = mkIf config.custom.home-manager.development.enable {
      text = ''
        { config, pkgs, lib, ... }:

        {
          home.packages = with pkgs; [
            # Core development tools
            git
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

            # Container tools
            docker-compose
            podman-compose

            # Nix tools
            nil
            nixpkgs-fmt
            alejandra
            nix-tree
            nix-du

            # Language-specific packages
            ${optionalString (elem "python" config.custom.home-manager.development.languages) ''
            python312
            python312Packages.pip
            python312Packages.virtualenv
            poetry
            ''}
            ${optionalString (elem "nodejs" config.custom.home-manager.development.languages) ''
            nodejs
            nodePackages.npm
            nodePackages.yarn
            nodePackages.pnpm
            nodePackages.typescript
            nodePackages.ts-node
            nodePackages.eslint
            nodePackages.prettier
            ''}
            ${optionalString (elem "dart" config.custom.home-manager.development.languages) ''
            flutter
            ''}
            ${optionalString (elem "php" config.custom.home-manager.development.languages) ''
            php82
            ''}
            ${optionalString (elem "rust" config.custom.home-manager.development.languages) ''
            rustc
            cargo
            ''}
            ${optionalString (elem "go" config.custom.home-manager.development.languages) ''
            go
            ''}
          ];

          programs.git = {
            enable = true;
            userName = lib.mkDefault "54ba";
            userEmail = lib.mkDefault "54bao.o@gmail.com";

            extraConfig = {
              init.defaultBranch = "main";
              pull.rebase = true;
              push.autoSetupRemote = true;
              core.editor = "nvim";
            };
          };
        }
      '';
    };

    # Create shell configuration
    environment.etc."nixos/home/shell.nix" = mkIf config.custom.home-manager.shell.enable {
      text = ''
        { config, pkgs, lib, ... }:

        {
          programs.${config.custom.home-manager.shell.defaultShell} = {
            enable = true;
            ${optionalString (config.custom.home-manager.shell.defaultShell == "zsh") ''
            enableCompletion = true;
            autosuggestion.enable = true;
            syntaxHighlighting.enable = true;
            ''}

            shellAliases = {
              ll = "eza -la";
              ls = "eza";
              cat = "bat";
              find = "fd";
              grep = "rg";

              # NixOS shortcuts
              nrs = "sudo nixos-rebuild switch";
              nrt = "sudo nixos-rebuild test";
              nrb = "sudo nixos-rebuild boot";
              nrc = "sudo nixos-rebuild switch --flake .";
              nrg = "sudo nix-collect-garbage -d";

              # Package management
              nps = "nix search nixpkgs";
              npi = "nix profile install";
              npr = "nix profile remove";
              npl = "nix profile list";
            };
          };

          ${optionalString config.custom.home-manager.shell.starship ''
          programs.starship = {
            enable = true;
            settings = {
              add_newline = true;
              character = {
                success_symbol = "[➜](bold green)";
                error_symbol = "[✗](bold red)";
              };
            };
          };
          ''}

          ${optionalString config.custom.home-manager.shell.direnv ''
          programs.direnv = {
            enable = true;
            enableZshIntegration = true;
            nix-direnv.enable = true;
          };
          ''}
        }
      '';
    };

    # Create desktop configuration
    environment.etc."nixos/home/desktop.nix" = mkIf config.custom.home-manager.desktop.enable {
      text = ''
        { config, pkgs, lib, ... }:

        {
          gtk = {
            enable = true;
            theme = {
              name = "${config.custom.home-manager.desktop.theme}";
              package = pkgs.gnome-themes-extra;
            };
            iconTheme = {
              name = "${config.custom.home-manager.desktop.iconTheme}";
              package = pkgs.papirus-icon-theme;
            };
          };

          qt = {
            enable = true;
            platformTheme.name = "adwaita";
            style.name = "adwaita-dark";
          };

          xdg = {
            enable = true;
            userDirs = {
              enable = true;
              createDirectories = true;
            };

            mimeApps = {
              enable = true;
              defaultApplications = {
                "text/html" = "firefox.desktop";
                "x-scheme-handler/http" = "firefox.desktop";
                "x-scheme-handler/https" = "firefox.desktop";
                "application/pdf" = "evince.desktop";
                "inode/directory" = "nautilus.desktop";
              };
            };
          };

          # Session variables for Wayland
          home.sessionVariables = {
            EDITOR = "nvim";
            BROWSER = "firefox";
            TERMINAL = "gnome-terminal";

            # Wayland optimizations
            WAYLAND_DISPLAY = "wayland-0";
            XDG_SESSION_TYPE = "wayland";
            NIXOS_OZONE_WL = "1";
            MOZ_ENABLE_WAYLAND = "1";
            QT_QPA_PLATFORM = "wayland;xcb";
            GDK_BACKEND = "wayland,x11";
          };
        }
      '';
    };

    # System packages needed for home-manager integration
    environment.systemPackages = with pkgs; [
      home-manager

            # Helper scripts for home-manager management
      (writeScriptBin "hm-rebuild" ''
        #!/bin/bash
        echo "Rebuilding home-manager configuration..."
        home-manager switch -f /etc/nixos/home-manager-base.nix
      '')

      (writeScriptBin "hm-edit" ''
        #!/bin/bash
        $EDITOR /etc/nixos/home-manager-base.nix
      '')
    ];
  };
}
