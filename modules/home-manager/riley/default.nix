{ pkgs, config, lib, inputs, ... }:
{
  imports = [
    ./alacritty.nix
    ./stylix.nix
    ./dunst.nix
    ./hypr.nix
    ./opencode.nix
    ./rofi.nix
    ./waybar.nix
    ./wlr-which-key.nix
    ./scripts.nix
    ./ghostty.nix
    ./git.nix
    ./librewolf.nix
    ./worktrunk.nix
    ./direnv.nix
    ./openpeon.nix
    ./zellij.nix
    ./fish.nix
    ./television.nix
    ./nvim.nix
    ./starship
  ];

  options.riley.browser = lib.mkOption {
    type = lib.types.str;
    default = "librewolf";
    description = "Default browser command for Riley's shell environment on this host.";
  };

  options.riley.altBrowser = lib.mkOption {
    type = lib.types.str;
    default = lib.mkUndefined;
    description = "Alternative browser command for Riley's desktop environment; must be set per host.";
  };

  options.riley.opencode.profile = lib.mkOption {
    type = lib.types.enum [
      "personal"
      "work"
    ];
    default = "personal";
    description = "OpenCode model profile for Riley's agents on this host.";
  };

  options.riley.opencode.superpowers.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Superpowers plugin and skill pack for OpenCode.";
  };

  config = {
    home.username = "riley";
    home.homeDirectory = "/home/riley";

    home.stateVersion = "25.11";
    home.enableNixpkgsReleaseCheck = false;

    programs.home-manager.enable = true;
    programs.nushell.enable = false;
    programs.nushell.configFile.source = ./config.nu;
    programs.nushell.extraConfig = ''
      let github_token = (open $"($env.XDG_RUNTIME_DIR)/agenix/github-token-file" | str trim)
      let forgejo_token = (open $"($env.XDG_RUNTIME_DIR)/agenix/forgejo-token-file" | str trim)

      load-env {
        GITHUB_TOKEN: $github_token
        FORGEJO_TOKEN: $forgejo_token
        FORGEJO_ACCESS_TOKEN: $forgejo_token
        BROWSER: "${config.riley.browser}"
        GH_BROWSER: "${config.riley.browser}"
        ALT_BROWSER: "${config.riley.altBrowser}"
      }
    '';
    age.secrets.github-token-file.file = ../../../secrets/github-token-file.age;
    age.secrets.forgejo-token-file.file = ../../../secrets/forgejo-token-file.age;
    age.secrets.openai-personal-api-token-file.file = ../../../secrets/openai-personal-api-token-file.age;

    home.file = {
      ".zshrc".text = ''
        export GITHUB_TOKEN=$(cat ${config.age.secrets.github-token-file.path})
        export FORGEJO_TOKEN=$(cat ${config.age.secrets.forgejo-token-file.path})
        # forgejo access token specifically for mcp server
        export FORGEJO_ACCESS_TOKEN=$(cat ${config.age.secrets.forgejo-token-file.path})
        export PERSONAL_OPENAI_TOKEN=$(cat ${config.age.secrets.openai-personal-api-token-file.path})
        export BROWSER=${config.riley.browser};
        export GH_BROWSER=${config.riley.browser};
        export ALT_BROWSER=${config.riley.altBrowser};
        export GH_ALT_BROWSER=${config.riley.altBrowser};
        source ~/.config/zsh/zsh-entrypoint.sh
      '';
      ".config/zsh/zsh-entrypoint.sh".source = ./zsh-entrypoint.sh;
      ".config/zsh/zsh-syntax-highligting-theme.sh".source = ./zsh-syntax-highligting-theme.sh;
      ".tmux.conf".source = ./tmux.conf;
    };
    
    # home.packages = with pkgs; [
    #   pgcli
    #   typescript-go
    #   zoxide
    #   fzf
    #   # inputs.ghostty.packages."${pkgs.system}".default
    # ];
  };
}
