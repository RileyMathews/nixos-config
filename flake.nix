{
  description = "Flake for nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kolide = {
      url = "github:kolide/nix-agent/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, nixpkgs-unstable, kolide, sops-nix, nixos-generators, disko }:
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
          scotty = nixpkgs.lib.nixosSystem {
            specialArgs = {inherit system unstablePkgs; };
            modules = [
              ./hosts/scotty/configuration.nix
              nixos-hardware.nixosModules.framework-16-7040-amd
              kolide.nixosModules.kolide-launcher
              sops-nix.nixosModules.sops
            ];
          };

          redis = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./hosts/redis-vm/configuration.nix
            ];
          };
        
          rabbitmq = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./hosts/rabbitmq-vm/configuration.nix
            ];
          };

          rpgweave-staging = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./hosts/rpgweave-staging-vm/configuration.nix
            ];
          };

          rpgweave-production = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./hosts/rpgweave-production-vm/configuration.nix
            ];
          };

          ntfy = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./hosts/ntfy/configuration.nix
            ];
          };

          vaultwarden = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./hosts/vaultwarden/configuration.nix
            ];
          };

          postgres-16 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./hosts/postgres-16/configuration.nix
            ];
          };

          pgadmin = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./hosts/pgadmin/configuration.nix
            ];
          };
        };    

        packages.x86_64-linux = {
          iso = nixos-generators.nixosGenerate {
            system = "x86_64-linux";
            format = "iso";
            modules = [
              ./hosts/iso/configuration.nix
            ];
          };
        };
      };
}
