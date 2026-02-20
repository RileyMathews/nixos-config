{ config, lib, ... }:
let
  cfg = config.opencode;
  defaultOhMyOpencodeAgentModelMapping = {
    sisyphus = {
      model = "anthropic/claude-opus-4-6";
      variant = "max";
    };
    hephaestus = {
      model = "openai/gpt-5.3-codex";
      variant = "medium";
    };
    oracle = {
      model = "openai/gpt-5.2";
      variant = "high";
    };
    librarian = {
      model = "anthropic/claude-haiku-4-5";
    };
    explore = {
      model = "anthropic/claude-haiku-4-5";
    };
    "multimodal-looker" = {
      model = "openai/gpt-5.2";
    };
    prometheus = {
      model = "anthropic/claude-opus-4-6";
      variant = "max";
    };
    metis = {
      model = "anthropic/claude-opus-4-6";
      variant = "max";
    };
    momus = {
      model = "openai/gpt-5.2";
      variant = "medium";
    };
    atlas = {
      model = "anthropic/claude-sonnet-4-6";
    };
  };

  defaultOhMyOpencodeCategoryModelMapping = {
    "visual-engineering" = {
      model = "anthropic/claude-opus-4-6";
      variant = "max";
    };
    ultrabrain = {
      model = "openai/gpt-5.3-codex";
      variant = "xhigh";
    };
    deep = {
      model = "openai/gpt-5.3-codex";
      variant = "medium";
    };
    artistry = {
      model = "anthropic/claude-opus-4-6";
      variant = "max";
    };
    quick = {
      model = "anthropic/claude-haiku-4-5";
    };
    "unspecified-low" = {
      model = "anthropic/claude-sonnet-4-6";
    };
    "unspecified-high" = {
      model = "anthropic/claude-opus-4-6";
      variant = "max";
    };
    writing = {
      model = "anthropic/claude-sonnet-4-6";
    };
  };

  sanitizeModelMapping = mapping:
    lib.mapAttrs
      (_: entryCfg: lib.filterAttrs (_key: value: value != null) entryCfg)
      mapping;

  sanitizedAgentModelMapping =
    sanitizeModelMapping (lib.recursiveUpdate defaultOhMyOpencodeAgentModelMapping cfg.ohMyOpencodeAgentModelMapping);

  sanitizedCategoryModelMapping =
    sanitizeModelMapping (lib.recursiveUpdate defaultOhMyOpencodeCategoryModelMapping cfg.ohMyOpencodeCategoryModelMapping);

  ohMyOpencodeBaseConfig = builtins.fromJSON (builtins.readFile ./opencode/oh-my-opencode.json);
  ohMyOpencodeConfig = ohMyOpencodeBaseConfig // {
    agents = sanitizedAgentModelMapping;
    categories = sanitizedCategoryModelMapping;
  };

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

    ohMyOpencodeAgentModelMapping = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = {
        oracle = {
          model = "openai/gpt-5.2";
          variant = "high";
        };
        librarian = {
          model = "anthropic/claude-haiku-4-5";
        };
      };
      description = ''
        Per-agent model overrides for oh-my-opencode.
        Module defaults are provided and can be overridden per host.
      '';
    };

    ohMyOpencodeCategoryModelMapping = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = {
        quick = {
          model = "anthropic/claude-haiku-4-5";
        };
        ultrabrain = {
          model = "openai/gpt-5.3-codex";
          variant = "xhigh";
        };
      };
      description = ''
        Per-category model overrides for oh-my-opencode.
        Module defaults are provided and can be overridden per host.
      '';
    };
  };

  config.home.file = {
    ".config/opencode/opencode.json".text = builtins.toJSON opencodeConfig + "\n";
    ".config/opencode/agent".source = ./opencode/agent;
    ".config/opencode/skills".source = ./opencode/skills;
    ".config/opencode/tools" = {
      source = ./opencode/tools;
    };
  } // lib.optionalAttrs cfg.enableOhMyOpencodePlugin {
    ".config/opencode/oh-my-opencode.json".text = builtins.toJSON ohMyOpencodeConfig + "\n";
  };
}
