#!/usr/bin/env bash
set -uo pipefail

for command in fj gh git jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$command" >&2
    exit 2
  fi
done

if [[ -n "${FORGEJO_HOST:-}" ]]; then
  forgejo_host="$FORGEJO_HOST"
else
  mapfile -t forgejo_hosts < <(fj auth list)
  if [[ ${#forgejo_hosts[@]} -ne 1 ]]; then
    printf 'Set FORGEJO_HOST; expected one fj login but found %d.\n' "${#forgejo_hosts[@]}" >&2
    exit 2
  fi
  forgejo_host="${forgejo_hosts[0]}"
fi

github_owner="${GITHUB_OWNER:-$(gh api user --jq .login)}"
if [[ -z "$github_owner" ]]; then
  printf 'Could not determine the authenticated GitHub user.\n' >&2
  exit 2
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

declare -a forgejo_repos=()
page=1
while :; do
  if ! page_output="$(fj --style minimal -H "$forgejo_host" user repos --page "$page" 2>&1)"; then
    printf 'Failed to list Forgejo repositories on page %d:\n%s\n' "$page" "$page_output" >&2
    exit 2
  fi

  page_count=0
  while IFS= read -r line; do
    if [[ "$line" == '- '* ]]; then
      forgejo_repos+=("${line#- }")
      ((page_count += 1))
    fi
  done <<< "$page_output"

  if ((page_count == 0 || page_count < 50)); then
    break
  fi
  ((page += 1))
done

if ((${#forgejo_repos[@]} == 0)); then
  printf 'Forgejo returned no owned repositories.\n' >&2
  exit 2
fi

github_query='query($owner: String!, $endCursor: String) {
  repositoryOwner(login: $owner) {
    repositories(first: 100, after: $endCursor, orderBy: {field: NAME, direction: ASC}) {
      nodes {
        name
        isEmpty
        defaultBranchRef { name target { oid } }
      }
      pageInfo { hasNextPage endCursor }
    }
  }
}'

if ! gh api graphql --paginate -f owner="$github_owner" -f query="$github_query" \
  --jq '.data.repositoryOwner.repositories.nodes[] | [.name, .isEmpty, (.defaultBranchRef.name // ""), (.defaultBranchRef.target.oid // "")] | @tsv' \
  >"$tmpdir/github-repos.tsv"; then
  printf 'Failed to list repositories owned by GitHub user %s.\n' "$github_owner" >&2
  exit 2
fi

declare -A github_names=()
declare -A github_empty=()
declare -A github_branches=()
declare -A github_heads=()
while IFS=$'\t' read -r name is_empty branch head; do
  key="${name,,}"
  github_names["$key"]="$name"
  github_empty["$key"]="$is_empty"
  github_branches["$key"]="$branch"
  github_heads["$key"]="$head"
done <"$tmpdir/github-repos.tsv"

matches=0
empty_matches=0
missing=0
head_mismatches=0
branch_mismatches=0
forgejo_errors=0

printf 'Forgejo: %s (%d owned repositories)\n' "$forgejo_host" "${#forgejo_repos[@]}"
printf 'GitHub:  %s (%d owned repositories)\n\n' "$github_owner" "${#github_names[@]}"

for forgejo_repo in "${forgejo_repos[@]}"; do
  repo_name="${forgejo_repo#*/}"
  key="${repo_name,,}"

  if [[ -z "${github_names[$key]+present}" ]]; then
    printf 'MISSING_GITHUB       %-45s expected %s/%s\n' "$forgejo_repo" "$github_owner" "$repo_name"
    ((missing += 1))
    continue
  fi

  forgejo_remote="ssh://git@${forgejo_host}/${forgejo_repo}.git"
  if ! remote_output="$(GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=10' git ls-remote --symref "$forgejo_remote" HEAD 2>&1)"; then
    printf 'FORGEJO_HEAD_ERROR   %-45s %s\n' "$forgejo_repo" "$remote_output"
    ((forgejo_errors += 1))
    continue
  fi

  forgejo_branch=''
  forgejo_head=''
  while IFS=$'\t' read -r first second; do
    if [[ "$first" == 'ref: refs/heads/'* && "$second" == 'HEAD' ]]; then
      forgejo_branch="${first#ref: refs/heads/}"
    elif [[ "$second" == 'HEAD' ]]; then
      forgejo_head="$first"
    fi
  done <<< "$remote_output"

  github_name="${github_names[$key]}"
  github_branch="${github_branches[$key]}"
  github_head="${github_heads[$key]}"

  if [[ -z "$forgejo_head" ]]; then
    if [[ "${github_empty[$key]}" == 'true' ]]; then
      printf 'MATCH_EMPTY          %s -> %s/%s\n' "$forgejo_repo" "$github_owner" "$github_name"
      ((empty_matches += 1))
    else
      printf 'FORGEJO_HEAD_ERROR   %-45s no default-branch HEAD; GitHub has %s at %s\n' \
        "$forgejo_repo" "$github_branch" "$github_head"
      ((forgejo_errors += 1))
    fi
  elif [[ -z "$github_head" ]]; then
    printf 'HEAD_MISMATCH        %-45s Forgejo %s@%s; GitHub is empty\n' \
      "$forgejo_repo" "$forgejo_branch" "$forgejo_head"
    ((head_mismatches += 1))
  elif [[ "$forgejo_head" != "$github_head" ]]; then
    printf 'HEAD_MISMATCH        %-45s Forgejo %s@%s; GitHub %s@%s\n' \
      "$forgejo_repo" "$forgejo_branch" "$forgejo_head" "$github_branch" "$github_head"
    ((head_mismatches += 1))
  elif [[ "$forgejo_branch" != "$github_branch" ]]; then
    printf 'BRANCH_NAME_MISMATCH %-45s same head %s; Forgejo %s, GitHub %s\n' \
      "$forgejo_repo" "$forgejo_head" "$forgejo_branch" "$github_branch"
    ((branch_mismatches += 1))
  else
    printf 'MATCH                %s %s@%s\n' "$forgejo_repo" "$forgejo_branch" "$forgejo_head"
    ((matches += 1))
  fi
done

anomalies=$((missing + head_mismatches + branch_mismatches + forgejo_errors))
printf '\nSummary\n'
printf '  Matching non-empty repositories: %d\n' "$matches"
printf '  Matching empty repositories:     %d\n' "$empty_matches"
printf '  Missing from GitHub:              %d\n' "$missing"
printf '  Different default-branch heads:  %d\n' "$head_mismatches"
printf '  Different default-branch names:  %d\n' "$branch_mismatches"
printf '  Forgejo HEAD lookup errors:       %d\n' "$forgejo_errors"

if ((anomalies > 0)); then
  exit 1
fi
