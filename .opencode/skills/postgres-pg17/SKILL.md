---
name: postgres-pg17
description: Connect to pg17 over SSH and manage Postgres roles/databases
license: MIT
compatibility: opencode
metadata:
  audience: agents
  workflow: homelab
---

## What I do

- Connect to `pg17.tailscale.rileymathews.com` over SSH using the operator account.
- Use local socket auth on the server to run `psql -U postgres` without prompting for a password.
- Create Postgres roles and databases idempotently.
- Verify credentials from the caller machine with a TCP `psql` login test.

## When to use me

Use this skill when a task asks to create or update PostgreSQL users/databases on the `pg17` host in this repo.

## Why this works

`hosts/vms/pg17/configuration.nix` sets:

- `services.postgresql.enableTCPIP = true`
- `local all all trust`
- `host all all 0.0.0.0/0 md5`

That means:

- SSH to the host, then local `psql` as `postgres` works without password.
- Remote clients can authenticate with username/password over TCP on port `5432`.

## Prerequisites

- SSH access to `pg17.tailscale.rileymathews.com`.
- `psql` available on the caller machine (for optional verification).
- Pick values for:
  - role name (`ROLE_NAME`)
  - role password (`ROLE_PASSWORD`)
  - database name (`DB_NAME`)

## Core workflow

### 1) Verify SSH connectivity

```bash
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new pg17.tailscale.rileymathews.com "hostname; whoami"
```

Expected: host `pg17` and your SSH user.

### 2) Create role and database idempotently (server-side)

Run this exact pattern from the caller machine:

```bash
ROLE_NAME="example_app"
ROLE_PASSWORD="change_me_strong"
DB_NAME="example_app"

ssh -o BatchMode=yes pg17.tailscale.rileymathews.com "psql -U postgres -d postgres -v ON_ERROR_STOP=1 <<'SQL'
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${ROLE_NAME}') THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', '${ROLE_NAME}', '${ROLE_PASSWORD}');
  END IF;
END
\$\$;

SELECT format('CREATE DATABASE %I OWNER %I', '${DB_NAME}', '${ROLE_NAME}')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}')\gexec

GRANT ALL PRIVILEGES ON DATABASE \"${DB_NAME}\" TO \"${ROLE_NAME}\";
SQL"
```

Notes:

- Keep `DO \$\$ ... \$\$;` escaped exactly like this, or shell expansion will break SQL.
- `\gexec` executes generated SQL only when the `SELECT` returns a row.
- `ON_ERROR_STOP=1` makes failures explicit for automation.

### 3) Verify login from caller machine (TCP)

```bash
PGPASSWORD="${ROLE_PASSWORD}" \
psql -h pg17.tailscale.rileymathews.com -U "${ROLE_NAME}" -d "${DB_NAME}" \
  -c "select current_user, current_database();"
```

Expected one row with the created role and database.

## Useful patterns

List roles/databases from server:

```bash
ssh pg17.tailscale.rileymathews.com "psql -U postgres -d postgres -c '\\du' -c '\\l'"
```

Rotate password:

```bash
ssh pg17.tailscale.rileymathews.com "psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c \"ALTER ROLE \\\"${ROLE_NAME}\\\" WITH PASSWORD '${ROLE_PASSWORD}';\""
```

## Troubleshooting

- `Host key verification failed`:
  - Run SSH once with `-o StrictHostKeyChecking=accept-new`.
- `psql: command not found` on caller machine:
  - Use only server-side creation, skip local verification, or install `psql` locally.
- SQL error near `DO 12345`:
  - You forgot to escape `$$` as `\$\$` in the SSH command.
- Role/database already exists:
  - The workflow is idempotent; reruns should succeed.

## Safety notes

- Do not commit generated app passwords to git.
- Prefer strong random passwords and pass via env vars/secret manager in real tasks.
- Use least privilege when grants beyond DB ownership are requested.
