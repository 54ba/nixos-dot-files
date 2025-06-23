# NixGL Module for NixOS - Graphics compatibility layer
# This module provides nixGL for running graphics applications that need OpenGL/Vulkan

{ config, lib, pkgs, ... }:

with lib;

{
  options.nixGL = {
    enable = mkEnableOption "Enable nixGL for graphics compatibility";
    
    defaultWrapper = mkOption {
      type = types.enum [ "intel" "nvidia" "mesa" ];
      default = "intel";
      description = "Default graphics wrapper to use";
    };
    
    enableVulkan = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Vulkan support through nixGL";
    };
  };

  config = mkIf config.nixGL.enable {
    # Add nixGL packages to system
    # Note: nixGL packages are not available in standard nixpkgs
    # Users should install them manually or use nixGL overlay
    environment.systemPackages = with pkgs; [
      # nixgl packages would go here when available
      # For now, we provide the configuration structure
    ];
    
    # Alternative: Install nixGL through nix-env or other means
    # nix-env -iA nixgl.nixGLIntel -f https://github.com/guibou/nixGL/archive/main.tar.gz

    # Environment variables for graphics applications
    environment.sessionVariables = {
      LIBGL_ALWAYS_INDIRECT = "0";
      MESA_GL_VERSION_OVERRIDE = "4.5";
      MESA_GLSL_VERSION_OVERRIDE = "450";
    };

    # Shell aliases for easy nixGL usage
    environment.shellAliases = {
      "nixgl" = "nixGL";
      "nixgl-mesa" = "nixGLMesa";
      "nixvulkan" = "nixVulkanMesa";
      
      # Convenient aliases for common applications
      "firefox-gl" = "nixGL firefox";
      "chrome-gl" = "nixGL google-chrome-stable";
      "code-gl" = "nixGL code";
      "code-cursor-gl" = "nixGL code-cursor";
      "warp-gl" = "nixGL warp-terminal";
    };

    environment.etc."nixgl-help".text = ''
      NixGL Usage Guide
      ================

      NixGL provides graphics compatibility for applications that need OpenGL/Vulkan.

      Basic Usage:
      ------------
      nixgl <application>
      nixgl-mesa <application>
      nixvulkan <application>

      Examples:
      ---------
      nixgl firefox
      nixgl steam
      nixvulkan blender
      nixgl code-cursor
      nixgl warp-terminal

      Pre-configured Aliases:
      ----------------------
      firefox-gl, chrome-gl, code-gl, code-cursor-gl, warp-gl

      Troubleshooting:
      ---------------
      If graphics applications don't work:
      1. Try different nixGL variants (mesa, nvidia)
      2. Check graphics drivers
      3. Verify OpenGL with: glxinfo | grep OpenGL
      4. For Vulkan: vulkaninfo
    '';
  };
}
