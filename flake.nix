{
  description = "NixOS configuration with home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
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
              programs.zsh = {
                enable = true;
                oh-my-zsh = {
                  enable = true;
                  theme = "robbyrussell";
                  plugins = [ "git" "docker" "python" ];
                };
                initContent = "eval \"$(starship init zsh)\"";
              };
              
              programs.starship = {
                enable = true;
                enableZshIntegration = true;
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
            };
          }
        ];
      };
    };
}
