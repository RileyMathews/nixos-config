{
  description = "Flake for nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent.url = "github:NousResearch/hermes-agent";
    vikunja-project-reset = {
      url = "git+ssh://git@git.rileymathews.com/riley/vikunja-project-reset.git";
    };
  };

  outputs = { nixpkgs, ... }@inputs:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      lib = nixpkgs.lib;

      mkVmHost = hostName:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            inputs.disko.nixosModules.disko
            inputs.agenix.nixosModules.default
            ./hosts/vms/${hostName}/configuration.nix
          ] ++ lib.optional (hostName == "hermes") inputs.hermes-agent.nixosModules.default;
        };

      vmHostNames =
        let
          vmEntries = builtins.readDir ./hosts/vms;
        in
        lib.filter (n:
          vmEntries.${n} == "directory" && builtins.pathExists (./hosts/vms/${n}/configuration.nix)
        ) (builtins.attrNames vmEntries);

      vmNixosConfigurations = lib.genAttrs vmHostNames mkVmHost;

    in {
      nixosConfigurations = {
        nas = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/nas/configuration.nix
            inputs.agenix.nixosModules.default
          ];
        };

        thegenerosityco = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/thegenerosityco/configuration.nix
            inputs.agenix.nixosModules.default
          ];
        };

        iso = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/iso/configuration.nix
          ];
        };

      } // vmNixosConfigurations;

      vmDeployments = vmHostNames;

      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          inputs.agenix.packages."x86_64-linux".default
          ansible
          bun
          jq
          nodejs
          python3
          python3Packages.pika
          python3Packages.requests
        ];
      };
    };
}
