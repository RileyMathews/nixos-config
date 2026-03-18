{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./nvidia-offload-config.nix
    ../shared/base.nix
  ];

  environment.variables = {
    GHC_JOBS = "16";
  };

  boot = {
    initrd = {
      luks.devices."luks-acc369d3-8fac-4a34-a4cd-b209e7710813".crypttabExtraOpts = [ "tpm2-device=auto" ];
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  networking.hostName = "picard";


  hardware = {
    system76 = {
      firmware-daemon.enable = true;
      kernel-modules.enable = true;
    };
  };


  services = {
    scx = {
      enable = true;
      scheduler = "scx_bpfland";
    };

    udev.extraRules = ''
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    '';

    power-profiles-daemon.enable = true;
    thermald.enable = true;

  };

  home-manager = {
    useGlobalPkgs = false;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
    users.riley = {
      _module.args.pkgs = lib.mkForce inputs.unstablePkgs;
      imports = [
        ../../../modules/home-manager/riley
        inputs.pr-tracker.homeManagerModules.default
        inputs.agenix.homeManagerModules.default
        inputs.stylix.homeModules.stylix
      ];
      riley.browser = "google-chrome-stable";
      riley.opencode.profile = "work";
      riley.targets.genericLinux.enable = false;
      services.pr-tracker-sync.enable = true;
    };
  };

  system.stateVersion = "25.05";
}
