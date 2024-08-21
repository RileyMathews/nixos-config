{
  description = "Flake for nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    kolide = {
      url = "github:kolide/nix-agent/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, nixpkgs-unstable, kolide }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;

        config = {
          allowUnfree = true;
        };
      };

      unstablePkgs = import nixpkgs-unstable {
        inherit system;
      };
    in
      {
        nixosConfigurations = {
          nixVm = nixpkgs.lib.nixosSystem {
            specialArgs = {inherit system unstablePkgs; };
            modules = [./hosts/nixVm/configuration.nix];
          };

          scotty = nixpkgs.lib.nixosSystem {
            specialArgs = {inherit system unstablePkgs; };
            modules = [
              ./hosts/scotty/configuration.nix
              nixos-hardware.nixosModules.framework-16-7040-amd
              kolide.nixosModules.kolide-launcher
            ];
          };
        };    
      };
}
