{ pkgs, config, lib, ... }:
let
  canonicalAgents = [
    "wardroom"
    "riker"
    "guide"
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
      guide = "opencode/claude-sonnet-4-6";
    };

    work = {
      haskell = "anthropic/claude-opus-4-6";
      guide = "anthropic/claude-haiku-4-6";
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

  # Collect all agents used by all profiles to detect orphaned templates
  allProfileAgents = lib.foldl' (acc: profileName: 
    acc // (lib.listToAttrs (map (agent: { name = agent; value = true; }) (lib.attrNames modelProfiles.${profileName})))
  ) { } (lib.attrNames modelProfiles);
  agentsWithProfiles = lib.attrNames allProfileAgents;

  orphanedTemplateFiles = lib.filter (name: 
    let agentName = lib.removeSuffix ".md" name;
    in !(lib.elem agentName agentsWithProfiles)) templateFiles;

  formatList = values:
    if values == [ ] then
      "(none)"
    else
      lib.concatStringsSep ", " values;

  # Per-profile validation: check all model values are non-empty strings
  profileModelAssertions =
    lib.concatMap
      (
        profileName:
        let
          profileModels = modelProfiles.${profileName};
          profileAgents = lib.attrNames profileModels;
          # Check that every agent in this profile has a non-empty model string
          invalidModelAgents = lib.filter (agent: 
            let model = profileModels.${agent};
            in model == "" || model == null || !(lib.isString model)
          ) profileAgents;
        in
        [
          {
            assertion = invalidModelAgents == [ ];
            message = "riley.opencode profile '${profileName}' has agents with empty or invalid model strings: ${formatList invalidModelAgents}";
          }
        ]
      )
      (lib.attrNames modelProfiles);

  selectedProfileAgents = lib.attrNames selectedModels;
  
  # Check that all agents in the selected profile have valid model strings
  selectedProfileInvalidModels = lib.filter (agent: 
    let model = selectedModels.${agent};
    in model == "" || model == null || !(lib.isString model)
  ) selectedProfileAgents;
  
  # Check that all agents in the selected profile have existing template files
  selectedProfileMissingTemplates = lib.filter (agent: 
    !(lib.elem "${agent}.md" templateFiles)
  ) selectedProfileAgents;

  canRender =
    missingTemplateFiles == [ ]
    && extraTemplateFiles == [ ]
    && orphanedTemplateFiles == [ ]
    && selectedProfileInvalidModels == [ ]
    && selectedProfileMissingTemplates == [ ];

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
        selectedProfileAgents
    else
      [ ];

  renderedAgentFiles =
    if canRender then
      lib.genAttrs selectedProfileAgents (agent: {
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
        assertion = orphanedTemplateFiles == [ ];
        message = "riley.opencode has orphaned templates with no profile deploying them: ${formatList orphanedTemplateFiles}";
      }
      {
        assertion = selectedProfileInvalidModels == [ ];
        message = "riley.opencode selected profile '${selectedProfile}' has agents with empty or invalid model strings: ${formatList selectedProfileInvalidModels}";
      }
      {
        assertion = selectedProfileMissingTemplates == [ ];
        message = "riley.opencode selected profile '${selectedProfile}' references agents without template files: ${formatList selectedProfileMissingTemplates}";
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
      ".config/opencode/AGENTS.md".source = ./opencode/AGENTS.md;
      ".config/opencode/tui.json".source = ./opencode/tui.json;
    }
    // lib.mapAttrs' (agent: value: lib.nameValuePair ".config/opencode/agent/${agent}.md" value) renderedAgentFiles;
}
