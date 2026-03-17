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
    ./worktrunk.nix
    ./direnv.nix
    ./openpeon.nix
    ./zellij.nix
  ];

  options.riley.browser = lib.mkOption {
    type = lib.types.str;
    default = "librewolf";
    description = "Default browser command for Riley's shell environment on this host.";
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

  options.riley.targets.genericLinux.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Home Manager's generic Linux target settings.";
  };


  config = {
    home.username = "riley";
    home.homeDirectory = "/home/riley";

    home.stateVersion = "25.11";

    programs.home-manager.enable = true;
    programs.nushell.enable = true;
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
      }
    '';
    programs.librewolf = {
      enable = true;
      profiles = {
        default = {
          id = 0;
          name = "default";
          isDefault = true;
          settings = {
            "browser.startup.homepage" = "https://search.rileymathews.com";
            "browser.search.defaultenginename" = "Searx";
            "browser.search.order.1" = "Searx";
            "extensions.autoDisableScopes" = 0;
            "privacy.sanitize.sanitizeOnShutdown" = false;
            "privacy.resistFingerprinting" = false;
            "privacy.fingerprintingProtection" = true;
            "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme";
          };
          search = {
            force = true;
            default = "Searx";
            order = [ "Searx" "Google" ];
            engines = {
              "Searx" = {
                urls = [{ template = "https://search.rileymathews.com/?q={searchTerms}"; }];
                iconUpdateURL = "https://nixos.wiki/favicon.png";
                updateInterval = 24 * 60 * 60 * 1000; # every day
                  definedAliases = [ "@searx" ];
              };
              "Google".metaData.alias = "@g"; # builtin engines only support specifying one additional alias
            };
          };
          extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
            ublock-origin
            bitwarden
            darkreader
            vimium
          ];
        };
      };
    };

    age.secrets.github-token-file.file = ../../../secrets/github-token-file.age;
    age.secrets.forgejo-token-file.file = ../../../secrets/forgejo-token-file.age;

    targets.genericLinux.enable = config.riley.targets.genericLinux.enable;

    home.file = {
      ".zshrc".text = ''
        export GITHUB_TOKEN=$(cat ${config.age.secrets.github-token-file.path})
        export FORGEJO_TOKEN=$(cat ${config.age.secrets.forgejo-token-file.path})
        # forgejo access token specifically for mcp server
        export FORGEJO_ACCESS_TOKEN=$(cat ${config.age.secrets.forgejo-token-file.path})
        export BROWSER=${config.riley.browser};
        export GH_BROWSER=${config.riley.browser};
        source ~/.config/zsh/zsh-entrypoint.sh
      '';
      ".config/zsh/zsh-entrypoint.sh".source = ./zsh-entrypoint.sh;
      ".config/zsh/zsh-syntax-highligting-theme.sh".source = ./zsh-syntax-highligting-theme.sh;
      ".tmux.conf".source = ./tmux.conf;
    };
    
    home.packages = with pkgs; [
      pgcli
      # inputs.ghostty.packages."${pkgs.system}".default
    ];
  };
}
