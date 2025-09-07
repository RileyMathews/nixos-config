build HOSTNAME:
    nix run nixpkgs#nixos-rebuild -- build --flake .#{{HOSTNAME}}

deploy HOSTNAME:
    nix run nixpkgs#nixos-rebuild -- switch --flake .#{{HOSTNAME}} --target-host nixos

