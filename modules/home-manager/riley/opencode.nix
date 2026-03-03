{ pkgs, config, lib, ... }:
let
  canonicalAgents = [
    "wardroom"
    "riker"
    "data"
    "worf"
    "troi"
    "laforge"
    "q"
    "crusher"
    "obrien"
    "haskell"
  ];

  modelProfiles = {
    personal = {
      wardroom = "opencode/claude-haiku-4-5";
      riker = "opencode/claude-haiku-4-5";
      data = "opencode/claude-sonnet-4-6";
      worf = "opencode/claude-haiku-4-5";
      troi = "opencode/gpt-5-nano";
      laforge = "opencode/kimi-k2.5";
      q = "opencode/claude-haiku-4-5";
      crusher = "opencode/claude-haiku-4-5";
      obrien = "opencode/gpt-5-nano";
      haskell = "opencode/kimi-k2.5";
    };

    work = {
      wardroom = "anthropic/claude-opus-4-6";
      riker = "anthropic/claude-opus-4-6";
      data = "anthropic/claude-opus-4-6";
      worf = "anthropic/claude-opus-4-6";
      troi = "anthropic/claude-opus-4-6";
      laforge = "anthropic/claude-opus-4-6";
      q = "anthropic/claude-opus-4-6";
      crusher = "anthropic/claude-opus-4-6";
      obrien = "anthropic/claude-opus-4-6";
      haskell = "anthropic/claude-opus-4-6";
    };
  };

  selectedProfile = config.riley.opencode.profile;
  selectedModels = modelProfiles.${selectedProfile};

  templateDir = ./opencode/agent;
  templatePath = agent: templateDir + "/${agent}.md";

  canonicalTemplateFiles = map (agent: "${agent}.md") canonicalAgents;
  templateFiles =
    lib.attrNames
      (lib.filterAttrs (name: fileType: fileType != "directory" && lib.hasSuffix ".md" name) (builtins.readDir templateDir));

  missingTemplateFiles = lib.filter (name: !(lib.elem name templateFiles)) canonicalTemplateFiles;
  extraTemplateFiles = lib.filter (name: !(lib.elem name canonicalTemplateFiles)) templateFiles;

  formatList = values:
    if values == [ ] then
      "(none)"
    else
      lib.concatStringsSep ", " values;

  profileModelAssertions =
    lib.concatMap
      (
        profileName:
        let
          profileModels = modelProfiles.${profileName};
          profileKeys = lib.attrNames profileModels;
          missingKeys = lib.filter (name: !(lib.elem name profileKeys)) canonicalAgents;
          extraKeys = lib.filter (name: !(lib.elem name canonicalAgents)) profileKeys;
        in
        [
          {
            assertion = missingKeys == [ ];
            message = "riley.opencode profile '${profileName}' is missing agent model mappings for: ${formatList missingKeys}";
          }
          {
            assertion = extraKeys == [ ];
            message = "riley.opencode profile '${profileName}' has unexpected agent model mappings for: ${formatList extraKeys}";
          }
        ]
      )
      (lib.attrNames modelProfiles);

  selectedProfileKeys = lib.attrNames selectedModels;
  selectedProfileMissingKeys = lib.filter (name: !(lib.elem name selectedProfileKeys)) canonicalAgents;
  selectedProfileExtraKeys = lib.filter (name: !(lib.elem name canonicalAgents)) selectedProfileKeys;

  canRender =
    missingTemplateFiles == [ ]
    && extraTemplateFiles == [ ]
    && selectedProfileMissingKeys == [ ]
    && selectedProfileExtraKeys == [ ];

  templateModelLineAssertions =
    if canRender then
      lib.concatMap
        (
          agent:
          let
            templateFile = templatePath agent;
            templateText = builtins.readFile templateFile;
            templateLines = lib.splitString "\n" templateText;
            modelLines = lib.filter (line: builtins.match "^[[:space:]]*model:[[:space:]]*.*$" line != null) templateLines;
            placeholderLines = lib.filter (line: line == "model: @MODEL@") templateLines;
            modelLineCount = builtins.length modelLines;
            placeholderLineCount = builtins.length placeholderLines;
          in
          [
            {
              assertion = modelLineCount == 1;
              message = "riley.opencode template '${agent}.md' must contain exactly one model: line; found ${toString modelLineCount}";
            }
            {
              assertion = placeholderLineCount == 1;
              message = "riley.opencode template '${agent}.md' must contain exactly one 'model: @MODEL@' line";
            }
          ]
        )
        canonicalAgents
    else
      [ ];

  renderedAgentFiles =
    if canRender then
      lib.genAttrs canonicalAgents (agent: {
        force = true;
        source = pkgs.replaceVars (templatePath agent) {
          MODEL = selectedModels.${agent};
        };
      })
    else
      { };
in
{
  assertions =
    [
      {
        assertion = missingTemplateFiles == [ ];
        message = "riley.opencode agent templates are missing required files: ${formatList missingTemplateFiles}";
      }
      {
        assertion = extraTemplateFiles == [ ];
        message = "riley.opencode agent template directory has unexpected *.md files: ${formatList extraTemplateFiles}";
      }
      {
        assertion = selectedProfileMissingKeys == [ ];
        message = "riley.opencode selected profile '${selectedProfile}' is missing agent model mappings for: ${formatList selectedProfileMissingKeys}";
      }
      {
        assertion = selectedProfileExtraKeys == [ ];
        message = "riley.opencode selected profile '${selectedProfile}' has unexpected agent model mappings for: ${formatList selectedProfileExtraKeys}";
      }
    ]
    ++ profileModelAssertions
    ++ (if canRender then templateModelLineAssertions else [ ]);

  home.file =
    {
      ".config/opencode/opencode.json".source = ./opencode/opencode.json;
      ".config/opencode/skills".source = ./opencode/skills;
      ".config/opencode/tools".source = ./opencode/tools;
      ".config/opencode/plugins".source = ./opencode/plugins;
      ".config/opencode/AGENT.md".source = ./opencode/AGENT.md;
      ".config/opencode/peon-ping/config.json".source = ./opencode/peon-ping/config.json;
    }
    // lib.mapAttrs' (agent: value: lib.nameValuePair ".config/opencode/agent/${agent}.md" value) renderedAgentFiles;
}
