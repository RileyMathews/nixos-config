{
  description = "Flake for nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs?ref=master";
    sentinelone.url = "github:devusb/sentinelone-nix";
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
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      unstablePkgs = import inputs.nixpkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [ 
          inputs.nur.overlays.default 
        ];
      };

      bleedingEdgePkgs = import inputs.nixpkgs-master {
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
          ];
        };

      vmHostNames =
        let
          vmEntries = builtins.readDir ./hosts/vms;
        in
        lib.filter (n:
          vmEntries.${n} == "directory" && builtins.pathExists (./hosts/vms/${n}/configuration.nix)
        ) (builtins.attrNames vmEntries);

      vmNixosConfigurations = lib.genAttrs vmHostNames mkVmHost;

      allInputs = inputs // {
        inherit unstablePkgs;
        inherit bleedingEdgePkgs;
      };

    in {
      nixosConfigurations = {

        picard = inputs.nixpkgs-unstable.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inputs = allInputs; };
          modules = [
            ./hosts/desktops/picard/configuration.nix
            inputs.kolide.nixosModules.kolide-launcher
            inputs.sentinelone.nixosModules.sentinelone
            ({ pkgs, ... }: {
              services.sentinelone = {
                enable = true;
                sentinelOneManagementTokenPath = ./s1token;          # Point to the file with the enrollment key
                customerId = "erik@mercury.com-composer";            # USE: emailAddress-hostname
                package = pkgs.sentinelone.overrideAttrs (old: {
                  pname = "sentinelagent";
                  version = "25.4.1.24";                             # Match the package version
                  src = ./SentinelAgent_linux_x86_64_v25_4_1_24.deb; # Point to the package you've downloaded
                });
              };

            })
          ];
        };

        nas = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/nas/configuration.nix
            inputs.agenix.nixosModules.default
          ];
        };

        thegenerosityco = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/thegenerosityco/configuration.nix
            inputs.agenix.nixosModules.default
          ];
        };

        iso = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
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
