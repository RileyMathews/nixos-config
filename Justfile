build HOSTNAME:
    nix run nixpkgs#nixos-rebuild -- build --flake .#{{HOSTNAME}}

deploy HOST:
    nix run nixpkgs#nixos-rebuild -- switch --flake .#{{HOST}} --target-host root@{{HOST}}

deploy-nas:
    nix run nixpkgs#nixos-rebuild -- switch --flake .#nas --target-host root@nas --build-host root@nas

finalize FLAKEPATH IP:
    nix run nixpkgs#nixos-rebuild -- switch --flake .#{{FLAKEPATH}} --target-host root@{{IP}}

provision FLAKEPATH IP:
    nix run github:nix-community/nixos-anywhere -- --flake {{FLAKEPATH}} --target-host root@{{IP}}

build-iso:
    nix run nixpkgs#nixos-rebuild -- build-image --flake .#iso --image-variant iso

# Deploy all VMs sequentially (fails immediately on any error)
deploy-all-vms:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "========================================="
    echo "Starting batch deployment of all VMs"
    echo "========================================="
    # Get VM list from flake and parse JSON array to space-separated list
    vms=$(nix eval --json .#vmDeployments 2>/dev/null | jq -r '.[]')
    for vm in $vms; do
      echo ""
      echo "========================================="
      echo "Deploying $vm..."
      echo "========================================="
      just deploy $vm
    done
    echo ""
    echo "========================================="
    echo "✓ All VMs deployed successfully!"
    echo "========================================="

build-all:
    #!/usr/bin/env bash
    set -euo pipefail
    # Get VM list from flake and parse JSON array to space-separated list
    vms=$(nix eval --json .#vmDeployments 2>/dev/null | jq -r '.[]')
    for vm in $vms; do
      echo ""
      echo "========================================="
      echo "building $vm..."
      echo "========================================="
      just build $vm
    done
    echo ""
    echo "========================================="
    echo "✓ All VMs built successfully!"
    echo "========================================="

test:
    python3 modules/home-manager/riley/scripts/check-haskell-build-status-agent --test

switch:
    #!/usr/bin/env bash
    set -euo pipefail
    host="$(cat /etc/hostname)"
    if [[ -f /etc/NIXOS ]] || [[ -f /etc/os-release && "$(grep -i '^ID=' /etc/os-release || true)" =~ ^ID=nixos$ ]]; then
      echo "Detected NixOS on '$host'; running nixos-rebuild switch"
      sudo nixos-rebuild switch --flake ".#$host"
    else
      echo "Detected non-NixOS on '$host'; running Home Manager switch"
      nix run home-manager -- switch --flake ".#$host"
    fi
