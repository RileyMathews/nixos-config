# NixOS Configuration - Agent Guidelines

## Build Commands
- Build configuration: `just build HOSTNAME` or `nix run nixpkgs#nixos-rebuild -- build --flake .#HOSTNAME`
- Deploy to remote: `just deploy .#HOSTNAME user@host` or `nix run nixpkgs#nixos-rebuild -- switch --flake .#HOSTNAME --target-host user@host --use-remote-sudo`
- Provision new system: `just provision .#HOSTNAME root@ip` or `nix run github:nix-community/nixos-anywhere -- --flake .#HOSTNAME --target-host root@ip`
- Enter dev shell: `nix develop`

## Code Style Guidelines
- Use 2-space indentation for Nix expressions
- Module structure: options → config → assertions (in that order)
- Use `with lib;` at top of modules for brevity
- Import dependencies explicitly in flake.nix inputs
- Use descriptive option names with consistent prefixes (e.g., `myCaddy.*`, `services.backup.*`)
- Always include `type`, `default`, and `description` for options
- Use `mkIf cfg.enable` for conditional configuration blocks
- Include assertions for required options when enabling modules
- Use `builtins.readFile` for external script content
- Follow NixOS module conventions with proper attribute paths