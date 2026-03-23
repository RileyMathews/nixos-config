{
  description = "Flake for nixos configuration";

  inputs = {
    pr-tracker.url = "github:rileymathews/pr-tracker-rust";
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
    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode = {
      url = "github:anomalyco/opencode?ref=v1.2.27";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    worktrunk = {
      url = "github:max-sixty/worktrunk?ref=v0.29.4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    forgebot = {
      url = "github:rileymathews/forgebot";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
    ghostty.url = "github:ghostty-org/ghostty?ref=v1.3.1";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix?ref=release-25.11";
    tree-sitter = {
      url = "github:tree-sitter/tree-sitter?ref=v0.26.7";
    };
    television = {
      url = "github:alexpasmantier/television?ref=0.15.3";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    nvf = {
      url = "github:NotAShelf/nvf";
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
          inputs.nix-cachyos-kernel.overlays.pinned
        ];
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
      };

    in {
      nixosConfigurations = {

        picard = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inputs = allInputs; };
          modules = [
            ./hosts/desktops/picard/configuration.nix
            inputs.home-manager.nixosModules.home-manager
            inputs.kolide.nixosModules.kolide-launcher
          ];
        };

        ds9 = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inputs = allInputs; };
          modules = [
            ./hosts/desktops/ds9/configuration.nix
            inputs.home-manager.nixosModules.home-manager
            inputs.kolide.nixosModules.kolide-launcher
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
          python3Packages.requests
        ];
      };
    };
}
