---
name: agenix
description: Manage agenix secrets non-interactively from the CLI
license: MIT
compatibility: opencode
metadata:
  audience: agents
  workflow: secrets
---

## What I do

- Create and update `age` secrets without opening an interactive editor.
- Use `RULES` + `agenix -e` with piped stdin for automation-friendly edits.
- Verify results with `agenix -d` and optionally rekey with `agenix -r`.

## When to use me

Use this skill when a task asks for unattended secret edits, scripted updates, or CI-friendly secret management in this repo.

## Prerequisites

- Run from `secrets/` unless you use absolute/fully qualified paths.
- Ensure `secrets.nix` contains an attribute for the target `*.age` filename.
- Ensure an identity that can decrypt the target secret is available (agent/default keys or `-i <key>`).

## Core workflow

### 1) Confirm the rule exists

`agenix` resolves recipients from `RULES` and the exact secret filename.

Example check target:

- Secret file: `opecde-test-secrets-file.age`
- Rule key must be exactly: `"opecde-test-secrets-file.age".publicKeys = [...]`

If the name does not match, `agenix -e` fails with an attribute-missing error.

### 2) Create or replace secret content non-interactively

```bash
printf 'my secret value\n' | RULES="./secrets.nix" agenix -e "opecde-test-secrets-file.age"
```

Notes:

- If stdin is non-interactive, `agenix` uses `cp /dev/stdin` as editor.
- This writes encrypted output directly to the target `*.age` file.

### 3) Verify decrypted content

```bash
agenix -d "opecde-test-secrets-file.age"
```

### 4) Rekey after recipient changes (optional)

```bash
RULES="./secrets.nix" agenix -r
```

## Useful command patterns

Create/update with explicit identity:

```bash
printf 'new value\n' | RULES="./secrets.nix" agenix -e "<secret>.age" -i "keys/agenix-master.agekey"
```

Decrypt with explicit identity:

```bash
agenix -d "<secret>.age" -i "keys/agenix-master.agekey"
```

## Troubleshooting

- `attribute '"<name>.age"' missing`:
  - The key in `secrets.nix` does not exactly match the file name passed to `-e`.
- `no identity matched any of the recipients`:
  - You cannot decrypt current ciphertext with the provided/default key; use a matching key or re-encrypt from a key that can decrypt.
- Wrong `RULES` path:
  - From `secrets/`, use `RULES="./secrets.nix"`.
  - From repo root, use `RULES="secrets/secrets.nix"` and pass `secrets/<name>.age`.

## Safety notes

- Never print real secret values in logs unless explicitly requested.
- Keep plaintext input ephemeral (`printf`/stdin) and avoid writing temporary plaintext files.
