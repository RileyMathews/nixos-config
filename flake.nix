{
  description = "Flake for nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, nixos-hardware }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;

        config = {
          allowUnfree = true;
        };
      };
    in
      {
        nixosConfigurations = {
          nixVm = nixpkgs.lib.nixosSystem {
            specialArgs = {inherit system;};
            modules = [./hosts/nixVm/configuration.nix];
          };

          scotty = nixpkgs.lib.nixosSystem {
            specialArgs = {inherit system;};
            modules = [
              ./hosts/scotty/configuration.nix
              nixos-hardware.nixosModules.framework-16-7040-amd
            ];
          };
        };    
      };
}
