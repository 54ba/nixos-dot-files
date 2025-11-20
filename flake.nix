{
  description = "NixOS configuration with home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    /*nix-snapd = {
      url = "github:nix-community/nix-snapd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };*/
  };

  #outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nix-snapd, ... }:
    outputs = { self, nixpkgs, nixpkgs-unstable,home-manager, ... }:
    let
      system = "x86_64-linux";
      overlay-unstable = final: prev: {
        unstable = nixpkgs-unstable.legacyPackages.${system};
      };
      #cursor-overlay = import ./overlays/cursor-overlay.nix;
      pkgs = import nixpkgs {
        inherit system;
        #overlays = [ overlay-unstable cursor-overlay ];
        config = {
          allowUnfree = true;
          # Force use of binary caches and avoid building from source
          allowBroken = false;
          allowUnsupportedSystem = false;
        };
      };
    in {
      nixosConfigurations.mahmoud-laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          #nix-snapd.nixosModules.default
          ./configuration.nix
          {
            # Configure nixpkgs overlays and config properly
            #nixpkgs.overlays = [ overlay-unstable cursor-overlay ];
            nixpkgs.config = {
              allowUnfree = true;
              allowBroken = false;
              allowUnsupportedSystem = false;
            };
          }
        ];
      };

      # Development shells
      /*devShells.${system} = {
        automation = import ./shells/automation-shell.nix { inherit pkgs; };
        python = import ./shells/python-shell.nix { inherit pkgs; };
        typescript = import ./shells/typescript-shell.nix { inherit pkgs; };
        php = import ./shells/php-shell.nix { inherit pkgs; };
        flutter = import ./shells/flutter-shell.nix { inherit pkgs; };
        full-dev = import ./shells/full-dev-shell.nix { inherit pkgs; };
      };*/

      # Standalone home-manager configuration
      homeConfigurations.mahmoud = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home-manager.nix
          {
            # Ensure the home directory and username are set correctly
            home.username = "mahmoud";
            home.homeDirectory = "/home/mahmoud";
            home.stateVersion = "25.05";
            
            # Allow unfree packages for home-manager
            nixpkgs.config.allowUnfree = true;
            
            # Enable home-manager to manage itself
            programs.home-manager.enable = true;
          }
        ];
      };
    };
}
