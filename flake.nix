{
  description = "Flake for nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
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
    kolide = {
      url = "github:kolide/nix-agent/main";
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, nixpkgs-unstable, nixos-generators, disko, agenix, sops-nix, kolide }:
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
        config = {
          allowUnfree = true;
        };
      };
    in
      {
      nixosConfigurations = {
        picard = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit system unstablePkgs; };
          modules = [
            ./hosts/picard/configuration.nix
            kolide.nixosModules.kolide-launcher
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

        postgres-17 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            agenix.nixosModules.default
            ./hosts/postgres-17/configuration.nix
          ];
        };

        worf = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit system unstablePkgs; };
          modules = [
            disko.nixosModules.disko
            agenix.nixosModules.default
            ./hosts/worf/configuration.nix
          ];
        };

        forgejo = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit system unstablePkgs; };
          modules = [
            disko.nixosModules.disko
            agenix.nixosModules.default
            ./hosts/forgejo/configuration.nix
          ];
        };

        backup-server = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit system unstablePkgs; };
          modules = [
            disko.nixosModules.disko
            agenix.nixosModules.default
            ./hosts/backup-server/configuration.nix
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

        defiant = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit system unstablePkgs; };
          modules = [
            disko.nixosModules.disko
            agenix.nixosModules.default
            ./hosts/defiant/configuration.nix
          ];
        };

        bridge = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit system unstablePkgs; };
          modules = [
            disko.nixosModules.disko
            agenix.nixosModules.default
            ./hosts/bridge/configuration.nix
          ];
        };

        discovery = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit system unstablePkgs; };
          modules = [
            disko.nixosModules.disko
            agenix.nixosModules.default
            ./hosts/discovery/configuration.nix
          ];
        };

        couchdb = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit system unstablePkgs; };
          modules = [
            disko.nixosModules.disko
            agenix.nixosModules.default
            ./hosts/couchdb/configuration.nix
          ];
        };

        relay = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit system unstablePkgs; };
          modules = [
            disko.nixosModules.disko
            agenix.nixosModules.default
            ./hosts/relay/configuration.nix
          ];
        };

        data = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit system unstablePkgs; };
          modules = [
            disko.nixosModules.disko
            agenix.nixosModules.default
            ./hosts/data/configuration.nix
          ];
        };

        redis = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit system unstablePkgs; };
          modules = [
            disko.nixosModules.disko
            agenix.nixosModules.default
            ./hosts/redis/configuration.nix
          ];
        };

        engineering = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit system unstablePkgs; };
          modules = [
            disko.nixosModules.disko
            agenix.nixosModules.default
            ./hosts/engineering/configuration.nix
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

      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          agenix.packages.${system}.default
        ];
      };
    };
}
