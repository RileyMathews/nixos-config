# Forgejo runner on `lab`

The Forgejo runner on `lab` exposes two execution labels. The Forgejo instance
and all repositories that can use this runner are trusted: jobs using the
container label have access to the host Docker socket and therefore have
effective root access to `lab`.

## Runner labels

- `homelab-coordinator` runs directly on the NixOS host. It exists for legacy
  static-site deployment workflows.
- `homelab-docker` runs in a digest-pinned Ubuntu 24.04 container. It is an
  intentionally plain image; each workflow installs the tools it needs.

The runner has a capacity of one. Jobs are deliberately serialized so two
workflows cannot inspect or mutate one another through the shared Docker
daemon.

## Bootstrapping an Ubuntu job

Plain Ubuntu does not include Node.js, Git, mise, the Docker CLI, or OpenSSH.
In particular, Node-based actions such as `actions/checkout` cannot run until a
compatible Node.js version is on `PATH`. Put a shell bootstrap step before the
first Node action:

```yaml
- name: Bootstrap CI tools
  run: |
    apt-get update
    apt-get install --yes --no-install-recommends \
      ca-certificates curl git openssh-client \
      docker.io docker-buildx docker-compose-v2
    curl --fail --silent --show-error --location https://mise.run \
      | MISE_VERSION=v2026.7.0 MISE_INSTALL_PATH=/usr/local/bin/mise sh
    mise use --global node@24
    echo "$HOME/.local/share/mise/shims" >> "$FORGEJO_PATH"

- uses: actions/checkout@v6

- name: Install project tools
  run: mise install --locked

- name: Run tests
  run: mise exec -- npm test
```

Projects should commit `mise.toml` and `mise.lock`. Using `mise exec` avoids
relying on interactive shell activation and ensures commands use the versions
selected by the project.

A workflow may override the runner's default image with another OCI image. If
that image does not contain Node.js, the same restriction applies to Node-based
actions.

## Docker Compose and Playwright

Docker commands run inside the job container, but they control the Docker
daemon on `lab`. Docker build contexts work normally because the client sends
the context to the daemon. Bind mounts such as `.:/app` do not: the daemon
resolves their source on the host rather than in the job container.

Use a CI Compose override that builds the current source into images and does
not bind-mount the checkout. Run Playwright as a Compose service so it shares a
network with the application:

```yaml
name: Browser tests

on:
  pull_request:
  push:
    branches: [main]

jobs:
  playwright:
    runs-on: homelab-docker
    env:
      COMPOSE_PROJECT_NAME: ci-${{ forgejo.run_id }}-${{ forgejo.run_attempt }}
    steps:
      - name: Bootstrap CI tools
        run: |
          apt-get update
          apt-get install --yes --no-install-recommends \
            ca-certificates curl git \
            docker.io docker-buildx docker-compose-v2
          curl --fail --silent --show-error --location https://mise.run \
            | MISE_VERSION=v2026.7.0 MISE_INSTALL_PATH=/usr/local/bin/mise sh
          mise use --global node@24
          echo "$HOME/.local/share/mise/shims" >> "$FORGEJO_PATH"

      - uses: actions/checkout@v6

      - name: Install project tools
        run: mise install --locked

      - name: Build and start the application
        run: docker compose -f compose.yml -f compose.ci.yml up --build --detach --wait app

      - name: Run Playwright
        run: docker compose -f compose.yml -f compose.ci.yml run --rm playwright

      - name: Clean up
        if: always()
        run: docker compose -f compose.yml -f compose.ci.yml down --volumes --remove-orphans
```

The application service should define a health check so `up --wait` only
succeeds when the server is ready. Pin the Playwright service image to the
version used by the project. Upload the Playwright report in a separate
`if: failure()` step before cleanup when failure artifacts are useful.

## SSH and Kamal deployments

The runner identity is stored at `/var/lib/gitea-runner/forgejo/.ssh`. That is
the only host path workflows are permitted to request as a volume. Mount it
read-only in a deployment job by specifying the Ubuntu job container and its
volume:

```yaml
name: Deploy

on:
  push:
    branches: [main]

concurrency:
  group: production-deploy
  cancel-in-progress: false

jobs:
  deploy:
    runs-on: homelab-docker
    container:
      image: docker.io/library/ubuntu:24.04@sha256:4fbb8e6a8395de5a7550b33509421a2bafbc0aab6c06ba2cef9ebffbc7092d90
      volumes:
        - /var/lib/gitea-runner/forgejo/.ssh:/root/.ssh:ro
    steps:
      - name: Bootstrap CI tools
        run: |
          apt-get update
          apt-get install --yes --no-install-recommends \
            ca-certificates curl git openssh-client \
            docker.io docker-buildx docker-compose-v2
          curl --fail --silent --show-error --location https://mise.run \
            | MISE_VERSION=v2026.7.0 MISE_INSTALL_PATH=/usr/local/bin/mise sh
          mise use --global node@24
          echo "$HOME/.local/share/mise/shims" >> "$FORGEJO_PATH"

      - uses: actions/checkout@v6

      - name: Install project tools
        run: mise install --locked

      - name: Verify the deployment target
        run: ssh -o BatchMode=yes deploy-host true

      - name: Deploy
        run: mise exec -- kamal deploy
```

The host-wide `/etc/ssh/ssh_known_hosts` file is mounted read-only into every
container job. Add each deployment target declaratively in the `lab` NixOS
configuration instead of using `ssh-keyscan` during a workflow:

```nix
programs.ssh.knownHosts.deploy-host.publicKey =
  "ssh-ed25519 AAAA...";
```

Restrict deployment workflows to protected branches or environments. Use a
separate concurrency group for each deployment environment so two Kamal
deployments cannot overlap.

## Cleanup and storage

Every Compose workflow must use an `if: always()` cleanup step with
`down --volumes --remove-orphans`. Docker also prunes unused images, networks,
containers, and build cache older than seven days each week. CI Docker state is
disposable and is not included in Restic backups.
