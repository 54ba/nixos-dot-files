{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.nixgl = {
      enable = mkEnableOption "nixGL graphics compatibility layer";
      
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
      
      applications = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable pre-configured application aliases";
        };
        
        wrappers = mkOption {
          type = types.listOf types.str;
          default = [ "firefox" "chrome" "code" "blender" "steam" ];
          description = "Applications to create nixGL wrappers for";
        };
      };
      
      help = mkOption {
        type = types.bool;
        default = true;
        description = "Install nixGL usage guide";
      };
    };
  };

  config = mkIf config.custom.nixgl.enable {
    # Environment variables for graphics applications
    environment.sessionVariables = {
      LIBGL_ALWAYS_INDIRECT = "0";
      MESA_GL_VERSION_OVERRIDE = "4.5";
      MESA_GLSL_VERSION_OVERRIDE = "450";
    } // optionalAttrs config.custom.nixgl.enableVulkan {
      VK_LOADER_DEBUG = "all";
      VK_INSTANCE_LAYERS = "";
    };

    # Shell aliases for easy nixGL usage
    environment.shellAliases = {
      "nixgl" = "nixGL";
      "nixgl-mesa" = "nixGLMesa";
      "nixvulkan" = "nixVulkanMesa";
    } // optionalAttrs config.custom.nixgl.applications.enable (
      listToAttrs (map (app: {
        name = "${app}-gl";
        value = "nixGL ${app}";
      }) config.custom.nixgl.applications.wrappers)
    ) // {
      # Additional specific aliases
      "warp-gl" = "nixGL warp-terminal";
      "code-cursor-gl" = "nixGL code-cursor";
      "discord-gl" = "nixGL discord";
      "slack-gl" = "nixGL slack";
      "zoom-gl" = "nixGL zoom-us";
    };

    # nixGL usage guide
    environment.etc."nixgl-help.txt" = mkIf config.custom.nixgl.help {
      text = ''
        NixGL Usage Guide
        ================

        NixGL provides graphics compatibility for applications that need OpenGL/Vulkan.

        Installation:
        ------------
        nix-env -iA nixgl.nixGLIntel -f https://github.com/guibou/nixGL/archive/main.tar.gz
        # Or for NVIDIA:
        nix-env -iA nixgl.nixGLNvidia -f https://github.com/guibou/nixGL/archive/main.tar.gz

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
        ${concatStringsSep ", " (map (app: "${app}-gl") config.custom.nixgl.applications.wrappers)}
        warp-gl, code-cursor-gl, discord-gl, slack-gl, zoom-gl

        Troubleshooting:
        ---------------
        If graphics applications don't work:
        1. Try different nixGL variants (mesa, nvidia)
        2. Check graphics drivers: lspci -k | grep -A 2 -i VGA
        3. Verify OpenGL with: glxinfo | grep OpenGL
        4. For Vulkan: vulkaninfo
        5. Check current wrapper: echo $NIXGL_WRAPPER

        System Information:
        ------------------
        Current configuration:
        - Default wrapper: ${config.custom.nixgl.defaultWrapper}
        - Vulkan enabled: ${if config.custom.nixgl.enableVulkan then "Yes" else "No"}
        - Application wrappers: ${if config.custom.nixgl.applications.enable then "Enabled" else "Disabled"}
      '';
    };

    # System packages for nixGL support
    environment.systemPackages = (
      # Base packages
      (with pkgs; [
        glxinfo
        vulkan-tools
        mesa-demos
      ])
      # Wrapper script and desktop entries if applications are enabled
      ++ optionals config.custom.nixgl.applications.enable [
        (pkgs.writeScriptBin "nixgl-wrapper" ''
          #!/bin/bash
          
          NIXGL_WRAPPER="''${NIXGL_WRAPPER:-${config.custom.nixgl.defaultWrapper}}"
          
          case "$NIXGL_WRAPPER" in
            "intel")
              exec nixGLIntel "$@"
              ;;
            "nvidia")
              exec nixGLNvidia "$@"
              ;;
            "mesa")
              exec nixGLMesa "$@"
              ;;
            *)
              echo "Unknown nixGL wrapper: $NIXGL_WRAPPER"
              echo "Available options: intel, nvidia, mesa"
              exit 1
              ;;
          esac
        '')
      ]
      # Desktop entries for wrapped applications
      ++ optionals config.custom.nixgl.applications.enable (
        map (app: pkgs.makeDesktopItem {
          name = "${app}-nixgl";
          desktopName = "${app} (nixGL)";
          exec = "nixgl-wrapper ${app}";
          icon = app;
          comment = "${app} with nixGL graphics compatibility";
          categories = [ "Graphics" "Application" ];
        }) config.custom.nixgl.applications.wrappers
      )
    );
  };
}
