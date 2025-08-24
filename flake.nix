{
  description = "NixOS configuration with home-manager";

  inputs = {
    # Use latest stable channel for better binary cache coverage
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    # Fallback to unstable for packages not in stable
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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
          # home-manager.nixosModules.home-manager
          # {
          #   home-manager.useGlobalPkgs = true;
          #   home-manager.useUserPackages = true;
          #   home-manager.backupFileExtension = "backup";
          #   home-manager.users.mahmoud = import ./home-manager.nix;
          # }
        ];
      };
    };
}

