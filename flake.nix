{
  description = "Flake for nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-generators = {
      url = "github:nix-community/nixos-generators/7c60ba4bc8d6aa2ba3e5b0f6ceb9fc07bc261565";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, nixpkgs-unstable, nixos-generators, disko, agenix, sops-nix }:
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
          redis = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./hosts/redis-vm/configuration.nix
            ];
          };

          playground = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              agenix.nixosModules.default
              ./hosts/playground/configuration.nix
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

          postgres-17 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              agenix.nixosModules.default
              ./hosts/postgres-17/configuration.nix
            ];
          };

          pgadmin = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./hosts/pgadmin/configuration.nix
            ];
          };

          gitea = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./hosts/gitea/configuration.nix
            ];
          };

          caddy-example = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              agenix.nixosModules.default
              ./hosts/caddy-example/configuration.nix
            ];
          };

          nginx-example = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              agenix.nixosModules.default
              sops-nix.nixosModules.sops
              ./hosts/nginx-example/configuration.nix
            ];
          };

          homeassistant = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              disko.nixosModules.disko
              ./hosts/homeassistant/configuration.nix
            ];
          };

          borg = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {inherit system unstablePkgs; };
            modules = [
              disko.nixosModules.disko
              agenix.nixosModules.default
              ./hosts/borg/configuration.nix
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
