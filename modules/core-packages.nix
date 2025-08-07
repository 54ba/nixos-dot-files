{ config, pkgs, lib, nixgl, ... }:

with lib;

{
  options = {
    custom.packages = {
      core.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable core system packages that should always be available";
      };
      minimal.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable minimal essential packages for basic system function";
      };
    };
  };

  config = mkMerge [
    # Minimal packages configuration
    (mkIf config.custom.packages.minimal.enable {
      environment.systemPackages = import ../packages/minimal-packages.nix { inherit pkgs; };
    })
    
    # Core packages configuration
    (mkIf config.custom.packages.core.enable {
      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;
      
      # Add nixGL overlay (temporarily disabled for testing)
      # nixpkgs.overlays = [
      #   nixgl.overlay
      #   (import ../overlays/nixgl-wrapper.nix)
      # ];
      
      # Core system packages that should always be available
      environment.systemPackages = (import ../packages/core-packages.nix { inherit pkgs; }) ++ 
      (lib.optionals (pkgs ? nixgl) [
        pkgs.nixgl.nixGLIntel
        pkgs.nixgl.nixGLDefault
      ]) ++
      (lib.optionals (pkgs ? nixgl && pkgs.nixgl ? nixGLNvidia) [
        pkgs.nixgl.nixGLNvidia
      ]);
      
      # Environment variables for nixGL (conditional)
      environment.sessionVariables = lib.mkIf (pkgs ? nixgl) ({
        NIXGL_INTEL = "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel";
      } // lib.optionalAttrs (pkgs.nixgl ? nixGLNvidia) {
        NIXGL_NVIDIA = "${pkgs.nixgl.nixGLNvidia}/bin/nixGLNvidia";
      });
      
      # Shell aliases for easier nixGL usage (conditional)
      environment.shellAliases = lib.mkIf (pkgs ? nixgl) ({
        "nixgl-intel" = "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel";
        "blender-gl" = "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.blender}/bin/blender";
        "gimp-gl" = "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.gimp}/bin/gimp";
        "obs-gl" = "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.obs-studio}/bin/obs";
      } // lib.optionalAttrs (pkgs.nixgl ? nixGLNvidia) {
        "nixgl-nvidia" = "${pkgs.nixgl.nixGLNvidia}/bin/nixGLNvidia";
      });
    })
  ];
}

