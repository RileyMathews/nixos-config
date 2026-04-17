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
    vms=$(nix eval --json .#vmDeployments 2>/dev/null | jq -r '.[]')
    for vm in $vms; do
      echo ""
      echo "========================================="
      echo "Checking $vm..."
      echo "========================================="
      just deploy-smart-if-changed "$vm"
    done
    echo ""
    echo "========================================="
    echo "✓ All VMs processed successfully!"
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

remote-host-services:
	#!/usr/bin/env bash
	set -euo pipefail
	hosts=(
	  backup-server bridge data defiant discovery engineering enterprise
	  forgebot forgejo immichdb lab pg17 redis relay
	  thegenerosityco-staging worf yamato
	)
	tmp="$(mktemp)"
	trap 'rm -f "$tmp"' EXIT
	for host in "${hosts[@]}"; do
	  {
	    if ssh -o BatchMode=yes -o ConnectTimeout=4 "root@${host}" "systemctl list-units --type=service --all --no-legend --no-pager --plain --output=json" 2>/dev/null | jq -r --arg host "$host" '.[] | "\(.unit) \($host)"'; then
	      :
	    else
	      echo "warning: failed to query ${host}" >&2
	    fi
	  } >>"$tmp" &
	done
	wait
	sort -u "$tmp"

logs:
    tv --source-command="just remote-host-services" --preview-command='ssh root@{1} "journalctl -u {0} -n 100 --no-pager"'

deploy-if-changed HOST:
    #!/usr/bin/env bash
    set -euo pipefail

    host="{{HOST}}"

    desired="$(nix build --no-link --print-out-paths ".#nixosConfigurations.${host}.config.system.build.toplevel")"
    current="$(ssh -o BatchMode=yes -o ConnectTimeout=5 "root@${host}" 'readlink -f /run/current-system || true')"

    echo "Host:    $host"
    echo "Current: ${current:-<unknown>}"
    echo "Desired: $desired"

    if [[ -n "${current:-}" && "$current" == "$desired" ]]; then
      echo "✓ ${host} already matches desired system; skipping"
      exit 0
    fi

    just deploy "$host"

deploy-smart-if-changed HOST:
    #!/usr/bin/env bash
    set -euo pipefail

    host="{{HOST}}"

    desired="$(nix build --no-link --print-out-paths ".#nixosConfigurations.${host}.config.system.build.toplevel")"
    current="$(ssh -o BatchMode=yes -o ConnectTimeout=5 "root@${host}" 'readlink -f /run/current-system || true')"

    echo "Host:    $host"
    echo "Current: ${current:-<unknown>}"
    echo "Desired: $desired"

    if [[ -n "${current:-}" && "$current" == "$desired" ]]; then
      echo "✓ ${host} already matches desired system; skipping"
      exit 0
    fi

    desired_kernel="$(readlink -f "$desired/kernel" 2>/dev/null || true)"
    desired_initrd="$(readlink -f "$desired/initrd" 2>/dev/null || true)"
    desired_kmods="$(readlink -f "$desired/kernel-modules" 2>/dev/null || true)"

    readarray -t booted_parts < <(
      ssh -o BatchMode=yes -o ConnectTimeout=5 "root@${host}" '
        readlink -f /run/booted-system/kernel 2>/dev/null || true
        readlink -f /run/booted-system/initrd 2>/dev/null || true
        readlink -f /run/booted-system/kernel-modules 2>/dev/null || true
      '
    )

    booted_kernel="${booted_parts[0]:-}"
    booted_initrd="${booted_parts[1]:-}"
    booted_kmods="${booted_parts[2]:-}"

    reboot_needed=0
    [[ -n "$desired_kernel" && "$desired_kernel" != "$booted_kernel" ]] && reboot_needed=1
    [[ -n "$desired_initrd" && "$desired_initrd" != "$booted_initrd" ]] && reboot_needed=1
    [[ -n "$desired_kmods"  && "$desired_kmods"  != "$booted_kmods"  ]] && reboot_needed=1

    if [[ "$reboot_needed" -eq 1 ]]; then
      echo "⚠ Boot-critical change detected; deploying with boot and rebooting ${host}"
      nix run nixpkgs#nixos-rebuild -- boot --flake ".#${host}" --target-host "root@${host}"
      ssh "root@${host}" 'systemctl reboot'
    else
      echo "No boot-critical change detected; switching ${host} live"
      nix run nixpkgs#nixos-rebuild -- switch --flake ".#${host}" --target-host "root@${host}"
    fi
