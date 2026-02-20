{ ... }:
{
  imports = [
    ../shared/home-manager/riley
  ];

  opencode.ohMyOpencodeAgentModelMapping = {
    sisyphus = {
      model = "opencode/kimi-k2.5-free";
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
      model = "opencode/minimax-m2.5-free";
    };
    explore = {
      model = "opencode/minimax-m2.5-free";
    };
    "multimodal-looker" = {
      model = "opencode/kimi-k2.5-free";
    };
    prometheus = {
      model = "openai/gpt-5.2";
      variant = "high";
    };
    metis = {
      model = "openai/gpt-5.2";
      variant = "high";
    };
    momus = {
      model = "openai/gpt-5.2";
      variant = "medium";
    };
    atlas = {
      model = "opencode/kimi-k2.5-free";
    };
  };

  opencode.ohMyOpencodeCategoryModelMapping = {
    "visual-engineering" = {
      model = "openai/gpt-5.2";
      variant = "high";
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
      model = "openai/gpt-5.2";
      variant = "high";
    };
    quick = {
      model = "opencode/gpt-5-nano";
    };
    "unspecified-low" = {
      model = "openai/gpt-5.3-codex";
      variant = "medium";
    };
    "unspecified-high" = {
      model = "openai/gpt-5.2";
      variant = "high";
    };
    writing = {
      model = "openai/gpt-5.2";
      variant = "medium";
    };
  };
}
