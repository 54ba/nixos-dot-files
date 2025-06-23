{
  description = "NixOS configuration with home-manager";

  inputs = {
    # Use stable channel for better binary cache coverage
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    # Fallback to unstable for packages not in stable
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      system = "x86_64-linux";
      # Create overlay to selectively use unstable packages when needed
      overlay-unstable = final: prev: {
        unstable = nixpkgs-unstable.legacyPackages.${system};
      };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overlay-unstable ];
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.mahmoud-laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.mahmoud = { pkgs, ... }: {
              home.stateVersion = "25.05";
              programs.home-manager.enable = true;
              
              home.packages = with pkgs; [
                oh-my-zsh
                zsh-autosuggestions
                zsh-syntax-highlighting
              ];
              
              programs.zsh = {
                enable = true;
                oh-my-zsh = {
                  enable = true;
                  theme = "robbyrussell";
                  plugins = [ "git" "docker" "python" "sudo" "history" ];
                };
                autosuggestion = {
                  enable = true;
                };
                syntaxHighlighting = {
                  enable = true;
                };
                autocd = true;
                dotDir = ".config/zsh";
                
                initContent = ''
                  # Source Oh My Zsh if it exists
                  export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh"
                  if [ -f $ZSH/oh-my-zsh.sh ]; then
                    source $ZSH/oh-my-zsh.sh
                  fi
                  
                  # Additional zsh configuration
                  bindkey -e  # Emacs key bindings
                  setopt AUTO_PUSHD       # Push the current directory visited on the stack
                  setopt PUSHD_IGNORE_DUPS # Do not store duplicates in the stack
                  setopt PUSHD_SILENT     # Do not print the directory stack after pushd or popd
                  
                  # Initialize starship prompt
                  eval "$(starship init zsh)"
                '';
              };
              
              programs.starship = {
                enable = true;
                enableZshIntegration = true;
                package = pkgs.starship;
                settings = {
                  add_newline = true;
                  character = {
                    success_symbol = "[➜](bold green)";
                    error_symbol = "[✗](bold red)";
                  };
                  git_branch = {
                    format = "[$symbol$branch]($style) ";
                  };
                };
              };
              
              # Configure Git for the user
              programs.git = {
                enable = true;
                userName = "mahmoud";
                userEmail = "mahmoud@example.com"; # Replace with your actual email
                extraConfig = {
                  credential.helper = "libsecret";
                  pull.rebase = false;
                  init.defaultBranch = "main";
                };
              };
              
              # Set XDG defaults via home-manager
              xdg = {
                enable = true;
                mimeApps = {
                  enable = true;
                  defaultApplications = {
                    "inode/directory" = "org.gnome.Nautilus.desktop";
                    "x-scheme-handler/http" = "firefox.desktop";
                    "x-scheme-handler/https" = "firefox.desktop";
                    "x-scheme-handler/chrome" = "firefox.desktop";
                    "text/html" = "firefox.desktop";
                  };
                };
              };
            };
          }
        ];
      };
    };
}
