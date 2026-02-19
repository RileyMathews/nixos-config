---
name: github-actions-logs
description: Fetch GitHub Actions job logs, even while running
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
  workflow: github
---

## What I do

- Find failing GitHub checks for a PR
- Fetch logs with `gh` first
- Fall back to raw job logs while runs are in progress

## When to use me

Use this when CI checks are failing or running and you need logs quickly.
Ask clarifying questions only if the PR or repo cannot be inferred.

## How to do it

### Step 1: List checks and capture job URLs

```bash
gh pr checks <pr-number>
```

Look for failing checks and copy their job URLs, which look like:

```
https://github.com/<owner>/<repo>/actions/runs/<run-id>/job/<job-id>
```

### Step 2: Try the normal `gh` log fetch

```bash
gh run view <run-id> --log-failed
```

If you need a specific job:

```bash
gh run view <run-id> --job <job-id> --log
```

If the CLI reports logs are unavailable because the run is still in progress,
use the fallback below.

### Step 3: Fallback to raw job logs (works while running)

```bash
gh api repos/<owner>/<repo>/actions/jobs/<job-id>/logs
```

This returns raw text logs immediately, even while the job is still running.

## Notes

- The fallback endpoint is the same source used by the GitHub UI.
- You can fetch logs for multiple failing jobs by repeating Step 3.
- If the job ID is unknown, extract it from the job URL in Step 1.
