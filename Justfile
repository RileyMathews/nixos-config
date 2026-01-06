build HOSTNAME:
    nix run nixpkgs#nixos-rebuild -- build --flake .#{{HOSTNAME}}

deploy FLAKEPATH HOST:
    nix run nixpkgs#nixos-rebuild -- switch --flake {{FLAKEPATH}} --target-host {{HOST}} --sudo --ask-sudo-password

provision FLAKEPATH IP:
    nix run github:nix-community/nixos-anywhere -- --flake {{FLAKEPATH}} --target-host root@{{IP}}

