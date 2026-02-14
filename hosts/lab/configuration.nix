{
  config,
  modulesPath,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
{
  imports = [
    ./../../modules/vms/basic-disk-config.nix
    ./../../modules/vms/basic-hardware-config.nix
    ./../../modules/vms/basic-config.nix
    ./../../modules/vms/swap-config.nix
    ./../../modules/tailscale
  ];
  networking.hostName = "lab";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;

  age.secrets.forgejo-runner-token-file = {
    file = ../../secrets/forgejo-runner-token-file.age;
    mode = "0400";
  };

  virtualisation.podman = {
    enable = true;
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.forgejo = {
      enable = true;
      name = "forgejo-runner-lab-01";
      url = "https://git.rileymathews.com";
      tokenFile = config.age.secrets.forgejo-runner-token-file.path;
      labels = [
        "ubuntu-latest:docker://node:22-bookworm"
      ];
      settings = {
        runner.capacity = 10;
      };
    };
  };
}
