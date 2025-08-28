{
  description = "NixOS configuration with home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      system = "x86_64-linux";
      overlay-unstable = final: prev: {
        unstable = nixpkgs-unstable.legacyPackages.${system};
      };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overlay-unstable ];
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
        specialArgs = { inherit pkgs; };
        modules = [
          ./configuration.nix
          # Disable home-manager NixOS module since we're using standalone
          # home-manager.nixosModules.home-manager
          # {
          #   home-manager.useGlobalPkgs = true;
          #   home-manager.useUserPackages = true;
          #   home-manager.backupFileExtension = "backup";
          #   home-manager.users.mahmoud = import ./home-manager.nix;
          # }
        ];
      };

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
