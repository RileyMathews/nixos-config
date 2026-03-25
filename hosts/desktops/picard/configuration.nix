{
  config,
  pkgs,
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

  boot.kernelPackages = inputs.unstablePkgs.linuxPackages_zen;
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

  powerManagement.cpuFreqGovernor = "performance";
  system.stateVersion = "25.05";
}
