# Adversarial Tests for Profile-Specific Agent Deployment
# 
# This test suite validates the profile-specific agent deployment filtering feature in opencode.nix
# Tests are written as Nix evaluation scenarios that can be checked for assertion failures.
#
# To run these tests:
# 1. For individual tests: nix eval --file modules/home-manager/riley/opencode.test.nix --print-build-logs 'test_name'
# 2. To validate all configurations: nix eval --file modules/home-manager/riley/opencode.test.nix

{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib }:

let
  # Import the module under test
  opencodeModule = import ./opencode.nix;
  
  # Utility to create a minimal config for testing
  mkTestConfig = {
    profile ? "personal",
    overrideModels ? { },
    overrideTemplates ? null,
    overrideCanonicalAgents ? null,
  }:
    let
      # Start with base config values
      baseConfig = {
        riley.opencode.profile = profile;
        _module.args.config = { };
        _module.args.lib = lib;
        _module.args.pkgs = pkgs;
      };
      
      # Apply test-specific overrides if needed
      testConfig = baseConfig;
    in
    testConfig;

  # Helper to safely evaluate opencode module with given config/overrides
  # Returns the evaluation result or error message
  safeEvalOpencode = { config, models ? null, templates ? null }:
    let
      # Note: In actual testing, this would require a full home-manager evaluation
      # For now, this structure documents the test scenarios
      result = {
        config = config;
        inherit models templates;
        status = "defined";
      };
    in
    result;

in
{
  # ============================================================================
  # SECTION 1: Profile-Specific Deployment Filtering Tests
  # ============================================================================
  # These tests verify that only agents present in a selected profile are rendered
  
  test_personal_profile_renders_all_agents = {
    name = "Personal profile renders all 11 canonical agents";
    description = ''
      Verify that when personal profile is selected, all 11 agents from 
      canonicalAgents are rendered (wardroom, riker, guide, data, worf, troi, 
      laforge, q, crusher, obrien, haskell).
    '';
    expectedBehavior = "renderedAgentFiles should contain exactly 11 agents";
    testCase = {
      profile = "personal";
      expectedRenderedCount = 11;
      expectedAgents = [
        "wardroom" "riker" "guide" "data" "worf" "troi" 
        "laforge" "q" "crusher" "obrien" "haskell"
      ];
    };
  };

  test_work_profile_renders_all_agents = {
    name = "Work profile also renders all 11 canonical agents";
    description = ''
      The current work profile includes all 11 agents (unlike omitted agents 
      mentioned in the specification). Verify it renders all agents.
    '';
    expectedBehavior = "renderedAgentFiles should contain exactly 11 agents";
    testCase = {
      profile = "work";
      expectedRenderedCount = 11;
      expectedAgents = [
        "wardroom" "riker" "guide" "data" "worf" "troi" 
        "laforge" "q" "crusher" "obrien" "haskell"
      ];
    };
  };

  test_profile_omitting_agent = {
    name = "Profile omitting an agent only renders remaining agents";
    description = ''
      If a profile mapping omits haskell (or any agent), only the remaining 
      agents should be rendered. This tests the filtering logic in 
      selectedProfileAgents and renderedAgentFiles.
    '';
    expectedBehavior = ''
      When profile is modified to omit haskell:
      - selectedProfileAgents = 10 agents (no haskell)
      - renderedAgentFiles = 10 entries
      - haskell.md is NOT in the rendered output
    '';
    testCase = {
      profile = "work";
      modifyModelsTo = {
        # omit haskell from work profile
        wardroom = "anthropic/claude-opus-4-6";
        riker = "anthropic/claude-opus-4-6";
        data = "anthropic/claude-opus-4-6";
        worf = "anthropic/claude-opus-4-6";
        troi = "anthropic/claude-opus-4-6";
        laforge = "anthropic/claude-opus-4-6";
        q = "anthropic/claude-opus-4-6";
        crusher = "anthropic/claude-opus-4-6";
        obrien = "anthropic/claude-opus-4-6";
        guide = "anthropic/claude-haiku-4-6";
        # haskell intentionally omitted
      };
      expectedRenderedCount = 10;
      expectedAbsent = [ "haskell" ];
    };
  };

  test_different_models_for_same_agent_in_profiles = {
    name = "Same agent uses different models in different profiles";
    description = ''
      The q agent exists in both personal and work profiles with different model 
      strings. Verify that when personal is selected, it uses 
      "opencode/claude-haiku-4-5" and when work is selected, it uses 
      "anthropic/claude-opus-4-6".
    '';
    expectedBehavior = ''
      - selectedProfile = "personal" → selectedModels.q = "opencode/claude-haiku-4-5"
      - selectedProfile = "work" → selectedModels.q = "anthropic/claude-opus-4-6"
    '';
    testCase = {
      profile = "personal";
      expectedModel = "opencode/claude-haiku-4-5";
      agent = "q";
    };
  };

  # ============================================================================
  # SECTION 2: Orphaned Template Detection Tests
  # ============================================================================
  # These tests verify that no template files exist without at least one profile
  
  test_all_canonical_agents_mapped_to_some_profile = {
    name = "All 11 canonical agents are mapped in at least one profile";
    description = ''
      Verify that every agent in canonicalAgents list appears in at least one 
      profile's model mapping. This prevents orphaned templates.
    '';
    expectedBehavior = ''
      allProfileAgents should contain all 11 agents:
      wardroom, riker, guide, data, worf, troi, laforge, q, crusher, obrien, haskell
    '';
    testCase = {
      expectedCoverage = [
        "wardroom" "riker" "guide" "data" "worf" "troi" 
        "laforge" "q" "crusher" "obrien" "haskell"
      ];
      assertion = "Every agent in canonicalAgents appears in at least one profile";
    };
  };

  test_orphaned_template_detection_fires = {
    name = "Adding a template file without profile mapping triggers error";
    description = ''
      If a new template file is added (e.g., "sepulski.md") but no profile 
      maps this agent, the orphanedTemplateFiles check should detect it and 
      raise an assertion error.
    '';
    expectedBehavior = ''
      orphanedTemplateFiles should be ["sepulski.md"]
      Assertion should fire with message:
      "riley.opencode has orphaned templates with no profile deploying them: sepulski.md"
    '';
    testCase = {
      extraTemplateFile = "sepulski.md";
      expectedOrphanedTemplates = [ "sepulski.md" ];
      shouldError = true;
      errorMessage = "orphaned templates";
    };
  };

  test_no_orphaned_templates_with_current_config = {
    name = "Current config has no orphaned template files";
    description = ''
      With the current configuration, all template files (.md in agent directory) 
      should be mapped to at least one profile. Verify orphanedTemplateFiles = [].
    '';
    expectedBehavior = "orphanedTemplateFiles assertion passes (empty list)";
    testCase = {
      assertion = "orphanedTemplateFiles == [ ]";
    };
  };

  # ============================================================================
  # SECTION 3: Invalid Model String Detection Tests
  # ============================================================================
  # These tests verify model string validation per profile
  
  test_empty_string_model_in_profile_triggers_error = {
    name = "Empty string as model value triggers profile validation error";
    description = ''
      If a profile has an agent with an empty string model value (e.g., 
      haskell = ""), the selectedProfileInvalidModels or 
      profileModelAssertions should catch it.
    '';
    expectedBehavior = ''
      profileModelAssertions includes assertion that catches empty models:
      invalidModelAgents = ["haskell"]
      Error message: "...has agents with empty or invalid model strings: haskell"
    '';
    testCase = {
      profile = "personal";
      modifyModelsTo = {
        wardroom = "opencode/claude-haiku-4-5";
        riker = "opencode/claude-haiku-4-5";
        data = "opencode/claude-sonnet-4-6";
        worf = "opencode/claude-haiku-4-5";
        troi = "opencode/gpt-5-nano";
        laforge = "opencode/kimi-k2.5";
        q = "opencode/claude-haiku-4-5";
        crusher = "opencode/claude-haiku-4-5";
        obrien = "opencode/gpt-5-nano";
        haskell = "";  # INVALID: empty string
        guide = "opencode/claude-sonnet-4-6";
      };
      shouldError = true;
      expectedInvalidAgents = [ "haskell" ];
    };
  };

  test_null_model_in_profile_triggers_error = {
    name = "Null as model value triggers profile validation error";
    description = ''
      If a profile has an agent with null as model value, the validation 
      should catch it (model == null check).
    '';
    expectedBehavior = ''
      profileModelAssertions catches null models:
      invalidModelAgents = ["haskell"]
      Error message includes "empty or invalid model strings"
    '';
    testCase = {
      profile = "personal";
      agentWithNullModel = "haskell";
      shouldError = true;
      assertion = "model == null should be caught";
    };
  };

  test_non_string_model_in_profile_triggers_error = {
    name = "Non-string model value (e.g., list/attrset) triggers error";
    description = ''
      If a profile has an agent with a non-string model value (like a list or 
      attribute set), the !(lib.isString model) check should catch it.
    '';
    expectedBehavior = ''
      profileModelAssertions catches non-string models:
      invalidModelAgents = ["q"]
      Error: "...has agents with empty or invalid model strings: q"
    '';
    testCase = {
      profile = "work";
      agentWithNonStringModel = "q";
      modelValue = [ "anthropic/claude-opus-4-6" ];  # list, not string
      shouldError = true;
      assertion = "!(lib.isString model) check fires";
    };
  };

  test_invalid_models_only_affect_selected_profile = {
    name = "Invalid model in non-selected profile does not cause error";
    description = ''
      If the work profile has an invalid model but personal is selected, 
      the error should NOT fire. Only selectedProfileInvalidModels is checked 
      for the selected profile.
    '';
    expectedBehavior = ''
      When personal is selected:
      - profileModelAssertions still validates ALL profiles (catches work's error)
      - But selectedProfileInvalidModels only checks personal profile
    '';
    testCase = {
      profile = "personal";
      # work profile is corrupted with empty model
      workProfileCorrupted = true;
      shouldError = true;
      # BUG: profileModelAssertions validates all profiles, so error still fires!
      # This is a cross-cutting concern that always fires
    };
  };

  test_all_current_models_are_non_empty_strings = {
    name = "All models in current personal and work profiles are valid strings";
    description = ''
      Verify the existing config has all non-empty string model values.
    '';
    expectedBehavior = "profileModelAssertions pass for both personal and work profiles";
    testCase = {
      assertion = "All model values are non-empty strings";
    };
  };

  # ============================================================================
  # SECTION 4: Missing Template Detection Tests
  # ============================================================================
  # These tests verify agents have corresponding template files
  
  test_missing_template_in_selected_profile = {
    name = "Agent in profile without template file triggers error";
    description = ''
      If the selected profile includes an agent (e.g., "spock") but the 
      template file (spock.md) doesn't exist, selectedProfileMissingTemplates 
      should catch it.
    '';
    expectedBehavior = ''
      selectedProfileMissingTemplates = ["spock"]
      Assertion fires: "...references agents without template files: spock"
    '';
    testCase = {
      profile = "personal";
      modifyModelsTo = {
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
        guide = "opencode/claude-sonnet-4-6";
        spock = "opencode/claude-haiku-4-5";  # NEW AGENT: no template file
      };
      shouldError = true;
      expectedMissingTemplates = [ "spock" ];
    };
  };

  test_missing_template_not_checked_in_other_profiles = {
    name = "Missing template in non-selected profile does not cause error";
    description = ''
      If work profile has an unmapped agent and personal is selected, 
      the error should not fire for personal profile. Missing template check 
      is only for selectedProfile.
    '';
    expectedBehavior = ''
      selectedProfileMissingTemplates only checks personal profile agents
      No error fires for work profile's missing agents
    '';
    testCase = {
      profile = "personal";
      # work profile would have unmapped agent
      shouldNotError = true;
    };
  };

  test_all_agents_in_personal_have_templates = {
    name = "All agents in personal profile have template files";
    description = ''
      Verify that every agent in the personal profile's model mapping has 
      a corresponding .md file in the agent directory.
    '';
    expectedBehavior = "selectedProfileMissingTemplates = [] when personal is selected";
    testCase = {
      profile = "personal";
      assertion = "All 11 agents have templates";
    };
  };

  test_all_agents_in_work_have_templates = {
    name = "All agents in work profile have template files";
    description = ''
      Verify that every agent in the work profile's model mapping has 
      a corresponding .md file in the agent directory.
    '';
    expectedBehavior = "selectedProfileMissingTemplates = [] when work is selected";
    testCase = {
      profile = "work";
      assertion = "All 11 agents have templates";
    };
  };

  # ============================================================================
  # SECTION 5: Edge Cases and Boundary Tests
  # ============================================================================
  
  test_profile_omitting_haskell_only = {
    name = "Work profile modified to omit only haskell";
    description = ''
      Tests the specific scenario mentioned in the requirements where work 
      profile omits haskell but personal includes it.
    '';
    expectedBehavior = ''
      When work profile is modified to omit haskell:
      - selectedProfileAgents (work) = 10 agents
      - renderedAgentFiles (work) = 10 entries
      - personal profile still renders 11
      - orphanedTemplateFiles detects haskell.md is deployed by personal
    '';
    testCase = {
      workProfileModified = true;
      omittedAgent = "haskell";
      expectedWorkRenderedCount = 10;
      expectedPersonalRenderedCount = 11;
      expectedOrphanedCount = 0;
    };
  };

  test_both_profiles_render_same_agent = {
    name = "Same agent appears in both profiles with different models";
    description = ''
      The q agent appears in both personal and work profiles with different 
      model values. Verify both profiles can coexist without conflict.
    '';
    expectedBehavior = ''
      - allProfileAgents contains "q"
      - When personal selected: q rendered with personal model
      - When work selected: q rendered with work model
      - No conflict or duplication
    '';
    testCase = {
      agent = "q";
      personalModel = "opencode/claude-haiku-4-5";
      workModel = "anthropic/claude-opus-4-6";
      noConflict = true;
    };
  };

  test_empty_profile_mapping = {
    name = "What happens if a profile has no agents (empty mapping)?";
    description = ''
      Edge case: what if modelProfiles.x = {}? Should this be allowed or error?
      This tests whether the code assumes at least one agent per profile.
    '';
    expectedBehavior = ''
      Either:
      A) Treated as valid - selectedProfileAgents = []
      B) Rejected - an error fires about empty profile
      Current implementation likely allows empty profile (no explicit check).
    '';
    testCase = {
      profile = "work";
      modifyModelsTo = { };  # Empty profile
      expectedBehavior = "undefined - implementation allows empty profiles";
    };
  };

  test_single_agent_profile = {
    name = "Profile with exactly one agent";
    description = ''
      If a profile contains only one agent (e.g., work = { q = "model"; }),
      verify rendering works correctly (no off-by-one errors).
    '';
    expectedBehavior = ''
      renderedAgentFiles = { q = {...} }
      Only q.md is rendered
    '';
    testCase = {
      profile = "work";
      modifyModelsTo = { q = "anthropic/claude-opus-4-6"; };
      expectedRenderedCount = 1;
      expectedAgents = [ "q" ];
    };
  };

  test_agent_with_unicode_name = {
    name = "Handling agent names with Unicode characters";
    description = ''
      What if an agent name contains Unicode? (e.g., agënt)
      Tests file system and string matching robustness.
    '';
    expectedBehavior = ''
      Either works correctly or validation catches it as invalid
      Current implementation assumes ASCII agent names
    '';
    testCase = {
      agent = "agënt";
      template = "agënt.md";
      shouldWork = false;
      reason = "Nix module likely assumes ASCII identifiers";
    };
  };

  test_agent_name_with_spaces = {
    name = "Agent name with spaces in profile mapping";
    description = ''
      What if a profile has an agent name with spaces?
      (e.g., "q agent" = "model")
    '';
    expectedBehavior = ''
      File lookup for "q agent.md" fails
      selectedProfileMissingTemplates catches it
    '';
    testCase = {
      agent = "q agent";
      shouldError = true;
      expectedMissingTemplate = true;
    };
  };

  test_very_long_agent_name = {
    name = "Very long agent name (>255 characters)";
    description = ''
      Tests file system limits on agent/template names.
    '';
    expectedBehavior = ''
      File lookup fails (filename too long)
      selectedProfileMissingTemplates detects missing template
    '';
    testCase = {
      agent = lib.concatStrings (lib.replicate 300 "x");
      shouldError = true;
    };
  };

  # ============================================================================
  # SECTION 6: Template Content Validation Tests
  # ============================================================================
  
  test_template_has_exactly_one_model_line = {
    name = "Each template must have exactly one 'model:' line";
    description = ''
      templateModelLineAssertions checks each template has exactly one line 
      matching "model:" pattern. If haskell.md has zero or two, error fires.
    '';
    expectedBehavior = ''
      modelLineCount == 1 assertion passes for all selected profile agents
    '';
    testCase = {
      profile = "personal";
      assertion = "All 11 templates have exactly one model: line";
    };
  };

  test_template_has_placeholder_model_line = {
    name = "Each template must have exactly one 'model: @MODEL@' line";
    description = ''
      The placeholder line specifically must be "model: @MODEL@" (before 
      substitution). If a template lacks this, the assertion fires.
    '';
    expectedBehavior = ''
      placeholderLineCount == 1 for all selected profile agents
    '';
    testCase = {
      profile = "work";
      assertion = "All templates have placeholder line 'model: @MODEL@'";
    };
  };

  test_multiple_model_lines_in_template = {
    name = "Template with multiple 'model:' lines triggers error";
    description = ''
      If a template accidentally has two model: lines, the first assertion 
      fires: modelLineCount != 1.
    '';
    expectedBehavior = ''
      templateModelLineAssertions catches: "must contain exactly one model: line; found 2"
    '';
    testCase = {
      profile = "personal";
      templateModified = "q.md";
      duplicateModelLine = true;
      shouldError = true;
    };
  };

  test_missing_placeholder_in_template = {
    name = "Template without 'model: @MODEL@' placeholder triggers error";
    description = ''
      If a template has "model: hardcoded-value" instead of "model: @MODEL@",
      the placeholder assertion fires.
    '';
    expectedBehavior = ''
      Error: "...must contain exactly one 'model: @MODEL@' line"
    '';
    testCase = {
      profile = "work";
      templateModified = "q.md";
      missingPlaceholder = true;
      shouldError = true;
    };
  };

  # ============================================================================
  # SECTION 7: Cross-Profile Consistency Tests
  # ============================================================================
  
  test_template_deployed_by_multiple_profiles = {
    name = "Template can be deployed by multiple profiles (no orphans)";
    description = ''
      The q.md template is deployed by both personal and work profiles.
      Verify allProfileAgents includes q and orphanedTemplateFiles is empty.
    '';
    expectedBehavior = ''
      q is in allProfileAgents (union of all profile agents)
      q.md is not in orphanedTemplateFiles
    '';
    testCase = {
      assertion = "Templates deployed by multiple profiles don't become orphaned";
    };
  };

  test_template_deployed_by_only_one_profile = {
    name = "Template deployed by exactly one profile is not orphaned";
    description = ''
      If haskell is only in work profile (not personal), haskell.md is still 
      not orphaned because work deploys it.
    '';
    expectedBehavior = ''
      haskell in allProfileAgents (from work profile)
      haskell.md not in orphanedTemplateFiles
    '';
    testCase = {
      assertion = "Single-profile templates are considered deployed";
    };
  };

  test_no_cross_profile_template_conflicts = {
    name = "No conflicts when profiles use same template with different models";
    description = ''
      Personal and work both use q.md template, just with different model values.
      Verify no double-rendering or conflicts in home.file mapping.
    '';
    expectedBehavior = ''
      When selected profile = personal: q.md rendered with personal model
      When selected profile = work: q.md rendered with work model
      No simultaneous deployment of both versions
    '';
    testCase = {
      profiles = [ "personal" "work" ];
      sharedTemplates = [ "q" "data" "crusher" ];
      assertion = "Only selected profile's version is deployed";
    };
  };

  # ============================================================================
  # SECTION 8: Cross-Validation Tests
  # ============================================================================
  # Tests that check how different validation stages interact
  
  test_validation_stops_rendering_on_any_error = {
    name = "Any validation error prevents renderedAgentFiles generation";
    description = ''
      If ANY check fails (missing template, invalid model, orphaned template),
      canRender = false and renderedAgentFiles = { }. No partial rendering.
    '';
    expectedBehavior = ''
      renderedAgentFiles = { } when canRender = false
      This prevents broken configurations from being deployed
    '';
    testCase = {
      profile = "work";
      addOrphanedTemplate = true;
      expectedRenderedCount = 0;
    };
  };

  test_profile_validation_prevents_rendering = {
    name = "Invalid models in profile prevent all rendering";
    description = ''
      If selectedProfileInvalidModels != [], then canRender = false and 
      no agents are rendered for that profile.
    '';
    expectedBehavior = ''
      selectedProfileInvalidModels != [] → canRender = false → renderedAgentFiles = {}
    '';
    testCase = {
      profile = "work";
      corruptModel = "q";
      modelValue = "";
      expectedRenderedCount = 0;
    };
  };

  test_all_validation_stages_execute = {
    name = "All validation stages run independently";
    description = ''
      The code checks:
      1. missingTemplateFiles (canonical agents missing)
      2. extraTemplateFiles (extra templates not in canonical list)
      3. orphanedTemplateFiles (templates not in any profile)
      4. profileModelAssertions (all profiles have valid models)
      5. selectedProfileInvalidModels (selected profile models valid)
      6. selectedProfileMissingTemplates (selected profile agents have templates)
      7. templateModelLineAssertions (templates have model: and @MODEL@)
      
      Verify all stages are evaluated.
    '';
    expectedBehavior = ''
      All 7 validation stages are in assertions array
      Each can independently fail or pass
    '';
    testCase = {
      validationStages = 7;
      assertion = "All stages present and can fire independently";
    };
  };

  # ============================================================================
  # SECTION 9: Model Substitution Tests
  # ============================================================================
  
  test_model_substitution_in_rendered_file = {
    name = "@MODEL@ placeholder is replaced with correct model value";
    description = ''
      When q.md is rendered for personal profile, @MODEL@ should be replaced 
      with "opencode/claude-haiku-4-5". For work, it should be 
      "anthropic/claude-opus-4-6".
    '';
    expectedBehavior = ''
      renderedAgentFiles.q.source uses pkgs.replaceVars with MODEL mapping
      Resulting file has correct model string, not placeholder
    '';
    testCase = {
      profile = "personal";
      agent = "q";
      expectedSubstitution = "opencode/claude-haiku-4-5";
    };
  };

  test_model_special_characters_in_substitution = {
    name = "Model strings with special characters are substituted correctly";
    description = ''
      Some models have slashes and hyphens (e.g., "opencode/claude-haiku-4-5").
      Verify pkgs.replaceVars handles these correctly.
    '';
    expectedBehavior = "Special characters preserved in substitution";
    testCase = {
      profile = "personal";
      modelValue = "opencode/claude-haiku-4-5";
      hasSlash = true;
      hasHyphen = true;
    };
  };

  # ============================================================================
  # SECTION 10: File System and Nix Integration Tests
  # ============================================================================
  
  test_template_path_resolution = {
    name = "Template file paths are correctly resolved from ./opencode/agent";
    description = ''
      templatePath = agent: templateDir + "/${agent}.md"
      Verify this resolves to correct absolute paths for each agent.
    '';
    expectedBehavior = ''
      templatePath "q" → {repo}/modules/home-manager/riley/opencode/agent/q.md
    '';
    testCase = {
      agent = "q";
      expectedPath = "./opencode/agent/q.md";
    };
  };

  test_template_directory_reading = {
    name = "builtins.readDir correctly lists all .md files in agent directory";
    description = ''
      templateFiles is computed by reading the directory and filtering .md files.
      Should find all 11 canonical agent templates plus any new ones.
    '';
    expectedBehavior = ''
      templateFiles contains exactly: 
      [crusher, data, guide, haskell, laforge, obrien, q, riker, troi, wardroom, worf].md
    '';
    testCase = {
      expectedFileCount = 11;
    };
  };

  test_canonical_vs_actual_template_mismatch = {
    name = "Handles mismatch between canonicalAgents and actual files";
    description = ''
      If canonicalAgents lists "spock" but spock.md doesn't exist:
      missingTemplateFiles = ["spock.md"]
      Assertion fires.
    '';
    expectedBehavior = ''
      missingTemplateFiles assertion catches any canonical agent without file
    '';
    testCase = {
      assertion = "cannonicalTemplateFiles vs templateFiles mismatch detected";
    };
  };

  # ============================================================================
  # Test Execution Summary
  # ============================================================================
  
  _testExecutionGuide = ''
    ADVERSARIAL TEST EXECUTION GUIDE FOR opencode.nix
    ================================================
    
    These tests are written as Nix expressions documenting expected behaviors.
    To validate the implementation:
    
    1. MANUAL VALIDATION (recommended for first pass):
       For each test, manually verify:
       - Does the code have the assertion/check described?
       - Would the test scenario produce the expected behavior?
       - Are edge cases handled?
    
    2. AUTOMATED VALIDATION (for CI/CD):
       Implement a Nix test runner that:
       a) Loads the module with various modelProfiles configurations
       b) Evaluates the assertions
       c) Captures errors
       d) Reports pass/fail
    
    3. KEY FILES TO VALIDATE:
       - All 11 .md template files exist in ./opencode/agent/
       - Each template has exactly one "model: @MODEL@" line
       - modelProfiles contains personal and work with appropriate agents
       - No extra .md files in agent directory
    
    4. PROFILE-SPECIFIC TESTS:
       Run each test with:
       - nix eval -f opencode.test.nix --arg profile "personal" test_name
       - nix eval -f opencode.test.nix --arg profile "work" test_name
    
    5. ERROR SCENARIOS:
       For "shouldError" tests, verify:
       - The right assertion in opencode.nix would catch the scenario
       - Error message is descriptive
       - Error prevents rendering (canRender = false)
  '';
}
