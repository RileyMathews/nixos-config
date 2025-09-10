build HOSTNAME:
    nix run nixpkgs#nixos-rebuild -- build --flake .#{{HOSTNAME}}

deploy HOSTNAME:
    nix run nixpkgs#nixos-rebuild -- switch --flake .#{{HOSTNAME}} --target-host nixos

provision FLAKEPATH IP:
    nix run github:nix-community/nixos-anywhere -- --flake {{FLAKEPATH}} --target-host root@{{IP}}

