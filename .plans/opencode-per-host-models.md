# Per-host OpenCode Model Profiles

## Goal
Allow selecting an OpenCode agent model profile per host (`personal` vs `work`), while keeping agent definitions as separate `.md` files and enforcing strict, loud failures when anything is missing or unexpected.

## Context
`modules/home-manager/riley/opencode.nix` currently deploys OpenCode config via static symlinks, including `".config/opencode/agent".source = ./opencode/agent;`, which hardcodes the `model:` per agent in `modules/home-manager/riley/opencode/agent/*.md`. We want a slim per-host setting that selects between exactly two model sets, with the opencode module owning the full agent->model mapping and validating templates and mappings strictly.

## Scope
- IN: two profiles (`personal`, `work`); strict templating of `modules/home-manager/riley/opencode/agent/*.md`; host-level selection via a single option; hard-fail assertions for missing/extra agents and placeholders.
- OUT: changing agent prompts/tools/instructions beyond introducing a single `model` placeholder; adding more than two profiles; making opencode.json model-driven unless needed later.

## Constraints
- MUST: keep separate agent `.md` files under `modules/home-manager/riley/opencode/agent/` and treat them as templates.
- MUST: strict failures for all “out of ordinary” conditions:
  - missing template for a canonical agent
  - extra `agent/*.md` template file not in the canonical list
  - profile mapping keys not matching the canonical list exactly
  - unknown `@...@` placeholders in templates
  - template missing the expected `model` placeholder pattern
- MUST NOT: silently fall back to a default model if any mapping/template is incomplete.

## Tasks
- [ ] 1. Add a slim per-host profile option
  - What: introduce `riley.opencode.profile` as an enum of `"personal"` and `"work"`, with a default (recommend `"personal"`). Keep consumers limited to this option.
  - Files: `modules/home-manager/riley/default.nix` (or `modules/home-manager/riley/opencode.nix`, but prefer centralizing options in `modules/home-manager/riley/default.nix`).
  - Done when: attempting to set any other value (or wrong type) fails at evaluation.

- [ ] 2. Define canonical agent list + two profile model maps (module-owned)
  - What: create a manually maintained canonical list like `[ "wardroom" "riker" "data" "worf" "troi" "laforge" "q" "crusher" "obrien" ]`, and two attrsets mapping each agent name to a model ID string.
  - Files: `modules/home-manager/riley/opencode.nix`.
  - Done when: both profiles fully cover the canonical list; existing defaults match today’s hardcoded model IDs.

- [ ] 3. Convert agent markdown files into strict templates
  - What: replace the hardcoded `model: ...` line in each file with a single placeholder token (recommend `model: @MODEL@`).
  - Files: `modules/home-manager/riley/opencode/agent/wardroom.md`, `modules/home-manager/riley/opencode/agent/riker.md`, `modules/home-manager/riley/opencode/agent/data.md`, `modules/home-manager/riley/opencode/agent/worf.md`, `modules/home-manager/riley/opencode/agent/troi.md`, `modules/home-manager/riley/opencode/agent/laforge.md`, `modules/home-manager/riley/opencode/agent/q.md`, `modules/home-manager/riley/opencode/agent/crusher.md`, `modules/home-manager/riley/opencode/agent/obrien.md`.
  - Done when: no agent template contains a concrete model ID; each contains exactly one `model: @MODEL@` occurrence (enforced by assertions in Task 4).

- [ ] 4. Render per-agent files with strict substitution and strict validations
  - What:
    - Stop sourcing the whole `./opencode/agent` directory directly.
    - For each canonical agent, generate `~/.config/opencode/agent/<agent>.md` from the corresponding template using strict substitution (recommend `pkgs.replaceVars` with `@MODEL@`).
    - Add assertions (evaluation-time) that:
      - template directory contains *exactly* the canonical agent templates (no extra `*.md`, no missing); use `builtins.readDir ./opencode/agent` to detect extras/missing.
      - selected profile mapping keys match the canonical agent list exactly (no missing/extra).
      - each template includes the required placeholder pattern (e.g. exactly one `model: @MODEL@` line); fail if not.
      - substitution fails loudly on any unexpected `@...@` placeholder (provided by `pkgs.replaceVars` behavior).
  - Files: `modules/home-manager/riley/opencode.nix`.
  - Done when: evaluation fails with a clear message if you (a) add an extra `.md` in `modules/home-manager/riley/opencode/agent/`, (b) remove a required template, (c) forget to add a model mapping for a canonical agent in either profile, or (d) introduce an unknown placeholder like `@FOO@`.

- [ ] 5. Select profiles per host
  - What: set `riley.opencode.profile` per host.
  - Files: `hosts/desktops/picard/configuration.nix`, `hosts/desktops/ds9/home.nix`.
  - Done when: picard and ds9 evaluate with different selected profiles (recommend `picard = "work"`, `ds9 = "personal"`).

## Verification
- `nix flake check`
- Build the relevant outputs for the hosts you changed (e.g. `nix build .#nixosConfigurations.picard.config.system.build.toplevel` and the ds9 home-manager output if exported by the flake).
