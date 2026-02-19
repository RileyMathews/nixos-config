---
name: forgejo-pr
description: Create pull requests on Forgejo hosts with fj, with API fallback
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  workflow: forgejo
---

## What I do

- Detect when the repository remote points to `git.rileymathews.com`
- Create a Forgejo pull request using `fj` (forgejo-cli)
- Fall back to the Forgejo REST API if `fj` is unavailable
- Return the created PR URL

## When to use me

Use this when the task includes pushing changes and opening a PR, and the git
remote host is `git.rileymathews.com`.

If the host is not `git.rileymathews.com`, use the normal host-specific workflow
instead (for example, GitHub with `gh`).

## How to do it

### Step 1: Confirm this is the Forgejo host

Get a remote URL from `origin` first, then `upstream` as fallback:

```bash
git remote get-url origin || git remote get-url upstream
```

Only continue when the host is `git.rileymathews.com`.

### Step 2: Ensure branch is pushed

Push the current branch and set upstream if needed:

```bash
git push -u origin "$(git branch --show-current)"
```

### Step 3: Preferred PR creation with `fj`

If `fj` is available, create the PR with explicit title/body/base/head.

```bash
fj pr create "<title>" --body-from-file "<body-file>" --base "<base-branch>" --head "<head-branch>"
```

Notes:

- `fj pr create --autofill` is acceptable when explicit title/body are not provided.
- `fj pr create --web` is acceptable only when a browser flow is explicitly desired.
- For AGit workflow, use `fj pr create --agit`.

### Step 4: Authenticate `fj` if required

For self-hosted instances, use application token login:

```bash
fj --host git.rileymathews.com auth add-key
```

If OAuth login is configured for the instance, this may also work:

```bash
fj --host git.rileymathews.com auth login
```

### Step 5: Fallback to Forgejo API

If `fj` is missing or fails, create the PR via API.

Endpoint:

- `POST /api/v1/repos/{owner}/{repo}/pulls`

Example:

```bash
curl -sS -X POST "https://git.rileymathews.com/api/v1/repos/<owner>/<repo>/pulls" \
  -H "Authorization: token $FORGEJO_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"<title>","body":"<body>","head":"<head-branch>","base":"<base-branch>"}'
```

Use a token with repository write permissions sufficient to open pull requests.

## Failure handling

- If an open PR already exists for the same head/base, return that PR URL instead of failing silently.
- If authentication fails, state what is missing (`fj` login or `FORGEJO_TOKEN`).
- If branch push fails, stop and report the git error.

## Output requirements

- Always return the PR URL.
- Include owner/repo and head -> base in one short line.
- Mention whether `fj` path or API fallback path was used.

## References

- Forgejo pull request workflow: https://forgejo.org/docs/latest/user/pull-requests-and-git-flow/
- Forgejo API usage: https://forgejo.org/docs/latest/user/api-usage/
- Forgejo OpenAPI: https://git.rileymathews.com/swagger.v1.json
- forgejo-cli wiki (PRs): https://codeberg.org/forgejo-contrib/forgejo-cli/wiki/PRs
