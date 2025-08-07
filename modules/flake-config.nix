{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.flake = {
      enable = mkEnableOption "flake configuration management";
      
      inputs = {
        nixpkgs = mkOption {
          type = types.str;
          default = "github:nixos/nixpkgs/nixos-25.05";
          description = "NixOS stable channel";
        };
        
        nixpkgsUnstable = mkOption {
          type = types.str;
          default = "github:nixos/nixpkgs/nixos-unstable";
          description = "NixOS unstable channel";
        };
        
        homeManager = mkOption {
          type = types.str;
          default = "github:nix-community/home-manager/release-25.05";
          description = "Home Manager channel";
        };
      };
      
      system = mkOption {
        type = types.str;
        default = "x86_64-linux";
        description = "System architecture";
      };
      
      hostname = mkOption {
        type = types.str;
        default = "mahmoud-laptop";
        description = "System hostname for flake configuration";
      };
      
      homeManager = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable home-manager integration in flake";
        };
        
        useGlobalPkgs = mkOption {
          type = types.bool;
          default = true;
          description = "Use global packages in home-manager";
        };
        
        useUserPackages = mkOption {
          type = types.bool;
          default = true;
          description = "Use user packages in home-manager";
        };
        
        backupFileExtension = mkOption {
          type = types.str;
          default = "backup";
          description = "Backup file extension for home-manager";
        };
      };
      
      overlays = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable custom overlays";
        };
        
        unstable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable unstable packages overlay";
        };
      };
    };
  };

  config = mkIf config.custom.flake.enable {
    # Generate flake.nix content
    environment.etc."nixos/flake-template.nix".text = ''
      {
        description = "Modular NixOS configuration with home-manager";

        inputs = {
          nixpkgs.url = "${config.custom.flake.inputs.nixpkgs}";
          ${optionalString (config.custom.flake.overlays.unstable) ''
          nixpkgs-unstable.url = "${config.custom.flake.inputs.nixpkgsUnstable}";
          ''}
          ${optionalString config.custom.flake.homeManager.enable ''
          home-manager = {
            url = "${config.custom.flake.inputs.homeManager}";
            inputs.nixpkgs.follows = "nixpkgs";
          };
          ''}
        };

        outputs = { self, nixpkgs${optionalString (config.custom.flake.overlays.unstable) ", nixpkgs-unstable"}${optionalString config.custom.flake.homeManager.enable ", home-manager"}, ... }:
          let
            system = "${config.custom.flake.system}";
            ${optionalString config.custom.flake.overlays.enable ''
            # Create overlay for unstable packages
            ${optionalString config.custom.flake.overlays.unstable ''
            overlay-unstable = final: prev: {
              unstable = nixpkgs-unstable.legacyPackages.''${system};
            };
            ''}
            ''}
            
            pkgs = import nixpkgs {
              inherit system;
              ${optionalString config.custom.flake.overlays.enable ''
              overlays = [${optionalString config.custom.flake.overlays.unstable " overlay-unstable"}];
              ''}
              config.allowUnfree = true;
            };
          in {
            nixosConfigurations.${config.custom.flake.hostname} = nixpkgs.lib.nixosSystem {
              inherit system;
              modules = [
                ./configuration.nix
                ${optionalString config.custom.flake.homeManager.enable ''
                home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = ${boolToString config.custom.flake.homeManager.useGlobalPkgs};
                  home-manager.useUserPackages = ${boolToString config.custom.flake.homeManager.useUserPackages};
                  home-manager.backupFileExtension = "${config.custom.flake.homeManager.backupFileExtension}";
                  home-manager.users.${config.custom.users.mainUser.name} = import ./home-manager.nix;
                }
                ''}
              ];
            };

            # Development shells
            devShells.''${system} = {
              default = pkgs.mkShell {
                buildInputs = with pkgs; [
                  nixos-rebuild
                  home-manager
                  git
                ];
                shellHook = '''
                  echo "NixOS Development Environment"
                  echo "Available commands:"
                  echo "  nixos-rebuild switch --flake .#${config.custom.flake.hostname}"
                  echo "  home-manager switch --flake .#${config.custom.users.mainUser.name}"
                ''';
              };
              
              minimal = pkgs.mkShell {
                buildInputs = with pkgs; [
                  git
                  nixos-rebuild
                ];
              };
            };

            # Package outputs for easy installation
            packages.''${system} = {
              # System configuration
              nixos = self.nixosConfigurations.${config.custom.flake.hostname}.config.system.build.toplevel;
              
              # Individual package collections
              minimal-packages = pkgs.buildEnv {
                name = "minimal-packages";
                paths = import ./packages/minimal-packages.nix { inherit pkgs; };
              };
              
              essential-packages = pkgs.buildEnv {
                name = "essential-packages";
                paths = import ./packages/essential-packages.nix { inherit pkgs; };
              };
            };
          };
      }
    '';

    # Create flake management scripts
    environment.systemPackages = [
      (pkgs.writeScriptBin "flake-init" ''
        #!/bin/bash
        set -e
        
        cd /etc/nixos
        
        echo "Initializing flake configuration..."
        
        # Copy template to actual flake.nix
        if [ ! -f flake.nix ]; then
          cp flake-template.nix flake.nix
          echo "Created flake.nix from template"
        else
          echo "flake.nix already exists, use flake-update to refresh"
        fi
        
        # Initialize git if not already done
        if [ ! -d .git ]; then
          git init
          git add .
          git commit -m "Initial NixOS configuration"
          echo "Initialized git repository"
        fi
        
        echo "Flake initialization complete!"
        echo "You can now use: nixos-rebuild switch --flake .#${config.custom.flake.hostname}"
      '')

      (pkgs.writeScriptBin "flake-update" ''
        #!/bin/bash
        set -e
        
        cd /etc/nixos
        
        echo "Updating flake configuration..."
        
        # Backup existing flake.nix
        if [ -f flake.nix ]; then
          cp flake.nix flake.nix.backup
          echo "Backed up existing flake.nix"
        fi
        
        # Update from template
        cp flake-template.nix flake.nix
        echo "Updated flake.nix from template"
        
        # Update flake inputs
        nix flake update
        echo "Updated flake inputs"
        
        echo "Flake update complete!"
      '')

      (pkgs.writeScriptBin "flake-rebuild" ''
        #!/bin/bash
        set -e
        
        cd /etc/nixos
        
        echo "Rebuilding system with flake..."
        
        # Check if flake.nix exists
        if [ ! -f flake.nix ]; then
          echo "No flake.nix found. Run flake-init first."
          exit 1
        fi
        
        # Rebuild system
        sudo nixos-rebuild switch --flake .#${config.custom.flake.hostname} "$@"
        
        echo "System rebuild complete!"
      '')

      (pkgs.writeScriptBin "flake-info" ''
        #!/bin/bash
        
        cd /etc/nixos
        
        echo "Flake Configuration Information"
        echo "==============================="
        echo "System: ${config.custom.flake.system}"
        echo "Hostname: ${config.custom.flake.hostname}"
        echo "NixPkgs: ${config.custom.flake.inputs.nixpkgs}"
        echo "Home Manager: ${if config.custom.flake.homeManager.enable then "Enabled" else "Disabled"}"
        echo "Unstable Overlay: ${if config.custom.flake.overlays.unstable then "Enabled" else "Disabled"}"
        echo ""
        
        if [ -f flake.nix ]; then
          echo "Available configurations:"
          nix flake show 2>/dev/null || echo "Run 'nix flake show' for detailed information"
        else
          echo "No flake.nix found. Run 'flake-init' to create one."
        fi
      '')
    ];

    # Create a flake.lock template (this would be generated by nix flake update)
    environment.etc."nixos/flake-lock-template.json".text = builtins.toJSON {
      nodes = {
        nixpkgs = {
          locked = {
            lastModified = 1640000000;
            narHash = "sha256-placeholder";
            owner = "NixOS";
            repo = "nixpkgs";
            rev = "placeholder";
            type = "github";
          };
          original = {
            owner = "nixos";
            ref = "nixos-25.05";
            repo = "nixpkgs";
            type = "github";
          };
        };
        root = {
          inputs = [ "nixpkgs" ] ++ optional config.custom.flake.homeManager.enable "home-manager";
        };
      } // optionalAttrs config.custom.flake.homeManager.enable {
        home-manager = {
          inputs = [ "nixpkgs" ];
          locked = {
            lastModified = 1640000000;
            narHash = "sha256-placeholder";
            owner = "nix-community";
            repo = "home-manager";
            rev = "placeholder";
            type = "github";
          };
          original = {
            owner = "nix-community";
            ref = "release-25.05";
            repo = "home-manager";
            type = "github";
          };
        };
      };
      root = "root";
      version = 7;
    };
  };
}
