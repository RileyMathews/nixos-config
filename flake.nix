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
    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, nixpkgs-unstable, nixos-generators, disko, agenix, sops-nix, kolide, auto-cpufreq }:
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

      # Optional: define per-host extra modules here.
      # Anything not listed falls back to defaultModules.
      hostExtras = {
        picard = [
          kolide.nixosModules.kolide-launcher
          auto-cpufreq.nixosModules.default
        ];
        iso = [ ];
      };

      # Optional: define per-host "base modules" you want on most machines
      defaultModules = [
        disko.nixosModules.disko
        agenix.nixosModules.default
      ];

      mkHost = hostName:
        let
          hostPath = ./hosts/${hostName}/configuration.nix;
          extras = hostExtras.${hostName} or [ ];
          modules =
            # If you want *some* hosts (like iso) to NOT get default modules,
            # just set hostExtras.iso = [] and move iso to a "noDefaults" set,
            # or keep a hostDefaults map. Simplest: special-case here:
            (if hostName == "iso" then [ hostPath ] else defaultModules ++ [ hostPath ] ++ extras);
        in
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit system unstablePkgs; };
          inherit modules;
        };

      # Discover directories under ./hosts automatically
      hostNames =
        builtins.attrNames (builtins.readDir ./hosts);

      # Keep only directories that contain configuration.nix
      validHostNames =
        lib.filter (n:
          let t = (builtins.readDir ./hosts).${n};
          in t == "directory" && builtins.pathExists (./hosts/${n}/configuration.nix)
        ) hostNames;

    in {
      nixosConfigurations =
        lib.genAttrs validHostNames mkHost;

      # If you still want an explicit list for vmDeployments, keep it separate
      vmDeployments = [
        "pg17"
        "worf"
        "forgejo"
        "backup-server"
        "borg"
        "defiant"
        "bridge"
        "discovery"
        "relay"
        "data"
        "redis"
        "engineering"
        "enterprise"
      ];

      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          agenix.packages.${system}.default
          jq
        ];
      };
    };
}

