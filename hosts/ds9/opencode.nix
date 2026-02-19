{ ... }:
{
  home.file = {
    ".config/opencode/opencode.json".source = ./opencode/opencode.json;
    ".config/opencode/oh-my-opencode.json".source = ./opencode/oh-my-opencode.json;
    ".config/opencode/agent".source = ./opencode/agent;
    ".config/opencode/skills".source = ./opencode/skills;
    ".config/opencode/tools".source = ./opencode/tools;
  };
}
