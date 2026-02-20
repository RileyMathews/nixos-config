{ config, lib, ... }:
let
  cfg = config.opencode;
  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    default_agent = "build";
    lsp = {
      haskell-language-server = {
        command = [ ];
        extensions = [ ".hs" ];
      };
    };
  } // lib.optionalAttrs cfg.enableOhMyOpencodePlugin {
    plugin = [ "oh-my-opencode@latest" ];
  };
in
{
  options.opencode = {
    enableOhMyOpencodePlugin = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install the oh-my-opencode plugin config file.";
    };
  };

  config.home.file = {
    ".config/opencode/opencode.json".text = builtins.toJSON opencodeConfig + "\n";
    ".config/opencode/agent".source = ./opencode/agent;
    ".config/opencode/skills".source = ./opencode/skills;
    ".config/opencode/tools" = {
      source = ./opencode/tools;
      recursive = true;
    };
  } // lib.optionalAttrs cfg.enableOhMyOpencodePlugin {
    ".config/opencode/oh-my-opencode.json".source = ./opencode/oh-my-opencode.json;
  };
}
