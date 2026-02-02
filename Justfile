build HOSTNAME:
    nix run nixpkgs#nixos-rebuild -- build --flake .#{{HOSTNAME}}

deploy HOST:
    nix run nixpkgs#nixos-rebuild -- switch --flake .#{{HOST}} --target-host root@{{HOST}}

provision FLAKEPATH IP:
    nix run github:nix-community/nixos-anywhere -- --flake {{FLAKEPATH}} --target-host root@{{IP}} --copy-host-keys

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
      just deploy ".#$vm" "$vm"
    done
    echo ""
    echo "========================================="
    echo "✓ All VMs deployed successfully!"
    echo "========================================="

