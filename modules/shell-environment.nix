{ config, pkgs, lib, ... }:

with lib;

{
  options = {
    custom.shellEnvironment = {
      enable = mkEnableOption "enhanced shell environment";

      features = {
        starship = mkEnableOption "modern shell prompt with starship";
        direnv = mkEnableOption "directory-based environment variables";
        fzf = mkEnableOption "fuzzy finder";
        bat = mkEnableOption "better cat";
        exa = mkEnableOption "better ls";
        fd = mkEnableOption "better find";
        ripgrep = mkEnableOption "better grep";
        jq = mkEnableOption "JSON processor";
        htop = mkEnableOption "better top";
        tmux = mkEnableOption "terminal multiplexer";
        zoxide = mkEnableOption "smart directory navigation";
      };

      aliases = {
        enable = mkEnableOption "useful shell aliases";
        ls = mkOption {
          type = types.str;
          default = "exa --icons --group-directories-first";
          description = "ls alias";
        };
        ll = mkOption {
          type = types.str;
          default = "exa --icons --group-directories-first -la";
          description = "ll alias";
        };
        cat = mkOption {
          type = types.str;
          default = "bat";
          description = "cat alias";
        };
        grep = mkOption {
          type = types.str;
          default = "rg";
          description = "grep alias";
        };
        find = mkOption {
          type = types.str;
          default = "fd";
          description = "find alias";
        };
      };
    };
  };

  config = mkIf config.custom.shellEnvironment.enable {
    # Install shell environment packages
    environment.systemPackages = with pkgs; mkIf config.custom.shellEnvironment.enable [
      # Modern shell tools
      (mkIf config.custom.shellEnvironment.features.starship starship)
      (mkIf config.custom.shellEnvironment.features.direnv direnv)
      (mkIf config.custom.shellEnvironment.features.fzf fzf)
      (mkIf config.custom.shellEnvironment.features.bat bat)
      (mkIf config.custom.shellEnvironment.features.exa eza)
      (mkIf config.custom.shellEnvironment.features.fd fd)
      (mkIf config.custom.shellEnvironment.features.ripgrep ripgrep)
      (mkIf config.custom.shellEnvironment.features.jq jq)
      (mkIf config.custom.shellEnvironment.features.htop htop)
      (mkIf config.custom.shellEnvironment.features.tmux tmux)
      (mkIf config.custom.shellEnvironment.features.zoxide zoxide)
    ];

    # Configure shell aliases
    environment.shellAliases = mkIf (config.custom.shellEnvironment.enable && config.custom.shellEnvironment.aliases.enable) {
      ls = config.custom.shellEnvironment.aliases.ls;
      ll = config.custom.shellEnvironment.aliases.ll;
      cat = config.custom.shellEnvironment.aliases.cat;
      grep = config.custom.shellEnvironment.aliases.grep;
      find = config.custom.shellEnvironment.aliases.find;
    };

    # Set default shell to zsh
    users.defaultUserShell = mkIf config.custom.shellEnvironment.enable pkgs.zsh;

    # Configure zsh as default shell
    programs.zsh = mkIf config.custom.shellEnvironment.enable {
      enable = true;
      enableCompletion = true;
      enableBashCompletion = true;
      syntaxHighlighting.enable = true;
      autosuggestions.enable = true;
      shellInit = ''
        # Initialize starship prompt if enabled
        ${if config.custom.shellEnvironment.features.starship then "eval \"$(starship init zsh)\"" else ""}

        # Initialize direnv if enabled
        ${if config.custom.shellEnvironment.features.direnv then "eval \"$(direnv hook zsh)\"" else ""}

        # FZF configuration if enabled
        ${if config.custom.shellEnvironment.features.fzf then ''
          source ${pkgs.fzf}/share/fzf/completion.zsh
          source ${pkgs.fzf}/share/fzf/key-bindings.zsh
        '' else ""}

        # Initialize zoxide if enabled
        ${if config.custom.shellEnvironment.features.zoxide then "eval \"$(zoxide init zsh)\"" else ""}
      '';
    };
  };
}
