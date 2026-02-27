{ ... }:
{
  home.file = {
    ".config/opencode/opencode.json".source = ./opencode/opencode.json;
    ".config/opencode/agent".source = ./opencode/agent;
    ".config/opencode/skills".source = ./opencode/skills;
    ".config/opencode/tools".source = ./opencode/tools;
    ".config/opencode/plugins".source = ./opencode/plugins;
    ".config/opencode/AGENT.md".source = ./opencode/AGENT.md;
    ".config/opencode/peon-ping/config.json".source = ./opencode/peon-ping/config.json;
  };
}
