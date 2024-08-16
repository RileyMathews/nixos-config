{
  description = "Flake for nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
  };

  outputs = { self, nixpkgs }:
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
            modules = [./configuration.nix];
          };
        };    
      };
}
