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
      url = "github:anomalyco/opencode?ref=v1.2.15";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    worktrunk = {
      url = "github:max-sixty/worktrunk?ref=v0.28.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    forgebot = {
      url = "github:rileymathews/forgebot";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, nixpkgs-unstable, nixos-generators, disko, agenix, sops-nix, kolide, auto-cpufreq, home-manager, pr-tracker, opencode, worktrunk, forgebot }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      unstablePkgs = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      lib = nixpkgs.lib;

      vmDefaultModules = [
        disko.nixosModules.disko
        agenix.nixosModules.default
      ];

      mkNixosHost = {
        hostPath,
        extraModules ? [ ],
        includeDefaults ? true,
      }:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit system unstablePkgs pr-tracker agenix opencode worktrunk forgebot; };
          modules =
            (if includeDefaults then vmDefaultModules else [ ])
            ++ [ hostPath ]
            ++ extraModules;
        };

      mkVmHost = hostName:
        mkNixosHost {
          hostPath = ./hosts/vms/${hostName}/configuration.nix;
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

        picard = mkNixosHost {
          hostPath = ./hosts/desktops/picard/configuration.nix;
          extraModules = [
            home-manager.nixosModules.home-manager
            kolide.nixosModules.kolide-launcher
            auto-cpufreq.nixosModules.default
          ];
        };

        nas = mkNixosHost {
          hostPath = ./hosts/nas/configuration.nix;
          extraModules = [];
        };

        iso = mkNixosHost {
          hostPath = ./hosts/iso/configuration.nix;
          includeDefaults = false;
        };

      } // vmNixosConfigurations;

      homeConfigurations = {
        ds9 = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit system unstablePkgs; };
          modules = [
            agenix.homeManagerModules.default
            ./hosts/desktops/ds9/home.nix
          ];
        };
      };

      vmDeployments = vmHostNames;

      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          agenix.packages.${system}.default
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
